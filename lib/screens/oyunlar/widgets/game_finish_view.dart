import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// End-of-game screen: three notes settle in, a short message, and
/// the two follow-ups — play again or leave.
class GameFinishView extends StatelessWidget {
  const GameFinishView({
    super.key,
    required this.title,
    required this.message,
    required this.onReplay,
    required this.onExit,
    this.exitLabel = 'Oyunlara Dön',
    this.summary,
  });

  final String title;
  final String message;
  final VoidCallback onReplay;
  final VoidCallback onExit;
  final String exitLabel;

  /// Optional result block (points, stars, best) shown under the message.
  final Widget? summary;

  static const _notes = [
    (Icons.music_note_rounded, AppColors.gold, 44.0),
    (Icons.audiotrack_rounded, AppColors.turquoise, 64.0),
    (Icons.music_note_rounded, AppColors.sage, 44.0),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _notes.length; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 500 + i * 150),
                      curve: Curves.easeOutBack,
                      builder:
                          (context, t, child) => Opacity(
                            opacity: t.clamp(0.0, 1.0),
                            child: Transform.scale(scale: t, child: child),
                          ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          _notes[i].$1,
                          color: _notes[i].$2,
                          size: _notes[i].$3,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (summary != null) ...[
                const SizedBox(height: 20),
                summary!,
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onReplay,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Tekrar Oyna'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  minimumSize: const Size.fromHeight(56),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onExit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.divider, width: 1.5),
                  minimumSize: const Size.fromHeight(56),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(exitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
