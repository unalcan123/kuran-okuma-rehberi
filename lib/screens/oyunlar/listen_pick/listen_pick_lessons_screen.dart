import 'package:flutter/material.dart';

import '../../../data/letters_data.dart';
import '../../../theme/app_colors.dart';
import '../../elifba/elifba_lessons_screen.dart';
import '../../elifba/widgets/lesson_card.dart';
import 'listen_pick_screen.dart';

/// Which lesson should the questions come from? Same lessons, same
/// cards as the Elifba list.
class ListenPickLessonsScreen extends StatelessWidget {
  const ListenPickLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dinle ve Seç')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ElifbaLessonsScreen.maxContentWidth,
          ),
          // The picture cards side by side, as in the Elifba list.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = ElifbaLessonsScreen.columnsFor(
                constraints.maxWidth,
              );
              final rows = (kElifbaLessons.length / columns).ceil();
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: rows + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, row) {
                  if (row == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Hangi dersten sorular gelsin?',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column > 0) const SizedBox(width: 16),
                        Expanded(
                          child: _lessonAt(
                            context,
                            (row - 1) * columns + column,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _lessonAt(BuildContext context, int index) {
    if (index >= kElifbaLessons.length) return const SizedBox.shrink();
    final lesson = kElifbaLessons[index];
    return LessonCard(
      key: ValueKey('lesson-card-${lesson.id}'),
      lesson: lesson,
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ListenPickScreen(lesson: lesson)),
          ),
    );
  }
}
