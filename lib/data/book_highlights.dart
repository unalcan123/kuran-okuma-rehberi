import '../helpers/arabic_colorizer.dart';
import '../helpers/haraka_colors.dart';
import '../models/arabic_letter.dart';
import '../models/waqf_example.dart';
import '../models/word_highlight.dart';
import 'kapali_te_data.dart';
import 'kelime_sonu_duraklar_data.dart';

/// Book pages of the lessons laid out as one explanation page ([BookPage],
/// Ders 23-30): lesson id → the pages of `ELIF BA BASKI DENEME 2012.pdf`
/// they reproduce.
const Map<String, String> kBookPageNumbers = {
  'el-takisi-okunan': '50',
  'el-takisi-okunmayan': '51',
  'el-takisi-hemze': '52',
  'el-takisi-hemze-vasil': '53',
  'zamir-he-uzatilmasi': '54-55',
  'zamir-he-uzatma-med': '55',
  'zamir-he-uzatma-yok': '55',
  'zamir-he-uzatma-yok-cezimli': '55',
  'zamir-he-uzatma-yok-cezimli-seddeli': '55',
  'kapali-te': '56',
  'kelime-sonu-duraklar': '57-59',
};

/// What the book prints red in the words of these lessons (pages 50-59:
/// only that letter, with its marks — everything else is black). The book
/// page ([WordGridTable] / [WaqfExamplesTable]) uses the same rules, so the
/// Grid and Tekli / Büyük views color each word as its page does.
WordHighlight? _highlightOf(String lessonId, int index) => switch (lessonId) {
  'el-takisi-okunan' || 'el-takisi-okunmayan' => WordHighlight.elLam,
  'el-takisi-hemze' => WordHighlight.elAlif,
  // The page shows the odd words with the vasıl mark red, the even ones
  // with their first letter red.
  'el-takisi-hemze-vasil' =>
    index.isOdd ? WordHighlight.vasl : WordHighlight.firstLetter,
  'zamir-he-uzatilmasi' ||
  'zamir-he-uzatma-yok' ||
  'zamir-he-uzatma-yok-cezimli' ||
  'zamir-he-uzatma-yok-cezimli-seddeli' => WordHighlight.he,
  'zamir-he-uzatma-med' => WordHighlight.med,
  _ => null,
};

const Map<String, List<WaqfExample>> _waqfTables = {
  'kapali-te': kKapaliTeExamples,
  'kelime-sonu-duraklar': kWaqfAllExamples,
};

/// The colors [letter] (item [index] of lesson [lessonId]) has on its book
/// page, or null for lessons that are not one of these pages.
ArabicColorProfile? bookHighlightProfile(
  String lessonId,
  ArabicLetter letter,
  int index,
) {
  final highlight = _highlightOf(lessonId, index);
  if (highlight != null) {
    final red = highlightIndex(letterClusters(letter.isolatedForm), highlight);
    return red == null
        ? ArabicColorProfile.none
        : ArabicColorProfile.highlight({red}, arabicRed);
  }
  final table = _waqfTables[lessonId];
  if (table == null) return null;
  for (final example in table) {
    final int redLetters;
    if (identical(example.passLetter, letter)) {
      redLetters = example.passRedLetters;
    } else if (identical(example.stopLetter, letter)) {
      redLetters = example.stopRedLetters;
    } else {
      continue;
    }
    final clusters = letterClusters(letter.isolatedForm).length;
    return ArabicColorProfile.highlight({
      for (var i = clusters - redLetters; i < clusters; i++) i,
    }, arabicRed);
  }
  return ArabicColorProfile.none;
}
