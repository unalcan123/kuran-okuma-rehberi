import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../data/letters_data.dart';
import 'lesson_letters_screen.dart';
import 'widgets/lesson_card.dart';

class ElifbaLessonsScreen extends StatelessWidget {
  const ElifbaLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maxContentWidth = Responsive.isDesktop(context) ? 800.0 : 640.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Elifba Dersleri')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: kElifbaLessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final lesson = kElifbaLessons[index];
              return LessonCard(
                lesson: lesson,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonLettersScreen(lesson: lesson),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
