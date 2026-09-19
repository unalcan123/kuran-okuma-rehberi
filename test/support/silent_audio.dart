import 'package:flutter/material.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:provider/provider.dart';

/// An [AudioService] stand-in that makes no sound, for tests that only
/// need a screen to open (playing needs a real device).
class SilentAudio extends ChangeNotifier implements AudioService {
  @override
  String? currentAsset;
  @override
  AudioPlaybackState state = AudioPlaybackState.stopped;
  @override
  bool get isPlaying => false;
  @override
  bool get isPaused => false;

  @override
  void preload(Iterable<String?> assets) {}

  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget withAudio(Widget child) => ChangeNotifierProvider<AudioService>.value(
  value: SilentAudio(),
  child: child,
);
