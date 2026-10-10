import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_engine.dart';
import 'sound_cache.dart';

/// [AudioEngine] on `audioplayers`: the apps' (Android, Windows, a future
/// iOS app) engine, and on the web only when asked for (`?ses=eski`, to
/// compare) or when the browser has no Web Audio.
class PluginAudioEngine extends AudioEngine {
  PluginAudioEngine(this._cache) {
    _player.onPlayerComplete.listen((_) {
      final id = _activeId;
      if (id == null) return;
      _activeId = null;
      onEnded?.call(id);
    });
  }

  final SoundCache _cache;
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer? _effectPlayer;

  /// The request playing (or paused) on [_player]; null when stopped.
  int? _activeId;

  double _rate = 1.0;

  /// The rate last given to the player (a browser's new audio element
  /// starts at 1.0 again, so a rate other than 1.0 is set on every play).
  double _appliedRate = 1.0;

  @override
  Future<void> play(int id, String assetPath, {required double rate}) async {
    _activeId = id;
    _rate = rate;
    await _player.stop();
    if (_activeId != id) return;
    final source = await _sourceFor(assetPath);
    if (_activeId != id) return;
    await _player.play(source);
    if (_activeId != id) return;
    await _applyRate();
  }

  Future<void> _applyRate() async {
    if (_rate == 1.0 && _appliedRate == 1.0) return;
    try {
      await _player.setPlaybackRate(_rate);
      _appliedRate = _rate;
    } catch (error) {
      debugPrint('AudioService: hız ayarlanamadı — $error');
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

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() async {
    _activeId = null;
    await _player.stop();
  }

  @override
  Future<void> setRate(double rate) async {
    _rate = rate;
    if (_activeId != null) await _applyRate();
  }

  @override
  Future<void> playEffect(String assetPath) async {
    final player = _effectPlayer ??= AudioPlayer();
    await player.stop();
    await player.play(await _sourceFor(assetPath));
  }

  @override
  Future<void> stopEffect() async => _effectPlayer?.stop();

  @override
  void dispose() {
    _player.dispose();
    _effectPlayer?.dispose();
  }
}
