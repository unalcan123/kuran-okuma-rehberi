import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/arabic_letter.dart';

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
class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  String? _currentAsset;
  AudioPlaybackState _state = AudioPlaybackState.stopped;
  List<String>? _queue;
  int _queueIndex = 0;

  AudioService() {
    _player.onPlayerComplete.listen((_) => _handleComplete());
  }

  /// The asset path currently loaded (playing or paused) — null when
  /// stopped. Lets UI highlight "this is the thing that's playing".
  String? get currentAsset => _currentAsset;
  AudioPlaybackState get state => _state;
  bool get isPlaying => _state == AudioPlaybackState.playing;
  bool get isPaused => _state == AudioPlaybackState.paused;

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
    try {
      await _player.stop();
      _currentAsset = assetPath;
      _state = AudioPlaybackState.playing;
      notifyListeners();
      await _player.play(AssetSource(assetPath));
    } catch (error) {
      debugPrint('AudioService: "$assetPath" çalınamadı — $error');
      _state = AudioPlaybackState.stopped;
      _currentAsset = null;
      notifyListeners();
    }
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
    final assetPath = queue[_queueIndex];
    try {
      await _player.stop();
      _currentAsset = assetPath;
      _state = AudioPlaybackState.playing;
      notifyListeners();
      await _player.play(AssetSource(assetPath));
    } catch (error) {
      debugPrint('AudioService: "$assetPath" çalınamadı — $error');
      await stop();
    }
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
    super.dispose();
  }
}
