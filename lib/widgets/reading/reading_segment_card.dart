import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../models/reading_segment.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_theme.dart';
import '../lesson_grid_background.dart';
import '../reading_arabic_text.dart';

/// Soft pastel colors of the number badges, in turn (like the design).
const List<(Color, Color)> _badgeColors = [
  (Color(0xFFFFF1C9), Color(0xFF795814)),
  (Color(0xFFDDF3E0), Color(0xFF27683B)),
  (Color(0xFFDCEEFB), Color(0xFF285B87)),
  (Color(0xFFEDE3FA), Color(0xFF684397)),
  (Color(0xFFFCE1E4), Color(0xFF9F3044)),
];

/// Soft green of the verse being read (border, glow, tint).
const Color _activeGlow = Color(0xFF4CB782);

/// Soft card tints, in turn (fill, border): mint, sky, peach, lilac.
const List<(Color, Color)> _cardTints = [
  (Color(0xFFF2FAF3), Color(0xFFCDEAD4)),
  (Color(0xFFF0F7FD), Color(0xFFC8E2F3)),
  (Color(0xFFFFF7EF), Color(0xFFF3DAC4)),
  (Color(0xFFF7F3FD), Color(0xFFDBD1F1)),
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
    this.onTap,
    this.unit = 'Ayet',
  });

  final int index;
  final ReadingSegment segment;
  final double fontSize;
  final bool showArabic;
  final bool showMeaning;
  final bool isActive;
  final bool isPlaying;
  final bool isTextHidden;
  final VoidCallback? onPlay;

  /// A tap anywhere on the card (outside its buttons): the segment from its
  /// start. Null when the segment has no recording.
  final VoidCallback? onTap;
  final String unit;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final opening = segment.isOpening;
    final accent = opening ? AppColors.gold : AppColors.turquoise;
    final arabicStyle = AppTextTheme.arabicSmall(
      fontSize: fontSize,
    ).copyWith(color: AppColors.navy, height: 1.9);

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
          title: _meaningTitles[context.language.code] ?? 'Anlam',
          text: segment.meaning,
          publishedText: segment.meaningSource.isNotEmpty,
          footnotes: segment.meaningFootnotes,
        ),
    ];

    final (tint, tintBorder) = _cardTints[index % _cardTints.length];
    final badge =
        opening && segment.number == null
            ? Icon(Icons.auto_awesome_rounded, color: accent, size: 26)
            : _Badge(number: segment.number ?? index + 1);

    final card = AnimatedContainer(
      key: ValueKey('reading-segment-$index'),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      // The verse being read glows soft green all around (fades in with the
      // container), so a child memorizing sees which one is sounding.
      decoration: BoxDecoration(
        color:
            isActive
                ? Color.alphaBlend(
                  _activeGlow.withValues(alpha: 0.08),
                  AppColors.surface,
                )
                : (opening ? const Color(0xFFFFFCF4) : tint),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isActive ? _activeGlow.withValues(alpha: 0.85) : tintBorder,
          width: isActive ? 2.4 : 1.5,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: _activeGlow.withValues(alpha: 0.45),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: AppColors.navy.withValues(alpha: isActive ? 0.08 : 0.05),
            blurRadius: isActive ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Room at the bottom for the corner decorations (never on the text).
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 24),
      foregroundDecoration: const _CornerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              badge,
              if (segment.instruction.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.t(segment.instruction),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
              if (isActive) ...[
                const SizedBox(width: 8),
                Icon(
                  isPlaying ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                  key: ValueKey('reading-active-mark-$index'),
                  color: accent,
                  size: 22,
                ),
              ],
              if (segment.instruction.isEmpty) const Spacer(),
              IconButton(
                key: ValueKey('reading-play-$index'),
                tooltip:
                    segment.audioAsset.isEmpty
                        ? context.t('Ses kaydı henüz eklenmedi')
                        : isActive && isPlaying
                        ? context.t('Duraklat')
                        : (opening
                            ? context.t('Besmeleyi dinle')
                            : '${segment.number ?? index + 1}. ${context.t(unit)} · ${context.t('Dinle')}'),
                onPressed: onPlay,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                iconSize: 34,
                color: accent,
                icon: Icon(
                  isActive && isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : (isActive
                          ? Icons.play_circle_fill_rounded
                          // A speaker: tapping the card reads this verse.
                          : Icons.volume_up_rounded),
                ),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(right: 6), child: arabic),
          ...meaningParts,
        ],
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return card;
    // The whole card is the play target (the buttons inside keep their own
    // taps); a child just taps the verse it wants to hear.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey('reading-card-tap-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
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
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 17),
      ),
    );
  }
}

const _meaningTitles = {
  'tr': 'Türkçe Anlam',
  'es': 'Significado',
  'fr': 'Sens',
  'de': 'Bedeutung',
  'en': 'Meaning',
  'bs': 'Značenje',
  'nl': 'Betekenis',
};
const _noteTitles = {
  'tr': 'Notlar',
  'es': 'Notas',
  'fr': 'Notes',
  'de': 'Anmerkungen',
  'en': 'Notes',
  'bs': 'Napomene',
  'nl': 'Noten',
};

class _Note extends StatelessWidget {
  const _Note({
    super.key,
    required this.title,
    required this.text,
    this.publishedText = false,
    this.footnotes = '',
  });

  final String title;
  final String text;
  final bool publishedText;
  final String footnotes;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 10, 12, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: AppColors.divider, height: 16),
        Text(
          context.t(title),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.turquoise,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          publishedText ? text : context.t(text),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        if (footnotes.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(_noteTitles[context.language.code] ?? 'Notes'),
            children: [
              Text(footnotes, style: Theme.of(context).textTheme.bodyMedium),
            ],
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.record_voice_over_rounded, color: AppColors.gold),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                context.t("Şimdi sen oku"),
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
          label: Text(context.t("Göster")),
        ),
      ],
    ),
  );
}

/// A little flower in the bottom-left corner of a reading card and a
/// butterfly in the bottom-right one, in the card's bottom padding, so they
/// never come over the Arabic or the buttons.
class _CornerDecoration extends Decoration {
  const _CornerDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _CornerPainter();
}

class _CornerPainter extends BoxPainter {
  static const _shapes = _CornerShapes();

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.height < 60) return;
    _shapes.paintCorners(canvas, offset & size);
  }
}

/// The background's shapes, for the corners.
class _CornerShapes extends LessonGridBackgroundPainter {
  const _CornerShapes();

  void paintCorners(Canvas canvas, Rect card) {
    drawFlower(
      canvas,
      Offset(card.left + 18, card.bottom - 16),
      6,
      const Color(0xFFF7A8C8),
    );
    drawFlower(
      canvas,
      Offset(card.left + 32, card.bottom - 12),
      4.5,
      const Color(0xFFFFD54F),
    );
    drawButterfly(
      canvas,
      Offset(card.right - 22, card.bottom - 13),
      8,
      const Color(0xFFB3A6F0),
      tilt: 0.3,
    );
  }
}
