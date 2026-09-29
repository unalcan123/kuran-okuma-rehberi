import 'package:flutter/material.dart';

import '../../data/letters_data.dart';
import '../../models/lesson.dart';
import '../../theme/app_colors.dart';
import 'lesson_letters_screen.dart';
import 'widgets/lesson_card.dart';
import '../../widgets/tablet_zoom.dart';

/// The Elifba lessons, as many cards side by side as comfortably fit — after
/// the GİRİŞ section ("Harflerin Çıkış Yerleri", [kElifbaIntroLessons]),
/// which comes before Ders 1 and is not numbered.
///
/// Like the other lists, the column count follows the width really
/// available (a phone held sideways gets two, a portrait phone one), so
/// rotating the device never leaves one card stretched across the screen.
class ElifbaLessonsScreen extends StatelessWidget {
  const ElifbaLessonsScreen({super.key});

  static const double maxContentWidth = 1100;
  static const double _minCardWidth = 290;
  static const int _maxColumns = 3;
  static const double _padding = 24;
  static const double _gap = 16;

  /// Cards that fit in [width] (already limited to the content width).
  static int columnsFor(double width) =>
      ((width - 2 * _padding + _gap) / (_minCardWidth + _gap))
          .floor()
          .clamp(1, _maxColumns);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elifba Dersleri')),
      body: TabletZoom(child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = columnsFor(constraints.maxWidth);
              // Every card has the same shape (LessonCard.aspectRatio), so
              // cards side by side are the same height.
              Widget row(List<Lesson> lessons, int first) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: _lessonAt(context, lessons, first + column),
                    ),
                  ],
                ],
              );
              final introRows = (kElifbaIntroLessons.length / columns).ceil();
              final rows = (kElifbaLessons.length / columns).ceil();
              final entries = <Widget Function()>[
                () => const _SectionTitle('GİRİŞ'),
                for (var r = 0; r < introRows; r++)
                  () => row(kElifbaIntroLessons, r * columns),
                () => const _SectionTitle('DERSLER'),
                for (var r = 0; r < rows; r++)
                  () => row(kElifbaLessons, r * columns),
              ];
              return ListView.separated(
                padding: const EdgeInsets.all(_padding),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: _gap),
                itemBuilder: (context, i) => entries[i](),
              );
            },
          ),
        ),
      )),
    );
  }

  /// The card for [lessons]' [index], or an empty slot after the last one.
  Widget _lessonAt(BuildContext context, List<Lesson> lessons, int index) {
    if (index >= lessons.length) return const SizedBox.shrink();
    final lesson = lessons[index];
    return LessonCard(
      key: ValueKey('lesson-card-${lesson.id}'),
      lesson: lesson,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LessonLettersScreen(lesson: lesson)),
        );
      },
    );
  }
}

/// "GİRİŞ" / "DERSLER" above the cards.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    ),
  );
}
