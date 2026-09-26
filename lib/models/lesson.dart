import 'arabic_letter.dart';
import 'lesson_page_layout.dart';

/// An Elifba lesson: a titled, ordered set of letters. Modeled as its
/// own type (rather than a hardcoded screen) so more lessons can be
/// added later without changing the lesson-list or letter-viewer
/// screens.
class Lesson {
  /// Stable content identity used by persisted game records; never renumber.
  final String id;
  /// User-facing lesson number, independent of [id] and PDF page numbers.
  final String label;
  final String title;
  final String subtitle;
  final List<ArabicLetter> letters;

  /// The book-page layout of [letters] for the "Sayfa Görünümü"; null for
  /// lessons that don't have one yet.
  final LessonPageLayout? pageLayout;

  const Lesson({
    required this.id,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.letters,
    this.pageLayout,
  });
}
