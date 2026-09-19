import 'package:flutter/material.dart';

import '../../../models/game_score.dart';
import '../../../theme/app_colors.dart';

/// The numbers of a finished game: points, how many were known at the
/// first try, one to three stars, and the personal best (which only
/// appears once it has been read from storage).
class GameResultSummary extends StatelessWidget {
  const GameResultSummary({
    super.key,
    required this.result,
    required this.submission,
  });

  final GameResult result;
  final GameSubmission? submission;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final submission = this.submission;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${result.points} Puan',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.turquoise,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${result.firstTry} / ${result.total} İlk Denemede Doğru',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          label: '${result.stars} yıldız',
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 450 + i * 200),
                    curve: Curves.easeOutBack,
                    builder:
                        (context, t, child) => Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform.scale(scale: t, child: child),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        i < result.stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 44,
                        color:
                            i < result.stars
                                ? AppColors.gold
                                : AppColors.divider,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (submission != null) ...[
          const SizedBox(height: 12),
          if (submission.isNewBest)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Yeni rekor!',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ],
            )
          else if (submission.best.bestScore != null)
            Text(
              'En İyi: ${submission.best.bestScore}',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ],
    );
  }
}
