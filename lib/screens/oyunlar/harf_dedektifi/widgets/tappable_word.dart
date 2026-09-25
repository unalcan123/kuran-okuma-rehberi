import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../harf_oyunlari/game_letters.dart';
import '../dedektif_data.dart';

enum WordLetterMark { none, found, hinted, wrong }

/// Gerçek bir Arapça kelime, TEK metin olarak (harfler bağlı, bölünmeden)
/// çizilir; her harfe ayrı dokunulabilir.
///
/// Harflerin yeri tahmin edilmez: metin [TextPainter] ile dizilir ve her
/// harfin (harekeleriyle birlikte) mantıksal aralığı için
/// `getBoxesForSelection` kutusu alınır. RTL'de görsel sırayı bu ölçüm verir;
/// harf genişlikleri eşit varsayılmaz. Dokunma alanları o kutulardır.
/// Vurgu yalnızca arkaya boyanan bir zemin ve harfin RENGİdir: renk
/// değişikliği şekillendirmeyi (bağlantıları, genişlikleri) değiştirmez.
class TappableWord extends StatefulWidget {
  const TappableWord({
    super.key,
    required this.word,
    required this.fontSize,
    required this.markOf,
    required this.onTapLetter,
    this.wordIndex = 0,
  });

  final DetectiveWord word;
  final double fontSize;
  final WordLetterMark Function(int letterIndex) markOf;
  final ValueChanged<int> onTapLetter;
  final int wordIndex;

  static TextStyle styleFor(double fontSize) =>
      lessonArabicStyle(fontSize, color: AppColors.navy);

  /// Onay işaretleri için kelimenin üstünde bırakılan boşluk.
  static double topSpace(double fontSize) => math.max(22, fontSize * 0.2);

  static const double sidePadding = 6;

  static TextPainter layoutWord(
    DetectiveWord word,
    double fontSize, {
    Color? Function(int letterIndex)? colorOf,
  }) {
    final base = styleFor(fontSize);
    return TextPainter(
      text: TextSpan(
        style: base,
        children: [
          for (var k = 0; k < word.letters.length; k++)
            TextSpan(
              text: word.text.substring(
                word.letters[k].start,
                word.letters[k].end,
              ),
              style:
                  colorOf?.call(k) == null
                      ? null
                      : TextStyle(color: colorOf!(k)),
            ),
        ],
      ),
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout();
  }

  /// Her harfin (mantıksal sırayla) metin içindeki kutusu.
  static List<Rect> letterBoxes(DetectiveWord word, TextPainter painter) => [
    for (final letter in word.letters)
      painter
          .getBoxesForSelection(
            TextSelection(baseOffset: letter.start, extentOffset: letter.end),
          )
          .map((b) => b.toRect())
          .fold<Rect?>(null, (a, b) => a == null ? b : a.expandToInclude(b)) ??
          Rect.zero,
  ];

  /// Kelimenin bu yazı boyutunda kaplayacağı alan (yerleşim hesabı için).
  static Size measure(DetectiveWord word, double fontSize) {
    final painter = layoutWord(word, fontSize);
    final size = Size(
      painter.width + sidePadding * 2,
      painter.height + topSpace(fontSize),
    );
    painter.dispose();
    return size;
  }

  @override
  State<TappableWord> createState() => _TappableWordState();
}

class _TappableWordState extends State<TappableWord> {
  TextPainter? _painter;

  @override
  void dispose() {
    _painter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final fontSize = widget.fontSize;
    final markOf = widget.markOf;
    final wordIndex = widget.wordIndex;
    _painter?.dispose();
    final painter = _painter = TappableWord.layoutWord(
      word,
      fontSize,
      colorOf:
          (k) => switch (markOf(k)) {
            WordLetterMark.found => AppColors.turquoise,
            _ => null,
          },
    );
    final boxes = TappableWord.letterBoxes(word, painter);
    final top = TappableWord.topSpace(fontSize);
    final origin = Offset(TappableWord.sidePadding, top);
    final size = Size(
      painter.width + TappableWord.sidePadding * 2,
      painter.height + top,
    );
    final checkSize = math.max(20.0, fontSize * 0.17);

    return Semantics(
      container: true,
      label: 'Kelime ${wordIndex + 1}',
      child: SizedBox.fromSize(
        size: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WordPainter(
                  painter: painter,
                  origin: origin,
                  boxes: boxes,
                  marks: [for (var k = 0; k < boxes.length; k++) markOf(k)],
                ),
              ),
            ),
            for (var k = 0; k < boxes.length; k++)
              Positioned.fromRect(
                rect: boxes[k].shift(origin),
                child: Semantics(
                  button: true,
                  label: 'Kelimenin ${k + 1}. harfi',
                  selected: markOf(k) == WordLetterMark.found,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      key: ValueKey('w$wordIndex.$k'),
                      onTap: () => widget.onTapLetter(k),
                      borderRadius: BorderRadius.circular(10),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: AppColors.skyBlueSoft.withValues(alpha: 0.35),
                      focusColor: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            for (var k = 0; k < boxes.length; k++)
              if (markOf(k) == WordLetterMark.found)
                Positioned(
                  left: origin.dx + boxes[k].center.dx - checkSize / 2,
                  top: math.max(0, top - checkSize - 2),
                  child: IgnorePointer(
                    child: _CheckBadge(size: checkSize),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.turquoise,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.check_rounded, color: Colors.white, size: size * 0.75),
  );
}

class _WordPainter extends CustomPainter {
  _WordPainter({
    required this.painter,
    required this.origin,
    required this.boxes,
    required this.marks,
  });

  final TextPainter painter;
  final Offset origin;
  final List<Rect> boxes;
  final List<WordLetterMark> marks;

  @override
  void paint(Canvas canvas, Size size) {
    for (var k = 0; k < boxes.length; k++) {
      final mark = marks[k];
      if (mark == WordLetterMark.none) continue;
      final box = boxes[k].shift(origin);
      // Satır yüksekliği harekeler için ferah; zemin harfin gövdesine otursun.
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          box.left,
          box.top + box.height * 0.12,
          box.right,
          box.bottom - box.height * 0.06,
        ),
        const Radius.circular(12),
      );
      switch (mark) {
        case WordLetterMark.found:
          canvas.drawRRect(rect, Paint()..color = AppColors.turquoiseSoft);
        case WordLetterMark.hinted:
          canvas.drawRRect(rect, Paint()..color = AppColors.goldSoft);
          canvas.drawRRect(
            rect,
            Paint()
              ..color = AppColors.gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        case WordLetterMark.wrong:
          canvas.drawRRect(
            rect,
            Paint()
              ..color = AppColors.navySoft.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        case WordLetterMark.none:
          break;
      }
    }
    painter.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(_WordPainter old) =>
      old.painter != painter || old.origin != origin;
}
