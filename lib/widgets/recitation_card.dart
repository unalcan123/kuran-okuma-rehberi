import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'picture_card.dart';

/// A prayer / surah list card: the picture on top, under it its own title
/// area — the number ("Dua 1") on the first line, the name on the second,
/// centred. The pictures carry no text (new ones are drawn without it); the
/// app writes both lines, in every language. Card and caption are one tap.
class RecitationCard extends StatelessWidget {
  const RecitationCard({
    super.key,
    required this.cardKey,
    required this.captionKey,
    required this.image,
    required this.aspectRatio,
    required this.radiusFactor,
    required this.number,
    required this.title,
    required this.onTap,
    this.arabic,
    this.imageSize,
    this.overlay,
  });

  /// Keys of the picture and of the title area (tests).
  final Key cardKey;
  final Key captionKey;
  final String? image;

  /// Width : height of the picture area.
  final double aspectRatio;
  final double radiusFactor;
  final String number;
  final String title;
  final String? arabic;
  final VoidCallback onTap;
  final Size? imageSize;
  final Widget? overlay;

  static const _radius = 18.0;
  static const _numberSize = 14.0;
  static const _titleSize = 18.0;

  /// Height of the title area for the current text scale: the number line
  /// and two lines of name, so every card in a grid is the same height.
  static double captionHeightOf(BuildContext context) =>
      MediaQuery.textScalerOf(
        context,
      ).scale(_numberSize * 1.3 + 2 * _titleSize * 1.2) +
      18;

  /// Grid cell height for cards [width] wide.
  static double extentOf(
    BuildContext context, {
    required double width,
    required double aspectRatio,
  }) => width / aspectRatio + captionHeightOf(context);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A223A5E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Column(
          children: [
            PictureCard(
              key: cardKey,
              image: image,
              aspectRatio: aspectRatio,
              radiusFactor: radiusFactor,
              label: number,
              title: title,
              arabic: arabic,
              imageSize: imageSize,
              overlay: overlay,
              onTap: onTap,
            ),
            Expanded(
              child: ExcludeSemantics(
                child: GestureDetector(
                  key: captionKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          number,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: _numberSize,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: AppColors.turquoise,
                          ),
                        ),
                        Flexible(child: _FitTitle(title)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The name in at most two centred lines; a long one (a translation) gets a
/// smaller font instead of being cut.
class _FitTitle extends StatelessWidget {
  const _FitTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scaler = MediaQuery.textScalerOf(context);
      // Measured in the font the Text will use (the theme's), not the
      // engine's default.
      final base = DefaultTextStyle.of(context).style.merge(
        const TextStyle(
          fontSize: RecitationCard._titleSize,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: Color(0xFF152843),
        ),
      );
      var size = base.fontSize!;
      for (; size > 10; size -= 1) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: base.copyWith(fontSize: size)),
          maxLines: 2,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout(maxWidth: c.maxWidth);
        final fits =
            !painter.didExceedMaxLines && painter.height <= c.maxHeight + .5;
        painter.dispose();
        if (fits) break;
      }
      return Center(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: base.copyWith(fontSize: size),
        ),
      );
    },
  );
}
