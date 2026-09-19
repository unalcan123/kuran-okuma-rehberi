import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/models/game_score.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GameScorer', () {
    test('first-try answers earn 15; every third in a row adds 5', () {
      final scorer = GameScorer(total: 7);
      final awards = [
        for (var i = 0; i < 7; i++) scorer.recordCorrect(firstTry: true),
      ];
      expect(awards.map((a) => a.points), [15, 15, 20, 15, 15, 20, 15]);
      expect(awards[2].hasStreakBonus, isTrue);
      expect(awards[2].regularPoints, 15);
      expect(awards[1].hasStreakBonus, isFalse);
      expect(scorer.points, 15 * 7 + 5 * 2);
      expect(scorer.firstTry, 7);
    });

    test('a retry earns 10, no bonus, and breaks the run', () {
      final scorer = GameScorer(total: 5);
      scorer.recordCorrect(firstTry: true);
      scorer.recordCorrect(firstTry: true);
      scorer.recordMiss();
      final retried = scorer.recordCorrect(firstTry: false);
      expect(retried.points, 10);
      expect(scorer.streak, 0);
      // the run starts over: two more first-try answers do not reach 3
      scorer.recordCorrect(firstTry: true);
      final award = scorer.recordCorrect(firstTry: true);
      expect(award.hasStreakBonus, isFalse);
      expect(scorer.points, 15 + 15 + 10 + 15 + 15);
      expect(scorer.firstTry, 4);
    });

    test('misses never remove points or make the score negative', () {
      final scorer = GameScorer(total: 3);
      for (var i = 0; i < 10; i++) {
        scorer.recordMiss();
      }
      expect(scorer.points, 0);
      scorer.recordCorrect(firstTry: false);
      scorer.recordMiss();
      expect(scorer.points, 10);
    });

    test('result reflects the game', () {
      final scorer = GameScorer(total: 2)..recordCorrect(firstTry: true);
      scorer.recordCorrect(firstTry: false);
      expect(scorer.result.points, 25);
      expect(scorer.result.firstTry, 1);
      expect(scorer.result.total, 2);
    });
  });

  group('stars', () {
    int stars(int firstTry, int total) =>
        GameResult(points: 0, firstTry: firstTry, total: total).stars;

    test('finishing is always at least one star, even with no first tries', () {
      expect(stars(0, 5), 1);
      expect(stars(0, 29), 1);
    });

    test('depends on the share of first-try answers', () {
      expect(stars(2, 5), 1); // 40%
      expect(stars(3, 5), 2); // 60%
      expect(stars(4, 5), 3); // 80%
      expect(stars(5, 5), 3);
      expect(stars(14, 29), 1);
      expect(stars(15, 29), 2);
      expect(stars(23, 29), 2); // 79%
      expect(stars(24, 29), 3); // 83%
    });

    test('does not depend on the raw points', () {
      const lucky = GameResult(points: 9999, firstTry: 1, total: 5);
      const careful = GameResult(points: 10, firstTry: 5, total: 5);
      expect(lucky.stars, 1);
      expect(careful.stars, 3);
    });
  });

  group('GameScoreStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    const good = GameResult(points: 80, firstTry: 5, total: 5);
    const worse = GameResult(points: 40, firstTry: 2, total: 5);
    const better = GameResult(points: 95, firstTry: 5, total: 5);

    test('first play has no previous record and is not a new record', () async {
      final store = GameScoreStore();
      expect((await store.recordOf('g')).hasPlayed, isFalse);
      final submission = await store.submit('g', good);
      expect(submission.previous.hasPlayed, isFalse);
      expect(submission.isNewBest, isFalse);
      expect(submission.best.bestScore, 80);
      expect(submission.best.bestStars, 3);
    });

    test('keeps the best, reports a new record only when beaten', () async {
      final store = GameScoreStore();
      await store.submit('g', good);
      final lower = await store.submit('g', worse);
      expect(lower.isNewBest, isFalse);
      expect(lower.best.bestScore, 80);
      expect(lower.best.bestStars, 3);
      final higher = await store.submit('g', better);
      expect(higher.isNewBest, isTrue);
      expect(higher.previous.bestScore, 80);
      expect((await store.recordOf('g')).bestScore, 95);
    });

    test('each game keeps its own record', () async {
      final store = GameScoreStore();
      await store.submit('game_1', good);
      await store.submit('game_2', worse);
      expect((await store.recordOf('game_1')).bestScore, 80);
      expect((await store.recordOf('game_2')).bestScore, 40);
      expect((await store.recordOf('game_3')).hasPlayed, isFalse);
    });

    test('survives a new store instance (data is on the device)', () async {
      await GameScoreStore().submit('g', good);
      expect((await GameScoreStore().recordOf('g')).bestScore, 80);
    });

    test('history counts plays, average, best and keeps the last five', () async {
      final store = GameScoreStore();
      expect((await store.historyOf('g')).hasPlayed, isFalse);
      expect((await store.historyOf('g')).average, 0);
      for (final points in [10, 20, 30, 40, 50, 60, 70]) {
        await store.submit(
          'g',
          GameResult(points: points, firstTry: 3, total: 5),
        );
      }
      final history = await store.historyOf('g');
      expect(history.plays, 7);
      expect(history.totalPoints, 280);
      expect(history.average, 40);
      expect(history.bestPoints, 70);
      expect(history.recent, [30, 40, 50, 60, 70], reason: 'oldest first');
    });

    test('a lower score is still counted in the history', () async {
      final store = GameScoreStore();
      await store.submit('g', better);
      await store.submit('g', worse);
      final history = await store.historyOf('g');
      expect(history.plays, 2);
      expect(history.bestPoints, 95);
      expect(history.recent, [95, 40]);
      expect(history.average, 67.5);
    });

    test('separate games of one family never mix their histories', () async {
      final store = GameScoreStore();
      await store.submit('drag_drop.1', good);
      await store.submit('drag_drop.1', better);
      await store.submit('drag_drop.2', worse);
      final one = await store.historyOf('drag_drop.1');
      final two = await store.historyOf('drag_drop.2');
      expect(one.recent, [80, 95]);
      expect(one.average, 87.5);
      expect(two.recent, [40]);
      expect(two.plays, 1);
      expect((await store.historyOf('drag_drop')).hasPlayed, isFalse);
    });

    test('games keep separate histories', () async {
      final store = GameScoreStore();
      await store.submit('game_1', good);
      expect((await store.historyOf('game_1')).plays, 1);
      expect((await store.historyOf('game_2')).plays, 0);
    });
  });
}
