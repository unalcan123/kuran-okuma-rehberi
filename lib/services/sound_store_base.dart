import 'dart:typed_data';

/// Keeps downloaded sounds on the device between visits. Reading and
/// writing are best-effort: a failure just means the sound is downloaded
/// again next time.
abstract class SoundStore {
  /// The stored bytes for [assetPath], or null if not stored.
  Future<Uint8List?> read(String assetPath);

  Future<void> write(String assetPath, Uint8List bytes);
}
