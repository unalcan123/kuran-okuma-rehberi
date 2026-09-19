import 'dart:math' as math;

import '../models/arabic_letter.dart';
import 'letter_forms_data.dart';
import 'letters_data.dart';

/// Prefix of Sürükle & Bırak's keys: each small game (level) keeps its own
/// best score and history under `drag_drop.<level id>`.
const String kDragDropGameKey = 'drag_drop';

/// Played (once, then followed by the letter's own recording) when a
/// letter lands on the right sound.
const String kGameCorrectSound = 'audio/oyunlar/dogru.mp3';

/// How many letters the random game deals.
const int kDragDropRandomCount = 5;

ArabicLetter _letter(int order) =>
    kArabicLetters.firstWhere((letter) => letter.order == order);

final ArabicLetter _lamElif = kLetterFormLetters.firstWhere(
  (letter) => letter.turkishName == 'Lam Elif',
);

/// The seven letter groups of the old app's "harf oyunları", in the
/// same order. Letters and recordings come straight from the Elifba
/// lessons, so nothing is duplicated here.
final List<List<ArabicLetter>> kDragDropGroups = [
  [_letter(1), _letter(2), _letter(3), _letter(4)],
  [_letter(5), _letter(6), _letter(7)],
  [_letter(8), _letter(9), _letter(10), _letter(11)],
  [_letter(12), _letter(13), _letter(14), _letter(15)],
  [_letter(16), _letter(17), _letter(18), _letter(19)],
  [_letter(20), _letter(21), _letter(22), _letter(23), _lamElif],
  [_letter(24), _letter(25), _letter(26), _letter(27), _letter(28)],
];

/// Every letter the random game can deal.
final List<ArabicLetter> kDragDropAllLetters = [
  for (final group in kDragDropGroups) ...group,
];

/// One small game: a fixed group of letters, or — when [letters] is
/// null — [kDragDropRandomCount] letters dealt anew every time.
class DragDropLevel {
  const DragDropLevel({required this.id, required this.title, this.letters});

  final String id;
  final String title;
  final List<ArabicLetter>? letters;

  bool get isRandom => letters == null;

  /// Where this level's best score is kept.
  String get gameKey => '$kDragDropGameKey.$id';

  List<ArabicLetter> draw(math.Random random) =>
      letters ??
      (List.of(kDragDropAllLetters)
        ..shuffle(random)).take(kDragDropRandomCount).toList();
}

final List<DragDropLevel> kDragDropLevels = [
  for (var i = 0; i < kDragDropGroups.length; i++)
    DragDropLevel(
      id: '${i + 1}',
      title: 'Oyun ${i + 1}',
      letters: kDragDropGroups[i],
    ),
  const DragDropLevel(id: 'random', title: 'Karışık'),
];
