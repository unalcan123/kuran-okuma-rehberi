/// Çevrimiçi (herkesin ortak) skor sıralamasının modelleri. Firebase'e bağlı
/// değildir; arka uç [LeaderboardBackend] arkasındadır.
library;

/// Bir oyunun çevrimiçi sıralamaya kabul edilecek sonuç sınırları. Aynı değerler
/// `firestore.rules` içindeki `gameLimits()`'te de vardır (biri değişirse
/// diğeri de değişmeli; test karşılaştırır).
class OnlineGameLimits {
  const OnlineGameLimits({
    required this.maxScore,
    required this.maxCorrect,
    required this.maxWrong,
    required this.maxMissed,
    required this.maxTotalItems,
  });

  final int maxScore;
  final int maxCorrect;
  final int maxWrong;
  final int maxMissed;
  final int maxTotalItems;
}

/// Bitmiş bir oyunun çevrimiçi sıralamaya gönderilecek sonucu. Harf oyunlarının
/// puan kuralı (`LetterGameCore.registerCorrect`): doğru +10, ilk denemede +5,
/// art arda her 3. ilk-deneme doğruda +5. Bu yüzden her geçerli sonuçta
///   10 × doğru ≤ puan ≤ 15 × doğru + 5 × ⌊doğru / 3⌋   (⇒ 3 × puan ≤ 50 × doğru)
/// ve puan 5'in katıdır.
class OnlineScore {
  const OnlineScore({
    required this.gameId,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.missedTargets,
    required this.totalItems,
  });

  final String gameId;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int missedTargets;
  final int totalItems;

  /// Doğru / (doğru + yanlış + kaçan), yüzde (oyun ekranındakiyle aynı hesap).
  int get accuracy {
    final total = correctAnswers + wrongAnswers + missedTargets;
    return total == 0 ? 0 : (correctAnswers * 100 / total).round();
  }

  /// Puan kuralıyla ve oyunun sınırlarıyla tutarlı mı? (İstemci tarafı ön
  /// kontrol; aynı denetim Firestore kurallarında da var.)
  bool isPlausible(OnlineGameLimits limits) {
    final c = correctAnswers;
    return score >= 0 &&
        c >= 0 &&
        wrongAnswers >= 0 &&
        missedTargets >= 0 &&
        totalItems >= 0 &&
        score % 5 == 0 &&
        score >= c * 10 &&
        score * 3 <= c * 50 &&
        c <= totalItems &&
        score <= limits.maxScore &&
        c <= limits.maxCorrect &&
        wrongAnswers <= limits.maxWrong &&
        missedTargets <= limits.maxMissed &&
        totalItems <= limits.maxTotalItems;
  }

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'score': score,
    'correct': correctAnswers,
    'wrong': wrongAnswers,
    'missed': missedTargets,
    'items': totalItems,
  };

  static OnlineScore? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    int? i(String k) => raw[k] is int ? raw[k] as int : null;
    final gameId = raw['gameId'];
    final score = i('score'), c = i('correct'), w = i('wrong');
    final m = i('missed'), t = i('items');
    if (gameId is! String || score == null || c == null || w == null) {
      return null;
    }
    if (m == null || t == null) return null;
    return OnlineScore(
      gameId: gameId,
      score: score,
      correctAnswers: c,
      wrongAnswers: w,
      missedTargets: m,
      totalItems: t,
    );
  }
}

/// Sıralamadaki bir satır.
class LeaderboardRow {
  const LeaderboardRow({
    required this.rank,
    required this.playerId,
    required this.nickname,
    required this.bestScore,
  });

  final int rank;
  final String playerId;
  final String nickname;
  final int bestScore;
}

/// Bir oyuncunun bir oyundaki kayıtlı en iyisi (sıra hesabı için zamanı da).
class StoredBest {
  const StoredBest({
    required this.bestScore,
    required this.bestAt,
    this.nickname = '',
  });

  final int bestScore;
  final String nickname;

  /// En iyiye ulaşılan an (sunucu zamanı). Eşit puanda önce ulaşan öndedir.
  final DateTime bestAt;
}

/// Oyun sonu ekranında gösterilen çevrimiçi sıralama.
class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.gameId,
    required this.top,
    required this.me,
    required this.totalPlayers,
  });

  final String gameId;

  /// İlk 10 (azalan puan; eşitlikte önce ulaşan).
  final List<LeaderboardRow> top;

  /// Oyuncunun kendi satırı (kaydı yoksa `null`).
  final LeaderboardRow? me;

  /// Bu oyunda çevrimiçi skoru olan oyuncu sayısı.
  final int totalPlayers;

  bool get meInTop => me != null && top.any((r) => r.playerId == me!.playerId);
}

enum OnlineStatus {
  /// Skor gönderildi (ya da daha iyisi zaten vardı), sıralama yüklendi.
  ranked,

  /// İnternet/Firebase'e ulaşılamadı: skor cihazda bekliyor, sonra gönderilir.
  savedOffline,

  /// Skor gönderildi ama sıralama yüklenemedi.
  loadFailed,

  /// Oyuncu seçilmedi: çevrimiçi sıralamaya yazılmaz.
  noPlayer,

  /// Takma ad çevrimiçi kurallara uymuyor.
  invalidName,

  /// Sonuç tutarsız/sınır dışı: gönderilmedi.
  rejected,

  /// Firebase bu cihazda/derlemede kullanılamıyor.
  unavailable,
}

class OnlineOutcome {
  const OnlineOutcome(this.status, {this.snapshot});

  final OnlineStatus status;
  final LeaderboardSnapshot? snapshot;
}
