import 'package:flutter/material.dart';

import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';

class ArabicGlyph extends StatelessWidget {
  final ArabicLetter letter;
  final double fontSize;

  const ArabicGlyph({super.key, required this.letter, required this.fontSize});

  static const _redMarks = {
    '\u064B',
    '\u064C',
    '\u064D',
    '\u064E',
    '\u064F',
    '\u0650',
    '\u0651',
    '\u0652',
  };

  static const _meddLetters = {'\u0627', '\u0648', '\u064A'};

  @override
  Widget build(BuildContext context) {
    final baseColor =
        letter.hasPositionForms || letter.isHeavyLetter
            ? AppColors.red
            : AppColors.navy;
    final style = AppTextTheme.arabicLetter(fontSize: fontSize);
    final spans = <TextSpan>[];
    var cluster = StringBuffer();

    void addCluster() {
      if (cluster.isEmpty) return;
      final clusterText = cluster.toString();
      final markStart = clusterText.indexOf(RegExp(r'[\u064B-\u0652]'));
      final baseText =
          markStart < 0 ? clusterText : clusterText.substring(0, markStart);
      final marksText = markStart < 0 ? '' : clusterText.substring(markStart);
      final hasHamza = baseText.contains('أ') || baseText.contains('إ');
      // A bare ا/و/ي with no hareke of its own, coming after something
      // else in the same word, is a medd (uzatma) letter — it's what's
      // stretching the previous vowel, so it gets called out in red
      // too (e.g. the "ا" in "بَا").
      final isMeddLetter =
          marksText.isEmpty &&
          spans.isNotEmpty &&
          _meddLetters.contains(baseText);
      final baseIsRed = letter.isHeavyLetter || hasHamza || isMeddLetter;

      if (marksText.isEmpty || baseIsRed) {
        // Base and mark render in the same color here (either there's
        // no mark, or the base itself is already red) — keep the
        // whole cluster as one TextSpan so the combining mark stays
        // shaped against its base glyph instead of being split into a
        // separate run, which some engines fail to position correctly
        // (seen with hemzeli elif: أَ / إِ / أُ).
        spans.add(
          TextSpan(
            text: clusterText,
            style: style.copyWith(color: baseIsRed ? AppColors.red : baseColor),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: baseText,
            style: style.copyWith(color: baseColor),
            children: [
              TextSpan(
                text: marksText,
                style: style.copyWith(color: AppColors.red),
              ),
            ],
          ),
        );
      }
      cluster = StringBuffer();
    }

    for (final rune in letter.isolatedForm.runes) {
      final character = String.fromCharCode(rune);
      if (_redMarks.contains(character)) {
        cluster.write(character);
      } else {
        addCluster();
        cluster.write(character);
      }
    }
    addCluster();

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
    );
  }
}
