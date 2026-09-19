import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/game_score.dart';
import '../../../theme/app_colors.dart';

/// One slim row under the progress bar: "Puan 120" on the left and, on
/// the right, the game's instruction. When an answer earns points the
/// instruction gives way for a moment to a small "+15" (and, on a good
/// run, a quiet "Güzel gidiyorsun!"), then comes back.
///
/// Pass a *new* [award] object for every answer; the same object is not
/// announced twice.
class GameScoreStrip extends StatefulWidget {
  const GameScoreStrip({
    super.key,
    required this.points,
    required this.award,
    required this.instruction,
  });

  final int points;
  final ScoreAward? award;
  final String instruction;

  @override
  State<GameScoreStrip> createState() => _GameScoreStripState();
}

class _GameScoreStripState extends State<GameScoreStrip> {
  ScoreAward? _shown;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _shown = widget.award;
    if (_shown != null) _armTimer();
  }

  @override
  void didUpdateWidget(GameScoreStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.award, oldWidget.award)) return;
    _hide?.cancel();
    setState(() => _shown = widget.award);
    if (widget.award != null) _armTimer();
  }

  void _armTimer() {
    _hide = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _shown = null);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final award = _shown;
    // Fixed height: the play area below must never shift when an award
    // appears or fades.
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          _PointsBadge(points: widget.points),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder:
                  (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
              child:
                  award == null
                      ? Row(
                        key: const ValueKey('instruction'),
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.instruction,
                              textAlign: TextAlign.start,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 13,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Align(
                        key: ObjectKey(award),
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _pill(
                                context,
                                '+${award.regularPoints}',
                                AppColors.turquoiseSoft,
                                AppColors.turquoise,
                              ),
                              if (award.hasStreakBonus) ...[
                                const SizedBox(width: 8),
                                _pill(
                                  context,
                                  'Güzel gidiyorsun! +${award.streakBonus}',
                                  AppColors.goldSoft,
                                  AppColors.navy,
                                  icon: Icons.music_note_rounded,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    String text,
    Color background,
    Color foreground, {
    IconData? icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          maxLines: 1,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
        ),
      ],
    ),
  );
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Puan',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(end: points.toDouble()),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder:
                (context, value, _) => Text(
                  '${value.round()}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
