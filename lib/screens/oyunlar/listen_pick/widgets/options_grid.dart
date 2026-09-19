import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../models/arabic_letter.dart';
import 'option_card.dart';

/// Lays the choices out in the arrangement (one column, two, or a single
/// row) where the *longest* choice can be drawn largest, then uses that
/// one font size for every card. Short letters get big cards; long words
/// automatically move to wide, stacked cards instead of shrinking to
/// unreadable.
class OptionsGrid extends StatelessWidget {
  const OptionsGrid({
    super.key,
    required this.options,
    required this.textOf,
    required this.maxFontSize,
    required this.itemBuilder,
    this.maxCellHeight = 220,
    this.gap = 12,
  });

  final List<ArabicLetter> options;
  final String Function(ArabicLetter item) textOf;
  final double maxFontSize;
  final double maxCellHeight;
  final double gap;
  final Widget Function(BuildContext context, ArabicLetter item, double fontSize)
  itemBuilder;

  static const _padX = 12.0;
  static const _padY = 6.0;
  static const _reference = 100.0;

  Size _measureWidest() {
    var width = 0.0;
    var height = 0.0;
    for (final item in options) {
      final painter = TextPainter(
        text: TextSpan(
          text: textOf(item),
          style: optionTextStyle(_reference),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      width = math.max(width, painter.width);
      height = math.max(height, painter.height);
      painter.dispose();
    }
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final count = options.length;
    final widest = _measureWidest();
    return LayoutBuilder(
      builder: (context, constraints) {
        var bestColumns = 1;
        var bestFont = -1.0;
        var bestCell = Size.zero;
        for (final columns in const [2, 1, 4, 3]) {
          if (columns > count || count % columns != 0) continue;
          final rows = count ~/ columns;
          final cellWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
          final cellHeight = math.min(
            (constraints.maxHeight - gap * (rows - 1)) / rows,
            maxCellHeight,
          );
          final font = math.min(
            (cellWidth - 2 * _padX) / widest.width,
            (cellHeight - 2 * _padY) / widest.height,
          ) * _reference;
          if (font > bestFont) {
            bestFont = font;
            bestColumns = columns;
            bestCell = Size(cellWidth, cellHeight);
          }
        }
        final fontSize = bestFont.clamp(12.0, maxFontSize);
        final rows = <Widget>[];
        for (var start = 0; start < count; start += bestColumns) {
          rows.add(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = start; i < start + bestColumns; i++) ...[
                  if (i > start) SizedBox(width: gap),
                  SizedBox(
                    width: bestCell.width,
                    height: bestCell.height,
                    child: itemBuilder(context, options[i], fontSize),
                  ),
                ],
              ],
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                rows[i],
              ],
            ],
          ),
        );
      },
    );
  }
}
