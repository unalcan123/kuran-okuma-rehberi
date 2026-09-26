import 'package:flutter/widgets.dart';

import '../data/book_highlights.dart';
import '../models/arabic_letter.dart';
import '../models/lesson.dart';
import 'arabic_colorizer.dart';

/// Tells the widgets under it which lesson they show, so each item is drawn
/// with the colors of the book page it is printed on (Sayfa, Grid and
/// Tekli/Büyük views alike). Anything outside a lesson, like the games,
/// uses [ArabicColorProfile.standard].
class LessonColorScope extends InheritedWidget {
  const LessonColorScope({
    super.key,
    required this.lesson,
    required super.child,
  });

  final Lesson lesson;

  static ArabicColorProfile profileOf(BuildContext context, ArabicLetter letter) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LessonColorScope>();
    if (scope == null) return ArabicColorProfile.standard;
    final lesson = scope.lesson;
    final index = lesson.letters.indexOf(letter);
    if (index < 0) return ArabicColorProfile.standard;
    final layout = lesson.pageLayout;
    if (layout != null) return layout.colorProfileOf(index);
    return bookHighlightProfile(lesson.id, letter, index) ??
        ArabicColorProfile.standard;
  }

  @override
  bool updateShouldNotify(LessonColorScope oldWidget) =>
      oldWidget.lesson != lesson;
}
