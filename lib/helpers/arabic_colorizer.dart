import 'package:flutter/material.dart';

import 'haraka_colors.dart';

/// Bir harf kümesinde renklendirilebilen öğeler.
enum ArabicPart {
  /// Every letter's body (e.g. s. 28: the whole şeddeli example is red).
  letter,

  /// 7 kalın harfin gövdesi — her zaman kırmızı (global, profilden bağımsız).
  thickLetter,
  fatha,
  kasra,
  damma,
  sukun,
  shadda,
  fathatan,
  kasratan,
  dammatan,
  daggerAlif, // çeker üstün ٰ
  subscriptAlif, // çeker esre ٖ
  maddah, // med işareti ٓ
  maddAlif,
  maddYa,
  maddWaw,
}

/// Arapça işaretlerin Unicode kod noktaları.
abstract final class ArabicMarks {
  static const int fathatan = 0x064B;
  static const int dammatan = 0x064C;
  static const int kasratan = 0x064D;
  static const int fatha = 0x064E;
  static const int damma = 0x064F;
  static const int kasra = 0x0650;
  static const int shadda = 0x0651;
  static const int sukun = 0x0652;
  static const int maddah = 0x0653;
  static const int subscriptAlif = 0x0656;
  static const int daggerAlif = 0x0670;
}

/// Renklendirilen işaret → öğe. Burada olmayan işaretler (hemze işareti vb.)
/// çevresindeki normal metin rengiyle çizilir.
const Map<int, ArabicPart> _markParts = {
  ArabicMarks.fatha: ArabicPart.fatha,
  ArabicMarks.kasra: ArabicPart.kasra,
  ArabicMarks.damma: ArabicPart.damma,
  ArabicMarks.sukun: ArabicPart.sukun,
  ArabicMarks.shadda: ArabicPart.shadda,
  ArabicMarks.fathatan: ArabicPart.fathatan,
  ArabicMarks.kasratan: ArabicPart.kasratan,
  ArabicMarks.dammatan: ArabicPart.dammatan,
  ArabicMarks.daggerAlif: ArabicPart.daggerAlif,
  ArabicMarks.subscriptAlif: ArabicPart.subscriptAlif,
  ArabicMarks.maddah: ArabicPart.maddah,
};

/// Her öğenin rengi — kitaptaki (s. 14-49) renk mantığı.
const Map<ArabicPart, Color> arabicPartColors = {
  ArabicPart.thickLetter: harakaThickLetterColor,
  ArabicPart.fatha: harakaFathaColor,
  ArabicPart.kasra: harakaKasraColor,
  ArabicPart.damma: harakaDammaColor,
  ArabicPart.sukun: harakaSukunColor,
  ArabicPart.shadda: harakaShaddaColor,
  ArabicPart.fathatan: arabicRed,
  ArabicPart.kasratan: arabicBlue,
  ArabicPart.dammatan: arabicGreen,
  ArabicPart.daggerAlif: arabicRed,
  ArabicPart.subscriptAlif: arabicRed,
  ArabicPart.maddah: arabicRed,
  ArabicPart.maddAlif: arabicRed,
  ArabicPart.maddYa: arabicBlue,
  ArabicPart.maddWaw: arabicGreen,
};

/// Harfin altına yazılan işaretler; geri kalan renkli işaretler üsttedir.
const Set<int> _belowMarks = {
  ArabicMarks.kasra,
  ArabicMarks.kasratan,
  ArabicMarks.subscriptAlif,
};

/// Şeddeyle aynı harfte bulunduğunda şeddenin rengini alan kısa harekeler
/// (kitap s. 28-31: şeddeli harfin harekesi mavi). Tenvin kendi renginde kalır.
const Set<int> _vowelsTakingShaddaColor = {
  ArabicMarks.fatha,
  ArabicMarks.damma,
  ArabicMarks.kasra,
};

/// [c] bir Arapça harfe eklenen birleştirici işaret mi (hareke, tenvin,
/// çeker, med, Kur'an durak işaretleri...)? Öyleyse önceki harfin kümesine
/// aittir.
bool isArabicCombiningMark(int c) =>
    (c >= 0x064B && c <= 0x065F) ||
    c == 0x0670 ||
    (c >= 0x0610 && c <= 0x061A) ||
    (c >= 0x06D6 && c <= 0x06ED);

/// Hangi öğenin hangi renkte çizileceği — kitabın bir SAYFASININ renk
/// mantığı. Kitap her sayfada yalnızca o sayfanın öğrettiği işaretleri boyar
/// (örn. s. 15-16: yalnızca üstün kırmızı). Profilde olmayan öğe normal metin
/// rengiyle çizilir. Sayfa profilleri `LessonBookPage.colorProfile`'da.
///
/// İstisna: 7 kalın harfin GÖVDESİ profilden bağımsız, her zaman kırmızıdır
/// ([thickArabicLetters]); profil bunu açıp kapatmaz (`ArabicPart.thickLetter`
/// profilde olsa da olmasa da).
class ArabicColorProfile {
  const ArabicColorProfile(
    this.colors, {
    this.clusterBodies = const {},
    this.clusterMarks = const {},
    this.plainMarks = const {},
  });

  /// Renklendirilen öğeler ve renkleri.
  final Map<ArabicPart, Color> colors;

  /// Belirli harflerin gövde rengi: metnin kaçıncı harf kümesi (boşluk da
  /// bir küme) → renk. Kitapta tek bir öğenin içinde yalnızca bir harf
  /// renkliyse (örn. s. 10-13'te kelimedeki hedef harf).
  final Map<int, Color> clusterBodies;

  /// Belirli harf kümelerinin BÜTÜN işaretlerinin rengi (metnin kaçıncı
  /// kümesi → renk): kitapta bir harf işaretleriyle birlikte tek renk
  /// basılmışsa (örn. s. 50-59'da kırmızı vurgulanan harf).
  final Map<int, Color> clusterMarks;

  /// [clusters]'daki harfler, işaretleriyle birlikte [color] renginde;
  /// gerisi renksiz (kitabın s. 50-59 vurgusu).
  factory ArabicColorProfile.highlight(Set<int> clusters, Color color) =>
      ArabicColorProfile(
        const {},
        clusterBodies: {for (final c in clusters) c: color},
        clusterMarks: {for (final c in clusters) c: color},
      );

  /// İşaretleri renksiz kalan harf kümeleri (metnin kaçıncı kümesi) —
  /// kitapta tek tek siyah basılmış işaretler (örn. s. 19 يَئِسَ'deki ئِ).
  final Set<int> plainMarks;

  /// Aynı renkler, [clusterBodies] ile.
  ArabicColorProfile withClusterBodies(Map<int, Color> bodies) =>
      ArabicColorProfile(
        colors,
        clusterBodies: bodies,
        clusterMarks: clusterMarks,
        plainMarks: plainMarks,
      );

  /// Aynı renkler, [plainMarks] ile.
  ArabicColorProfile withPlainMarks(Set<int> clusters) => ArabicColorProfile(
    colors,
    clusterBodies: clusterBodies,
    clusterMarks: clusterMarks,
    plainMarks: clusters,
  );

  /// Bütün kurallar (kitabın bir sayfasına bağlı olmayan yerler: oyunlar,
  /// henüz kitap sayfası modellenmemiş dersler).
  static const ArabicColorProfile standard = ArabicColorProfile(
    arabicPartColors,
  );

  /// Hiçbir şey boyanmaz.
  static const ArabicColorProfile none = ArabicColorProfile({});

  /// [parts]'ı kitaptaki renkleriyle ([arabicPartColors]) boyayan profil.
  factory ArabicColorProfile.only(Set<ArabicPart> parts) => ArabicColorProfile({
    for (final part in parts) part: arabicPartColors[part]!,
  });

  Color? operator [](ArabicPart part) => colors[part];

  bool get isEmpty =>
      colors.isEmpty && clusterBodies.isEmpty && clusterMarks.isEmpty;

  static bool _sameSet(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  bool operator ==(Object other) =>
      other is ArabicColorProfile &&
      other.colors.length == colors.length &&
      colors.entries.every((e) => other.colors[e.key] == e.value) &&
      other.clusterBodies.length == clusterBodies.length &&
      clusterBodies.entries.every(
        (e) => other.clusterBodies[e.key] == e.value,
      ) &&
      other.clusterMarks.length == clusterMarks.length &&
      clusterMarks.entries.every((e) => other.clusterMarks[e.key] == e.value) &&
      _sameSet(other.plainMarks, plainMarks);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      colors.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      clusterBodies.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      clusterMarks.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(plainMarks),
  );
}

/// Bir kümedeki tek bir işaret: metindeki yeri, kod noktası ve rengi (null:
/// renklendirilmez, normal metin rengiyle çizilir).
class ArabicMarkColor {
  const ArabicMarkColor(this.index, this.codeUnit, this.color);

  final int index;
  final int codeUnit;
  final Color? color;

  bool get isBelow => _belowMarks.contains(codeUnit);
  bool get isShadda => codeUnit == ArabicMarks.shadda;
}

/// Bir harf kümesinin (harf + işaretleri) nasıl renkleneceği. Harfin
/// gövdesi ve her işaret AYRI ayrı renk alır — örn. siyah bir ب'nin
/// üstündeki üstün kırmızı.
class ArabicClusterColors {
  const ArabicClusterColors({
    required this.start,
    required this.end,
    required this.base,
    required this.parts,
    required this.marks,
    this.body,
  });

  /// Kümenin metindeki [start, end) aralığı (UTF-16).
  final int start;
  final int end;

  /// Kümenin harfi.
  final String base;

  /// Kümede renk alan öğeler.
  final Set<ArabicPart> parts;

  /// Kümenin bütün işaretleri (renk alsın almasın), metindeki sırayla.
  final List<ArabicMarkColor> marks;

  /// Harfin gövdesinin (glifinin) rengi (kalın harf, uzatma harfi) ya da null.
  final Color? body;

  /// Şeddenin rengi.
  Color? get shaddaColor => marks.where((m) => m.isShadda).firstOrNull?.color;

  /// Harfin üstündeki (şedde dışı) ilk renkli işaretin rengi.
  Color? get above =>
      marks
          .where((m) => !m.isShadda && !m.isBelow && m.color != null)
          .firstOrNull
          ?.color;

  /// Harfin altındaki ilk renkli işaretin rengi.
  Color? get below =>
      marks.where((m) => m.isBelow && m.color != null).firstOrNull?.color;

  bool get hasColoredMark => marks.any((m) => m.color != null);

  /// İşaretleri farklı renklerde mi (renksiz işaret de bir "renk" sayılır)?
  bool get hasMixedMarks =>
      hasColoredMark && marks.map((m) => m.color).toSet().length > 1;

  bool get isColored => body != null || hasColoredMark;
}

/// Arapça metni harf kümelerine ayırır ve bir [ArabicColorProfile]'a göre
/// her kümenin hangi öğesinin hangi renkte çizileceğini söyler. Çizim yapmaz
/// (bkz. [ColoredArabicText]); metni de değiştirmez — sadece okur.
///
/// Uzatma (med) harfi kuralı (kitap s. 32-38): harekesiz bir
///  * ا, önceki harfte ÜSTÜN varsa → med elif,
///  * ي / ى, önceki harfte ESRE varsa → med yâ,
///  * و, önceki harfte ÖTRE varsa → med vâv.
/// Her elif/yâ/vâv boyanmaz: iki üstünden sonraki elif (بًا), vav-ı cemi'den
/// sonraki elif (أُوتُوا) ya da cezimli/harekeli yâ/vâv med değildir.
///
/// Şeddeli harfin kısa harekesi (üstün/esre/ötre) şeddenin rengini alır
/// (kitap s. 28-31), profil şeddeyi boyuyorsa.
abstract final class ArabicColorizer {
  static List<ArabicClusterColors> plan(
    String text, {
    ArabicColorProfile profile = ArabicColorProfile.standard,
  }) {
    final result = <ArabicClusterColors>[];
    Set<int>? previousMarks;
    var i = 0;
    while (i < text.length) {
      if (isArabicCombiningMark(text.codeUnitAt(i))) {
        i++; // metnin başında sahipsiz işaret
        continue;
      }
      final baseEnd = _baseEnd(text, i);
      var end = baseEnd;
      while (end < text.length && isArabicCombiningMark(text.codeUnitAt(end))) {
        end++;
      }
      final base = text.substring(i, baseEnd);
      final codes = {for (var j = baseEnd; j < end; j++) text.codeUnitAt(j)};
      final parts = <ArabicPart>{};

      Color? body;
      if (base != ' ' && profile[ArabicPart.letter] != null) {
        parts.add(ArabicPart.letter);
        body = profile[ArabicPart.letter];
      }
      if (codes.isEmpty && previousMarks != null) {
        final madd = _maddPart(base, previousMarks);
        if (madd != null && profile[madd] != null) {
          parts.add(madd);
          body = profile[madd];
        }
      }

      final own = profile.clusterBodies[result.length];
      if (own != null) body = own;

      // GLOBAL: kalın harfin gövdesi her profilde kırmızı (sayfa profilinden
      // ve kümeye özel gövde renginden önce gelir). İşaretlere dokunmaz.
      if (isThickArabicLetter(base)) {
        parts.add(ArabicPart.thickLetter);
        body = harakaThickLetterColor;
      }

      final plain = profile.plainMarks.contains(result.length);
      final shaddaColor =
          codes.contains(ArabicMarks.shadda) && !plain
              ? profile[ArabicPart.shadda]
              : null;
      final marks = <ArabicMarkColor>[];
      for (var j = baseEnd; j < end; j++) {
        final code = text.codeUnitAt(j);
        final part = _markParts[code];
        var color = part == null || plain ? null : profile[part];
        final whole = profile.clusterMarks[result.length];
        if (whole != null) {
          marks.add(ArabicMarkColor(j, code, whole));
          if (part != null) parts.add(part);
          continue;
        }
        if (shaddaColor != null && _vowelsTakingShaddaColor.contains(code)) {
          color = shaddaColor;
        }
        if (color != null) parts.add(part!);
        marks.add(ArabicMarkColor(j, code, color));
      }

      result.add(
        ArabicClusterColors(
          start: i,
          end: end,
          base: base,
          parts: parts,
          marks: marks,
          body: body,
        ),
      );
      previousMarks = base == ' ' ? null : codes;
      i = end;
    }
    return result;
  }

  /// Elif + med işareti (آ) fontta tek bir glife (آ) birleşir; işaret
  /// ayrılırsa glif değişir. Bu yüzden ikisi birlikte "harf" sayılır.
  static int _baseEnd(String text, int i) =>
      text.codeUnitAt(i) == _alif &&
              i + 1 < text.length &&
              text.codeUnitAt(i + 1) == ArabicMarks.maddah
          ? i + 2
          : i + 1;

  static const int _alif = 0x0627;

  static ArabicPart? _maddPart(String base, Set<int> previousMarks) {
    switch (base) {
      case 'ا':
        return previousMarks.contains(ArabicMarks.fatha)
            ? ArabicPart.maddAlif
            : null;
      case 'ي':
      case 'ى':
        return previousMarks.contains(ArabicMarks.kasra)
            ? ArabicPart.maddYa
            : null;
      case 'و':
        return previousMarks.contains(ArabicMarks.damma)
            ? ArabicPart.maddWaw
            : null;
    }
    return null;
  }
}

/// [text]'ten bütün birleştirici işaretleri (hareke, tenvin, şedde...)
/// çıkarır — harflerin şekli ve yeri değişmez, işaretler yer kaplamaz.
/// Elif'in med işareti (آ → آ tek glif) harfin parçası sayılır, kalır.
String stripArabicMarks(String text) =>
    ArabicColorizer.plan(
      text,
      profile: ArabicColorProfile.none,
    ).map((c) => c.base).join();

/// [text]'in [start, end) aralığında başlayan harf kümelerinin sırası
/// (profillerde `clusterBodies` / `clusterMarks` anahtarı) — bir kelimenin
/// bir parçasını (ör. vurgulanan son harfler) metni bölmeden boyamak için.
Set<int> arabicClustersInRange(String text, int start, int end) {
  final plan = ArabicColorizer.plan(text, profile: ArabicColorProfile.none);
  return {
    for (var i = 0; i < plan.length; i++)
      if (plan[i].start >= start && plan[i].start < end) i,
  };
}
