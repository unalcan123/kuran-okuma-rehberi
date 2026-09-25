import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../theme/app_colors.dart';
import '../harf_dedektifi/dedektif_data.dart';
import '../harf_oyunlari/game_letters.dart';
import '../harf_oyunlari/profil/player_repository.dart';
import 'ciz_progress_store.dart';
import 'ciz_session.dart';
import 'harf_ciziyorum_game_screen.dart';

/// Harf Çiziyorum başlangıcı: harf seçilir (yıldızlarıyla), "Sırayla Öğren"
/// o harften başlayarak 5 harf; "Zorlandıklarımı Çalış" zorlanılanlar.
/// Bu sürüm harflerin yalnızca TEK BAŞINA yazılışını çalıştırır.
class HarfCiziyorumScreen extends StatefulWidget {
  const HarfCiziyorumScreen({super.key});

  @override
  State<HarfCiziyorumScreen> createState() => _HarfCiziyorumScreenState();
}

class _HarfCiziyorumScreenState extends State<HarfCiziyorumScreen> {
  final _store = DrawProgressStore();
  Map<int, LetterDrawProgress> _progress = {};
  int? _selected;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  String? _profileId() {
    try {
      return context.read<PlayerRepository>().activePlayer?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _reload() async {
    final p = await _store.load(_profileId());
    if (!mounted) return;
    setState(() {
      _progress = p;
      _selected ??= suggestedStart(p);
    });
  }

  Future<void> _start(List<int> letters) async {
    if (letters.isEmpty) return;
    final exit = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HarfCiziyorumGameScreen(letterIds: letters),
      ),
    );
    if (!mounted) return;
    if (exit == true) {
      Navigator.of(context).pop();
    } else {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Responsive.isDesktop(context) ? 820.0 : 640.0;
    final selected = _selected ?? 1;
    final practice = practiceLetters(_progress);
    final stars = _progress.values.fold(0, (a, p) => a + p.stars);
    return Scaffold(
      appBar: AppBar(title: const Text('Harf Çiziyorum')),
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
                      color: AppColors.goldSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.brush_rounded,
                      size: 36,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harf Çiziyorum',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'İzini takip et, noktalarını koy, harfi öğren!',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Harfini seç',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  Text(
                    ' $stars / 56',
                    key: const ValueKey('total-stars'),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, c) {
                  final columns = (c.maxWidth / 76).floor().clamp(4, 10);
                  final size = (c.maxWidth - (columns - 1) * 8) / columns;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    // Elifba sırası sağdan sola dizilir.
                    textDirection: TextDirection.rtl,
                    children: [
                      for (final l in kDetectiveLetters)
                        _LetterTile(
                          key: ValueKey('letter-${l.id}'),
                          letter: l,
                          size: size,
                          stars: _progress[l.id]?.stars ?? 0,
                          selected: l.id == selected,
                          onTap: () => setState(() => _selected = l.id),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Bu bölümde harflerin tek başına yazılışını çalışıyoruz. '
                'Her oturum 5 harf.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('in-order-button'),
                onPressed: () => _start(lettersFrom(selected)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'Sırayla Öğren (${letterById(selected).name} harfinden)',
                ),
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
                key: const ValueKey('practice-start-button'),
                onPressed: practice.isEmpty ? null : () => _start(practice),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  practice.isEmpty
                      ? 'Zorlandıklarımı Çalış (henüz yok)'
                      : 'Zorlandıklarımı Çalış (${practice.length} harf)',
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

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    super.key,
    required this.letter,
    required this.size,
    required this.stars,
    required this.selected,
    required this.onTap,
  });

  final DetectiveLetter letter;
  final double size;
  final int stars;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${letter.name}, $stars yıldız',
    child: ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size * 1.15,
        child: Material(
          color: selected ? AppColors.turquoiseSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.turquoise : AppColors.divider,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                        child: Text(
                          letter.char,
                          textScaler: TextScaler.noScaling,
                          style: singleGlyphStyle(34),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 2; i++)
                        Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: i < stars ? AppColors.gold : AppColors.divider,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
