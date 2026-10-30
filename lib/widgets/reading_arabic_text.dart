import '../l10n/l10n.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Wraps passages normally, limiting enlargement only when a whole word
/// would exceed the card's available width.
class ReadingArabicText extends StatelessWidget {
  const ReadingArabicText(
    this.text, {
    super.key,
    required this.style,
    this.highlightStart,
    this.highlightEnd,
  });

  final String text;
  final int? highlightStart, highlightEnd;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final requested = MediaQuery.textScalerOf(context);
      var widest = 0.0;
      final painter = TextPainter(
        textDirection: TextDirection.rtl,
        textScaler: requested,
      );
      for (final word in text.split(RegExp(r'\s+'))) {
        painter.text = TextSpan(text: word, style: style);
        painter.layout();
        widest = math.max(widest, painter.width);
      }
      painter.dispose();
      final factor =
          constraints.hasBoundedWidth && widest > constraints.maxWidth
              ? constraints.maxWidth / widest
              : 1.0;
      final start = highlightStart;
      final end = highlightEnd;
      final highlighted =
          start != null &&
          end != null &&
          start >= 0 &&
          end > start &&
          end <= text.length;
      final span =
          highlighted
              ? TextSpan(
                children: [
                  TextSpan(text: text.substring(0, start)),
                  TextSpan(
                    text: text.substring(start, end),
                    style: const TextStyle(
                      color: Color(0xFF145C39),
                      backgroundColor: Color(0xFFFFE49A),
                    ),
                  ),
                  TextSpan(text: text.substring(end)),
                ],
              )
              : TextSpan(text: context.t(text));
      final textKey = highlighted ? GlobalKey() : null;
      if (highlighted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = textKey?.currentContext;
          if (target == null || !target.mounted) return;
          final paragraph = target.findRenderObject();
          final scrollable = Scrollable.maybeOf(target);
          if (paragraph is! RenderParagraph ||
              !paragraph.attached ||
              scrollable == null) {
            return;
          }
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: end),
          );
          if (boxes.isEmpty) return;
          final rect = boxes
              .map((box) => box.toRect())
              .reduce((a, b) => a.expandToInclude(b));
          final viewport = RenderAbstractViewport.maybeOf(paragraph);
          if (viewport == null) return;
          final top =
              viewport.getOffsetToReveal(paragraph, 0, rect: rect).offset;
          final bottom =
              viewport.getOffsetToReveal(paragraph, 1, rect: rect).offset;
          final position = scrollable.position;
          if (position.pixels >= bottom && position.pixels <= top) return;
          // Only move if the actual word has left the reading viewport.
          // Preserve the full Arabic run; no separate word widgets or glyph changes.
          final offset =
              viewport.getOffsetToReveal(paragraph, 0.4, rect: rect).offset;
          position.animateTo(
            offset.clamp(position.minScrollExtent, position.maxScrollExtent),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        });
      }
      return Text.rich(
        span,
        key: textKey,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: style,
        textScaler:
            factor == 1
                ? requested
                : TextScaler.linear(
                  requested.scale(style.fontSize!) / style.fontSize! * factor,
                ),
      );
    },
  );
}
