import '../../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';

import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';

/// Renders a letter's başta/ortada/sonda forms.
///
/// [compact] (used inside the "Tüm Harfler" grid card) makes each of
/// the three columns [Expanded] so the row exactly fills whatever
/// width the card actually has — it shrinks smoothly instead of
/// overflowing when the grid gives the card less room. The full
/// ("Tek Harf" hero) mode instead sizes each column to a fixed width
/// and lets the row size itself, since there it's centered on an
/// otherwise-empty page rather than squeezed into a grid cell.
class PositionForms extends StatelessWidget {
  final ArabicLetter letter;
  final bool compact;
  final bool large;

  /// Extra size multiplier for the non-[compact] ("Tek Harf" hero)
  /// layout — bumped up on tablet/desktop so this stays legible from
  /// further away instead of just sitting in a small block in the
  /// middle of a big screen. Ignored when [compact] is true.
  final double scale;

  const PositionForms({
    super.key,
    required this.letter,
    this.compact = false,
    this.large = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final examples = letter.positionExamples;
    // Arabic reads right-to-left, so "Başta" (start of the word) must
    // land on the right and "Sonda" (end) on the left. Laying the row
    // out under plain LTR directionality with this pre-flipped order
    // achieves exactly that without touching how each glyph itself
    // shapes — do not reorder this to "fix" RTL, it already is.
    final labels = ['Sonda', 'Ortada', 'Başta'];
    final forms = [letter.finalForm!, letter.medialForm!, letter.initialForm!];
    final orderedExamples =
        examples == null
            ? const <String?>[null, null, null]
            : [examples[2], examples[1], examples[0]];

    final columns = [
      for (var index = 0; index < forms.length; index++)
        _FormColumn(
          label: labels[index],
          form: forms[index],
          example: orderedExamples[index],
          target: letter.isolatedForm.replaceAll('ـ', ''),
          compact: compact,
          large: large,
          scale: scale,
        ),
    ];

    final gap = compact ? 4.0 : 14.0 * scale;
    final columnWidth = 92.0 * scale;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment:
            large ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < columns.length; index++) ...[
            if (index > 0) SizedBox(width: gap),
            compact
                ? Expanded(child: columns[index])
                : SizedBox(width: columnWidth, child: columns[index]),
          ],
        ],
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  final String label;
  final String form;
  final String? example;
  final String target;
  final bool compact;
  final bool large;
  final double scale;

  const _FormColumn({
    required this.label,
    required this.form,
    required this.example,
    required this.target,
    required this.compact,
    this.large = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (large) {
      Widget arabic(String text, double size, Color color) => ReadingFittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          style: AppTextTheme.arabicSmall(
            fontSize: size,
          ).copyWith(color: color, height: 1.2),
        ),
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.turquoiseSoft.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(flex: 3, child: arabic(form, 76, AppColors.red)),
            if (example != null)
              Expanded(flex: 2, child: arabic(example!, 50, AppColors.navy)),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 11 : 15 * scale,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: compact ? 2 : 4 * scale),
        ReadingFittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            form,
            style: AppTextTheme.arabicSmall(
              fontSize: compact ? 34 : 56 * scale,
            ),
          ),
        ),
        if (example != null) ...[
          SizedBox(height: compact ? 2 : 4 * scale),
          ReadingFittedBox(
            fit: BoxFit.scaleDown,
            child: _HighlightedExample(
              example: example!,
              target: target,
              compact: compact,
              scale: scale,
            ),
          ),
        ],
      ],
    );
  }
}

class _HighlightedExample extends StatelessWidget {
  final String example;
  final String target;
  final bool compact;
  final double scale;

  const _HighlightedExample({
    required this.example,
    required this.target,
    required this.compact,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final targetIndex = example.indexOf(target);
    final style = AppTextTheme.arabicSmall(fontSize: compact ? 29 : 44 * scale);
    if (targetIndex < 0) return Text(example, style: style);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: example.substring(0, targetIndex), style: style),
          TextSpan(text: target, style: style.copyWith(color: AppColors.red)),
          TextSpan(
            text: example.substring(targetIndex + target.length),
            style: style,
          ),
        ],
      ),
      textDirection: TextDirection.rtl,
    );
  }
}
