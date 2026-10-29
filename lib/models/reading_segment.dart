import '../data/surah_meanings.dart';
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
    this.meaningSource = '',
    this.meaningFootnotes = '',
    this.instruction = '',
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
  final String meaningSource;
  final String meaningFootnotes;
  final String instruction;

  /// Turkish reading of the Arabic (prayers may have one).
  final String? pronunciation;

  /// The besmele that opens a surah: read first, drawn as the heading.
  final bool isOpening;

  /// A surah as the dataset gives it: its besmele (own recording) first,
  /// then its ayetler — the same order its "Dinle" always played.
  static List<ReadingSegment> ofSurah(
    Surah surah, {
    String languageCode = 'tr',
  }) {
    final published = kSurahMeanings[surah.id]?[languageCode];
    return [
      ReadingSegment(
        id: 'besmele',
        number: surah.id == 'fatiha' ? 1 : null,
        meaning: surah.id == 'fatiha' ? published?.verses[1] ?? '' : '',
        meaningSource: surah.id == 'fatiha' ? published?.attribution ?? '' : '',
        meaningFootnotes:
            surah.id == 'fatiha' ? published?.footnotes[1] ?? '' : '',
        arabic: displayArabic(surah.besmele),
        audioAsset: surah.besmeleAudioAsset,
        isOpening: true,
      ),
      if (surah.ayetler.any((a) => a.verse != null))
        // Ayets read in phrases (Âyetel Kürsî, Âmenerrasûlü), each with its
        // own recording: every card shows its verse; the Turkish meal is
        // split with them, other languages give the whole verse once, on
        // its first phrase.
        for (final (i, ayet) in surah.ayetler.indexed)
          ReadingSegment(
            id: 'ayet-${ayet.number}',
            number: ayet.verse ?? ayet.number,
            arabic: displayArabic(ayet.arabic),
            meaning:
                languageCode == 'tr'
                    ? ayet.meaningTr
                    : _firstOfVerse(surah, i)
                    ? published?.verses[ayet.verse] ?? ''
                    : '',
            meaningSource: published?.attribution ?? '',
            meaningFootnotes:
                languageCode != 'tr' && _firstOfVerse(surah, i)
                    ? published?.footnotes[ayet.verse] ?? ''
                    : '',
            audioAsset: ayet.audioAsset,
          )
      else
        for (final ayet in surah.ayetler)
          ReadingSegment(
            id: 'ayet-${ayet.number}',
            number:
                surah.id == 'fatiha'
                    ? (ayet.number < 7 ? ayet.number + 1 : 7)
                    : (surah.id == 'nasr' && ayet.number > 3 ? 3 : ayet.number),
            arabic: displayArabic(ayet.arabic),
            meaning:
                published?.verses[surah.id == 'fatiha'
                    ? (ayet.number < 7 ? ayet.number + 1 : 7)
                    : (surah.id == 'nasr' && ayet.number > 3
                        ? 3
                        : ayet.number)] ??
                ayet.meaningTr,
            meaningSource: published?.attribution ?? '',
            meaningFootnotes:
                published?.footnotes[surah.id == 'fatiha'
                    ? (ayet.number < 7 ? ayet.number + 1 : 7)
                    : (surah.id == 'nasr' && ayet.number > 3
                        ? 3
                        : ayet.number)] ??
                '',
            audioAsset: ayet.audioAsset,
          ),
    ];
  }

  /// Quran text as the Quran font (Shaikh Hamdullah Mushaf) draws it: the
  /// subscript alef (long î) is written ۪ as in the Turkish mushaf; waqf
  /// signs it has no glyph for — small high tah, zain "câiz" (Tîn 4,
  /// Hümeze 4), "qif" (Kadir 5) — are left out (another font drew them big
  /// and broken over the word). The data keeps the source text.
  static const _noGlyphMarks = ['ؕ', 'ؗ', 'ࣞ'];

  static String displayArabic(String text) => _noGlyphMarks
      .fold(text, (t, mark) => t.replaceAll(mark, ''))
      .replaceAll('ٖ', '۪');

  static bool _firstOfVerse(Surah surah, int i) =>
      i == 0 || surah.ayetler[i - 1].verse != surah.ayetler[i].verse;

  /// A prayer's parts in order.
  static List<ReadingSegment> ofDua(Dua dua, {String languageCode = 'tr'}) => [
    for (var i = 0; i < dua.segments.length; i++)
      ReadingSegment(
        id: 'part-${dua.segments[i].id}',
        number: i + 1,
        arabic: dua.segments[i].arabic,
        meaning:
            dua.segments[i].meanings[languageCode] ?? dua.segments[i].meaningTr,
        meaningSource: dua.segments[i].meaningSource,
        instruction: dua.segments[i].instruction,
        pronunciation: dua.segments[i].pronunciationTr,
        audioAsset: dua.segments[i].audioAsset,
      ),
  ];
}
