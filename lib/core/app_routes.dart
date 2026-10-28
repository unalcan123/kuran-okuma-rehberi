import 'package:flutter/material.dart';
import '../data/letters_data.dart';
import '../data/supplementary_sureler_data.dart';
import '../data/additional_dualar_data.dart';
import '../l10n/l10n.dart';
import '../screens/home/home_screen.dart';
import '../screens/elifba/elifba_lessons_screen.dart';
import '../screens/elifba/lesson_letters_screen.dart';
import '../screens/sureler/sureler_list_screen.dart';
import '../screens/sureler/surah_detail_screen.dart';
import '../screens/dualar/dualar_list_screen.dart';
import '../screens/dualar/dua_detail_screen.dart';
import '../screens/sources/sources_screen.dart';
import '../screens/privacy/privacy_screen.dart';

abstract final class AppRoutes {
  static Route<dynamic>? generate(RouteSettings settings) {
    final path = Uri.tryParse(settings.name ?? '/')?.path ?? '/';
    Widget? page;
    switch (path) {
      case '/':
        page = const HomeScreen();
      case '/dersler':
        page = const ElifbaLessonsScreen();
      case '/sureler':
        page = const SurelerListScreen();
      case '/dualar':
        page = const DualarListScreen();
      case '/kaynaklar':
        page = const SourcesScreen();
      case '/gizlilik':
        page = const PrivacyScreen();
    }
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length == 2) {
      if (parts.first == 'sure') {
        for (final surah in kAllNamazTexts) {
          if (surah.id == parts.last) page = SurahDetailScreen(surah: surah);
        }
      } else if (parts.first == 'dua') {
        for (final dua in kAllDualar) {
          if (dua.id == parts.last) page = DuaDetailScreen(dua: dua);
        }
      } else if (parts.first == 'ders') {
        final number = int.tryParse(parts.last);
        if (number != null && number > 0 && number <= kElifbaLessons.length) {
          page = LessonLettersScreen(lesson: kElifbaLessons[number - 1]);
        } else {
          for (final lesson in [...kElifbaIntroLessons, ...kElifbaLessons]) {
            if (lesson.id == parts.last) {
              page = LessonLettersScreen(lesson: lesson);
            }
          }
        }
      }
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => page ?? const _MissingPage(),
    );
  }
}

class _MissingPage extends StatelessWidget {
  const _MissingPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.t('Sayfa bulunamadı'))),
    body: Center(
      child: TextButton(
        onPressed:
            () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (_) => false),
        child: Text(context.t('Ana sayfa')),
      ),
    ),
  );
}
