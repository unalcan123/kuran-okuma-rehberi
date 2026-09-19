import 'package:flutter/material.dart';

import '../../data/letters_data.dart';
import 'lesson_letters_screen.dart';
import 'widgets/lesson_card.dart';

/// The Elifba lessons, as many cards side by side as comfortably fit.
///
/// Like the other lists, the column count follows the width really
/// available (a phone held sideways gets two, a portrait phone one), so
/// rotating the device never leaves one card stretched across the screen.
class ElifbaLessonsScreen extends StatelessWidget {
  const ElifbaLessonsScreen({super.key});

  static const double _maxContentWidth = 1100;
  static const double _minCardWidth = 330;
  static const int _maxColumns = 3;
  static const double _padding = 24;
  static const double _gap = 16;

  /// Cards that fit in [width] (already limited to the content width).
  @visibleForTesting
  static int columnsFor(double width) =>
      ((width - 2 * _padding + _gap) / (_minCardWidth + _gap))
          .floor()
          .clamp(1, _maxColumns);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elifba Dersleri')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = columnsFor(constraints.maxWidth);
              final rows = (kElifbaLessons.length / columns).ceil();
              return ListView.separated(
                padding: const EdgeInsets.all(_padding),
                itemCount: rows,
                separatorBuilder: (_, __) => const SizedBox(height: _gap),
                itemBuilder: (context, row) => IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column > 0) const SizedBox(width: _gap),
                        Expanded(child: _lessonAt(context, row * columns + column)),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The card for lesson [index], or an empty slot after the last lesson.
  Widget _lessonAt(BuildContext context, int index) {
    if (index >= kElifbaLessons.length) return const SizedBox.shrink();
    final lesson = kElifbaLessons[index];
    return LessonCard(
      lesson: lesson,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LessonLettersScreen(lesson: lesson)),
        );
      },
    );
  }
}
