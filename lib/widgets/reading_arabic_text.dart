import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Wraps passages normally, limiting enlargement only when a whole word
/// would exceed the card's available width.
class ReadingArabicText extends StatelessWidget {
  const ReadingArabicText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final requested = MediaQuery.textScalerOf(context);
      var widest = 0.0;
      final painter = TextPainter(textDirection: TextDirection.rtl,
        textScaler: requested);
      for (final word in text.split(RegExp(r'\s+'))) {
        painter.text = TextSpan(text: word, style: style);
        painter.layout();
        widest = math.max(widest, painter.width);
      }
      painter.dispose();
      final factor = constraints.hasBoundedWidth && widest > constraints.maxWidth
          ? constraints.maxWidth / widest : 1.0;
      return Text(text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: style,
        textScaler: factor == 1 ? requested : TextScaler.linear(
          requested.scale(style.fontSize!) / style.fontSize! * factor),
      );
    },
  );
}
