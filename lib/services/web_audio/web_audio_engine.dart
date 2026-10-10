import 'dart:async';
import 'dart:collection';

import '../audio_engine.dart';
import '../sound_cache.dart';
import 'web_audio_port.dart';

/// How the web engine plays a sound.
enum WebSoundRoute {
  /// Decoded once, then played from memory through the audio context:
  /// letters, short words and game effects (short, always at speed 1.0).
  decoded,

  /// A plain audio element not connected to the audio context: surahs,
  /// prayers, the Turkish explanations and anything at another speed. The
  /// browser keeps the pitch; a decoded sound's speed would change it.
  element,
}

/// Decoded sounds are kept only for files up to this size (an Elifba clip
/// is at most ~46 KB, a few seconds); longer ones play from an element.
const int kMaxDecodedClipBytes = 96 * 1024;

WebSoundRoute webSoundRouteFor(
  String assetPath, {
  double rate = 1.0,
  int? byteLength,
}) {
  if (rate != 1.0) return WebSoundRoute.element;
  if (byteLength != null && byteLength > kMaxDecodedClipBytes) {
    return WebSoundRoute.element;
  }
  if (assetPath.startsWith('audio/elifba/') ||
      assetPath.startsWith('audio/oyunlar/')) {
    return WebSoundRoute.decoded;
  }
  return WebSoundRoute.element;
}

/// The web's [AudioEngine] (see `docs/SES.md`, "Web ses motoru"):
///
/// - [WebSoundRoute.decoded]: one audio context for the whole app, each
///   sound decoded once (`decodeAudioData`) into a limited cache
///   ([memoryBudget], least recently used goes first), every play a new
///   source node; the main channel's earlier one is stopped first.
/// - [WebSoundRoute.element]: one plain audio element per channel, speed
///   set before it plays (and kept: the browser would reset it on load).
///
/// Every main-channel request has its id; whatever an older request was
///   waiting for (download, decoding, the context) it gives up once a newer
///   request or [stop] came, and an old sound's end is never reported as
///   the new one's.
///
/// Nothing starts by itself: a sound that could not start (the context
/// would not run) is dropped, not started later; going to the background
/// stops decoded sounds, and coming back only wakes the context.
class WebAudioEngine extends AudioEngine {
  WebAudioEngine(
    this._port,
    this._cache, {
    this.memoryBudget = 20 << 20,
    this.resumeTimeout = const Duration(milliseconds: 1500),
  }) : _media = _port.createMediaChannel() {
    _port.attach(onVisibility: _onVisibility, onStatus: _onStatus);
  }

  final WebAudioPort _port;
  final SoundCache _cache;

  /// Most memory the decoded sounds may take (a lesson's ~30 letters take
  /// ~4-5 MB).
  final int memoryBudget;

  /// How long a play waits for the audio context to run.
  final Duration resumeTimeout;

  // --- Main channel -------------------------------------------------------

  /// The request playing / paused / getting ready; null when stopped.
  int? _id;
  WebSoundRoute? _route;
  double _rate = 1.0;
  bool _paused = false;

  SoundVoice? _voice;
  DecodedSound? _sound;
  double _pausedAt = 0;

  /// Made at once, so that the first touch already unlocks it on iOS.
  final MediaChannel _media;

  /// [_media] holds the current request's recording.
  bool _mediaReady = false;

  // --- Effect channel -----------------------------------------------------

  int _effectId = 0;
  SoundVoice? _effectVoice;
  MediaChannel? _effectMedia;

  // --- Decoded sounds -----------------------------------------------------

  /// In order of use, least recent first (a map literal keeps the order).
  final _sounds = <String, DecodedSound>{};
  final _decoding = <String, Future<DecodedSound?>>{};

  /// Could not be decoded: these play from an element.
  final _undecodable = <String>{};
  int _memory = 0;

  final _wanted = Queue<String>();
  bool _preloading = false;
  int _preloadAllowance = 0;

  /// Memory the decoded sounds take now.
  int get memoryUsed => _memory;

  /// Decoded and kept (for tests and diagnostics).
  Iterable<String> get decodedAssets => _sounds.keys;

  @override
  Future<void> play(int id, String assetPath, {required double rate}) async {
    _silenceMain(keepElement: true);
    _id = id;
    _rate = rate;
    _paused = false;
    _pausedAt = 0;
    var route = webSoundRouteFor(
      assetPath,
      rate: rate,
      byteLength: _cache.peek(assetPath)?.length,
    );
    if (_undecodable.contains(assetPath)) route = WebSoundRoute.element;
    _port.log('çal #$id', '${route.name} $assetPath hız $rate');
    if (route == WebSoundRoute.decoded) {
      if (_route == WebSoundRoute.element) _media.clear();
      _route = route;
      final sound = await _decoded(assetPath);
      if (_id != id) return;
      if (sound != null) return _startDecoded(id, sound);
      route = WebSoundRoute.element;
    }
    _route = route;
    await _playElement(id, assetPath);
  }

  Future<void> _startDecoded(int id, DecodedSound sound) async {
    _sound = sound;
    if (!await _contextRuns()) {
      if (_id != id) return;
      _forget();
      throw StateError('ses bağlamı çalışmıyor');
    }
    if (_id != id || _paused) return; // paused before it began: resume()
    _startVoice(id, sound, 0);
  }

  void _startVoice(int id, DecodedSound sound, double offset) {
    late final SoundVoice voice;
    voice = _port.start(
      sound,
      offset: offset,
      onEnded: () {
        if (_voice != voice || _id != id) return;
        _forget();
        onEnded?.call(id);
      },
    );
    _voice = voice;
  }

  Future<void> _playElement(int id, String assetPath) async {
    // Usually in memory already: then the element plays within the touch.
    var bytes = _cache.peek(assetPath);
    if (bytes == null) {
      bytes = await _cache.load(assetPath);
      if (_id != id) return;
    }
    _media.setSource(
      bytes: bytes,
      url: _port.assetUrl(assetPath),
      mimeType: _mimeType(assetPath),
      rate: _rate,
      onEnded: () {
        if (_id != id) return;
        _forget();
        onEnded?.call(id);
      },
      onError: (error) {
        if (_id != id) return;
        _port.log('element-error', '$assetPath $error');
        _forget();
        _media.clear();
        onEnded?.call(id, interrupted: true);
      },
    );
    _mediaReady = true;
    if (_paused) return; // resume() plays it
    try {
      await _media.play();
    } catch (error) {
      // A newer request, stop() or pause() cut it short: that is expected.
      if (_id != id || _paused) return;
      _forget();
      _media.clear();
      rethrow;
    }
  }

  /// Stops what the main channel plays without reporting it.
  void _silenceMain({bool keepElement = false}) {
    _voice?.stop();
    _voice = null;
    _sound = null;
    _mediaReady = false;
    if (_route == WebSoundRoute.element) {
      if (keepElement) {
        _media.pause();
      } else {
        _media.clear();
      }
    }
  }

  void _forget() {
    _id = null;
    _route = null;
    _paused = false;
    _voice = null;
    _sound = null;
    _mediaReady = false;
  }

  @override
  Future<void> pause() async {
    if (_id == null || _paused) return;
    _paused = true;
    if (_route == WebSoundRoute.element) {
      _media.pause();
      return;
    }
    final voice = _voice;
    if (voice != null) {
      _pausedAt = voice.position;
      voice.stop();
      _voice = null;
    }
  }

  @override
  Future<void> resume() async {
    final id = _id;
    if (id == null || !_paused) return;
    _paused = false;
    if (_route == WebSoundRoute.element) {
      if (!_mediaReady) return; // still loading: play() goes on
      try {
        await _media.play();
      } catch (error) {
        if (_id != id || _paused) return;
        _interrupt(id);
      }
      return;
    }
    final sound = _sound;
    if (sound == null) return; // still decoding: play() goes on
    if (!await _contextRuns()) {
      if (_id == id && !_paused) _interrupt(id);
      return;
    }
    if (_id != id || _paused || _voice != null) return;
    _startVoice(id, sound, _pausedAt);
  }

  @override
  Future<void> stop() async {
    _silenceMain();
    _forget();
  }

  @override
  Future<void> setRate(double rate) async {
    _rate = rate;
    // A decoded sound keeps its speed (its speed would change the pitch);
    // only short sounds at 1.0 go that way.
    if (_id != null && _route == WebSoundRoute.element && _mediaReady) {
      _media.setRate(rate);
    }
  }

  void _interrupt(int id) {
    _silenceMain();
    _forget();
    onEnded?.call(id, interrupted: true);
  }

  @override
  Future<void> playEffect(String assetPath) async {
    final id = ++_effectId;
    _silenceEffect();
    final sound =
        _undecodable.contains(assetPath) ? null : await _decoded(assetPath);
    if (id != _effectId) return;
    if (sound == null) {
      final media = _effectMedia ??= _port.createMediaChannel();
      final bytes = await _cache.load(assetPath);
      if (id != _effectId) return;
      media.setSource(
        bytes: bytes,
        url: _port.assetUrl(assetPath),
        mimeType: _mimeType(assetPath),
        rate: 1.0,
        onEnded: () {},
        onError: (_) {},
      );
      await media.play();
      return;
    }
    if (!await _contextRuns() || id != _effectId) return;
    late final SoundVoice voice;
    voice = _port.start(
      sound,
      onEnded: () {
        if (_effectVoice == voice) _effectVoice = null;
      },
    );
    _effectVoice = voice;
  }

  @override
  Future<void> stopEffect() async {
    _effectId++;
    _silenceEffect();
  }

  void _silenceEffect() {
    _effectVoice?.stop();
    _effectVoice = null;
    _effectMedia?.clear();
  }

  Future<bool> _contextRuns() async {
    if (_port.status == AudioContextStatus.running) return true;
    _port.ensureContext();
    return _port.resume(resumeTimeout);
  }

  // --- Decoded sounds -----------------------------------------------------

  Future<DecodedSound?> _decoded(String assetPath) {
    final kept = _sounds.remove(assetPath);
    if (kept != null) {
      _sounds[assetPath] = kept; // most recently used
      return Future.value(kept);
    }
    return _decoding[assetPath] ??= _decode(assetPath);
  }

  Future<DecodedSound?> _decode(String assetPath) async {
    // Yield first so the caller has registered this before it can finish.
    await null;
    try {
      final bytes = await _cache.load(assetPath);
      if (bytes == null) return null; // not downloaded: the element tries
      if (bytes.length > kMaxDecodedClipBytes) {
        _undecodable.add(assetPath);
        return null;
      }
      _port.ensureContext();
      final sound = await _port.decode(bytes);
      _keep(assetPath, sound);
      return sound;
    } catch (error) {
      _port.log('decode-error', '$assetPath $error');
      _undecodable.add(assetPath);
      return null;
    } finally {
      _decoding.remove(assetPath);
    }
  }

  void _keep(String assetPath, DecodedSound sound) {
    final old = _sounds.remove(assetPath);
    if (old != null) _memory -= old.memorySize;
    _sounds[assetPath] = sound;
    _memory += sound.memorySize;
    // A playing voice holds its own sound; forgetting it here only means
    // decoding again next time.
    while (_memory > memoryBudget && _sounds.length > 1) {
      final oldest = _sounds.keys.first;
      _memory -= _sounds.remove(oldest)!.memorySize;
    }
  }

  /// Decodes the screen's short sounds in the background, one at a time,
  /// once the audio context exists (it is made on the first touch; making
  /// it earlier is what iOS dislikes). A screen gets most of the budget.
  @override
  void preload(List<String> assetPaths) {
    final fresh = [
      for (final path in assetPaths)
        if (webSoundRouteFor(path) == WebSoundRoute.decoded &&
            !_sounds.containsKey(path) &&
            !_undecodable.contains(path))
          path,
    ];
    if (fresh.isEmpty) return;
    // The newest screen first; what an earlier screen still wanted waits.
    final rest = _wanted.where((path) => !fresh.contains(path)).toList();
    _wanted
      ..clear()
      ..addAll(fresh)
      ..addAll(rest);
    _preloadAllowance = memoryBudget * 3 ~/ 4;
    unawaited(_preloadNext());
  }

  Future<void> _preloadNext() async {
    if (_preloading) return;
    _preloading = true;
    try {
      while (_wanted.isNotEmpty &&
          _preloadAllowance > 0 &&
          _port.status != AudioContextStatus.none &&
          _port.status != AudioContextStatus.closed) {
        final path = _wanted.removeFirst();
        if (_sounds.containsKey(path)) continue;
        final sound = await _decoded(path);
        if (sound != null) _preloadAllowance -= sound.memorySize;
      }
    } finally {
      _preloading = false;
    }
  }

  // --- Browser events -----------------------------------------------------

  void _onVisibility(bool visible) {
    if (visible) {
      // Only wake the context; nothing was left to play in it.
      final status = _port.status;
      if (status == AudioContextStatus.suspended ||
          status == AudioContextStatus.interrupted) {
        unawaited(_port.resume(resumeTimeout));
      }
      return;
    }
    _stopDecodedVoices();
  }

  void _onStatus(AudioContextStatus status) {
    switch (status) {
      case AudioContextStatus.running:
        unawaited(_preloadNext()); // the context exists: decode the screen's
      case AudioContextStatus.suspended:
      case AudioContextStatus.interrupted:
      case AudioContextStatus.closed:
        // A call, Siri, the background, or a new context: a decoded sound
        // would otherwise go on by itself when the context comes back.
        _stopDecodedVoices();
        if (status == AudioContextStatus.suspended) unawaited(_preloadNext());
      case AudioContextStatus.none:
        break;
    }
  }

  void _stopDecodedVoices() {
    _effectVoice?.stop();
    _effectVoice = null;
    final id = _id;
    if (id != null && _route == WebSoundRoute.decoded && _voice != null) {
      _interrupt(id);
    }
  }

  static String _mimeType(String assetPath) =>
      assetPath.endsWith('.wav') ? 'audio/wav' : 'audio/mpeg';

  @override
  void dispose() {
    _silenceMain();
    _forget();
    _silenceEffect();
    _media.dispose();
    _effectMedia?.dispose();
    _sounds.clear();
    _wanted.clear();
    _port.dispose();
  }
}
