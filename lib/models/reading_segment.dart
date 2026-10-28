import 'dua.dart';
import 'surah.dart';

/// One part of a text read aloud on a reading screen: a surah's besmele or
/// one of its ayetler, or one part of a prayer. The reading screen, its
/// player (play, highlight, repeat, speed, auto-scroll) and memorizing work
/// on these, so surahs and prayers share one engine. Built from the data as
/// it is ([ReadingSegment.ofSurah] / [ofDua]); nothing is copied or changed.
class ReadingSegment {
  const ReadingSegment({
    required this.id,
    required this.arabic,
    required this.audioAsset,
    this.number,
    this.meaning = '',
    this.pronunciation,
    this.isOpening = false,
  });

  /// Stable within its surah / prayer (e.g. "besmele", "ayet-3", "part-0").
  final String id;
  final String arabic;
  final String audioAsset;

  /// The displayed ayet / prayer part number. Only Fatiha has a numbered
  /// besmele; its last ayet spans two cards, both numbered 7.
  final int? number;

  /// Turkish meaning ("meal"); empty when there is none.
  final String meaning;

  /// Turkish reading of the Arabic (prayers may have one).
  final String? pronunciation;

  /// The besmele that opens a surah: read first, drawn as the heading.
  final bool isOpening;

  /// A surah as the dataset gives it: its besmele (own recording) first,
  /// then its ayetler — the same order its "Dinle" always played.
  static List<ReadingSegment> ofSurah(Surah surah) => [
    ReadingSegment(
      id: 'besmele',
      number: surah.id == 'fatiha' ? 1 : null,
      arabic: surah.besmele,
      audioAsset: surah.besmeleAudioAsset,
      isOpening: true,
    ),
    for (final ayet in surah.ayetler)
      ReadingSegment(
        id: 'ayet-${ayet.number}',
        number:
            surah.id == 'fatiha'
                ? (ayet.number < 7 ? ayet.number + 1 : 7)
                : ayet.number,
        arabic: ayet.arabic,
        meaning: ayet.meaningTr,
        audioAsset: ayet.audioAsset,
      ),
  ];

  /// A prayer's parts in order.
  static List<ReadingSegment> ofDua(Dua dua) => [
    for (var i = 0; i < dua.segments.length; i++)
      ReadingSegment(
        id: 'part-${dua.segments[i].id}',
        number: i + 1,
        arabic: dua.segments[i].arabic,
        meaning: dua.segments[i].meaningTr,
        pronunciation: dua.segments[i].pronunciationTr,
        audioAsset: dua.segments[i].audioAsset,
      ),
  ];
}
