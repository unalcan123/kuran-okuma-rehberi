import 'package:flutter/material.dart';

import '../models/arabic_letter.dart';
import '../models/waqf_example.dart';
import '../theme/app_colors.dart';
import 'word_cell.dart';

/// The book's "Durulduğunda / Geçildiğinde" table: each word as it is read
/// when stopping on it and when passing on, the part that changes in red.
/// Tapping a word plays its recording.
class WaqfExamplesTable extends StatelessWidget {
  final List<WaqfExample> examples;
  final double fontSize;

  const WaqfExamplesTable({super.key, required this.examples, this.fontSize = 36});

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: AppColors.gold.withValues(alpha: 0.45));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.goldSoft.withValues(alpha: 0.35),
          border: Border.fromBorderSide(border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Table(
          border: TableBorder(
            horizontalInside: border,
            verticalInside: border,
          ),
          // NOT `fill`: if every cell fills, the row has no height of its own
          // and the whole table collapses to nothing.
          defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.goldSoft),
              children: const [_HeaderCell('Durulduğunda'), _HeaderCell('Geçildiğinde')],
            ),
            for (final e in examples)
              TableRow(
                children: [
                  _cell(e.stopLetter, e.stop, e.stopRedLetters),
                  _cell(e.passLetter, e.pass, e.passRedLetters),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(ArabicLetter letter, String word, int redLetters) {
    final (head, tail) = splitLastLetters(word, redLetters);
    return WordCell(letter: letter, before: head, red: tail, fontSize: fontSize);
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.red,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
