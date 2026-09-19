import '../models/arabic_letter.dart';
import 'letters_data.dart';

/// Prefix of the memory game's keys: every level keeps its own best score
/// and history under `memory.<level id>`.
const String kMemoryGameKey = 'memory';

/// The three steps of difficulty, easiest first.
enum MemoryTier {
  easy('Kolay'),
  hard('Zor'),
  veryHard('Çok Zor');

  const MemoryTier(this.label);

  final String label;
}

/// One memory game: the letters whose pairs are hidden among the cards.
class MemoryLevel {
  const MemoryLevel({
    required this.id,
    required this.tier,
    required this.number,
    required this.letters,
  });

  final String id;
  final MemoryTier tier;

  /// Position within its tier (1, 2, 3 …).
  final int number;
  final List<ArabicLetter> letters;

  String get title => '${tier.label} $number';

  /// Where this level's best score and history are kept.
  String get gameKey => '$kMemoryGameKey.$id';

  int get pairCount => letters.length;
}

ArabicLetter _l(int order) =>
    kArabicLetters.firstWhere((letter) => letter.order == order);

MemoryLevel _level(MemoryTier tier, int number, List<int> orders) =>
    MemoryLevel(
      id: '${tier.name}$number',
      tier: tier,
      number: number,
      letters: [for (final order in orders) _l(order)],
    );

/// The letter groups of the old Elifba app's memory game, kept as they
/// were: the easy ones follow the alphabet, the harder ones mix in the
/// look-alike letters (ض ط ظ ع غ ...). The old app listed one group twice
/// (Orta 1 and 2); it appears once here.
/// (Numbers are letters' order in the alphabet: 1 Elif … 28 Ye.)
final List<MemoryLevel> kMemoryLevels = [
  _level(MemoryTier.easy, 1, [1, 2, 3, 4]),
  _level(MemoryTier.easy, 2, [5, 6, 7, 8]),
  _level(MemoryTier.easy, 3, [9, 10, 11, 12, 13]),
  _level(MemoryTier.hard, 1, [14, 15, 16, 17, 18, 19]),
  _level(MemoryTier.hard, 2, [22, 23, 24, 25, 26, 27, 28]),
  _level(MemoryTier.hard, 3, [15, 19, 20, 21, 22, 23, 24]),
  _level(MemoryTier.hard, 4, [15, 16, 17, 18, 19, 20, 21]),
  _level(MemoryTier.veryHard, 1, [15, 16, 17, 18, 19, 20, 21, 23, 27, 28]),
  _level(MemoryTier.veryHard, 2, [15, 16, 17, 18, 19, 20, 21, 22, 27, 28]),
];
