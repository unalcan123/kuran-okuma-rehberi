import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../data/memory_game_data.dart';
import '../../../helpers/colored_arabic_text.dart';
import '../../../models/game_score.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../widgets/game_colors.dart';
import 'memory_game_screen.dart';

/// Hafıza is played level by level, from Kolay to Çok Zor. Each card
/// shows its letters and, once played, the stars of the best play.
class MemoryLevelsScreen extends StatefulWidget {
  const MemoryLevelsScreen({super.key});

  @override
  State<MemoryLevelsScreen> createState() => _MemoryLevelsScreenState();
}

class _MemoryLevelsScreenState extends State<MemoryLevelsScreen> {
  late Future<List<GameRecord>> _records = _load();

  Future<List<GameRecord>> _load() {
    final store = context.read<GameScoreStore>();
    return Future.wait([
      for (final level in kMemoryLevels) store.recordOf(level.gameKey),
    ]);
  }

  Future<void> _play(MemoryLevel level) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MemoryGameScreen(level: level)),
    );
    if (!mounted) return;
    final records = _load();
    setState(() {
      _records = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.isDesktop(context) ? 800.0 : 640.0;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hafıza')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FutureBuilder<List<GameRecord>>(
            future: _records,
            builder: (context, snapshot) {
              final records = snapshot.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text(
                    'Aynı harfleri bul. Hangisinden başlayalım?',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  for (final tier in MemoryTier.values) ...[
                    const SizedBox(height: 22),
                    Text(
                      tier.label,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final level in kMemoryLevels.where(
                      (l) => l.tier == tier,
                    )) ...[
                      _LevelCard(
                        level: level,
                        accentIndex: tier.index,
                        stars: records?[kMemoryLevels.indexOf(level)].bestStars,
                        onTap: () => _play(level),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.accentIndex,
    required this.stars,
    required this.onTap,
  });

  final MemoryLevel level;
  final int accentIndex;
  final int? stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (accent, soft) =
        GameColors.accents[accentIndex % GameColors.accents.length];
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${level.number}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${level.title} · ${level.pairCount} çift',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ColoredArabicText(
                          level.letters
                              .map((letter) => letter.isolatedForm)
                              .join('  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextTheme.arabicSmall(
                            fontSize: 24,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (stars != null)
                Semantics(
                  label: '$stars yıldız',
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(
                            i < stars!
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 22,
                            color:
                                i < stars! ? AppColors.gold : AppColors.divider,
                          ),
                      ],
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
