import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/arabic_scale.dart';
import 'arabic_colorizer.dart';

/// Elifba öğretim ekranlarında Arapça metin için ortak widget: [Text] gibi
/// kullanılır, ama [profile]'a göre (kitabın o sayfasının renk mantığı,
/// kurallar [ArabicColorizer]'da) hareke/tenvin/şedde gibi işaretler ve kalın
/// ya da uzatma harflerinin glifi renkli çizilir. Renklendirilecek bir şey
/// yoksa sıradan [Text] ile TIPATIP aynı çizer, ek maliyet yoktur.
///
/// NASIL — harfin gövdesi ASLA kısmen boyanmaz, Arapça şekillendirme ASLA
/// bozulmaz:
///  * Metin hiçbir zaman harf ile harekesi arasından bölünmez. D:\Elifbe2025
///    projesinde metni renge göre ayrı `TextSpan`'lara bölmek denendi ve
///    GERÇEK CİHAZDA BOZULDU (HarfBuzz harfle harekeyi aynı parçada görmek
///    ister; ayrılınca şedde/hareke kayboluyor).
///  * Önce tam metin normal renkte çizilir ([Text]).
///  * İşaretler: aynı metin, işaretin renginde bir katmana çizilir; sonra
///    HAREKESİZ metin (harfler aynı yerde, işaretler yer kaplamaz) o katmandan
///    SİLİNİR (`BlendMode.dstOut`). Geriye yalnızca işaretlerin pikselleri
///    kalır — harfin gövdesine tek piksel renk taşmaz, kutu/oran tahmini yok.
///  * Harf gövdesi (kalın harf, uzatma harfi): harekesiz metin, yalnızca o
///    harfin glifi renkli, diğerleri saydam olarak çizilir. Harekesiz metinde
///    harfler arasında işaret olmadığından renk değişimi şekillendirmeyi
///    bozmaz; kitap da (PDF) renkleri tam olarak böyle, glif glif verir.
/// Bkz. `test/colored_arabic_text_test.dart`.
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
    this.profile = ArabicColorProfile.standard,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  /// Hangi öğelerin hangi renkte çizileceği (kitabın ilgili sayfası).
  final ArabicColorProfile profile;

  @override
  Widget build(BuildContext context) {
    // A lesson's Arabic is drawn larger on tablets and desktops.
    final scale = ArabicScale.of(context);
    final style =
        scale == 1 || this.style.fontSize == null
            ? this.style
            : this.style.copyWith(fontSize: this.style.fontSize! * scale);
    final base = Text(
      text,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
    final plan = ArabicColorizer.plan(text, profile: profile);
    if (!plan.any((c) => c.isColored)) return base;

    final defaults = DefaultTextStyle.of(context);
    return CustomPaint(
      foregroundPainter: _ArabicColorPainter(
        text: text,
        plan: plan,
        style: defaults.style.merge(style),
        textAlign: textAlign ?? defaults.textAlign ?? TextAlign.start,
        textDirection: textDirection ?? Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: maxLines ?? defaults.maxLines,
        ellipsis:
            (overflow ?? defaults.overflow) == TextOverflow.ellipsis
                ? '\u2026'
                : null,
        textHeightBehavior: defaults.textHeightBehavior,
        locale: Localizations.maybeLocaleOf(context),
      ),
      child: base,
    );
  }
}

class _ArabicColorPainter extends CustomPainter {
  _ArabicColorPainter({
    required this.text,
    required this.plan,
    required this.style,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.maxLines,
    required this.ellipsis,
    required this.textHeightBehavior,
    required this.locale,
  });

  final String text;
  final List<ArabicClusterColors> plan;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final int? maxLines;
  final String? ellipsis;
  final TextHeightBehavior? textHeightBehavior;
  final Locale? locale;

  TextPainter _layout(InlineSpan span, double width) => TextPainter(
    text: span,
    textAlign: textAlign,
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: maxLines,
    ellipsis: ellipsis,
    textHeightBehavior: textHeightBehavior,
    locale: locale,
  )..layout(minWidth: width, maxWidth: width);

  /// [text] with, for each cluster, only the marks [keep] allows.
  String _withMarks(bool Function(ArabicClusterColors, ArabicMarkColor) keep) {
    final buffer = StringBuffer();
    for (final cluster in plan) {
      buffer.write(cluster.base);
      for (final mark in cluster.marks) {
        if (keep(cluster, mark)) buffer.writeCharCode(mark.codeUnit);
      }
    }
    return buffer.toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final fontSize = textScaler.scale(style.fontSize ?? 14);
    // Katmanlar kutunun dışına taşan işaretleri de kapsasın.
    final bounds = (Offset.zero & size).inflate(fontSize);

    // 1) Harf gövdeleri: harekesiz metin, yalnızca boyanacak glifler renkli.
    if (plan.any((c) => c.body != null)) {
      final spans = <TextSpan>[
        for (var i = 0; i < plan.length; i++)
          TextSpan(
            text: plan[i].base,
            style: TextStyle(
              color: _bodyColor(plan, i) ?? const Color(0x00000000),
            ),
          ),
      ];
      _layout(
        TextSpan(style: style, children: spans),
        width,
      ).paint(canvas, Offset.zero);
    }

    // 2) İşaretler, renk renk: [keep] metni o renkte çizilir, sonra [erase]
    //    metni (aynı harfler, o renkte olmayan işaretler) silinir.
    // Şeddenin rengi önce: üstüne binen işaret (örn. ٌّ'deki tenvin) kendi
    // katmanında sonra, şeddenin üstüne çizilir.
    final shaddaColors = {
      for (final c in plan)
        for (final m in c.marks)
          if (m.isShadda && m.color != null) m.color!,
    };
    final colors = {
      ...shaddaColors,
      for (final c in plan)
        for (final m in c.marks)
          if (m.color != null) m.color!,
    };
    // Silme, harf kenarlarındaki yumuşatma (antialias) pikselleri de
    // kapsasın diye glifi biraz kalın çizer.
    final eraseStroke = math.max(1.0, fontSize * 0.03);
    for (final color in colors) {
      bool hasColor(ArabicClusterColors c) =>
          c.marks.any((m) => m.color == color);
      // Şeddenin üstündeki işaret şedde olmadan aşağı iner: şedde boyanıyor
      // ama üstündeki işaret boyanmıyorsa bu yöntemle ayrılamaz; o nadir
      // durumda (henüz hiçbir kitap sayfasında yok) üstteki işaret de boyanır.
      bool shaddaLifts(ArabicClusterColors c) =>
          c.marks.any((m) => m.isShadda && m.color == color);
      final keep = _withMarks((c, m) => hasColor(c));
      final erase = _withMarks(
        (c, m) =>
            hasColor(c) &&
            m.color != color &&
            !(shaddaLifts(c) && !m.isShadda && !m.isBelow),
      );
      canvas.saveLayer(bounds, Paint());
      _layout(
        TextSpan(text: keep, style: style.copyWith(color: color)),
        width,
      ).paint(canvas, Offset.zero);
      canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstOut);
      final eraser = _layout(
        TextSpan(
          text: erase,
          style: style.copyWith(color: const Color(0xFF000000)),
        ),
        width,
      );
      eraser.paint(canvas, Offset.zero);
      _layout(
        TextSpan(
          text: erase,
          style: style.copyWith(
            foreground:
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = eraseStroke
                  ..strokeJoin = StrokeJoin.round,
          ),
        ),
        width,
      ).paint(canvas, Offset.zero);
      canvas.restore();
      canvas.restore();
    }
  }

  /// Lâm-elif (لا) tek bir glif (ligatür) olarak çizilir; bir glifin bir
  /// kısmı ayrı renk alamaz. Kitapta da (s. 33, لَا) ligatür tek renktir:
  /// Lâm'ın rengi. Bu yüzden Lâm'a bitişen elif Lâm'ın rengini alır.
  static Color? _bodyColor(List<ArabicClusterColors> plan, int i) {
    if (i > 0 && plan[i - 1].base == 'ل' && _alifs.contains(plan[i].base)) {
      return plan[i - 1].body;
    }
    return plan[i].body;
  }

  static const _alifs = {'ا', 'أ', 'إ', 'آ', 'ٱ'};

  @override
  bool shouldRepaint(covariant _ArabicColorPainter old) =>
      old.text != text ||
      old.style != style ||
      old.textAlign != textAlign ||
      old.textDirection != textDirection ||
      old.textScaler != textScaler ||
      old.maxLines != maxLines ||
      old.ellipsis != ellipsis ||
      !_samePlan(old.plan, plan);

  static bool _samePlan(
    List<ArabicClusterColors> a,
    List<ArabicClusterColors> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].body != b[i].body) return false;
      final am = a[i].marks, bm = b[i].marks;
      if (am.length != bm.length) return false;
      for (var j = 0; j < am.length; j++) {
        if (am[j].color != bm[j].color) return false;
      }
    }
    return true;
  }
}
