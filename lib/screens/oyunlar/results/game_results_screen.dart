import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../models/game_score.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../games.dart';

/// "Sonuçlarım": a list of the games the child has played. Each row is
/// one separate game (say "Oyun 3", or a Dinle ve Seç lesson) with how
/// many times it was finished, its average and best score, and the
/// scores of its last five plays. Games not played yet are left out.
class GameResultsScreen extends StatefulWidget {
  const GameResultsScreen({super.key});

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen> {
  late Future<Map<String, GameHistory>> _histories = _load();
  int _totalPlays = 0;

  Future<Map<String, GameHistory>> _load() async {
    final store = context.read<GameScoreStore>();
    final keys = [
      for (final game in kGames)
        for (final variant in game.variants) variant.key,
    ];
    final histories = await Future.wait([
      for (final key in keys) store.historyOf(key),
    ]);
    final total = histories.fold(0, (sum, history) => sum + history.plays);
    if (mounted && total != _totalPlays) setState(() => _totalPlays = total);
    return {for (var i = 0; i < keys.length; i++) keys[i]: histories[i]};
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sonuçlar silinsin mi?'),
            content: const Text(
              'Tüm oyunların puanları, ortalamaları ve rekorları silinecek. '
              'Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sıfırla'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<GameScoreStore>().clearAll();
    if (!mounted) return;
    final reloaded = _load();
    setState(() {
      _histories = reloaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.isDesktop(context) ? 800.0 : 640.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonuçlarım'),
        actions: [
          IconButton(
            tooltip: 'Sonuçları sıfırla',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _totalPlays == 0 ? null : _confirmReset,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FutureBuilder<Map<String, GameHistory>>(
            future: _histories,
            builder: (context, snapshot) {
              final histories = snapshot.data;
              if (histories == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final totalPlays = histories.values.fold(
                0,
                (sum, history) => sum + history.plays,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Text(
                    totalPlays == 0
                        ? 'Oyun oynadıkça puanların burada görünür.'
                        : 'Toplam $totalPlays oyun oynadın.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  for (final game in kGames) ...[
                    const SizedBox(height: 16),
                    _GameSection(game: game, histories: histories),
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

class _GameSection extends StatelessWidget {
  const _GameSection({required this.game, required this.histories});

  final GameEntry game;
  final Map<String, GameHistory> histories;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final played = [
      for (final variant in game.variants)
        if (histories[variant.key]?.hasPlayed ?? false) variant,
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: game.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(game.icon, color: game.foreground, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  game.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (played.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Henüz oynanmadı.',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else
            for (final variant in played) ...[
              const Divider(height: 28, color: AppColors.divider),
              _ResultRow(
                title: variant.title,
                history: histories[variant.key]!,
                accent: game.foreground,
              ),
            ],
        ],
      ),
    );
  }
}

/// One played game: name, plays / average / best, then its last scores
/// oldest to newest.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.history,
    required this.accent,
  });

  final String title;
  final GameHistory history;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Fact(label: 'Oynama', value: '${history.plays}'),
            _Fact(label: 'Ortalama', value: '${history.average.round()}'),
            _Fact(label: 'En İyi', value: '${history.bestPoints}'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          history.recent.length < GameHistory.recentCount
              ? 'Son ${history.recent.length} oyun'
              : 'Son ${GameHistory.recentCount} oyun',
          style: muted,
        ),
        const SizedBox(height: 6),
        // Five equal slots so the last five always share one line.
        Row(
          children: [
            for (var i = 0; i < GameHistory.recentCount; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child:
                    i < history.recent.length
                        ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: i == history.recent.length - 1 ? 0.28 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${history.recent[i]}',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
