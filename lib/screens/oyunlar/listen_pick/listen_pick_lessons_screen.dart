import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../data/letters_data.dart';
import '../../../theme/app_colors.dart';
import '../../elifba/widgets/lesson_card.dart';
import 'listen_pick_screen.dart';

/// Which lesson should the questions come from? Same lessons, same
/// cards as the Elifba list.
class ListenPickLessonsScreen extends StatelessWidget {
  const ListenPickLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maxContentWidth = Responsive.isDesktop(context) ? 800.0 : 640.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Dinle ve Seç')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            itemCount: kElifbaLessons.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Hangi dersten sorular gelsin?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              final lesson = kElifbaLessons[index - 1];
              return LessonCard(
                lesson: lesson,
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListenPickScreen(lesson: lesson),
                      ),
                    ),
              );
            },
          ),
        ),
      ),
    );
  }
}
