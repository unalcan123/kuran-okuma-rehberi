import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

/// A list card that is a picture: the Elifba lessons, the surahs and the
/// prayers all use it (pictures cropped by `tool/crop_lesson_cards.py`).
/// The picture already shows the number and the title, so nothing is
/// written over it; the title is only given to screen readers. The whole
/// card is one tap target.
///
/// Without a picture ([image] null) the card is a plain text card of the
/// same shape ([label], [title], [subtitle] / [arabic]).
class PictureCard extends StatelessWidget {
  const PictureCard({
    super.key,
    required this.image,
    required this.aspectRatio,
    required this.radiusFactor,
    required this.label,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.arabic,
    this.tapKey,
    this.imageSize,
    this.overlay,
  });

  final String? image;

  /// Width : height of the card; the picture is fitted whole inside it
  /// (BoxFit.contain), so no title or badge is ever cut.
  final double aspectRatio;

  /// Corner radius of the picture's own rounded frame, relative to its width.
  final double radiusFactor;

  final String label;
  final String title;
  final String? subtitle;
  final String? arabic;
  final VoidCallback onTap;

  /// Key of the tap target (for tests).
  final Key? tapKey;

  /// The picture's pixel size; with [overlay], where the fitted picture
  /// lies inside the card.
  final Size? imageSize;

  /// Drawn exactly over the fitted picture (same size), above it; taps go
  /// through to the card.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Semantics(
        button: true,
        label: '$label · $title',
        excludeSemantics: image != null,
        child:
            image != null
                ? _Picture(
                  image: image,
                  radiusFactor: radiusFactor,
                  onTap: onTap,
                  tapKey: tapKey,
                  imageSize: imageSize,
                  overlay: overlay,
                )
                : _TextCard(card: this),
      ),
    );
  }
}

class _Picture extends StatelessWidget {
  final String image;
  final double radiusFactor;
  final VoidCallback onTap;
  final Key? tapKey;
  final Size? imageSize;
  final Widget? overlay;

  const _Picture({
    required this.image,
    required this.radiusFactor,
    required this.onTap,
    this.tapKey,
    this.imageSize,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = BorderRadius.circular(
          constraints.maxWidth * radiusFactor,
        );
        final picture = Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: tapKey,
            onTap: onTap,
            customBorder: RoundedRectangleBorder(borderRadius: radius),
            splashColor: AppColors.turquoise.withValues(alpha: 0.18),
            highlightColor: AppColors.turquoise.withValues(alpha: 0.08),
            // Ink paints on the Material, so the ripple shows over it.
            child: Ink.image(image: AssetImage(image), fit: BoxFit.contain),
          ),
        );
        final overlay = this.overlay;
        final imageSize = this.imageSize;
        if (overlay == null || imageSize == null) return picture;
        final box = constraints.biggest;
        final fitted = applyBoxFit(BoxFit.contain, imageSize, box).destination;
        final rect = Alignment.center.inscribe(fitted, Offset.zero & box);
        return Stack(
          children: [
            Positioned.fill(child: picture),
            Positioned.fromRect(
              rect: rect,
              child: IgnorePointer(child: overlay),
            ),
          ],
        );
      },
    );
  }
}

/// Same shape as a picture card, for an item without a picture yet.
class _TextCard extends StatelessWidget {
  final PictureCard card;

  const _TextCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: card.tapKey,
        onTap: card.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider, width: 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.turquoiseSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      card.label,
                      style: theme.labelMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.title,
                    style: theme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  if (card.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      card.subtitle!,
                      style: theme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (card.arabic != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      card.arabic!,
                      textDirection: TextDirection.rtl,
                      style: AppTextTheme.arabicSmall(
                        fontSize: 24,
                      ).copyWith(color: AppColors.turquoise),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
