import 'sound_cache.dart';

export 'audio_engine_factory_stub.dart'
    if (dart.library.js_interop) 'audio_engine_factory_web.dart';

/// Called when the clip of play request [id] is over: it ended by itself,
/// or ([interrupted]) the system took the sound away (the page went to the
/// background, a phone call) and it will not go on by itself.
typedef AudioEndedCallback = void Function(int id, {bool interrupted});

/// What actually makes the sound behind [AudioService]. The service keeps
/// the app's state (what plays, the playlist, play / pause); an engine only
/// plays, on two channels: the main one (letters, surahs, prayers, the
/// Turkish explanations — one at a time) and the effect one (a game's
/// "correct" sound, which may sound over the main one).
///
/// - Apps (Android, Windows, a future iOS app): `audioplayers`
///   ([PluginAudioEngine]).
/// - Web: decoded sounds and plain audio elements (`WebAudioEngine`), since
///   `audioplayers` routes every web sound through a bridge that iPhone and
///   iPad Safari are suspected to distort (`docs/SES.md`).
abstract class AudioEngine {
  /// Set by [AudioService] before the first play.
  AudioEndedCallback? onEnded;

  /// Starts [assetPath] on the main channel as request [id] at speed
  /// [rate], replacing what played there. Completes once it started (or
  /// was replaced by a newer request); throws when it cannot play.
  Future<void> play(int id, String assetPath, {required double rate});

  Future<void> pause();
  Future<void> resume();

  /// Stops the main channel; nothing of an earlier request starts later.
  Future<void> stop();

  /// The speed of the clip playing now (and, for an engine that keeps it,
  /// of later ones; [play] always gets the speed too).
  Future<void> setRate(double rate);

  Future<void> playEffect(String assetPath);
  Future<void> stopEffect();

  /// The screen can play [assetPaths] soon (they are being downloaded into
  /// the [SoundCache] already); an engine may get them ready.
  void preload(List<String> assetPaths) {}

  void dispose();
}

/// Builds the engine for this platform.
typedef AudioEngineFactory = AudioEngine Function(SoundCache cache);
