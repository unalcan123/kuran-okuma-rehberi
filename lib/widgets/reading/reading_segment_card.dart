import 'package:flutter/material.dart';

import '../../models/reading_segment.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_theme.dart';
import '../reading_arabic_text.dart';

/// Soft pastel colors of the number badges, in turn (like the design).
const List<(Color, Color)> _badgeColors = [
  (Color(0xFFFFF1C9), Color(0xFFB7862B)),
  (Color(0xFFDDF3E0), Color(0xFF3F8F55)),
  (Color(0xFFDCEEFB), Color(0xFF3F7DB5)),
  (Color(0xFFEDE3FA), Color(0xFF7A55B5)),
  (Color(0xFFFCE1E4), Color(0xFFC0485A)),
];

/// One ayet / prayer part on a reading screen: number, the Arabic (the
/// priority, on a clean light card), its own play button (at least 48×48),
/// and — only when chosen in the settings — the Turkish meaning under it.
///
/// While it is being read the card gets a pastel border, a light tint and a
/// small "sounding" mark; the Arabic keeps its color. With "Metni Gizle" the
/// Arabic makes room for "Şimdi sen oku" and a "Göster" button.
class ReadingSegmentCard extends StatelessWidget {
  const ReadingSegmentCard({
    super.key,
    required this.index,
    required this.segment,
    required this.fontSize,
    required this.showArabic,
    required this.showMeaning,
    required this.isActive,
    required this.isPlaying,
    required this.isTextHidden,
    required this.onPlay,
    required this.onReveal,
  });

  final int index;
  final ReadingSegment segment;
  final double fontSize;
  final bool showArabic;
  final bool showMeaning;
  final bool isActive;
  final bool isPlaying;
  final bool isTextHidden;
  final VoidCallback onPlay;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final opening = segment.isOpening;
    final accent = opening ? AppColors.gold : AppColors.turquoise;
    final arabicStyle = AppTextTheme.arabicSmall(
      fontSize: fontSize,
    ).copyWith(color: opening ? AppColors.gold : AppColors.navy, height: 1.9);

    Widget arabic;
    if (isTextHidden) {
      arabic = _YourTurn(index: index, onReveal: onReveal);
    } else if (showArabic) {
      arabic = Directionality(
        textDirection: TextDirection.rtl,
        child: ReadingArabicText(segment.arabic, style: arabicStyle),
      );
    } else {
      arabic = const SizedBox.shrink();
    }

    final meaningParts = <Widget>[
      if (segment.pronunciation case final p? when p.isNotEmpty)
        _Note(title: 'Türkçe Okunuş', text: p),
      if (showMeaning && segment.meaning.isNotEmpty)
        _Note(
          key: ValueKey('reading-meaning-$index'),
          title: 'Türkçe Anlam',
          text: segment.meaning,
        ),
    ];

    final badge =
        opening
            ? Icon(Icons.auto_awesome_rounded, color: accent, size: 26)
            : _Badge(number: segment.number ?? index + 1);

    return AnimatedContainer(
      key: ValueKey('reading-segment-$index'),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color:
            isActive
                ? Color.alphaBlend(
                  accent.withValues(alpha: 0.08),
                  AppColors.surface,
                )
                : (opening ? const Color(0xFFFFFCF4) : AppColors.surface),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isActive ? accent.withValues(alpha: 0.75) : AppColors.divider,
          width: isActive ? 2.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: isActive ? 0.10 : 0.05),
            blurRadius: isActive ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              badge,
              if (isActive) ...[
                const SizedBox(width: 8),
                Icon(
                  isPlaying ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                  key: ValueKey('reading-active-mark-$index'),
                  color: accent,
                  size: 22,
                ),
              ],
              const Spacer(),
              IconButton(
                key: ValueKey('reading-play-$index'),
                tooltip:
                    isActive && isPlaying
                        ? 'Duraklat'
                        : (opening ? 'Besmeleyi dinle' : 'Bunu dinle'),
                onPressed: onPlay,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                iconSize: 34,
                color: accent,
                icon: Icon(
                  isActive && isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : (isActive
                          ? Icons.play_circle_fill_rounded
                          : Icons.play_circle_outline_rounded),
                ),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(right: 6), child: arabic),
          ...meaningParts,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _badgeColors[(number - 1) % _badgeColors.length];
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        '$number',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 10, 12, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: AppColors.divider, height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.turquoise,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

/// "Metni Gizle": the student recites the part from memory.
class _YourTurn extends StatelessWidget {
  const _YourTurn({required this.index, required this.onReveal});

  final int index;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('reading-hidden-$index'),
    margin: const EdgeInsets.fromLTRB(6, 4, 6, 0),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    decoration: BoxDecoration(
      color: AppColors.goldSoft,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
    ),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.record_voice_over_rounded, color: AppColors.gold),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Şimdi sen oku',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        FilledButton.tonalIcon(
          key: ValueKey('reading-reveal-$index'),
          onPressed: onReveal,
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.visibility_rounded),
          label: const Text('Göster'),
        ),
      ],
    ),
  );
}
