import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../lesson_view_mode.dart';

/// Quiet segmented control for switching a lesson's study views —
/// deliberately small and understated, not a full tab bar. [segments]
/// lists the views offered, in order, with their labels.
class LessonModeToggle extends StatelessWidget {
  final LessonViewMode mode;
  final ValueChanged<LessonViewMode> onChanged;
  final Map<LessonViewMode, String> segments;

  const LessonModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      // A narrow phone shrinks the whole control rather than cutting a label.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in segments.entries)
              _Segment(
                key: ValueKey('mode-${entry.key.name}'),
                label: entry.value,
                compact: segments.length > 2,
                selected: mode == entry.key,
                onTap: () => onChanged(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.turquoiseSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 18,
            vertical: 10,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.turquoise : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
