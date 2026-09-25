import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../harf_oyunlari/game_letters.dart';
import '../yazi_data.dart';

/// Çocuklar için ekran klavyesi.
///
/// Harfler Elifba sırasıyla, SAĞDAN SOLA dizilir (ا en sağ üstte). Telefonda
/// 7 sütun × 4 satır, geniş ekranda 14 sütun × 2 satır: tuşlar küçülmez,
/// satır sayısı değişir. "Ek Harfler" ve "Harekeler" ayrı bölümlerdir.
///
/// Tuşlar odak ALMAZ ve [TextFieldTapRegion] içindedir: tuşa dokunmak yazı
/// alanının odağını/imlecini kaybettirmez; yazı imlecin olduğu yere gider.
class ArabicKeyboard extends StatelessWidget {
  const ArabicKeyboard({
    super.key,
    required this.section,
    required this.onSection,
    required this.onKey,
    required this.onBackspace,
    required this.onSpace,
    this.onNewline,
    this.highlight,
    this.fillHeight = false,
  });

  /// Verilen yüksekliği doldur: bölüm seçimi ve Sil/Boşluk/Satır HER ZAMAN
  /// görünür, yalnızca harf satırları gerekirse kayar (yatay telefon).
  final bool fillHeight;

  final KeySection section;
  final ValueChanged<KeySection> onSection;
  final void Function(YaziKey key, KeySection section) onKey;
  final VoidCallback onBackspace;
  final VoidCallback onSpace;

  /// `null`: yeni satır yok (tek satırlık alan).
  final VoidCallback? onNewline;

  /// İpucu: belirginleşecek karakter.
  final String? highlight;

  List<YaziKey> get _keys => switch (section) {
    KeySection.letters => kLetterKeys,
    KeySection.extra => kExtraKeys,
    KeySection.haraka => kHarakaKeys,
  };

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
    child: LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 640 ? 14 : 7;
        final gap = 5.0;
        final keyWidth = (c.maxWidth - gap * (columns - 1)) / columns;
        final keyHeight = keyWidth.clamp(44.0, 56.0);
        final keys = _keys;
        final rows = <List<YaziKey>>[];
        for (var i = 0; i < keys.length; i += columns) {
          rows.add(keys.sublist(i, (i + columns).clamp(0, keys.length)));
        }
        final keyArea = <Widget>[
          // Harekeler bölümündeki kısa açıklama.
          if (section == KeySection.haraka)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Hareke, imleçten önceki harfe eklenir.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          for (final row in rows) ...[
            Row(
              // Sağdan sola: ilk harf en sağda.
              textDirection: TextDirection.rtl,
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  SizedBox(
                    width: keyWidth,
                    height: keyHeight,
                    child: _Key(
                      yaziKey: row[i],
                      highlighted: highlight == row[i].insert,
                      haraka: section == KeySection.haraka,
                      onTap: () => onKey(row[i], section),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: gap),
          ],
        ];
        final bottom = SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _ActionKey(
                  key: const ValueKey('key-backspace'),
                  icon: Icons.backspace_outlined,
                  label: 'Sil',
                  onTap: onBackspace,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 5,
                child: _ActionKey(
                  key: const ValueKey('key-space'),
                  icon: Icons.space_bar_rounded,
                  label: 'Boşluk',
                  onTap: onSpace,
                ),
              ),
              if (onNewline != null) ...[
                SizedBox(width: gap),
                Expanded(
                  flex: 3,
                  child: _ActionKey(
                    key: const ValueKey('key-newline'),
                    icon: Icons.keyboard_return_rounded,
                    label: 'Satır',
                    onTap: onNewline!,
                  ),
                ),
              ],
            ],
          ),
        );
        final bar = _SectionBar(section: section, onSection: onSection);
        if (fillHeight) {
          return Column(
            children: [
              bar,
              const SizedBox(height: 6),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: keyArea,
                  ),
                ),
              ),
              bottom,
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [bar, const SizedBox(height: 6), ...keyArea, bottom],
        );
      },
    ),
  );
}

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.section, required this.onSection});

  final KeySection section;
  final ValueChanged<KeySection> onSection;

  @override
  Widget build(BuildContext context) {
    const items = [
      (KeySection.letters, 'Harfler'),
      (KeySection.extra, 'Ek Harfler'),
      (KeySection.haraka, 'Harekeler'),
    ];
    return Row(
      children: [
        for (final (s, label) in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: s == section ? AppColors.turquoise : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: ValueKey('section-${s.name}'),
                  canRequestFocus: false,
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSection(s),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            s == section
                                ? AppColors.turquoise
                                : AppColors.divider,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: s == section ? Colors.white : AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.yaziKey,
    required this.highlighted,
    required this.haraka,
    required this.onTap,
  });

  final YaziKey yaziKey;
  final bool highlighted;
  final bool haraka;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: yaziKey.name ?? yaziKey.label,
    child: ExcludeSemantics(
      child: Material(
        color: highlighted ? AppColors.goldSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        elevation: 1,
        child: InkWell(
          key: ValueKey('key-${yaziKey.insert}'),
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: highlighted ? AppColors.gold : AppColors.divider,
                width: highlighted ? 3 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  yaziKey.label,
                  textDirection: TextDirection.rtl,
                  textScaler: TextScaler.noScaling,
                  style: singleGlyphStyle(haraka ? 30 : 28),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.skyBlueSoft,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      canRequestFocus: false,
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.navy),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
