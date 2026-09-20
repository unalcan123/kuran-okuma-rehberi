/// Which part of a word the book prints in red on its example pages.
enum WordHighlight {
  /// Nothing is marked.
  none,

  /// The lam of the article (اَلْ): "Lâm okunur / okunmaz" pages.
  elLam,

  /// The elif of the article, wherever it is in the phrase.
  elAlif,

  /// The first letter (the hemze a word starts with).
  firstLetter,

  /// The vasıl mark (ٱ) of a hemze that is not read.
  vasl,

  /// The pronoun He (هُ / هِ) at the end of a word, before the next word.
  he,

  /// The letter carrying the long med sign (ٓ).
  med,
}

bool _isMark(int unit) =>
    (unit >= 0x064B && unit <= 0x065F) ||
    unit == 0x0670 ||
    (unit >= 0x0610 && unit <= 0x061A) ||
    (unit >= 0x06D6 && unit <= 0x06ED);

/// A word split into letters, each with the hareke/shedde/tenvin marks that
/// belong to it (a space is a "letter" of its own).
List<String> letterClusters(String word) {
  final clusters = <String>[];
  for (var i = 0; i < word.length; i++) {
    if (clusters.isNotEmpty && _isMark(word.codeUnitAt(i))) {
      clusters[clusters.length - 1] += word[i];
    } else {
      clusters.add(word[i]);
    }
  }
  return clusters;
}

const int _alif = 0x0627, _lam = 0x0644, _he = 0x0647, _waslaAlif = 0x0671;

/// The index of the letter [highlight] marks in [clusters], or null.
int? highlightIndex(List<String> clusters, WordHighlight highlight) {
  int base(int i) => clusters[i].codeUnitAt(0);
  switch (highlight) {
    case WordHighlight.none:
      return null;
    case WordHighlight.firstLetter:
      return clusters.isEmpty ? null : 0;
    case WordHighlight.elLam:
      // اَلْ + word: the lam is the letter right after the elif.
      return clusters.length > 1 && base(0) == _alif && base(1) == _lam ? 1 : null;
    case WordHighlight.elAlif:
      for (var i = 0; i < clusters.length - 1; i++) {
        if (base(i) == _alif && base(i + 1) == _lam) return i;
      }
      return null;
    case WordHighlight.vasl:
      for (var i = 0; i < clusters.length; i++) {
        if (base(i) == _waslaAlif) return i;
      }
      return null;
    case WordHighlight.he:
      // The He that ends a word (next comes a space), else the last He.
      int? last;
      for (var i = 0; i < clusters.length; i++) {
        if (base(i) != _he) continue;
        last = i;
        if (i + 1 < clusters.length && clusters[i + 1] == ' ') return i;
      }
      return last;
    case WordHighlight.med:
      for (var i = 0; i < clusters.length; i++) {
        if (clusters[i].contains('ٓ')) return i;
      }
      return null;
  }
}

/// [word] cut into (before, red, after) for [highlight]; `red` is empty when
/// the rule marks nothing.
(String before, String red, String after) splitForHighlight(
  String word,
  WordHighlight highlight,
) {
  final clusters = letterClusters(word);
  final index = highlightIndex(clusters, highlight);
  if (index == null) return (word, '', '');
  return (
    clusters.sublist(0, index).join(),
    clusters[index],
    clusters.sublist(index + 1).join(),
  );
}
