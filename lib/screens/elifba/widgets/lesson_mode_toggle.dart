import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../lesson_view_mode.dart';

/// Quiet segmented control for switching between the "Tüm Harfler"
/// and "Tek Harf" study modes — deliberately small and understated,
/// not a full tab bar.
class LessonModeToggle extends StatelessWidget {
  final LessonViewMode mode;
  final ValueChanged<LessonViewMode> onChanged;
  final bool showBookMode;

  const LessonModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
    this.showBookMode = false,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Tüm Harfler',
            compact: showBookMode,
            selected: mode == LessonViewMode.grid,
            onTap: () => onChanged(LessonViewMode.grid),
          ),
          _Segment(
            label: 'Tek Harf',
            compact: showBookMode,
            selected: mode == LessonViewMode.single,
            onTap: () => onChanged(LessonViewMode.single),
          ),
          if (showBookMode)
            _Segment(
              label: 'Kitap Modu',
              compact: true,
              selected: mode == LessonViewMode.book,
              onTap: () => onChanged(LessonViewMode.book),
            ),
        ],
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
