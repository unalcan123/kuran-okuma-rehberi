// Shared scoring for every game. Learning comes first: the only thing a
// mistake costs is the small "first try" bonus — points are never taken
// away and a score can never go below zero. There is no timer.

/// What one correct answer earned, so the screen can say so quietly.
class ScoreAward {
  const ScoreAward({
    required this.base,
    required this.firstTryBonus,
    required this.streakBonus,
  });

  final int base;
  final int firstTryBonus;
  final int streakBonus;

  int get points => base + firstTryBonus + streakBonus;

  /// Points shown as the plain "+N"; the streak part is announced apart.
  int get regularPoints => base + firstTryBonus;

  bool get hasStreakBonus => streakBonus > 0;
}

/// How a finished game went.
class GameResult {
  const GameResult({
    required this.points,
    required this.firstTry,
    required this.total,
  });

  final int points;

  /// Items answered correctly on the very first attempt.
  final int firstTry;

  /// Items in the game. All of them were answered correctly — a game only
  /// finishes once every item is right.
  final int total;

  static const double threeStarShare = 0.8;
  static const double twoStarShare = 0.5;

  /// 1–3 stars. Finishing always earns one; the rest depends on how many
  /// items were known at the first try (what shows real learning), not on
  /// the raw points.
  int get stars {
    if (total == 0) return 1;
    final share = firstTry / total;
    if (share >= threeStarShare) return 3;
    if (share >= twoStarShare) return 2;
    return 1;
  }
}

/// Points for a game in progress.
///
/// - correct answer: +10
/// - correct on the first attempt: +5 more
/// - every 3rd first-try answer in a row: +5 more
/// - a miss: nothing lost; it only means that item no longer counts as
///   "first try" and the run starts over.
class GameScorer {
  GameScorer({required this.total});

  static const int basePoints = 10;
  static const int firstTryBonus = 5;
  static const int streakLength = 3;
  static const int streakBonus = 5;

  final int total;
  int _points = 0;
  int _firstTry = 0;
  int _streak = 0;

  int get points => _points;
  int get firstTry => _firstTry;
  int get streak => _streak;

  ScoreAward recordCorrect({required bool firstTry}) {
    var firstTryPoints = 0;
    var streakPoints = 0;
    if (firstTry) {
      _firstTry++;
      _streak++;
      firstTryPoints = GameScorer.firstTryBonus;
      if (_streak % streakLength == 0) streakPoints = GameScorer.streakBonus;
    } else {
      _streak = 0;
    }
    final award = ScoreAward(
      base: basePoints,
      firstTryBonus: firstTryPoints,
      streakBonus: streakPoints,
    );
    _points += award.points;
    return award;
  }

  void recordMiss() => _streak = 0;

  GameResult get result =>
      GameResult(points: _points, firstTry: _firstTry, total: total);
}

/// A game's saved best.
class GameRecord {
  const GameRecord({this.bestScore, this.bestStars});

  const GameRecord.empty() : bestScore = null, bestStars = null;

  final int? bestScore;
  final int? bestStars;

  bool get hasPlayed => bestScore != null;
}

/// Everything a game has been played for so far, for the results page.
/// Only finished games count.
class GameHistory {
  const GameHistory({
    this.plays = 0,
    this.totalPoints = 0,
    this.bestPoints = 0,
    this.recent = const [],
  });

  /// How many results are kept and shown as "the last five".
  static const int recentCount = 5;

  final int plays;
  final int totalPoints;
  final int bestPoints;

  /// Points of the last [recentCount] games, oldest first.
  final List<int> recent;

  bool get hasPlayed => plays > 0;

  double get average => plays == 0 ? 0 : totalPoints / plays;
}

/// What saving a result did: the record from before, the record now, and
/// whether this play beat an earlier one.
class GameSubmission {
  const GameSubmission({required this.previous, required this.best});

  final GameRecord previous;
  final GameRecord best;

  bool get isNewBest =>
      previous.hasPlayed && (best.bestScore ?? 0) > (previous.bestScore ?? 0);
}
