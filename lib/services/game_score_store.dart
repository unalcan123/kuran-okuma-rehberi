import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_score.dart';

/// Keeps each game's results on the device: the best score and stars and
/// a play history — how many times it was played, the total and best
/// points and the last few scores. Every separate game (a Sürükle & Bırak
/// level, a Dinle ve Seç lesson, …) has a key of its own, so its history
/// never mixes with another's and adding a game needs nothing here.
///
/// Saving is best-effort: if the device storage fails the game simply
/// carries on without a record.
class GameScoreStore {
  static String _scoreKey(String key) => 'game_score.$key.best_score';
  static String _starsKey(String key) => 'game_score.$key.best_stars';
  static String _playsKey(String key) => 'game_history.$key.plays';
  static String _totalKey(String key) => 'game_history.$key.total';
  static String _topKey(String key) => 'game_history.$key.top';
  static String _recentKey(String key) => 'game_history.$key.recent';

  Future<GameRecord> recordOf(String gameKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final score = prefs.getInt(_scoreKey(gameKey));
      if (score == null) return const GameRecord.empty();
      return GameRecord(
        bestScore: score,
        bestStars: prefs.getInt(_starsKey(gameKey)),
      );
    } catch (error) {
      debugPrint('GameScoreStore: "$gameKey" okunamadı — $error');
      return const GameRecord.empty();
    }
  }

  Future<GameHistory> historyOf(String gameKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return GameHistory(
        plays: prefs.getInt(_playsKey(gameKey)) ?? 0,
        totalPoints: prefs.getInt(_totalKey(gameKey)) ?? 0,
        bestPoints: prefs.getInt(_topKey(gameKey)) ?? 0,
        recent: [
          for (final value in prefs.getStringList(_recentKey(gameKey)) ?? [])
            if (int.tryParse(value) case final points?) points,
        ],
      );
    } catch (error) {
      debugPrint('GameScoreStore: "$gameKey" geçmişi okunamadı — $error');
      return const GameHistory();
    }
  }

  /// Records [result] for [gameKey]: keeps the higher score and the
  /// higher star count independently and adds the play to the history.
  Future<GameSubmission> submit(String gameKey, GameResult result) async {
    final previous = await recordOf(gameKey);
    final best = GameRecord(
      bestScore: math.max(previous.bestScore ?? 0, result.points),
      bestStars: math.max(previous.bestStars ?? 0, result.stars),
    );
    try {
      final history = await historyOf(gameKey);
      final recent = [
        ...history.recent,
        result.points,
      ].takeLast(GameHistory.recentCount);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_scoreKey(gameKey), best.bestScore!);
      await prefs.setInt(_starsKey(gameKey), best.bestStars!);
      await prefs.setInt(_playsKey(gameKey), history.plays + 1);
      await prefs.setInt(_totalKey(gameKey), history.totalPoints + result.points);
      await prefs.setInt(
        _topKey(gameKey),
        math.max(history.bestPoints, result.points),
      );
      await prefs.setStringList(_recentKey(gameKey), [
        for (final points in recent) '$points',
      ]);
    } catch (error) {
      debugPrint('GameScoreStore: "$gameKey" kaydedilemedi — $error');
    }
    return GameSubmission(previous: previous, best: best);
  }

  /// Deletes every game's best scores and history. Nothing else the app
  /// stores on the device is touched.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith('game_score.') || key.startsWith('game_history.')) {
          await prefs.remove(key);
        }
      }
    } catch (error) {
      debugPrint('GameScoreStore: sonuçlar silinemedi — $error');
    }
  }
}

extension on List<int> {
  List<int> takeLast(int count) =>
      length <= count ? this : sublist(length - count);
}
