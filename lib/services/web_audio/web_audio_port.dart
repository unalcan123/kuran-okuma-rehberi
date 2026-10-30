import 'dart:typed_data';

/// The browser's audio context, as [WebAudioPort.status] reports it.
/// [interrupted] is iOS Safari's state after a call, Siri or the app
/// going to the background.
enum AudioContextStatus { none, suspended, running, interrupted, closed }

/// A sound decoded once into the audio context's own format: starting it
/// needs no decoding, no seeking and no resampling.
abstract class DecodedSound {
  /// Bytes it takes in memory.
  int get memorySize;

  /// Length in seconds.
  double get duration;
}

/// One playing of a [DecodedSound] (a new one for every play).
abstract class SoundVoice {
  /// Stops it (with a few milliseconds' fade, so it does not click) and
  /// lets go of its audio nodes. Its `onEnded` is not called afterwards.
  void stop();

  /// Seconds of the sound played so far.
  double get position;
}

/// One plain audio element, *not* connected to the audio context: the
/// browser plays it itself and keeps the pitch at another speed.
abstract class MediaChannel {
  /// Position in seconds from the media element, not a wall clock.
  double? get position => null;

  /// Puts [bytes] (or, when they could not be loaded, the file at [url]) in
  /// the element at speed [rate], ready for [play]. Replaces the earlier
  /// recording; its events are not reported any more.
  void setSource({
    required Uint8List? bytes,
    required String url,
    required String mimeType,
    required double rate,
    required void Function() onEnded,
    required void Function(Object error) onError,
  });

  /// Throws when the browser refuses (or a newer [setSource] / [pause] /
  /// [clear] interrupted it).
  Future<void> play();

  void pause();
  void setRate(double rate);

  /// Pauses and lets go of the recording.
  void clear();

  void dispose();
}

/// What [WebAudioEngine] needs from the browser. The real one is
/// `JsWebAudioPort` (package:web); tests use a fake.
///
/// Opening the audio context on the user's touch happens inside the port:
/// it has to be done in the touch's own event, before any `await`.
abstract class WebAudioPort {
  AudioContextStatus get status;

  /// Makes the audio context if there is none (it may start suspended).
  void ensureContext();

  /// Asks the context to run; false if it does not within [timeout] (iOS
  /// before the first touch, or after an interruption it does not leave).
  Future<bool> resume(Duration timeout);

  /// Throws when the bytes cannot be decoded.
  Future<DecodedSound> decode(Uint8List bytes);

  /// Starts [sound] now from [offset] seconds; [onEnded] when it plays out.
  SoundVoice start(
    DecodedSound sound, {
    double offset = 0,
    required void Function() onEnded,
  });

  MediaChannel createMediaChannel();

  /// Where the browser can fetch [assetPath] (`audio/...`).
  String assetUrl(String assetPath);

  /// [onVisibility]: the page went to the background (false) / came back.
  /// [onStatus]: the audio context's state changed (also when the port made
  /// a new context).
  void attach({
    required void Function(bool visible) onVisibility,
    required void Function(AudioContextStatus status) onStatus,
  });

  /// Diagnostics (`?sesTani=1`); does nothing otherwise.
  void log(String event, [String? detail]) {}

  void dispose();
}
