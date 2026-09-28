/// A Turkish explanation or heading of a book page that can be listened to.
///
/// [id] is stable and tied to the book page, never to the lesson number
/// shown in the app ("s054_01" = PDF page 54, first explanation;
/// "s054_baslik_1" = its heading): lessons can be merged or renumbered
/// without renaming a recording. The texts, and what the recordings were
/// made from, are in `tool/turkish_audio/manifest.json`.
///
/// On a page, it covers [paragraphs] explanation paragraphs from where it
/// starts, read as one recording (one rule or definition is not cut up).
class TrAudio {
  final String id;
  final int paragraphs;

  const TrAudio(this.id, [this.paragraphs = 1]);
}

/// Where the recording of [id] is, as [AudioService] plays it.
String turkishAudioAsset(String id) => 'audio/tr/$id.mp3';
