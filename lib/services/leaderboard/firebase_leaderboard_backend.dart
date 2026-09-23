import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'leaderboard_backend.dart';
import 'leaderboard_models.dart';

/// Firestore şeması (kurallar: `firestore.rules`, dizin: `firestore.indexes.json`):
///
/// `players/{playerId}`
///   playerId, ownerUid, nickname, createdAt, updatedAt
///
/// `leaderboard_scores/{gameId}__{playerId}` — oyuncu başına oyun başına TEK
/// belge (yalnızca en iyi sonuç):
///   playerId, ownerUid, nickname, gameId, bestScore, correctAnswers,
///   wrongAnswers, missedTargets, totalItems, accuracy, bestAt, updatedAt
///
/// Sıralama: `gameId ==` + `bestScore` azalan + `bestAt` artan (eşit puanda önce
/// ulaşan önde; `bestAt` sunucu zamanıdır, istemci değiştiremez).
class FirebaseLeaderboardBackend implements LeaderboardBackend {
  FirebaseLeaderboardBackend({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  static const String playersCollection = 'players';
  static const String scoresCollection = 'leaderboard_scores';

  static String scoreDocId(String gameId, String playerId) =>
      '${gameId}__$playerId';

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _players =>
      _db.collection(playersCollection);
  CollectionReference<Map<String, dynamic>> get _scores =>
      _db.collection(scoresCollection);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'invalid-argument') {
        throw LeaderboardRejected('${e.code}: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<String> signIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }

  @override
  Future<void> savePlayer({
    required String playerId,
    required String ownerUid,
    required String nickname,
  }) => _guard(() async {
    final ref = _players.doc(playerId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'playerId': playerId,
        'ownerUid': ownerUid,
        'nickname': nickname,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else if (snap.data()?['nickname'] != nickname) {
      await ref.update({
        'nickname': nickname,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  });

  @override
  Future<void> submitBest({
    required String playerId,
    required String ownerUid,
    required String nickname,
    required OnlineScore score,
  }) => _guard(() async {
    final ref = _scores.doc(scoreDocId(score.gameId, playerId));
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final old = snap.data()?['bestScore'];
      if (old is int && score.score <= old) return; // en iyi düşürülmez
      tx.set(ref, {
        'playerId': playerId,
        'ownerUid': ownerUid,
        'nickname': nickname,
        'gameId': score.gameId,
        'bestScore': score.score,
        'correctAnswers': score.correctAnswers,
        'wrongAnswers': score.wrongAnswers,
        'missedTargets': score.missedTargets,
        'totalItems': score.totalItems,
        'accuracy': score.accuracy,
        'bestAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  });

  @override
  Future<StoredBest?> fetchBest(String gameId, String playerId) =>
      _guard(() async {
        final snap = await _scores.doc(scoreDocId(gameId, playerId)).get();
        final d = snap.data();
        if (d == null) return null;
        final best = d['bestScore'], at = d['bestAt'];
        if (best is! int || at is! Timestamp) return null;
        return StoredBest(
          bestScore: best,
          bestAt: at.toDate(),
          nickname: '${d['nickname'] ?? ''}',
        );
      });

  Query<Map<String, dynamic>> _game(String gameId) =>
      _scores.where('gameId', isEqualTo: gameId);

  @override
  Future<List<LeaderboardRow>> top(String gameId, int limit) =>
      _guard(() async {
        final snap =
            await _game(gameId)
                .orderBy('bestScore', descending: true)
                .orderBy('bestAt')
                .limit(limit)
                .get();
        final rows = <LeaderboardRow>[];
        for (final doc in snap.docs) {
          final d = doc.data();
          rows.add(
            LeaderboardRow(
              rank: rows.length + 1,
              playerId: '${d['playerId']}',
              nickname: '${d['nickname']}',
              bestScore: d['bestScore'] is int ? d['bestScore'] as int : 0,
            ),
          );
        }
        return rows;
      });

  @override
  Future<int> countAhead(String gameId, StoredBest mine) => _guard(() async {
    final higher =
        _game(
          gameId,
        ).where('bestScore', isGreaterThan: mine.bestScore).count().get();
    final tiedEarlier =
        _game(gameId)
            .where('bestScore', isEqualTo: mine.bestScore)
            .where('bestAt', isLessThan: Timestamp.fromDate(mine.bestAt))
            .count()
            .get();
    final r = await Future.wait([higher, tiedEarlier]);
    return (r[0].count ?? 0) + (r[1].count ?? 0);
  });

  @override
  Future<int> countPlayers(String gameId) => _guard(() async {
    final snap = await _game(gameId).count().get();
    return snap.count ?? 0;
  });

  @override
  Future<void> deletePlayer(String playerId, Iterable<String> gameIds) =>
      _guard(() async {
        final batch = _db.batch();
        for (final g in gameIds) {
          batch.delete(_scores.doc(scoreDocId(g, playerId)));
        }
        batch.delete(_players.doc(playerId));
        await batch.commit();
      });
}
