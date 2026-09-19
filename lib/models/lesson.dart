import 'arabic_letter.dart';

/// An Elifba lesson: a titled, ordered set of letters. Modeled as its
/// own type (rather than a hardcoded screen) so more lessons can be
/// added later without changing the lesson-list or letter-viewer
/// screens.
class Lesson {
  final String id;
  final String label;
  final String title;
  final String subtitle;
  final List<ArabicLetter> letters;

  const Lesson({
    required this.id,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.letters,
  });
}
