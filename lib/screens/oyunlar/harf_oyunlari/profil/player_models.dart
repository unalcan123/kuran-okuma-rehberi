import 'package:flutter/material.dart';
import '../../../../services/leaderboard/leaderboard_models.dart';

/// Oyun kimlikleri. Her oyun için ayrı skor tablosu bu kimlikle tutulur; ileride
/// "Genel Skor" bu kimliklerin toplanmasıyla eklenebilir (şimdi yok).
class GameIds {
  GameIds._();

  static const String bulPatlat = 'bul_patlat';
  static const String harfArabalari = 'harf_arabalari';

  /// Skor tablosu olan oyunlar (sıra, tablodaki sekme sırasıdır).
  static const List<String> leaderboardGames = [bulPatlat, harfArabalari];
}

/// Çevrimiçi sıralamaya bağlı oyunlar ve kabul edilen sonuç sınırları.
/// Yeni oyun eklemek: buraya bir satır + `firestore.rules` → `gameLimits()`
/// (test ikisinin aynı olduğunu denetler).
///
/// Kodla kesin olanlar: puan kuralı (bkz. [OnlineScore]), doğru ≤ toplam öğe,
/// Bul & Patlat'ta 5 hedef kaçınca oyun biter (`maxMissed`). Oyun 120 sn sürer;
/// hedef balon/araba ekrana alttan/soldan girip görünür olmadan dokunulamaz.
/// Oyun kodunda doğru sayısına kesin bir tavan olmadığı için mutlak üst sınır
/// cömert tutuldu: 120 sn'de en çok saniyede 2 doğru = 240 doğru →
/// 240 × 50 / 3 = 4000 puan. Gerçek skorlar görüldükçe düşürülebilir.
const Map<String, OnlineGameLimits> kOnlineLeaderboardGames = {
  GameIds.bulPatlat: OnlineGameLimits(
    maxScore: 4000,
    maxCorrect: 240,
    maxWrong: 1000,
    maxMissed: 5,
    maxTotalItems: 1000,
  ),
  GameIds.harfArabalari: OnlineGameLimits(
    maxScore: 4000,
    maxCorrect: 240,
    maxWrong: 1000,
    maxMissed: 240,
    maxTotalItems: 1000,
  ),
};

/// Çocuk için güvenli, fotoğrafsız avatar seçenekleri.
class PlayerAvatar {
  const PlayerAvatar(this.id, this.icon, this.color);

  final String id;
  final IconData icon;
  final Color color;
}

const List<PlayerAvatar> kPlayerAvatars = [
  PlayerAvatar('star', Icons.star_rounded, Color(0xFFE0B040)),
  PlayerAvatar('moon', Icons.nightlight_round, Color(0xFF7F9CD6)),
  PlayerAvatar('note', Icons.music_note_rounded, Color(0xFF6FBF9F)),
  PlayerAvatar('diamond', Icons.diamond_rounded, Color(0xFF8FB7D9)),
  PlayerAvatar('sun', Icons.wb_sunny_rounded, Color(0xFFE6A26A)),
  PlayerAvatar('cloud', Icons.cloud_rounded, Color(0xFF9DB4C8)),
  PlayerAvatar('leaf', Icons.eco_rounded, Color(0xFF8DBB7E)),
  PlayerAvatar('heart', Icons.favorite_rounded, Color(0xFFD98C8C)),
];

PlayerAvatar avatarById(String id) => kPlayerAvatars.firstWhere(
  (a) => a.id == id,
  orElse: () => kPlayerAvatars.first,
);

/// Yerel oyuncu profili. YALNIZCA takma ad + avatar: e-posta, telefon, adres,
/// doğum tarihi, fotoğraf ve gerçek ad tutulmaz. İleride bir backend'e
/// (Firebase/Supabase) olduğu gibi taşınabilecek düz bir modeldir.
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.displayName,
    required this.avatarId,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String avatarId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'avatarId': avatarId,
    'createdAt': createdAt.toIso8601String(),
  };

  static PlayerProfile? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['displayName'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return null;
    }
    return PlayerProfile(
      id: id,
      displayName: name,
      avatarId: raw['avatarId'] is String ? raw['avatarId'] as String : 'star',
      createdAt: DateTime.tryParse('${raw['createdAt']}') ?? DateTime.now(),
    );
  }
}

/// Bir oyunun bitişindeki sonuç (kaydedilecek olay).
class PlayerGameResult {
  const PlayerGameResult({
    required this.playerId,
    required this.gameId,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.missedTargets,
    required this.totalItems,
    required this.playedAt,
  });

  final String playerId;
  final String gameId;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int missedTargets;

  /// Oyun sırasında ekrana gelen toplam öğe (balon/araba).
  final int totalItems;
  final DateTime playedAt;

  /// Doğru / (doğru + yanlış + kaçırılan hedef), yüzde. Saklanmaz, hesaplanır.
  int get accuracyPercent {
    final total = correctAnswers + wrongAnswers + missedTargets;
    return total == 0 ? 0 : (correctAnswers * 100 / total).round();
  }
}

/// Bir oyuncunun bir oyundaki birikmiş kaydı (kişisel en iyi + toplamlar).
/// Doğruluk saklanmaz; toplamlardan gerektiğinde hesaplanır (tekrarlı veri yok).
class PlayerGameStats {
  const PlayerGameStats({
    this.bestScore = 0,
    this.bestAt,
    this.lastScore = 0,
    this.lastPlayedAt,
    this.gamesPlayed = 0,
    this.totalCorrect = 0,
    this.totalWrong = 0,
    this.totalMissed = 0,
    this.totalItems = 0,
  });

  final int bestScore;
  final DateTime? bestAt;
  final int lastScore;
  final DateTime? lastPlayedAt;
  final int gamesPlayed;
  final int totalCorrect;
  final int totalWrong;
  final int totalMissed;
  final int totalItems;

  int get accuracyPercent {
    final total = totalCorrect + totalWrong + totalMissed;
    return total == 0 ? 0 : (totalCorrect * 100 / total).round();
  }

  /// Yeni bir sonucu ekler. Kişisel en iyi yalnızca AŞILIRSA güncellenir
  /// (eşit skor eski tarihi korur: skor tablosunda ilk ulaşan önde kalır).
  PlayerGameStats applied(PlayerGameResult r) {
    final improved = r.score > bestScore || bestAt == null;
    return PlayerGameStats(
      bestScore: improved ? r.score : bestScore,
      bestAt: improved ? r.playedAt : bestAt,
      lastScore: r.score,
      lastPlayedAt: r.playedAt,
      gamesPlayed: gamesPlayed + 1,
      totalCorrect: totalCorrect + r.correctAnswers,
      totalWrong: totalWrong + r.wrongAnswers,
      totalMissed: totalMissed + r.missedTargets,
      totalItems: totalItems + r.totalItems,
    );
  }

  Map<String, dynamic> toJson() => {
    'bestScore': bestScore,
    'bestAt': bestAt?.toIso8601String(),
    'lastScore': lastScore,
    'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    'gamesPlayed': gamesPlayed,
    'totalCorrect': totalCorrect,
    'totalWrong': totalWrong,
    'totalMissed': totalMissed,
    'totalItems': totalItems,
  };

  static PlayerGameStats fromJson(Map<dynamic, dynamic> j) {
    int i(String k) => (j[k] is num) ? (j[k] as num).toInt() : 0;
    DateTime? d(String k) =>
        j[k] is String ? DateTime.tryParse(j[k] as String) : null;
    return PlayerGameStats(
      bestScore: i('bestScore'),
      bestAt: d('bestAt'),
      lastScore: i('lastScore'),
      lastPlayedAt: d('lastPlayedAt'),
      gamesPlayed: i('gamesPlayed'),
      totalCorrect: i('totalCorrect'),
      totalWrong: i('totalWrong'),
      totalMissed: i('totalMissed'),
      totalItems: i('totalItems'),
    );
  }
}

/// Oyuncu adı doğrulama sonuçları.
enum PlayerNameError {
  empty,
  tooShort,
  tooLong,
  invalidChars,
  notAllowed,
  taken,
}
