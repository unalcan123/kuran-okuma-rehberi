import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../models/game_score.dart';
import '../../../../services/game_score_store.dart';
import '../../../../services/leaderboard/leaderboard_models.dart';
import '../../../../services/leaderboard/leaderboard_service.dart';
import 'player_models.dart';
import 'player_repository.dart';

/// Biten bir oyunun sonucunu kaydeder ve "önceki en iyi" skoru döndürür
/// (sonuç panelindeki "En İyi" = max(önceki en iyi, bu oyunun puanı)).
///
///  * Uygulamanın mevcut sonuç deposuna ([GameScoreStore], "Sonuçlarım" ekranı)
///    [storeKey] altında her zaman yazılır.
///  * Aktif oyuncu varsa sonuç ONUN oyun kaydına yazılır ([gameId] için ayrı
///    skor tablosu); oyuncular birbirinin skorunun üzerine yazmaz ve önceki en
///    iyi de onun kişisel en iyisidir.
Future<int> recordFinishedGame(
  BuildContext context, {
  required String gameId,
  required String storeKey,
  required int score,
  required int firstTry,
  required int correct,
  required int wrong,
  required int missed,
  required int totalItems,
}) async {
  final store = context.read<GameScoreStore>();
  final repo = context.read<PlayerRepository>();
  final player = repo.activePlayer;

  // Oyuncu kaydı beklemeden (senkron) yazılır: kayıt cihaz depolamasını
  // beklerken oyuncu skoru zaten güncel ve sonuç ekranı hazırdır.
  int? playerBest;
  if (player != null) {
    playerBest = repo.bestScore(player.id, gameId);
    unawaited(
      repo.recordResult(
        PlayerGameResult(
          playerId: player.id,
          gameId: gameId,
          score: score,
          correctAnswers: correct,
          wrongAnswers: wrong,
          missedTargets: missed,
          totalItems: totalItems,
          playedAt: DateTime.now(),
        ),
      ),
    );
  }

  final submission = await store.submit(
    storeKey,
    GameResult(points: score, firstTry: firstTry, total: math.max(1, correct)),
  );
  return playerBest ?? submission.previous.bestScore ?? 0;
}

/// Sonucu çevrimiçi sıralamaya gönderir ve sıralamayı yükler. Çevrimiçi servis
/// yoksa `null` (bölüm gösterilmez). Aktif oyuncu yoksa sonuç
/// [OnlineStatus.noPlayer] olur; yerel kayıt yine [recordFinishedGame] ile yapılır.
Future<OnlineOutcome>? submitOnlineResult(
  BuildContext context,
  OnlineScore score,
) {
  final service = maybeLeaderboardService(context);
  if (service == null) return null;
  final player = context.read<PlayerRepository>().activePlayer;
  return service.submitAndLoad(
    profileId: player?.id,
    nickname: player?.displayName,
    score: score,
  );
}
