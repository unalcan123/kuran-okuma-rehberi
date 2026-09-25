import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../theme/app_colors.dart';
import '../harf_oyunlari/game_letters.dart';
import 'dedektif_data.dart';
import 'dedektif_engine.dart';
import 'harf_dedektifi_game_screen.dart';

/// Harf Dedektifi başlangıcı: mod ve harf grubu seçilir, 5 kısa tur
/// başlar (süre yok).
class HarfDedektifiScreen extends StatefulWidget {
  const HarfDedektifiScreen({super.key});

  @override
  State<HarfDedektifiScreen> createState() => _HarfDedektifiScreenState();
}

class _HarfDedektifiScreenState extends State<HarfDedektifiScreen> {
  DetectiveMode _mode = DetectiveMode.shapes;
  LetterChoice _choice = kLetterChoices.first;

  static const _icons = {
    DetectiveMode.shapes: Icons.category_rounded,
    DetectiveMode.similar: Icons.compare_rounded,
    DetectiveMode.words: Icons.manage_search_rounded,
  };

  Future<void> _start() async {
    final exit = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HarfDedektifiGameScreen(mode: _mode, choice: _choice),
      ),
    );
    if (exit == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Responsive.isDesktop(context) ? 760.0 : 640.0;
    final fits =
        _choice.letterIds == null ||
        DetectiveRoundFactory.choiceFits(_mode, _choice.ids);
    return Scaffold(
      appBar: AppBar(title: const Text('Harf Dedektifi')),
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
                      Icons.search_rounded,
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
                          'Harf Dedektifi',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'Harfleri farklı şekilleriyle ve kelimelerin içinde bul!',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle('Oyun türü'),
              for (final mode in DetectiveMode.values) ...[
                _ModeTile(
                  mode: mode,
                  icon: _icons[mode]!,
                  selected: mode == _mode,
                  onTap: () => setState(() => _mode = mode),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              _SectionTitle('Harfler'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in kLetterChoices)
                    ChoiceChip(
                      key: ValueKey('choice-${choice.id}'),
                      label: Text(choice.title),
                      selected: choice == _choice,
                      showCheckmark: false,
                      selectedColor: AppColors.turquoiseSoft,
                      side: BorderSide(
                        color:
                            choice == _choice
                                ? AppColors.turquoise
                                : AppColors.divider,
                      ),
                      labelStyle: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                      onSelected: (_) => setState(() => _choice = choice),
                    ),
                ],
              ),
              if (_choice.letterIds case final ids?) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    [for (final id in ids) letterById(id).char].join('  '),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: lessonArabicStyle(34),
                  ),
                ),
              ],
              if (!fits) ...[
                const SizedBox(height: 8),
                Row(
                  key: const ValueKey('choice-note'),
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _mode == DetectiveMode.similar
                            ? 'Bu grupta benzer harf yok; tüm benzer harf gruplarıyla oynanır.'
                            : 'Bu gruptaki harfler için yeterli kelime yok; tüm harflerle oynanır.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
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
                      '$kDetectiveRoundCount kısa tur · süre yok',
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
                key: const ValueKey('detective-start'),
                onPressed: _start,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Başla'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final DetectiveMode mode;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.turquoiseSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: ValueKey('mode-${mode.key}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.turquoise : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: selected ? AppColors.turquoise : AppColors.navySoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        mode.subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.turquoise,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
