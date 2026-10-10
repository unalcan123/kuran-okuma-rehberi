import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'audio_diagnostics_web.dart';
import 'web_audio_port.dart';

/// [WebAudioPort] on the browser (package:web).
///
/// The audio context is made — or woken, or replaced when iOS left it
/// "interrupted" and would not give it back — in the user's own touch
/// event (a capture listener on the window, so before Flutter handles the
/// touch and before any `await`). The first touch also plays one silent
/// sample in it and touches the audio elements, which is what iOS needs to
/// let them play later (the next ayet after a pause, for instance).
class JsWebAudioPort extends WebAudioPort {
  JsWebAudioPort({this.diagnostics}) {
    diagnostics?.status = _describe;
  }

  /// Whether this browser has Web Audio at all.
  static bool get isSupported => web.window.has('AudioContext');

  final AudioDiagnostics? diagnostics;

  web.AudioContext? _context;
  JSFunction? _onContextState;

  /// The silent sample has been played in the current context.
  bool _unlocked = false;

  /// A resume of the current context did not work: if it stays
  /// "interrupted", the next touch makes a new context.
  bool _resumeFailed = false;

  final _channels = <JsMediaChannel>[];
  final _listeners = <(web.EventTarget, String, JSFunction)>[];

  void Function(bool visible)? _onVisibility;
  void Function(AudioContextStatus status)? _onStatus;

  static const _gestures = [
    'pointerdown',
    'pointerup',
    'touchstart',
    'touchend',
    'mousedown',
    'keydown',
    'click',
  ];

  @override
  AudioContextStatus get status => _statusOf(_context);

  static AudioContextStatus _statusOf(web.AudioContext? context) =>
      switch (context?.state) {
        null => AudioContextStatus.none,
        'running' => AudioContextStatus.running,
        'suspended' => AudioContextStatus.suspended,
        'interrupted' => AudioContextStatus.interrupted,
        _ => AudioContextStatus.closed,
      };

  @override
  void attach({
    required void Function(bool visible) onVisibility,
    required void Function(AudioContextStatus status) onStatus,
  }) {
    _onVisibility = onVisibility;
    _onStatus = onStatus;
    final gesture = ((web.Event event) => _onGesture(event)).toJS;
    for (final type in _gestures) {
      _listen(web.window, type, gesture, capture: true);
    }
    _listen(
      web.document,
      'visibilitychange',
      ((web.Event _) => _visibility(web.document.visibilityState == 'visible'))
          .toJS,
    );
    _listen(web.window, 'pagehide', ((web.Event _) => _visibility(false)).toJS);
    _listen(web.window, 'pageshow', ((web.Event _) => _visibility(true)).toJS);
    diagnostics?.log('hazır', 'Web Audio motoru');
  }

  void _listen(
    web.EventTarget target,
    String type,
    JSFunction listener, {
    bool capture = false,
  }) {
    target.addEventListener(
      type,
      listener,
      web.AddEventListenerOptions(capture: capture, passive: true),
    );
    _listeners.add((target, type, listener));
  }

  void _visibility(bool visible) {
    diagnostics?.log(visible ? 'görünür' : 'arka plan', _describeContext());
    _onVisibility?.call(visible);
  }

  /// In the touch event itself: no `await` before `resume()`.
  void _onGesture(web.Event event) {
    // A script's click is no user touch: it could not unlock sound anyway.
    if (!event.isTrusted) return;
    var context = _context;
    final state = context?.state;
    if (context == null ||
        state == 'closed' ||
        (state == 'interrupted' && _resumeFailed)) {
      context = _replaceContext(reason: state ?? 'ilk dokunuş');
    } else if (state == 'running' &&
        _unlocked &&
        _channels.every((channel) => channel.unlocked)) {
      return; // nothing to do: the usual case
    }
    if (context.state != 'running') _resumeInGesture(context, event.type);
    if (!_unlocked) {
      _unlocked = true;
      _playSilence(context);
    }
    for (final channel in _channels) {
      channel.unlock();
    }
  }

  void _resumeInGesture(web.AudioContext context, String why) {
    diagnostics?.log('resume', '$why (${context.state})');
    context.resume().toDart.then(
      (_) {
        if (identical(context, _context)) _resumeFailed = false;
      },
      onError: (Object error) {
        if (!identical(context, _context)) return;
        _resumeFailed = true;
        diagnostics?.log('resume reddedildi', '$error');
      },
    );
    // A resume that never settles is a failure too (WebKit 276016).
    Timer(const Duration(milliseconds: 1200), () {
      if (identical(context, _context) && context.state != 'running') {
        _resumeFailed = true;
        diagnostics?.log('resume olmadı', context.state);
      }
    });
  }

  web.AudioContext _replaceContext({required String reason}) {
    final old = _context;
    if (old != null) {
      if (_onContextState != null) {
        old.removeEventListener('statechange', _onContextState);
      }
      if (old.state != 'closed') {
        old.close().toDart.then((_) {}, onError: (Object _) {});
      }
    }
    final context = web.AudioContext();
    final listener = ((web.Event _) => _contextChanged(context)).toJS;
    context.addEventListener('statechange', listener);
    _onContextState = listener;
    _context = context;
    _unlocked = false;
    _resumeFailed = false;
    diagnostics?.log('yeni bağlam', '$reason → ${_describeContext()}');
    // Sounds of the old context are gone; tell the engine.
    _onStatus?.call(_statusOf(context));
    return context;
  }

  void _contextChanged(web.AudioContext context) {
    if (!identical(context, _context)) return;
    diagnostics?.log('bağlam', context.state);
    if (context.state == 'running') _resumeFailed = false;
    _onStatus?.call(_statusOf(context));
  }

  void _playSilence(web.AudioContext context) {
    try {
      final source = context.createBufferSource()
        ..buffer = context.createBuffer(1, 1, context.sampleRate);
      source.connect(context.destination);
      source.onended = ((web.Event _) => source.disconnect()).toJS;
      source.start(0);
    } catch (_) {
      // Only an unlock aid.
    }
  }

  @override
  void ensureContext() {
    final state = _context?.state;
    if (state == null || state == 'closed') {
      _replaceContext(reason: state == null ? 'ses isteği' : 'kapalıydı');
    }
  }

  @override
  Future<bool> resume(Duration timeout) async {
    final context = _context;
    if (context == null) return false;
    if (context.state == 'running') return true;
    try {
      await context.resume().toDart.timeout(timeout);
    } catch (_) {
      // Refused or no answer: checked below.
    }
    final running = identical(context, _context) && context.state == 'running';
    if (!running && identical(context, _context)) _resumeFailed = true;
    if (!running) diagnostics?.log('çalışmıyor', context.state);
    return running;
  }

  @override
  Future<DecodedSound> decode(Uint8List bytes) async {
    ensureContext();
    // decodeAudioData takes the buffer over: give it a copy, the cache
    // keeps its bytes.
    final copy = Uint8List.fromList(bytes);
    final buffer = await _context!.decodeAudioData(copy.buffer.toJS).toDart;
    return _JsDecodedSound(buffer);
  }

  @override
  SoundVoice start(
    DecodedSound sound, {
    double offset = 0,
    required void Function() onEnded,
  }) {
    final context = _context!;
    final buffer = (sound as _JsDecodedSound).buffer;
    final source = context.createBufferSource()..buffer = buffer;
    final gain = context.createGain();
    source.connect(gain);
    gain.connect(context.destination);
    final voice = _JsVoice(
      context,
      source,
      gain,
      offset: offset,
      duration: buffer.duration,
      onEnded: onEnded,
    );
    source.onended = ((web.Event _) => voice._ended()).toJS;
    source.start(0, offset);
    diagnostics?.log(
      'buffer çal',
      '${buffer.duration.toStringAsFixed(2)} sn, ${buffer.sampleRate} Hz'
          '${offset > 0 ? ', ${offset.toStringAsFixed(2)} sn\'den' : ''}',
    );
    return voice;
  }

  @override
  MediaChannel createMediaChannel() {
    final channel = JsMediaChannel(this);
    _channels.add(channel);
    return channel;
  }

  @override
  String assetUrl(String assetPath) =>
      ui_web.assetManager.getAssetUrl('assets/$assetPath');

  @override
  void log(String event, [String? detail]) => diagnostics?.log(event, detail);

  String _describeContext() {
    final context = _context;
    if (context == null) return 'bağlam yok';
    var text = '${context.state} ${context.sampleRate.round()} Hz';
    try {
      text +=
          ' base ${(context.baseLatency * 1000).round()} ms'
          ' out ${(context.outputLatency * 1000).round()} ms';
    } catch (_) {
      // Older Safari has no latencies.
    }
    return text;
  }

  String _describe() => 'bağlam: ${_describeContext()}';

  @override
  void dispose() {
    for (final (target, type, listener) in _listeners) {
      target.removeEventListener(
        type,
        listener,
        web.EventListenerOptions(capture: _gestures.contains(type)),
      );
    }
    _listeners.clear();
    for (final channel in [..._channels]) {
      channel.dispose();
    }
    final context = _context;
    _context = null;
    if (context != null && context.state != 'closed') {
      context.close().toDart.then((_) {}, onError: (Object _) {});
    }
  }
}

class _JsDecodedSound implements DecodedSound {
  _JsDecodedSound(this.buffer);

  final web.AudioBuffer buffer;

  @override
  int get memorySize => buffer.length * buffer.numberOfChannels * 4;

  @override
  double get duration => buffer.duration;
}

class _JsVoice implements SoundVoice {
  _JsVoice(
    this._context,
    this._source,
    this._gain, {
    required this.offset,
    required this.duration,
    required this.onEnded,
  }) : _startedAt = _context.currentTime;

  final web.AudioContext _context;
  final web.AudioBufferSourceNode _source;
  final web.GainNode _gain;
  final double offset;
  final double duration;
  final void Function() onEnded;
  final double _startedAt;

  bool _stopped = false;
  bool _done = false;

  @override
  double get position {
    final played = offset + (_context.currentTime - _startedAt);
    return played.clamp(0, duration).toDouble();
  }

  void _ended() {
    if (_done) return;
    _release();
    if (!_stopped) onEnded();
  }

  @override
  void stop() {
    if (_stopped || _done) return;
    _stopped = true;
    try {
      // ~12 ms fade instead of cutting the wave (which clicks).
      final now = _context.currentTime;
      _gain.gain
        ..cancelScheduledValues(now)
        ..setValueAtTime(_gain.gain.value, now)
        ..linearRampToValueAtTime(0, now + 0.012);
      _source.stop(now + 0.015);
    } catch (_) {
      _release();
      return;
    }
    // A suspended or closed context never sends "ended": let go anyway.
    Timer(const Duration(milliseconds: 250), _release);
  }

  void _release() {
    if (_done) return;
    _done = true;
    _source.onended = null;
    try {
      _source.disconnect();
      _gain.disconnect();
    } catch (_) {
      // Already disconnected.
    }
  }
}

/// One plain `<audio>` element for a channel (reused: iOS lets an element
/// that played once play again later without a new touch). Its listeners
/// are added once; a recording's [setSource] callbacks are dropped as soon
/// as another one comes.
class JsMediaChannel implements MediaChannel {
  JsMediaChannel(this._port) {
    _element.preload = 'auto';
    _keepPitch();
    _on('ended', (_) => _ended());
    _on('error', (_) => _error());
    if (_port.diagnostics != null) {
      for (final type in const [
        'playing',
        'waiting',
        'stalled',
        'seeking',
        'pause',
        'ratechange',
      ]) {
        _on(type, (_) => _logEvent(type));
      }
    }
  }

  final JsWebAudioPort _port;
  final web.HTMLAudioElement _element = web.HTMLAudioElement();
  final _listeners = <(String, JSFunction)>[];

  String? _objectUrl;
  String? _src;
  void Function()? _onEnded;
  void Function(Object error)? _onError;
  bool unlocked = false;
  Timer? _watch;

  void _on(String type, void Function(web.Event event) handler) {
    final listener = handler.toJS;
    _element.addEventListener(type, listener);
    _listeners.add((type, listener));
  }

  void _keepPitch() {
    _element.preservesPitch = true;
    (_element as JSObject)['webkitPreservesPitch'] = true.toJS;
  }

  @override
  void setSource({
    required Uint8List? bytes,
    required String url,
    required String mimeType,
    required double rate,
    required void Function() onEnded,
    required void Function(Object error) onError,
  }) {
    _onEnded = onEnded;
    _onError = onError;
    final oldUrl = _objectUrl;
    if (bytes != null) {
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: mimeType),
      );
      _objectUrl = web.URL.createObjectURL(blob);
    } else {
      _objectUrl = null;
    }
    // A new source resets playbackRate to defaultPlaybackRate (HTML
    // "load" algorithm): set both, before it plays.
    _element.defaultPlaybackRate = rate;
    _element.src = _objectUrl ?? url;
    _element.playbackRate = rate;
    _keepPitch();
    _src = _element.src;
    if (oldUrl != null) web.URL.revokeObjectURL(oldUrl);
  }

  @override
  Future<void> play() async {
    await _element.play().toDart;
    unlocked = true;
  }

  @override
  void pause() => _element.pause();

  @override
  void setRate(double rate) {
    _element.defaultPlaybackRate = rate;
    _element.playbackRate = rate;
  }

  @override
  void clear() {
    _onEnded = null;
    _onError = null;
    _src = null;
    _element.pause();
    if (_element.hasAttribute('src')) {
      _element.removeAttribute('src');
      _element.load(); // lets go of the recording
    }
    final oldUrl = _objectUrl;
    _objectUrl = null;
    if (oldUrl != null) web.URL.revokeObjectURL(oldUrl);
  }

  /// In a touch: iOS then lets this element play later without one.
  void unlock() {
    if (unlocked) return;
    unlocked = true;
    if (!_element.hasAttribute('src')) _element.load();
  }

  void _ended() {
    // An "ended" queued for the previous recording finds the new one not
    // ended: ignored.
    if (_src == null || _element.src != _src || !_element.ended) return;
    _port.diagnostics?.log('element bitti');
    _onEnded?.call();
  }

  void _error() {
    if (_src == null || _element.src != _src) return;
    final error = _element.error;
    _onError?.call('MediaError ${error?.code}: ${error?.message}');
  }

  void _logEvent(String type) {
    final diagnostics = _port.diagnostics!;
    diagnostics.log(
      'element $type',
      't=${_element.currentTime.toStringAsFixed(2)} '
          'hız=${_element.playbackRate} varsayılan=${_element.defaultPlaybackRate} '
          'perde=${_element.preservesPitch}',
    );
    if (type == 'playing') _watchStalls();
    if (type == 'pause') {
      _watch?.cancel();
      _watch = null;
    }
  }

  /// Diagnostics only: the element's clock against the real one; a gap
  /// means the sound froze (what was suspected on iOS).
  void _watchStalls() {
    _watch?.cancel();
    var lastWall = web.window.performance.now();
    var lastTime = _element.currentTime;
    _watch = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_element.paused || _element.ended) {
        timer.cancel();
        if (identical(_watch, timer)) _watch = null;
        return;
      }
      final wall = web.window.performance.now();
      final time = _element.currentTime;
      final expected = (wall - lastWall) / 1000 * _element.playbackRate;
      final advanced = time - lastTime;
      if (expected > 0.15 && advanced < expected * 0.5) {
        _port.diagnostics!.log(
          'TAKILMA',
          '${((expected - advanced) * 1000).round()} ms, t=${time.toStringAsFixed(2)}',
        );
      }
      lastWall = wall;
      lastTime = time;
    });
  }

  @override
  void dispose() {
    _watch?.cancel();
    clear();
    for (final (type, listener) in _listeners) {
      _element.removeEventListener(type, listener);
    }
    _listeners.clear();
    _port._channels.remove(this);
  }
}
