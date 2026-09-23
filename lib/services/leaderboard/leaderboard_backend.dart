import 'leaderboard_models.dart';

/// Çevrimiçi sıralamanın depolama katmanı. Gerçeği Firebase
/// ([FirebaseLeaderboardBackend]); testlerde bellek içi sahte kullanılır.
///
/// Oyuncu kimliği (`playerId`) = `<Firebase anonim UID>_<yerel profil id>`:
/// aynı cihazdaki her çocuk ayrı oyuncudur, ama hepsi o cihazın UID'sine aittir
/// (kurallar sahipliği bu önekle denetler).
abstract class LeaderboardBackend {
  /// Anonim oturum açar (açıksa aynısını döner) ve UID'yi verir.
  Future<String> signIn();

  /// `players/{playerId}` profilini oluşturur / takma adı günceller.
  Future<void> savePlayer({
    required String playerId,
    required String ownerUid,
    required String nickname,
  });

  /// Sonuç kayıtlı en iyiden yüksekse yazar (işlem içinde oku-karşılaştır-yaz).
  /// Kayıtlı en iyi asla düşürülmez.
  Future<void> submitBest({
    required String playerId,
    required String ownerUid,
    required String nickname,
    required OnlineScore score,
  });

  /// Oyuncunun bu oyundaki kayıtlı en iyisi (yoksa `null`).
  Future<StoredBest?> fetchBest(String gameId, String playerId);

  /// En iyi [limit] oyuncu: puan azalan, eşitlikte önce ulaşan.
  Future<List<LeaderboardRow>> top(String gameId, int limit);

  /// Bu oyuncunun önündeki kayıt sayısı (sıra = bu + 1). Tümünü indirmez;
  /// sunucuda sayım (aggregation count) yapar.
  Future<int> countAhead(String gameId, StoredBest mine);

  /// Bu oyunda skoru olan oyuncu sayısı.
  Future<int> countPlayers(String gameId);

  /// Oyuncunun adını profilde ve [gameIds] skor kayıtlarında günceller
  /// (profil yoksa oluşturur; skor yoksa atlar).
  Future<void> renamePlayer({
    required String playerId,
    required String ownerUid,
    required String nickname,
    required Iterable<String> gameIds,
  });

  /// Oyuncunun profilini ve [gameIds] skorlarını siler.
  Future<void> deletePlayer(String playerId, Iterable<String> gameIds);
}

/// Kurallar isteği reddetti (sahte/tutarsız veri ya da yetki yok): tekrar
/// denemenin anlamı yok.
class LeaderboardRejected implements Exception {
  const LeaderboardRejected(this.message);
  final String message;

  @override
  String toString() => 'LeaderboardRejected: $message';
}
