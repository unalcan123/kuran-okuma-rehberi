import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "3 / 7" chip for an app bar.
class GameStepPill extends StatelessWidget {
  const GameStepPill({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.goldSoft,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
    ),
    child: Text(
      '$current / $total',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
    ),
  );
}

/// Slim progress bar that eases to its new value.
class GameProgressBar extends StatelessWidget {
  const GameProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.clamp(0.0, 1.0)),
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
    builder:
        (context, animated, _) => ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: animated,
            minHeight: 6,
            color: AppColors.turquoise,
            backgroundColor: AppColors.turquoiseSoft,
          ),
        ),
  );
}
