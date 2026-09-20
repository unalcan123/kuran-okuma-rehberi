import 'arabic_letter.dart';

/// One row of a "Durulduğunda / Geçildiğinde" table (Ders 32 and Ders 33 of
/// the book): the same word read when passing on and when stopping.
///
/// The Arabic comes from the lesson's word list — entry [pair] (1-based) is
/// the pair's (passing, stopping) words — so each word's text and recording
/// exist in one place only.
class WaqfExample {
  final List<ArabicLetter> words;
  final int pair;

  /// How many letters at the end of the word are drawn red (the part that
  /// changes), when passing on and when stopping.
  final int passRedLetters;
  final int stopRedLetters;

  const WaqfExample(
    this.words,
    this.pair, {
    this.passRedLetters = 1,
    this.stopRedLetters = 1,
  });

  ArabicLetter get passLetter => words[2 * pair - 2];
  ArabicLetter get stopLetter => words[2 * pair - 1];

  String get pass => passLetter.isolatedForm;
  String get stop => stopLetter.isolatedForm;
}

bool _isArabicMark(int unit) =>
    (unit >= 0x064B && unit <= 0x065F) ||
    unit == 0x0670 ||
    (unit >= 0x0610 && unit <= 0x061A) ||
    (unit >= 0x06D6 && unit <= 0x06ED);

/// Splits [word] before its last [letters] letters. Each letter takes its
/// hareke/shedde/tenvin marks with it, so no mark is ever cut off.
(String head, String tail) splitLastLetters(String word, int letters) {
  var cut = word.length;
  var remaining = letters;
  while (cut > 0 && remaining > 0) {
    cut--;
    while (cut > 0 && _isArabicMark(word.codeUnitAt(cut))) {
      cut--;
    }
    remaining--;
  }
  return (word.substring(0, cut), word.substring(cut));
}
