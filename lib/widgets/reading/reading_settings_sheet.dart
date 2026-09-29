import 'package:flutter/material.dart';

import '../../services/reading_settings.dart';
import '../../theme/app_colors.dart';

/// Words that differ between a surah ("Ayet") and a prayer ("Bölüm").
class ReadingNouns {
  const ReadingNouns({required this.one, required this.stepByStep});

  /// "Ayet" / "Bölüm".
  final String one;

  /// "Ayet Ayet" / "Bölüm Bölüm".
  final String stepByStep;

  static const surah = ReadingNouns(one: 'Ayet', stepByStep: 'Ayet Ayet');
  static const dua = ReadingNouns(one: 'Bölüm', stepByStep: 'Bölüm Bölüm');
}

/// The ⚙ button of a reading screen: opens [ReadingSettingsSheet].
class ReadingSettingsButton extends StatelessWidget {
  const ReadingSettingsButton({super.key, required this.nouns, this.settings});

  final ReadingNouns nouns;
  final ReadingSettings? settings;

  static Future<void> open(
    BuildContext context, {
    required ReadingNouns nouns,
    ReadingSettings? settings,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: 640),
    builder:
        (context) => FractionallySizedBox(
          heightFactor: 0.88,
          child: ReadingSettingsSheet(
            nouns: nouns,
            settings: settings ?? ReadingSettings.instance,
          ),
        ),
  );

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('reading-settings-button'),
    tooltip: 'Okuma ayarları',
    iconSize: 28,
    icon: const Icon(Icons.settings_rounded),
    onPressed: () => open(context, nouns: nouns, settings: settings),
  );
}

/// The reading screens' settings — the same for Sureler and Dualar:
/// OKUMA (Arabic size, speed), İÇERİK (Arabic text, Turkish meaning),
/// EZBER / TEKRAR (mode, repeat count, pause, hide the text). Every change
/// is saved on the device ([ReadingSettings]).
class ReadingSettingsSheet extends StatelessWidget {
  const ReadingSettingsSheet({
    super.key,
    required this.nouns,
    required this.settings,
  });

  final ReadingNouns nouns;
  final ReadingSettings settings;

  static String percent(double scale) => '%${(scale * 100).round()}';

  static String speedLabel(double speed) =>
      '${speed.toStringAsFixed(speed * 100 % 10 == 0 ? 1 : 2)}x';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final theme = Theme.of(context).textTheme;
        return SafeArea(
          child: Column(
            children: [
              // The title and "Kapat" stay put; the settings scroll.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                child: Row(
                  children: [
                    const Icon(Icons.settings_rounded, color: AppColors.navy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ayarlar',
                        style: theme.titleLarge?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kapat',
                      onPressed: () => Navigator.of(context).maybePop(),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(child: _settingsList(context, theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _settingsList(BuildContext context, TextTheme theme) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    children: [
      const _SectionTitle('OKUMA'),
      _Label(Icons.format_size_rounded, 'Arapça Yazı Boyutu'),
      Row(
        children: [
          _RoundButton(
            key: const ValueKey('arabic-size-down'),
            icon: Icons.remove_rounded,
            tooltip: 'Arapça yazıyı küçült',
            onPressed:
                settings.arabicScale > ReadingSettings.arabicScales.first
                    ? () => settings.stepArabicScale(-1)
                    : null,
          ),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final scale in ReadingSettings.arabicScales)
                  _Choice(
                    key: ValueKey('arabic-size-${percent(scale)}'),
                    label: percent(scale),
                    selected: settings.arabicScale == scale,
                    onTap: () => settings.arabicScale = scale,
                  ),
              ],
            ),
          ),
          _RoundButton(
            key: const ValueKey('arabic-size-up'),
            icon: Icons.add_rounded,
            tooltip: 'Arapça yazıyı büyüt',
            onPressed:
                settings.arabicScale < ReadingSettings.arabicScales.last
                    ? () => settings.stepArabicScale(1)
                    : null,
          ),
        ],
      ),
      const SizedBox(height: 14),
      _Label(Icons.speed_rounded, 'Okuma Hızı'),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final speed in ReadingSettings.speeds)
            _Choice(
              key: ValueKey('speed-${speedLabel(speed)}'),
              label: speedLabel(speed),
              selected: settings.speed == speed,
              onTap: () => settings.speed = speed,
            ),
        ],
      ),
      const _SectionTitle('İÇERİK'),
      _Switch(
        key: const ValueKey('show-arabic'),
        icon: Icons.menu_book_rounded,
        title: 'Arapça Metin',
        value: settings.showArabic,
        onChanged: (v) => settings.showArabic = v,
      ),
      _Switch(
        key: const ValueKey('show-meaning'),
        icon: Icons.translate_rounded,
        title: 'Türkçe Meali Göster',
        value: settings.showMeaning,
        onChanged: (v) => settings.showMeaning = v,
      ),
      const _SectionTitle('EZBER / TEKRAR'),
      _Label(Icons.school_rounded, 'Ezber Modu'),
      Row(
        children: [
          for (final (mode, icon, title, hint) in [
            (
              MemorizationMode.stepByStep,
              Icons.menu_book_rounded,
              nouns.stepByStep,
              'Sırasıyla ilerle',
            ),
            (
              MemorizationMode.shuffled,
              Icons.shuffle_rounded,
              'Karışık',
              'Rastgele sıra',
            ),
            (
              MemorizationMode.listenOnly,
              Icons.hearing_rounded,
              'Sadece Dinle',
              'Baştan sona',
            ),
          ]) ...[
            if (mode != MemorizationMode.stepByStep) const SizedBox(width: 8),
            Expanded(
              child: _ModeTile(
                key: ValueKey('mode-${mode.name}'),
                icon: icon,
                title: title,
                hint: hint,
                selected: settings.mode == mode,
                onTap: () => settings.mode = mode,
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _Label(Icons.repeat_rounded, 'Tekrar Sayısı')),
          _RoundButton(
            key: const ValueKey('repeat-down'),
            icon: Icons.remove_rounded,
            tooltip: 'Tekrarı azalt',
            onPressed:
                settings.repeatCount > ReadingSettings.minRepeat
                    ? () => settings.repeatCount--
                    : null,
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${settings.repeatCount}x',
              key: const ValueKey('repeat-count'),
              textAlign: TextAlign.center,
              style: theme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          _RoundButton(
            key: const ValueKey('repeat-up'),
            icon: Icons.add_rounded,
            tooltip: 'Tekrarı artır',
            onPressed:
                settings.repeatCount < ReadingSettings.maxRepeat
                    ? () => settings.repeatCount++
                    : null,
          ),
        ],
      ),
      const SizedBox(height: 14),
      _Label(
        Icons.schedule_rounded,
        '${nouns.one == 'Ayet' ? 'Ayetler' : 'Bölümler'} Arası Bekleme',
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final seconds in ReadingSettings.pauses)
            _Choice(
              key: ValueKey('pause-$seconds'),
              label: '$seconds sn',
              selected: settings.pauseSeconds == seconds,
              onTap: () => settings.pauseSeconds = seconds,
            ),
        ],
      ),
      const SizedBox(height: 8),
      _Switch(
        key: const ValueKey('hide-text'),
        icon: Icons.visibility_off_rounded,
        title: 'Ezberlerken metni gizle',
        subtitle:
            settings.mode == MemorizationMode.stepByStep
                ? '${nouns.one} önce görünür ve okunur; sonra '
                    '"Şimdi sen oku" çıkar.'
                : '"${nouns.stepByStep}" modunda çalışır.',
        value: settings.hideTextWhileMemorizing,
        onChanged:
            settings.mode == MemorizationMode.stepByStep
                ? (v) => settings.hideTextWhileMemorizing = v
                : null,
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.skyBlueSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: AppColors.skyBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ezberlerken her ${nouns.one.toLowerCase()} istenen '
                'sayıda tekrarlanır ve bir sonrakine otomatik geçilir.',
                style: theme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.turquoise,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 22, color: AppColors.navySoft),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    selectedColor: AppColors.skyBlue,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    side: BorderSide(color: selected ? AppColors.skyBlue : AppColors.divider),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    icon: Icon(icon),
  );
}

class _Switch extends StatelessWidget {
  const _Switch({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    secondary: Icon(icon, color: AppColors.navySoft),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
    activeColor: Colors.white,
    activeTrackColor: AppColors.skyBlue,
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? AppColors.skyBlueSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.skyBlue : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? AppColors.skyBlue : AppColors.navy),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
