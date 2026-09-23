import 'dart:io';

import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_backend.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_models.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_service.dart';

/// Bellek içi arka uç: Firestore kurallarının ve sorgularının anlamını taklit
/// eder (en iyi düşmez, puan azalan + önce ulaşan önde, sahiplik öneki).
class FakeBackend implements LeaderboardBackend {
  FakeBackend({this.uid = 'deviceA', Map<String, FakeDoc>? shared})
    : docs = shared ?? {};

  String uid;
  final Map<String, FakeDoc> docs; // "<gameId>__<playerId>"
  final Map<String, String> players = {};
  bool online = true;
  int writes = 0;
  static int _clock = 0;

  void _net() {
    if (!online) throw const SocketException('çevrimdışı');
  }

  @override
  Future<String> signIn() async {
    _net();
    return uid;
  }

  @override
  Future<void> savePlayer({
    required String playerId,
    required String ownerUid,
    required String nickname,
  }) async {
    _net();
    if (!playerId.startsWith('${ownerUid}_')) {
      throw const LeaderboardRejected('sahip değil');
    }
    players[playerId] = nickname;
  }

  @override
  Future<void> submitBest({
    required String playerId,
    required String ownerUid,
    required String nickname,
    required OnlineScore score,
  }) async {
    _net();
    final id = '${score.gameId}__$playerId';
    final old = docs[id];
    if (old != null && score.score <= old.best) return;
    writes++;
    docs[id] = FakeDoc(playerId, nickname, score.gameId, score.score, ++_clock);
  }

  List<FakeDoc> _sorted(String gameId) =>
      docs.values.where((d) => d.gameId == gameId).toList()..sort(
        (a, b) =>
            b.best != a.best ? b.best.compareTo(a.best) : a.at.compareTo(b.at),
      );

  @override
  Future<StoredBest?> fetchBest(String gameId, String playerId) async {
    _net();
    final d = docs['${gameId}__$playerId'];
    return d == null
        ? null
        : StoredBest(
          bestScore: d.best,
          bestAt: DateTime(2026).add(Duration(seconds: d.at)),
          nickname: d.nickname,
        );
  }

  @override
  Future<List<LeaderboardRow>> top(String gameId, int limit) async {
    _net();
    final rows = _sorted(gameId).take(limit).toList();
    return [
      for (var i = 0; i < rows.length; i++)
        LeaderboardRow(
          rank: i + 1,
          playerId: rows[i].playerId,
          nickname: rows[i].nickname,
          bestScore: rows[i].best,
        ),
    ];
  }

  @override
  Future<int> countAhead(String gameId, StoredBest mine) async {
    _net();
    final at = mine.bestAt.difference(DateTime(2026)).inSeconds;
    return docs.values
        .where(
          (d) =>
              d.gameId == gameId &&
              (d.best > mine.bestScore ||
                  (d.best == mine.bestScore && d.at < at)),
        )
        .length;
  }

  @override
  Future<int> countPlayers(String gameId) async {
    _net();
    return docs.values.where((d) => d.gameId == gameId).length;
  }

  final renames = <String, String>{};

  @override
  Future<void> renamePlayer({
    required String playerId,
    required String ownerUid,
    required String nickname,
    required Iterable<String> gameIds,
  }) async {
    _net();
    players[playerId] = nickname;
    renames[playerId] = nickname;
    for (final g in gameIds) {
      final d = docs['${g}__$playerId'];
      if (d != null) {
        docs['${g}__$playerId'] = FakeDoc(playerId, nickname, g, d.best, d.at);
      }
    }
  }

  @override
  Future<void> deletePlayer(String playerId, Iterable<String> gameIds) async {
    _net();
    for (final g in gameIds) {
      docs.remove('${g}__$playerId');
    }
    players.remove(playerId);
  }
}

class FakeDoc {
  FakeDoc(this.playerId, this.nickname, this.gameId, this.best, this.at);
  final String playerId;
  final String nickname;
  final String gameId;
  final int best;
  final int at;
}

/// [correct] doğru, hepsi ilk denemede: puan kuralına uygun en yüksek puan.
OnlineScore scoreOf(String gameId, int points, {int? correct}) {
  final c = correct ?? (points * 3 / 50).ceil();
  return OnlineScore(
    gameId: gameId,
    score: points,
    correctAnswers: c,
    wrongAnswers: 1,
    missedTargets: 1,
    totalItems: c + 10,
  );
}

LeaderboardService serviceFor(FakeBackend b) => LeaderboardService(
  backend: b,
  games: kOnlineLeaderboardGames,
  timeout: const Duration(seconds: 2),
);

List<String> rowsOf(OnlineOutcome o) => [
  for (final r in o.snapshot!.top) '${r.nickname} ${r.bestScore}',
];
