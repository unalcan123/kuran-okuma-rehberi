import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../theme/app_colors.dart';
import '../harf_oyunlari/profil/player_repository.dart';
import 'harf_treni_game_screen.dart';
import 'tren_engine.dart';
import 'tren_fonts.dart';
import 'tren_progress_store.dart';

/// Harf Treni başlangıcı: seviye seçilir (Seviye 1 önerilir), 5 tren.
class HarfTreniScreen extends StatefulWidget {
  const HarfTreniScreen({super.key, this.fonts});

  /// Testler için: doğrulanmış yazı tipleri (verilmezse ölçülür).
  @visibleForTesting
  final List<String>? fonts;

  @override
  State<HarfTreniScreen> createState() => _HarfTreniScreenState();
}

class _HarfTreniScreenState extends State<HarfTreniScreen> {
  final _store = TrainProgressStore();
  TrainLevel _level = TrainLevel.l1;
  Map<int, int> _weights = {};
  late final List<String> _fonts = widget.fonts ?? verifiedTrainFonts();

  bool get _level4Ready => _fonts.length >= 2;

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  String? _profileId() {
    try {
      return context.read<PlayerRepository>().activePlayer?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadWeights() async {
    final w = await _store.weightsFor(_level, profileId: _profileId());
    if (mounted) setState(() => _weights = w);
  }

  List<int> get _practice {
    final ids =
        _weights.keys.toList()
          ..sort((a, b) => _weights[b]!.compareTo(_weights[a]!));
    return ids.take(3).toList();
  }

  Future<void> _start({List<int> focus = const []}) async {
    final exit = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) =>
                HarfTreniGameScreen(level: _level, fonts: _fonts, focus: focus),
      ),
    );
    if (!mounted) return;
    if (exit == true) {
      Navigator.of(context).pop();
    } else {
      _loadWeights();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Responsive.isDesktop(context) ? 760.0 : 640.0;
    final practice = _practice;
    return Scaffold(
      appBar: AppBar(title: const Text('Harf Treni')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.turquoiseSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.train_rounded,
                      size: 38,
                      color: AppColors.turquoise,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harf Treni',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'Aynı harfleri bul, vagonları doldur!',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Seviye',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              for (final level in TrainLevel.values) ...[
                _LevelTile(
                  level: level,
                  selected: level == _level,
                  recommended: level == TrainLevel.l1,
                  enabled: level != TrainLevel.l4 || _level4Ready,
                  onTap: () {
                    setState(() => _level = level);
                    _loadWeights();
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (!_level4Ready)
                Row(
                  key: const ValueKey('fonts-missing'),
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Yazı tipleri yüklenemedi; Seviye 4 şimdilik kapalı.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$kTrainCount tren · süre yok',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('train-start'),
                onPressed: _start,
                icon: const Icon(Icons.train_rounded),
                label: const Text('Başla'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  minimumSize: const Size.fromHeight(56),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                key: const ValueKey('train-practice'),
                onPressed:
                    practice.isEmpty ? null : () => _start(focus: practice),
                icon: const Icon(Icons.search_rounded),
                label: Text(
                  practice.isEmpty
                      ? 'Zorlandıklarımı Çalış (henüz yok)'
                      : 'Zorlandıklarımı Çalış',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.goldSoft,
                  foregroundColor: AppColors.navy,
                  minimumSize: const Size.fromHeight(56),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.selected,
    required this.recommended,
    required this.enabled,
    required this.onTap,
  });

  final TrainLevel level;
  final bool selected;
  final bool recommended;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected ? AppColors.turquoiseSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('level-${level.number}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.turquoise : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      selected ? AppColors.turquoise : AppColors.goldSoft,
                  child: Text(
                    '${level.number}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            level.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          if (recommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Önerilen',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${level.subtitle} · ${level.wagons} vagon, ${level.cards} kart',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
