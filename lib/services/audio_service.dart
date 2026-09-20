import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/arabic_letter.dart';
import 'sound_cache.dart';
import 'sound_store.dart';

enum AudioPlaybackState { stopped, playing, paused }

/// App-wide audio player — one [AudioPlayer] instance for the whole
/// app, so starting a new sound always stops whatever was playing
/// instead of two clips overlapping.
///
/// Elifba only ever plays one short clip at a time ([playLetter]).
/// Sureler need a bit more: play/pause/stop and reciting a surah's
/// besmele + ayetler back-to-back as one continuous "Dinle" ([playPlaylist]).
/// Both sit on the same [AudioPlayer], so nothing can play over
/// anything else app-wide.
///
/// On the web a sound is a download, and the browser player fetches the
/// file again for every single play. Screens therefore call [preload]
/// when they open, and every sound is played from memory once loaded
/// (see [SoundCache]). Native apps have the files locally and skip this.
class AudioService extends ChangeNotifier {
  AudioService({SoundCache? cache})
    : _cache =
          cache ?? SoundCache(store: createSoundStore(kSoundCacheVersion)) {
    _player.onPlayerComplete.listen((_) => _handleComplete());
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer? _effectPlayer;
  final SoundCache _cache;

  String? _currentAsset;
  AudioPlaybackState _state = AudioPlaybackState.stopped;
  List<String>? _queue;
  int _queueIndex = 0;

  /// Bumped by every new play request and by [stop]. A request that finds
  /// the number changed while it was waiting (a newer tap, a stop) gives
  /// up instead of starting late or overwriting the newer state.
  int _playToken = 0;

  /// The asset path currently loaded (playing or paused) — null when
  /// stopped. Lets UI highlight "this is the thing that's playing".
  String? get currentAsset => _currentAsset;
  AudioPlaybackState get state => _state;
  bool get isPlaying => _state == AudioPlaybackState.playing;
  bool get isPaused => _state == AudioPlaybackState.paused;

  /// Downloads these sounds in the background so that tapping them later
  /// starts at once. Call it when a screen opens with the asset paths the
  /// screen can play; nulls are ignored. Only does something on the web.
  void preload(Iterable<String?> assetPaths) {
    if (!kIsWeb) return;
    unawaited(
      _cache.preload([
        for (final path in assetPaths)
          if (path != null && path.isNotEmpty) path,
      ]),
    );
  }

  Future<void> playLetter(ArabicLetter letter) async {
    final assetPath = letter.audioAsset;
    if (assetPath == null || assetPath.isEmpty) return;
    await playAsset(assetPath);
  }

  /// Tapping the same asset that's already current toggles pause/
  /// resume instead of restarting it from the beginning; tapping a
  /// different (or stopped) asset starts it fresh. Matches how the
  /// old project's per-ayet play button behaved.
  Future<void> playOrToggle(String assetPath) async {
    if (_currentAsset == assetPath) {
      if (_state == AudioPlaybackState.playing) {
        await pause();
        return;
      }
      if (_state == AudioPlaybackState.paused) {
        await resume();
        return;
      }
    }
    await playAsset(assetPath);
  }

  /// Plays a single asset, replacing whatever was playing before.
  Future<void> playAsset(String assetPath) async {
    _queue = null;
    await _start(assetPath);
  }

  /// Plays a list of assets back-to-back, advancing automatically as
  /// each one finishes — e.g. a surah's besmele followed by its
  /// ayetler, one continuous "Dinle".
  Future<void> playPlaylist(List<String> assetPaths) async {
    if (assetPaths.isEmpty) return;
    _queue = assetPaths;
    _queueIndex = 0;
    await _playQueueCurrent();
  }

  Future<void> _playQueueCurrent() async {
    final queue = _queue;
    if (queue == null || _queueIndex >= queue.length) return;
    // Have the next clip ready so the gap between clips stays short.
    if (kIsWeb && _queueIndex + 1 < queue.length) {
      unawaited(_cache.load(queue[_queueIndex + 1]));
    }
    await _start(queue[_queueIndex]);
  }

  Future<void> _start(String assetPath) async {
    final token = ++_playToken;
    try {
      await _player.stop();
      if (token != _playToken) return;
      _currentAsset = assetPath;
      _state = AudioPlaybackState.playing;
      notifyListeners();
      final source = await _sourceFor(assetPath);
      if (token != _playToken) return;
      await _player.play(source);
    } catch (error) {
      debugPrint('AudioService: "$assetPath" çalınamadı — $error');
      if (token != _playToken) return;
      _queue = null;
      _queueIndex = 0;
      _state = AudioPlaybackState.stopped;
      _currentAsset = null;
      notifyListeners();
    }
  }

  /// From memory on the web (loading it first if it isn't there yet),
  /// straight from the app's own files everywhere else.
  Future<Source> _sourceFor(String assetPath) async {
    if (!kIsWeb) return AssetSource(assetPath);
    final bytes = await _cache.load(assetPath);
    if (bytes == null) return AssetSource(assetPath);
    return BytesSource(
      bytes,
      mimeType: assetPath.endsWith('.wav') ? 'audio/wav' : 'audio/mpeg',
    );
  }

  void _handleComplete() {
    final queue = _queue;
    if (queue != null && _queueIndex < queue.length - 1) {
      _queueIndex++;
      _playQueueCurrent();
      return;
    }
    _queue = null;
    _currentAsset = null;
    _state = AudioPlaybackState.stopped;
    notifyListeners();
  }

  /// Kısa efekt sesi (oyunlarda doğru cevap gibi). Ders/harf sesinden ayrı
  /// bir kanaldır: efekt çalarken çalan harf sesi kesilmez ve tersi; ama aynı
  /// anda yalnızca bir efekt çalar.
  Future<void> playEffect(String assetPath) async {
    try {
      final player = _effectPlayer ??= AudioPlayer();
      await player.stop();
      await player.play(await _sourceFor(assetPath));
    } catch (error) {
      debugPrint('AudioService: efekt "$assetPath" çalınamadı — $error');
    }
  }

  Future<void> stopEffect() async {
    try {
      await _effectPlayer?.stop();
    } catch (error) {
      debugPrint('AudioService: efekt durdurulamadı — $error');
    }
  }

  Future<void> pause() async {
    if (_state != AudioPlaybackState.playing) return;
    await _player.pause();
    _state = AudioPlaybackState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_state != AudioPlaybackState.paused) return;
    await _player.resume();
    _state = AudioPlaybackState.playing;
    notifyListeners();
  }

  Future<void> stop() async {
    _playToken++;
    _queue = null;
    _queueIndex = 0;
    await _player.stop();
    _currentAsset = null;
    _state = AudioPlaybackState.stopped;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    _effectPlayer?.dispose();
    super.dispose();
  }
}
