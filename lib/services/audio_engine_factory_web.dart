import 'audio_engine.dart';
import 'plugin_audio_engine.dart';
import 'sound_cache.dart';
import 'web_audio/audio_diagnostics_web.dart';
import 'web_audio/js_web_audio_port.dart';
import 'web_audio/web_audio_engine.dart';

/// Web: the app's own engine ([WebAudioEngine]); `audioplayers` only with
/// `?ses=eski` (to compare on a device) or without Web Audio.
AudioEngine createAudioEngine(SoundCache cache) {
  final flags = WebAudioFlags.fromAddress(Uri.base);
  final legacy = flags.legacy || !JsWebAudioPort.isSupported;
  final diagnostics =
      flags.diagnostics
          ? AudioDiagnostics(
            engineName: legacy ? 'eski (audioplayers)' : 'yeni (Web Audio)',
          )
          : null;
  if (legacy) {
    diagnostics?.log('hazır', 'eski motor');
    return PluginAudioEngine(cache);
  }
  return WebAudioEngine(JsWebAudioPort(diagnostics: diagnostics), cache);
}
