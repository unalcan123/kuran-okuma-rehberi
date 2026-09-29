import 'package:flutter/material.dart';

import '../../../data/lesson_card_images.dart';
import '../../../helpers/colored_arabic_text.dart';
import '../../../models/lesson.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../../../widgets/picture_card.dart';

/// A lesson in the lesson list: its picture card ([kLessonCardImages]). The
/// title and Arabic painted into the picture are covered ([kLessonCardArt])
/// and the card writes the lesson's own label, title and a correct Arabic
/// sample over them ([LessonCardTexts]). A lesson without a picture gets a
/// plain text card of the same shape ([PictureCard]).
class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const LessonCard({super.key, required this.lesson, required this.onTap});

  /// Width : height of every card. The pictures are 1.38-1.82 (median ~1.5);
  /// each is fitted whole (BoxFit.contain), so no title or badge is cut.
  static const double aspectRatio = 1.5;

  @override
  Widget build(BuildContext context) {
    final image = kLessonCardImages[lesson.id];
    final art = kLessonCardArt[lesson.id];
    return PictureCard(
      image: image,
      aspectRatio: aspectRatio,
      // 16 px on a ~245 px wide card.
      radiusFactor: 16 / 245,
      label: lesson.label,
      title: lesson.title,
      subtitle: lesson.subtitle,
      tapKey: image == null ? null : ValueKey('lesson-card-image-$image'),
      imageSize: art?.size,
      overlay:
          art == null
              ? null
              : LessonCardTexts(
                art: art,
                label: lesson.label,
                title: lesson.title,
              ),
      onTap: onTap,
    );
  }
}

/// The texts written over a lesson card's picture: a soft plate with the
/// "Ders N" badge and the title over the painted ones, and a white tile with
/// the lesson's Arabic sample over each painted letter tile. Sized from the
/// picture's width, so it scales with the card.
class LessonCardTexts extends StatelessWidget {
  const LessonCardTexts({
    super.key,
    required this.art,
    required this.label,
    required this.title,
  });

  final LessonCardArt art;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        Rect px(Rect f) =>
            Rect.fromLTRB(f.left * w, f.top * h, f.right * w, f.bottom * h);
        return Stack(
          children: [
            Positioned.fromRect(
              rect: px(art.title),
              child: _TitlePlate(label: label, title: title, unit: w),
            ),
            for (final tile in art.tiles)
              Positioned.fromRect(
                rect: px(tile.rect),
                child: _ArabicTile(arabic: tile.arabic, unit: w),
              ),
          ],
        );
      },
    );
  }
}

class _TitlePlate extends StatelessWidget {
  const _TitlePlate({
    required this.label,
    required this.title,
    required this.unit,
  });

  final String label;
  final String title;

  /// The picture's width.
  final double unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(unit * 0.045),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: unit * 0.006,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: unit * 0.025,
        vertical: unit * 0.018,
      ),
      child: LayoutBuilder(
        builder: (context, inner) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: inner.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: unit * 0.03,
                      vertical: unit * 0.004,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.turquoiseSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      label,
                      style: theme.labelMedium?.copyWith(
                        fontSize: unit * 0.05,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: unit * 0.012),
                  Text(
                    title,
                    style: theme.titleLarge?.copyWith(
                      fontSize: unit * 0.068,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArabicTile extends StatelessWidget {
  const _ArabicTile({required this.arabic, required this.unit});

  final String arabic;

  /// The picture's width.
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(unit * 0.03),
      ),
      padding: EdgeInsets.all(unit * 0.018),
      // Fills the tile (tight, so FittedBox scales up): a single letter
      // large, its mark easy to see; a word as wide as the tile allows.
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: ColoredArabicText(
            arabic,
            textDirection: TextDirection.rtl,
            style: AppTextTheme.arabicLetter(
              fontSize: 40,
            ).copyWith(height: 1.2),
          ),
        ),
      ),
    );
  }
}
