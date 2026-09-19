import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../data/drag_drop_game_data.dart';
import '../../../models/game_score.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../widgets/game_colors.dart';
import 'drag_drop_game_screen.dart';

/// Sürükle & Bırak is a set of small games: seven fixed letter groups
/// and one that deals five random letters. Each card shows the stars of
/// the child's best play, once there is one.
class DragDropLevelsScreen extends StatefulWidget {
  const DragDropLevelsScreen({super.key});

  @override
  State<DragDropLevelsScreen> createState() => _DragDropLevelsScreenState();
}

class _DragDropLevelsScreenState extends State<DragDropLevelsScreen> {
  late Future<List<GameRecord>> _records = _load();

  Future<List<GameRecord>> _load() {
    final store = context.read<GameScoreStore>();
    return Future.wait([
      for (final level in kDragDropLevels) store.recordOf(level.gameKey),
    ]);
  }

  Future<void> _play(DragDropLevel level) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DragDropGameScreen(level: level),
      ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Sürükle & Bırak')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FutureBuilder<List<GameRecord>>(
            future: _records,
            builder: (context, snapshot) {
              final records = snapshot.data;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: kDragDropLevels.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Hangi oyunu oynamak istersin?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }
                  final level = kDragDropLevels[index - 1];
                  return _LevelCard(
                    level: level,
                    accentIndex: index - 1,
                    stars: records?[index - 1].bestStars,
                    onTap: () => _play(level),
                  );
                },
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

  final DragDropLevel level;
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child:
                      level.isRandom
                          ? Icon(Icons.shuffle_rounded, color: accent, size: 28)
                          : Text(
                            level.id,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (level.isRandom)
                      Text(
                        'Her seferinde $kDragDropRandomCount yeni harf',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            level.letters!
                                .map((letter) => letter.isolatedForm)
                                .join('   '),
                            style: AppTextTheme.arabicSmall(
                              fontSize: 26,
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
