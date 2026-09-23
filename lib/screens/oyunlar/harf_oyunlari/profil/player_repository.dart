import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/leaderboard/nickname_policy.dart';
import 'player_models.dart';

/// Cihazdaki yerel oyuncu profilleri, aktif oyuncu ve oyun başına skorlar.
///
/// Depolama (SharedPreferences, üç anahtar; veri modeli backend'e taşınabilir):
///  * `game_players_v1`       → [PlayerProfile] listesi (JSON)
///  * `game_active_player_v1` → aktif oyuncunun id'si
///  * `game_stats_v1`         → { playerId: { gameId: PlayerGameStats } }
///
/// Birden fazla çocuk aynı cihazı kullanabilir; her oyuncunun her oyundaki
/// skoru ayrı anahtarda tutulur, birbirinin üzerine yazılmaz.
class PlayerRepository extends ChangeNotifier {
  PlayerRepository();

  static const String profilesKey = 'game_players_v1';
  static const String activeKey = 'game_active_player_v1';
  static const String statsKey = 'game_stats_v1';

  /// Profil adı en fazla bu kadar karakter.
  static const int maxNameLength = NicknamePolicy.maxLength;

  final List<PlayerProfile> _profiles = [];
  final Map<String, Map<String, PlayerGameStats>> _stats = {};
  String? _activeId;
  bool _loaded = false;

  /// Bu oturumda "Kim oynuyor?" zaten soruldu (kapatıldıysa tekrar tekrar sorma).
  bool promptedThisSession = false;

  bool get loaded => _loaded;
  List<PlayerProfile> get profiles => List.unmodifiable(_profiles);

  PlayerProfile? get activePlayer {
    for (final p in _profiles) {
      if (p.id == _activeId) return p;
    }
    return null;
  }

  PlayerProfile? profileById(String id) {
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---- yükleme / kaydetme ---------------------------------------------------

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profiles.clear();
      _stats.clear();

      final rawProfiles = prefs.getString(profilesKey);
      if (rawProfiles != null) {
        for (final item in jsonDecode(rawProfiles) as List) {
          final p = PlayerProfile.tryFromJson(item);
          if (p != null) _profiles.add(p);
        }
      }
      final rawStats = prefs.getString(statsKey);
      if (rawStats != null) {
        (jsonDecode(rawStats) as Map).forEach((playerId, games) {
          if (games is! Map) return;
          final perGame = <String, PlayerGameStats>{};
          games.forEach((gameId, s) {
            if (s is Map) perGame['$gameId'] = PlayerGameStats.fromJson(s);
          });
          _stats['$playerId'] = perGame;
        });
      }
      final active = prefs.getString(activeKey);
      _activeId = _profiles.any((p) => p.id == active) ? active : null;
    } catch (e) {
      // Bozuk kayıt uygulamayı çökertmez: boş başlar.
      debugPrint('PlayerRepository: kayıt okunamadı — $e');
      _profiles.clear();
      _stats.clear();
      _activeId = null;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        profilesKey,
        jsonEncode([for (final p in _profiles) p.toJson()]),
      );
      await prefs.setString(
        statsKey,
        jsonEncode({
          for (final e in _stats.entries)
            e.key: {for (final g in e.value.entries) g.key: g.value.toJson()},
        }),
      );
      if (_activeId == null) {
        await prefs.remove(activeKey);
      } else {
        await prefs.setString(activeKey, _activeId!);
      }
    } catch (e) {
      debugPrint('PlayerRepository: kayıt yazılamadı — $e');
    }
  }

  // ---- profiller ------------------------------------------------------------

  /// Boşlukları sadeleştirir: baştaki/sondaki boşluk gider, ardışık boşluklar
  /// tek olur, kontrol karakterleri atılır (bkz. [NicknamePolicy]).
  static String normalizeName(String raw) => NicknamePolicy.normalize(raw);

  /// Geçerliyse `null`, değilse hata nedeni. Kurallar çevrimiçi sıralamayla
  /// aynıdır ([NicknamePolicy]); ayrıca bu cihazda aynı ad iki kez olamaz.
  PlayerNameError? validateName(String raw) {
    final policyError = NicknamePolicy.validate(raw);
    if (policyError != null) {
      return switch (policyError) {
        NicknameError.empty => PlayerNameError.empty,
        NicknameError.tooShort => PlayerNameError.tooShort,
        NicknameError.tooLong => PlayerNameError.tooLong,
        NicknameError.invalidChars => PlayerNameError.invalidChars,
        NicknameError.notAllowed => PlayerNameError.notAllowed,
      };
    }
    final lower = normalizeName(raw).toLowerCase();
    if (_profiles.any((p) => p.displayName.toLowerCase() == lower)) {
      return PlayerNameError.taken;
    }
    return null;
  }

  static String _newId() =>
      'p${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${math.Random().nextInt(1 << 20).toRadixString(36)}';

  /// Yeni oyuncu oluşturur ve aktif yapar. Geçersiz adda `null` döner.
  Future<PlayerProfile?> createProfile(String rawName, String avatarId) async {
    if (validateName(rawName) != null) return null;
    final profile = PlayerProfile(
      id: _newId(),
      displayName: normalizeName(rawName),
      avatarId:
          kPlayerAvatars.any((a) => a.id == avatarId)
              ? avatarId
              : kPlayerAvatars.first.id,
      createdAt: DateTime.now(),
    );
    _profiles.add(profile);
    _activeId = profile.id;
    notifyListeners();
    await _save();
    return profile;
  }

  Future<void> selectProfile(String id) async {
    if (!_profiles.any((p) => p.id == id) || _activeId == id) return;
    _activeId = id;
    notifyListeners();
    await _save();
  }

  /// Oyuncuyu ve tüm skorlarını siler (çocuğun/ebeveynin verisini kaldırma hakkı).
  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    _stats.remove(id);
    if (_activeId == id) _activeId = null;
    notifyListeners();
    await _save();
  }

  // ---- skorlar --------------------------------------------------------------

  PlayerGameStats statsFor(String playerId, String gameId) =>
      _stats[playerId]?[gameId] ?? const PlayerGameStats();

  int bestScore(String playerId, String gameId) =>
      statsFor(playerId, gameId).bestScore;

  /// Sonucu ilgili oyuncunun ilgili oyun kaydına ekler. Profil silinmişse yok sayar.
  Future<void> recordResult(PlayerGameResult result) async {
    if (!_profiles.any((p) => p.id == result.playerId)) return;
    final perGame = _stats.putIfAbsent(result.playerId, () => {});
    perGame[result.gameId] = statsFor(
      result.playerId,
      result.gameId,
    ).applied(result);
    notifyListeners();
    await _save();
  }

  // ---- skor tablosu -----------------------------------------------------------

  /// Bu cihazdaki oyuncuların [gameId] oyunundaki kişisel en iyilerine göre
  /// sıralama. Beraberlikte önce o skora ulaşan, sonra ada göre. Şimdilik
  /// [limit] = 10; ileride 20 vb. yalnızca bu parametreyle değişir.
  List<LeaderboardEntry> leaderboard(String gameId, {int? limit = 10}) {
    final rows = <(PlayerProfile, PlayerGameStats)>[
      for (final p in _profiles)
        if (statsFor(p.id, gameId).gamesPlayed > 0) (p, statsFor(p.id, gameId)),
    ];
    rows.sort((a, b) {
      final byScore = b.$2.bestScore.compareTo(a.$2.bestScore);
      if (byScore != 0) return byScore;
      final ta = a.$2.bestAt, tb = b.$2.bestAt;
      if (ta != null && tb != null) {
        final byTime = ta.compareTo(tb);
        if (byTime != 0) return byTime;
      }
      return a.$1.displayName.toLowerCase().compareTo(
        b.$1.displayName.toLowerCase(),
      );
    });
    final entries = [
      for (var i = 0; i < rows.length; i++)
        LeaderboardEntry(rank: i + 1, profile: rows[i].$1, stats: rows[i].$2),
    ];
    return limit == null ? entries : entries.take(limit).toList();
  }

  /// Aktif oyuncunun sıralaması (tabloda yoksa `null`).
  LeaderboardEntry? entryOf(String playerId, String gameId) {
    for (final e in leaderboard(gameId, limit: null)) {
      if (e.profile.id == playerId) return e;
    }
    return null;
  }
}
