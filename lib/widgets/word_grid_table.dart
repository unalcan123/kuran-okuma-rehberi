import 'package:flutter/material.dart';

import '../models/arabic_letter.dart';
import '../models/word_highlight.dart';
import '../theme/app_colors.dart';
import 'word_cell.dart';

/// The book's grids of example words (dashed boxes, first word at the
/// right like in the book), each word tappable, the part the book prints in
/// red marked according to [highlight].
///
/// [columns] is what the book has; on a narrow screen the grid uses fewer
/// columns so no word gets too small (cells are at least [minCellWidth]
/// wide).
class WordGridTable extends StatelessWidget {
  final List<ArabicLetter> words;
  final WordHighlight highlight;
  final int columns;
  final double minCellWidth;
  final double fontSize;

  const WordGridTable({
    super.key,
    required this.words,
    this.highlight = WordHighlight.none,
    this.columns = 3,
    this.minCellWidth = 150,
    this.fontSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    final line = BorderSide(color: AppColors.gold.withValues(alpha: 0.45));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : 600.0;
        final count = (width / minCellWidth).floor().clamp(1, columns);
        final rows = (words.length / count).ceil();
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.goldSoft.withValues(alpha: 0.35),
              border: Border.fromBorderSide(line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Table(
              // Right to left, so the first word is at the right (the book).
              textDirection: TextDirection.rtl,
              border: TableBorder(horizontalInside: line, verticalInside: line),
              // NOT `fill`: rows with only `fill` cells collapse to no height.
              defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
              children: [
                for (var r = 0; r < rows; r++)
                  TableRow(
                    children: [
                      for (var c = 0; c < count; c++)
                        if (r * count + c < words.length)
                          _cell(words[r * count + c])
                        else
                          const SizedBox.shrink(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cell(ArabicLetter letter) {
    final (before, red, after) = splitForHighlight(letter.isolatedForm, highlight);
    return WordCell(
      letter: letter,
      before: before,
      red: red,
      after: after,
      fontSize: fontSize,
    );
  }
}
