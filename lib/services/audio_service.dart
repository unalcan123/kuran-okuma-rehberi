import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/arabic_letter.dart';
import 'audio_engine.dart';
import 'sound_cache.dart';
import 'sound_store.dart';

enum AudioPlaybackState { stopped, playing, paused }

/// App-wide audio player — one player for the whole
/// app, so starting a new sound always stops whatever was playing
/// instead of two clips overlapping. The sound itself comes from an
/// [AudioEngine] (`audioplayers` in the apps, its own engine on the web).
///
/// Elifba only ever plays one short clip at a time ([playLetter]).
/// Sureler need a bit more: play/pause/stop and reciting a surah's
/// besmele + ayetler back-to-back as one continuous "Dinle" ([playPlaylist]).
/// Both sit on the same player, so nothing can play over
/// anything else app-wide.
///
/// On the web a sound is a download, and the browser player fetches the
/// file again for every single play. Screens therefore call [preload]
/// when they open, and every sound is played from memory once loaded
/// (see [SoundCache]). Native apps have the files locally and skip this.
/// Orijinal kayıtlar (hocamızın okuduğu harf/ders sesleri) hiç değiştirilmez.
/// Bir kaydın yalnızca çalma seviyesi düzeltilecekse düzeltilmiş kopyası
/// `assets/audio/duzeltmeler/` altına konur ve burada eşlenir; uygulama
/// orijinal yolu ister, kopya çalar. Satırı silmek orijinale döndürür.
const Map<String, String> kAudioReplacements = {
  // Ders 1 Lam çok yüksek ve kırpılıyordu ("bağırıyor"): ~4 dB kısık,
  // tepe sınırlı, kuyruk yumuşak (kullanıcı isteği, 2026-10-12).
  'audio/elifba/ders_1_harfler/23_lam.mp3':
      'audio/duzeltmeler/23_lam_seviye.mp3',
};

/// [assetPath] yerine çalınacak dosya (çoğu zaman kendisi).
String playableAsset(String assetPath) =>
    kAudioReplacements[assetPath] ?? assetPath;

class AudioService extends ChangeNotifier {
  AudioService({SoundCache? cache, AudioEngineFactory? engine})
    : _cache =
          cache ?? SoundCache(store: createSoundStore(kSoundCacheVersion)) {
    _engine = (engine ?? createAudioEngine)(_cache)..onEnded = _handleEnded;
  }

  late final AudioEngine _engine;
  final SoundCache _cache;

  String? _currentAsset;
  AudioPlaybackState _state = AudioPlaybackState.stopped;
  List<String>? _queue;
  int _queueIndex = 0;

  /// Bumped by every new play request and by [stop]. A request that finds
  /// the number changed while it was waiting (a newer tap, a stop) gives
  /// up instead of starting late or overwriting the newer state.
  int _playToken = 0;

  /// Speed of every clip ([setPlaybackRate]); 1.0 = normal. Kept while
  /// nothing plays too: the next clip starts at it.
  double _playbackRate = 1.0;

  /// The asset path currently loaded (playing or paused) — null when
  /// stopped. Lets UI highlight "this is the thing that's playing".
  String? get currentAsset => _currentAsset;
  AudioPlaybackState get state => _state;
  bool get isPlaying => _state == AudioPlaybackState.playing;
  bool get isPaused => _state == AudioPlaybackState.paused;
  double get playbackRate => _playbackRate;

  Duration? get position => _currentAsset == null ? null : _engine.position;

  /// Reading speed (the Sureler / Dualar "Okuma Hızı", 0.75–1.25) on the
  /// same single player, applied to what is playing now and to every clip
  /// after it. The platforms keep the pitch (time-stretch, not a faster
  /// tape). Screens that set it put it back to 1.0 when they close, so the
  /// Elifba sounds always play at normal speed.
  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate;
    if (_state == AudioPlaybackState.stopped) return;
    try {
      await _engine.setRate(rate);
    } catch (error) {
      debugPrint('AudioService: hız ayarlanamadı — $error');
    }
  }

  /// Downloads these sounds in the background so that tapping them later
  /// starts at once. Call it when a screen opens with the asset paths the
  /// screen can play; nulls are ignored. Only does something on the web.
  void preload(Iterable<String?> assetPaths) {
    if (!kIsWeb) return;
    final paths = [
      for (final path in assetPaths)
        if (path != null && path.isNotEmpty) playableAsset(path),
    ];
    unawaited(_cache.preload(paths));
    _engine.preload(paths);
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

  /// Synchronous up to the engine's first wait, so that on the web a sound
  /// already in memory starts within the touch that asked for it.
  Future<void> _start(String requested) async {
    final assetPath = playableAsset(requested);
    final token = ++_playToken;
    _currentAsset = requested;
    _state = AudioPlaybackState.playing;
    notifyListeners();
    if (token != _playToken) return; // a listener already started another
    try {
      await _engine.play(token, assetPath, rate: _playbackRate);
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

  /// The engine reports the end of request [id]; an older request's end
  /// (a sound already replaced or stopped) is ignored.
  void _handleEnded(int id, {bool interrupted = false}) {
    if (id != _playToken || _state == AudioPlaybackState.stopped) return;
    final queue = _queue;
    if (!interrupted && queue != null && _queueIndex < queue.length - 1) {
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
      await _engine.playEffect(assetPath);
    } catch (error) {
      debugPrint('AudioService: efekt "$assetPath" çalınamadı — $error');
    }
  }

  Future<void> stopEffect() async {
    try {
      await _engine.stopEffect();
    } catch (error) {
      debugPrint('AudioService: efekt durdurulamadı — $error');
    }
  }

  Future<void> pause() async {
    if (_state != AudioPlaybackState.playing) return;
    _state = AudioPlaybackState.paused;
    notifyListeners();
    await _engine.pause();
  }

  Future<void> resume() async {
    if (_state != AudioPlaybackState.paused) return;
    _state = AudioPlaybackState.playing;
    notifyListeners();
    await _engine.resume();
  }

  Future<void> stop() async {
    _playToken++;
    _queue = null;
    _queueIndex = 0;
    _currentAsset = null;
    _state = AudioPlaybackState.stopped;
    notifyListeners();
    await _engine.stop();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }
}
