import 'audio_engine.dart';
import 'plugin_audio_engine.dart';
import 'sound_cache.dart';

/// Apps (Android, Windows, a future iOS app) and tests: `audioplayers`.
AudioEngine createAudioEngine(SoundCache cache) => PluginAudioEngine(cache);
