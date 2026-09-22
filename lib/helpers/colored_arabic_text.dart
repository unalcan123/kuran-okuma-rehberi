import 'package:flutter/material.dart';

import 'haraka_colors.dart';

/// [text]'te renklendirilecek bir hareke, kalın harf YA DA [baseColorOf] bir
/// renk döndürdüğü bir küme var mı? (varsa aşağıdaki daha maliyetli üst-üste
/// çizim yoluna girilir; yoksa maliyetsiz sıradan [Text] kullanılır).
bool _needsOverlay(
  String text, {
  required bool colorHarakat,
  required bool highlightThickLetters,
  BaseColorResolver? baseColorOf,
}) {
  for (var i = 0; i < text.length; i++) {
    final u = text.codeUnitAt(i);
    if (colorHarakat && harakaColorByCodePoint.containsKey(u)) return true;
    if (highlightThickLetters && thickArabicLetters.contains(text[i])) {
      return true;
    }
  }
  if (baseColorOf != null) {
    var isFirst = true;
    for (var i = 0; i < text.length; i++) {
      if (_isArabicCombiningMark(text.codeUnitAt(i))) continue;
      final hasOwnMarks =
          i + 1 < text.length && _isArabicCombiningMark(text.codeUnitAt(i + 1));
      if (baseColorOf(text[i], isFirstCluster: isFirst, hasOwnMarks: hasOwnMarks) !=
          null) {
        return true;
      }
      isFirst = false;
    }
  }
  return false;
}

/// Bir harf kümesinin BAŞ harfi için, çağıranın kendi kuralına göre bir
/// renk seçer (örn. hemze/uzatma harfi kırmızı) — döndürülen `null` "bu
/// harfin gövdesine dokunma, mevcut stil rengini kullan" demektir.
/// [isFirstCluster] metindeki İLK harf kümesi mi (örn. uzatma/medd kuralı
/// "kendinden önce bir şey varsa" der; ilk harf hiçbir şeyi uzatmıyordur).
/// [hasOwnMarks]: bu harf kümesinin (renklendirilsin ya da renklendirilmesin,
/// tenvin dahil) EN AZ BİR eki var mı — örn. uzatma/medd harfi kuralı
/// "kendi harekesi yoksa" der.
typedef BaseColorResolver =
    Color? Function(
      String baseChar, {
      required bool isFirstCluster,
      required bool hasOwnMarks,
    });

/// Elifba öğretim ekranlarında Arapça metin için ortak widget: [Text] gibi
/// kullanılır, ama:
///  * [colorHarakat] açıksa üstün/sükûn kırmızı, esre/şedde mavi, ötre yeşil
///    gösterilir (sadece işaretin kendisi, harfin gövdesi değil);
///  * [highlightThickLetters] açıksa 7 kalın harfin (خ ص ض ط ظ غ ق) GÖVDESİ
///    kırmızı gösterilir;
///  * [baseColorOf] verilirse, her harf kümesinin BAŞ harfi için ayrıca
///    çağıranın kendi kuralına göre bir taban rengi uygulanabilir (örn.
///    hemzeli elif/uzatma harfi vurgusu — bkz. `arabic_glyph.dart`).
/// Hiçbiri devrede değilse (ya da renklendirilecek bir şey yoksa) sıradan
/// [Text] ile TIPATIP aynı çizer, ek maliyet yoktur.
///
/// ÖNEMLİ — Arapça harf birleşimi (shaping) NASIL korunuyor: D:\Elifbe2025
/// projesinde önce metni renge göre ayrı `TextSpan`'lara bölmek denendi ve
/// GERÇEK CİHAZDA BOZULDU — HarfBuzz'ın işaret-taban (mark-to-base)
/// konumlaması harfle harekeyi AYNI şekillendirme parçasında görmek ister;
/// ayrılınca şedde/hareke kayboluyor, harf sırası bozuluyor. Bu yüzden
/// burada metin HİÇ BÖLÜNMEDEN tek parça olarak bırakılır; her zaman TAM
/// metin, TEK stille şekillendirilir. Renklendirme, şekillendirmeden
/// sonraki ÇİZİM katmanında yapılır: aynı tam metin 1 (normal renk) + en
/// fazla birkaç kez (kırmızı/mavi/yeşil/taban rengi) üst üste çizilir; her
/// ek çizim yalnızca ilgili karakterlerin kapladığı dar kutularla kırpılır
/// (ClipPath). Şekillendirme her çizimde aynı tam metne göre yapıldığından
/// harf birleşimi/sıralaması/hareke pozisyonu asla bozulmaz (bkz.
/// `test/colored_arabic_text_test.dart`).
class ColoredArabicText extends StatelessWidget {
  const ColoredArabicText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.colorHarakat = true,
    this.highlightThickLetters = true,
    this.baseColorOf,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final bool colorHarakat;
  final bool highlightThickLetters;
  final BaseColorResolver? baseColorOf;

  @override
  Widget build(BuildContext context) {
    if (!_needsOverlay(
      text,
      colorHarakat: colorHarakat,
      highlightThickLetters: highlightThickLetters,
      baseColorOf: baseColorOf,
    )) {
      // Renklendirilecek bir şey yoksa (ya da hepsi kapalıysa) sıradan
      // Text — eski davranışla bire bir aynı, ek maliyet yok.
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      );
    }
    return _ArabicOverlayText(
      text: text,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      colorHarakat: colorHarakat,
      highlightThickLetters: highlightThickLetters,
      baseColorOf: baseColorOf,
    );
  }
}

class _ArabicOverlayText extends StatelessWidget {
  const _ArabicOverlayText({
    required this.text,
    required this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
    this.softWrap,
    required this.colorHarakat,
    required this.highlightThickLetters,
    this.baseColorOf,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final bool colorHarakat;
  final bool highlightThickLetters;
  final BaseColorResolver? baseColorOf;

  Widget _plain(Color? color) => Text(
    text,
    style: color == null ? style : style.copyWith(color: color),
    textAlign: textAlign,
    textDirection: textDirection,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dir = textDirection ?? Directionality.of(context);

        // Tam metni TEK stille şekillendir (hiçbir parçalama yok); her renk
        // grubunun kapladığı kutuları AYNI şekillenmiş metinden oku.
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textAlign: textAlign ?? TextAlign.start,
          textDirection: dir,
          maxLines: maxLines,
        )..layout(maxWidth: constraints.maxWidth);

        final rectsByColor = _arabicOverlayRects(
          painter,
          text,
          colorHarakat: colorHarakat,
          highlightThickLetters: highlightThickLetters,
          baseColorOf: baseColorOf,
        );
        painter.dispose();

        return Stack(
          textDirection: dir,
          children: [
            _plain(null),
            for (final entry in rectsByColor.entries)
              ClipPath(
                clipper: _RectsClipper(entry.value),
                child: _plain(entry.key),
              ),
          ],
        );
      },
    );
  }
}

/// Fetha/damme/sükun: harfin ÜSTÜNDE. Şedde de üstte ama harften daha da
/// dışarıda durur (üste, sesli harekenin üzerine biner). Kesre tektir,
/// harfin ALTINDA.
const int _kFatha = 0x064E;
const int _kDamma = 0x064F;
const int _kKasra = 0x0650;
const int _kShadda = 0x0651;
const int _kSukun = 0x0652;
const Set<int> _aboveVowels = {_kFatha, _kDamma, _kSukun};

/// [c] Arapça harfe eklenen birleştirici bir işaret mi (hareke, tenvin,
/// üstteki elif vb.)? Öyleyse harf kümesinin (grapheme cluster) bir parçası
/// sayılır — [TextPainter.getBoxesForSelection] yalnızca TAM kümeler için
/// (harf + bütün ekleri) geçerli bir kutu döner; kümenin ortasından bir
/// seçim istenirse (sadece harf ya da sadece işaret) BOŞ liste döner. Bu
/// yüzden boyama, harfin kendisi değil TÜM kümenin kutusu üzerinden, o
/// kutunun üst/alt şeridine göre yapılır (bkz. Elifbe2025'teki
/// `test/haraka_debug_test.dart` ile HASENAT/Hasenat yazı tipinde — aynı
/// dosya, aynı font — ölçülen gerçek oranlar).
bool _isArabicCombiningMark(int c) => c >= 0x064B && c <= 0x065F || c == 0x0670;

/// Her harfin KENDİ gövdesinin kapladığı düşey oran (üst, alt) — Hasenat
/// yazı tipinde harfleri tek tek ölçüp çıkarıldı. Oranlar
/// [TextPainter.getBoxesForSelection]'ın döndürdüğü KUTUYA göredir — bu
/// kutu satırın TAMAMI değil (fontSize×height'in bir alt kümesi; satırın
/// üstünde/altında ekstra boşluk (leading) bırakır), o yüzden ham piksel
/// ölçümleri önce bu kutuya göre normalize edilip SONRA güvenlik payı
/// uygulandı (kutuya göre değil satırın tamamına göre normalize edilirse
/// oranlar gerçekte olduğundan daha "gevşek" çıkar ve hareke harfin en
/// üst ucuna hafifçe taşabilir — bu tam olarak yaşanıp düzeltilen hata).
/// Harfler boy olarak çok farklı (ل/ك tepede erken başlar, ج/ح/م altta
/// geç biter) — TEK bir sabit oran hepsine uymuz. Boyama, HER HARF İÇİN
/// KENDİ gövdesinin dışında kalan bölgeye kısıtlanır: üstteki hareke
/// [0, top], alttaki hareke [bottom, 1] arasında; harfin gövdesi
/// ([top, bottom]) hiçbir zaman boyanmaz (kalın harf kuralı hariç, o
/// KASITLI olarak gövdeyi boyar).
const Map<String, (double, double)> _letterInk = {
  'ا': (0.25, 0.65),
  'ب': (0.44, 0.76),
  'ت': (0.39, 0.66),
  'ث': (0.32, 0.66),
  'ج': (0.47, 0.87),
  'ح': (0.47, 0.87),
  'خ': (0.39, 0.87),
  'د': (0.40, 0.65),
  'ذ': (0.31, 0.65),
  'ر': (0.50, 0.80),
  'ز': (0.40, 0.80),
  'س': (0.47, 0.84),
  'ش': (0.31, 0.84),
  'ص': (0.45, 0.84),
  'ض': (0.39, 0.84),
  'ط': (0.24, 0.65),
  'ظ': (0.24, 0.65),
  'ع': (0.39, 0.87),
  'غ': (0.29, 0.87),
  'ف': (0.26, 0.65),
  'ق': (0.27, 0.72),
  'ك': (0.22, 0.65),
  'ل': (0.22, 0.74),
  'م': (0.45, 0.87),
  'ن': (0.32, 0.68),
  'ه': (0.44, 0.65),
  'و': (0.46, 0.82),
  'ي': (0.39, 0.84),
};

/// Tabloda olmayan bir karakter (tatvil, lam-elif bitişiği, rakam vb.) için
/// EN GÜVENLİ (en dar) bölge: tüm harflerin en tepesi/en altı — hiçbirinin
/// gövdesine taşmaz, sadece bazı uç durumlarda hareke biraz eksik boyanır.
const (double, double) _defaultInk = (0.20, 0.90);

/// İKİNCİ (daha dar/güvenli) tablo: bir harf TEK BAŞINA değil bir KELİME
/// İÇİNDE göründüğünde (başta/ortada/sonda bitişik şekli) kullanılır.
/// Bitişik şekiller çoğu harfte İZOLE halinden DAHA UZUN sürer — özellikle
/// bağlantı çengeli/kuyruğu harfin "üstündeki" ya da "altındaki" boş
/// alana taşar (örn. bitişik م/ب/ح, izole halinden çok daha yukarı başlar).
/// Kelime içindeki gerçek harflerle (مد، حق، محمد، كتب، طلب...) ölçülüp
/// doğrulandı — bkz. proje geçmişindeki kalibrasyon notları. Tek harf +
/// hareke gösterimi (örn. Ders 1-9'daki "بَ") İZOLE tabloyu kullanır çünkü
/// harf gerçekten tek başına, bağlantısız şekliyle çizilir.
const Map<String, (double, double)> _letterInkJoined = {
  'ا': (0.17, 0.73),
  'ب': (0.24, 0.83),
  'ت': (0.24, 0.78),
  'ث': (0.24, 0.74),
  'ج': (0.46, 0.87),
  'ح': (0.35, 0.87),
  'خ': (0.25, 0.87),
  'د': (0.31, 0.65),
  'ذ': (0.25, 0.65),
  'ر': (0.31, 0.82),
  'ز': (0.32, 0.88),
  'س': (0.39, 0.90),
  'ش': (0.23, 0.90),
  'ص': (0.34, 0.84),
  'ض': (0.26, 0.84),
  'ط': (0.24, 0.78),
  'ظ': (0.24, 0.83),
  'ع': (0.31, 0.90),
  'غ': (0.26, 0.87),
  'ف': (0.26, 0.82),
  'ق': (0.25, 0.80),
  'ك': (0.22, 0.78),
  'ل': (0.22, 0.83),
  'م': (0.35, 0.87),
  'ن': (0.32, 0.84),
  'ه': (0.36, 0.73),
  'و': (0.38, 0.90),
  'ي': (0.31, 0.90),
};

/// [baseChar]'ın hangi tabloyu kullanacağı: [joined] false ise (metindeki
/// TEK harf kümesi budur) izole tablo, aksi halde bitişik tablo.
(double, double) _inkOf(String baseChar, {required bool joined}) {
  if (!joined) return _letterInk[baseChar] ?? _defaultInk;
  return _letterInkJoined[baseChar] ?? const (0.17, 0.90);
}

/// [text]'teki harf kümesi (base+ekleri) sayısı.
int _countBaseClusters(String text) {
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    if (!_isArabicCombiningMark(text.codeUnitAt(i))) count++;
  }
  return count;
}

/// [text]'teki her renklendirilecek hareke, kalın harf gövdesi ve
/// [baseColorOf] taban rengi verilmiş harf kümesinin dikdörtgenini,
/// rengine göre gruplayarak döner. Aynı harf kümesinde şedde + bir sesli
/// harf birlikte varsa (بَّ, بُّ), üst bölge ikiye bölünür: şedde dışta
/// (harften en uzak), sesli içte (harfe yakın).
Map<Color, List<Rect>> _arabicOverlayRects(
  TextPainter painter,
  String text, {
  required bool colorHarakat,
  required bool highlightThickLetters,
  BaseColorResolver? baseColorOf,
}) {
  final rectsByColor = <Color, List<Rect>>{};
  void add(Color color, Rect rect) =>
      rectsByColor.putIfAbsent(color, () => []).add(rect);

  // Metinde birden fazla harf kümesi varsa (tek harf + hareke değil, bir
  // kelime/ifade), her harf KENDİ bitişik (başta/ortada/sonda) şekliyle
  // çizilir — o zaman [_letterInkJoined] kullanılır. Tek bir harf kümesi
  // varsa (örn. "بَ") harf gerçekten izole şekliyle çizilir, [_letterInk]
  // kullanılır (bkz. o tablonun belgesi).
  final joined = _countBaseClusters(text) > 1;

  var i = 0;
  var isFirstCluster = true;
  while (i < text.length) {
    if (_isArabicCombiningMark(text.codeUnitAt(i))) {
      i++; // bir harfin eki; o harf kümesi işlenirken zaten ele alınır
      continue;
    }
    var end = i + 1;
    while (end < text.length && _isArabicCombiningMark(text.codeUnitAt(end))) {
      end++;
    }
    final baseChar = text[i];
    final isThick = highlightThickLetters && thickArabicLetters.contains(baseChar);
    final customBase = baseColorOf?.call(
      baseChar,
      isFirstCluster: isFirstCluster,
      hasOwnMarks: end > i + 1,
    );
    final marks = colorHarakat
        ? <int>{
            for (var j = i + 1; j < end; j++)
              if (harakaColorByCodePoint.containsKey(text.codeUnitAt(j)))
                text.codeUnitAt(j),
          }
        : const <int>{};
    isFirstCluster = false;

    if (!isThick && customBase == null && marks.isEmpty) {
      i = end;
      continue;
    }

    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: i, extentOffset: end),
    );
    if (boxes.isEmpty) {
      i = end;
      continue;
    }
    final box = boxes.first.toRect();
    final h = box.height;
    final (top, bottom) = _inkOf(baseChar, joined: joined);

    // Taban (harfin kendisi) rengi: özel bir çağıran kuralı > kalın harf
    // kuralı > (renklendirme yok, mevcut stil kalır).
    final baseOverride = customBase ?? (isThick ? harakaThickLetterColor : null);
    if (baseOverride != null) {
      add(baseOverride,
          Rect.fromLTRB(box.left, box.top + h * top, box.right, box.top + h * bottom));
    }

    final hasVowelAbove = marks.any(_aboveVowels.contains);
    final hasShadda = marks.contains(_kShadda);
    if (hasShadda && hasVowelAbove) {
      final split = top * 0.76; // harften en uzağı şedde, harfe yakını sesli
      add(harakaShaddaColor, Rect.fromLTRB(box.left, box.top, box.right, box.top + h * split));
      final vowel = marks.firstWhere(_aboveVowels.contains);
      add(harakaColorByCodePoint[vowel]!,
          Rect.fromLTRB(box.left, box.top + h * split, box.right, box.top + h * top));
    } else if (hasShadda) {
      add(harakaShaddaColor, Rect.fromLTRB(box.left, box.top, box.right, box.top + h * top));
    } else if (hasVowelAbove) {
      final vowel = marks.firstWhere(_aboveVowels.contains);
      add(harakaColorByCodePoint[vowel]!,
          Rect.fromLTRB(box.left, box.top, box.right, box.top + h * top));
    }
    if (marks.contains(_kKasra)) {
      add(harakaKasraColor,
          Rect.fromLTRB(box.left, box.top + h * bottom, box.right, box.bottom));
    }
    i = end;
  }
  return rectsByColor;
}

/// Birden çok dikdörtgeni tek kırpma yoluna birleştirir.
class _RectsClipper extends CustomClipper<Path> {
  const _RectsClipper(this.rects);

  final List<Rect> rects;

  @override
  Path getClip(Size size) {
    final path = Path();
    for (final rect in rects) {
      path.addRect(rect);
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _RectsClipper oldClipper) => true;
}
