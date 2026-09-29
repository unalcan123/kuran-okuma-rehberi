import 'package:flutter/material.dart';

import '../../../data/lesson_card_images.dart';
import '../../../models/lesson.dart';
import '../../../widgets/picture_card.dart';

/// A lesson in the lesson list: its picture card ([kLessonCardImages]) —
/// the picture already shows "Ders N" and the title, so nothing is written
/// over it. A lesson without a picture gets a plain text card of the same
/// shape ([PictureCard]).
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
    return PictureCard(
      image: image,
      aspectRatio: aspectRatio,
      // 16 px on a ~245 px wide card.
      radiusFactor: 16 / 245,
      label: lesson.label,
      title: lesson.title,
      subtitle: lesson.subtitle,
      tapKey: image == null ? null : ValueKey('lesson-card-image-$image'),
      onTap: onTap,
    );
  }
}
