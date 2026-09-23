import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'leaderboard_backend.dart';
import 'leaderboard_models.dart';
import 'nickname_policy.dart';

/// Oyunların ortak çevrimiçi sıralama servisi (yerel skor sisteminin ÜSTÜNDE
/// bir katman; yerel kayıtlar her zaman ayrıca tutulur).
///
///  * Oyuncu = yerel profil (takma ad). Çevrimiçi kimlik
///    `<anonim UID>_<profil id>` — aynı adı taşıyan iki çocuk farklı oyuncudur.
///  * Oyun sonunda sonuç önce cihazdaki "bekleyenler" kuyruğuna yazılır
///    (oyun+oyuncu başına yalnızca en iyisi), sonra gönderilir. İnternet yoksa
///    kuyrukta kalır; sonraki oyun sonunda ya da uygulama açılışında gönderilir.
///  * Firebase hataları asla oyunu çökertmez: her çağrı zaman aşımlı ve
///    yakalanmıştır; sonuç [OnlineOutcome] olarak döner.
/// Ağaçta [LeaderboardService] varsa onu döndürür (testlerde/ön izlemede
/// olmayabilir; o zaman çevrimiçi bölüm hiç gösterilmez).
LeaderboardService? maybeLeaderboardService(BuildContext context) {
  try {
    return Provider.of<LeaderboardService>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}

class LeaderboardService {
  /// [backend] arka planda hazırlanabilir (uygulama açılışı Firebase'i
  /// beklemez). `null` ile tamamlanırsa çevrimiçi sıralama bu derlemede yok
  /// demektir (bölüm gizlenir); hata ile tamamlanırsa (ör. web'de internet yokken
  /// Firebase yüklenemedi) sonuçlar cihazda bekletilir.
  LeaderboardService({
    required FutureOr<LeaderboardBackend?> backend,
    required Map<String, OnlineGameLimits> games,
    this.timeout = const Duration(seconds: 10),
    this.topLimit = 10,
  }) : _backendFuture = Future.value(backend),
       games = Map.unmodifiable(games) {
    // Yakalanmamış hata uyarısı olmasın; hata çağrılarda ele alınır.
    _backendFuture.ignore();
  }

  static const String pendingKey = 'leaderboard_pending_v1';

  /// Gönderilmeyi bekleyen ad değişiklikleri: { profileId: nickname }.
  static const String renameKey = 'leaderboard_rename_v1';

  final Future<LeaderboardBackend?> _backendFuture;
  final Map<String, OnlineGameLimits> games;
  final Duration timeout;
  final int topLimit;

  LeaderboardBackend? _backendOrNull;

  /// Hazır arka uç; hazırlanamadıysa hata fırlatır (çevrimdışı gibi ele alınır).
  LeaderboardBackend get _backend => _backendOrNull!;

  /// `false`: bu derlemede çevrimiçi sıralama yok. Hata (Firebase yüklenemedi)
  /// fırlatır.
  Future<bool> _ready() async {
    if (_backendOrNull != null) return true;
    _backendOrNull = await _backendFuture.timeout(timeout);
    return _backendOrNull != null;
  }

  /// Arka uç yapılandırılmamışsa `false` (hata/zaman aşımı `true` sayılır:
  /// Firebase var ama şu an ulaşılamıyor).
  Future<bool> _configured() async {
    try {
      return await _ready();
    } catch (_) {
      return true;
    }
  }

  String? _uid;
  final Set<String> _savedPlayers = {};
  Future<void>? _flushing;

  /// Çevrimiçi oyuncu kimliği. Profil id'si yalnızca `[a-z0-9]` içerir
  /// (kurallar bunu bekler).
  static String playerIdFor(String uid, String profileId) =>
      '${uid}_${profileId.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '')}';

  /// Uygulama açılışında: anonim oturum + bekleyen skorları gönderme.
  /// Hata olursa sessizce geçer.
  Future<void> init() async {
    try {
      if (!await _ready()) return;
      await _ensureUid();
      await _flushPending();
    } catch (e) {
      debugPrint('LeaderboardService.init: $e');
    }
  }

  Future<String> _ensureUid() async =>
      _uid ??= await _backend.signIn().timeout(timeout);

  // ---- bekleyenler kuyruğu ----------------------------------------------------

  static String _pendingId(String gameId, String profileId) =>
      '$gameId|$profileId';

  Future<Map<String, dynamic>> _readPending([String key = pendingKey]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _writePending(
    Map<String, dynamic> pending, [
    String key = pendingKey,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (pending.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, jsonEncode(pending));
      }
    } catch (e) {
      debugPrint('LeaderboardService: kuyruk yazılamadı — $e');
    }
  }

  Future<void> _enqueue(
    String profileId,
    String nickname,
    OnlineScore s,
  ) async {
    final pending = await _readPending();
    final id = _pendingId(s.gameId, profileId);
    final existing = pending[id];
    final old =
        existing is Map ? OnlineScore.tryFromJson(existing['score']) : null;
    if (old != null && old.score >= s.score) return;
    pending[id] = {
      'profileId': profileId,
      'nickname': nickname,
      'score': s.toJson(),
    };
    await _writePending(pending);
  }

  /// Kuyruktaki her sonucu göndermeye çalışır. Ağ hatası → kuyrukta kalır;
  /// kurallar reddederse (tutarsız veri) atılır. Aynı anda tek gönderim.
  Future<void> _flushPending() =>
      _flushing ??= _doFlush().whenComplete(() => _flushing = null);

  Future<void> _doFlush() async {
    final pending = await _readPending();
    final renames = await _readPending(renameKey);
    if (pending.isEmpty && renames.isEmpty) return;
    if (!await _ready()) return;
    final uid = await _ensureUid();
    Object? networkError;
    for (final profileId in renames.keys.toList()) {
      final nickname = renames[profileId];
      if (nickname is! String) {
        renames.remove(profileId);
        continue;
      }
      try {
        await _backend
            .renamePlayer(
              playerId: playerIdFor(uid, profileId),
              ownerUid: uid,
              nickname: nickname,
              gameIds: games.keys,
            )
            .timeout(timeout);
        renames.remove(profileId);
      } on LeaderboardRejected catch (e) {
        debugPrint('LeaderboardService: ad reddedildi — $e');
        renames.remove(profileId);
      } catch (e) {
        networkError = e;
        break;
      }
    }
    await _writePending(renames, renameKey);
    if (networkError != null) throw networkError;
    for (final id in pending.keys.toList()) {
      final entry = pending[id];
      final score =
          entry is Map ? OnlineScore.tryFromJson(entry['score']) : null;
      final profileId = entry is Map ? entry['profileId'] : null;
      final nickname = entry is Map ? entry['nickname'] : null;
      if (score == null || profileId is! String || nickname is! String) {
        pending.remove(id);
        continue;
      }
      final playerId = playerIdFor(uid, profileId);
      try {
        if (_savedPlayers.add(playerId)) {
          try {
            await _backend
                .savePlayer(
                  playerId: playerId,
                  ownerUid: uid,
                  nickname: nickname,
                )
                .timeout(timeout);
          } catch (_) {
            _savedPlayers.remove(playerId);
            rethrow;
          }
        }
        await _backend
            .submitBest(
              playerId: playerId,
              ownerUid: uid,
              nickname: nickname,
              score: score,
            )
            .timeout(timeout);
        pending.remove(id);
      } on LeaderboardRejected catch (e) {
        debugPrint('LeaderboardService: reddedildi, atılıyor — $e');
        pending.remove(id);
      } catch (e) {
        networkError = e;
        break; // bağlantı yok: kalanlar da beklesin
      }
    }
    await _writePending(pending);
    if (networkError != null) throw networkError;
  }

  // ---- oyun sonu --------------------------------------------------------------

  /// Oyun bitince çağrılır: sonucu gönderir (gerekirse kuyruğa alır) ve
  /// sıralamayı yükler. [profileId] `null` ise (oyuncu seçilmemiş) çevrimiçine
  /// yazılmaz.
  Future<OnlineOutcome> submitAndLoad({
    required String? profileId,
    required String? nickname,
    required OnlineScore score,
  }) async {
    if (!await _configured()) {
      return const OnlineOutcome(OnlineStatus.unavailable);
    }
    if (profileId == null || nickname == null) {
      return const OnlineOutcome(OnlineStatus.noPlayer);
    }
    final name = NicknamePolicy.normalize(nickname);
    if (!NicknamePolicy.isValid(name)) {
      return const OnlineOutcome(OnlineStatus.invalidName);
    }
    final limits = games[score.gameId];
    if (limits == null || !score.isPlausible(limits)) {
      return const OnlineOutcome(OnlineStatus.rejected);
    }
    await _enqueue(profileId, name, score);
    try {
      await _flushPending();
    } catch (e) {
      debugPrint('LeaderboardService: gönderilemedi (bekliyor) — $e');
      return const OnlineOutcome(OnlineStatus.savedOffline);
    }
    return _load(profileId, score.gameId);
  }

  /// "Tekrar dene": bekleyenleri göndermeyi dener, sonra sıralamayı yükler.
  Future<OnlineOutcome> retry({
    required String? profileId,
    required String gameId,
  }) async {
    if (!await _configured()) {
      return const OnlineOutcome(OnlineStatus.unavailable);
    }
    try {
      await _flushPending();
    } catch (_) {
      return const OnlineOutcome(OnlineStatus.savedOffline);
    }
    return _load(profileId, gameId);
  }

  /// Bu profilin bu oyun için gönderilmeyi bekleyen sonucu var mı?
  Future<bool> hasPending(String profileId, String gameId) async =>
      (await _readPending()).containsKey(_pendingId(gameId, profileId));

  Future<OnlineOutcome> _load(String? profileId, String gameId) async {
    try {
      final snapshot = await loadSnapshot(profileId, gameId).timeout(timeout);
      return OnlineOutcome(OnlineStatus.ranked, snapshot: snapshot);
    } catch (e) {
      debugPrint('LeaderboardService: sıralama yüklenemedi — $e');
      return const OnlineOutcome(OnlineStatus.loadFailed);
    }
  }

  /// İlk 10 + oyuncunun kendi sırası + toplam oyuncu. Tüm koleksiyon
  /// indirilmez: ilk 10 belge, oyuncunun belgesi ve 2–3 sunucu sayımı.
  @visibleForTesting
  Future<LeaderboardSnapshot> loadSnapshot(
    String? profileId,
    String gameId,
  ) async {
    if (!await _ready()) throw StateError('çevrimiçi sıralama yok');
    final backend = _backend;
    final uid = await _ensureUid();
    final playerId = profileId == null ? null : playerIdFor(uid, profileId);

    final topF = backend.top(gameId, topLimit);
    final totalF = backend.countPlayers(gameId);
    final mineF =
        playerId == null
            ? Future<StoredBest?>.value()
            : backend.fetchBest(gameId, playerId);
    final top = await topF;
    final total = await totalF;
    final mine = await mineF;

    LeaderboardRow? me;
    if (mine != null && playerId != null) {
      final inTop = top.where((r) => r.playerId == playerId);
      if (inTop.isNotEmpty) {
        me = inTop.first;
      } else {
        final ahead = await backend.countAhead(gameId, mine);
        me = LeaderboardRow(
          rank: ahead + 1,
          playerId: playerId,
          nickname: mine.nickname,
          bestScore: mine.bestScore,
        );
      }
    }
    return LeaderboardSnapshot(
      gameId: gameId,
      top: top,
      me: me,
      // Sayım ile ilk 10 farklı anlarda okunur; tutarsız görünmesin.
      totalPlayers: [
        total,
        top.length,
        me?.rank ?? 0,
      ].reduce((a, b) => a > b ? a : b),
    );
  }

  // ---- ad değişikliği -----------------------------------------------------------

  /// Oyuncu adını düzeltti: çevrimiçi profil ve skor kayıtlarındaki ad
  /// güncellenir (internet yoksa sonra). Bekleyen skorlar da yeni adla gider.
  Future<void> renamePlayer(String profileId, String nickname) async {
    final name = NicknamePolicy.normalize(nickname);
    if (!NicknamePolicy.isValid(name)) return;
    final pending = await _readPending();
    for (final entry in pending.values) {
      if (entry is Map && entry['profileId'] == profileId) {
        entry['nickname'] = name;
      }
    }
    await _writePending(pending);
    final renames = await _readPending(renameKey);
    renames[profileId] = name;
    await _writePending(renames, renameKey);
    try {
      await _flushPending();
    } catch (e) {
      debugPrint('LeaderboardService: ad sonra güncellenecek — $e');
    }
  }

  // ---- silme ------------------------------------------------------------------

  /// Yerel profil silinince çevrimiçi kaydını da siler (en iyi çaba; internet
  /// yoksa kayıt sunucuda kalır). Bekleyen sonuçları da atar.
  Future<void> forgetPlayer(String profileId) async {
    final pending = await _readPending();
    pending.removeWhere((k, _) => k.endsWith('|$profileId'));
    await _writePending(pending);
    try {
      if (!await _ready()) return;
      final uid = await _ensureUid();
      final playerId = playerIdFor(uid, profileId);
      _savedPlayers.remove(playerId);
      await _backend.deletePlayer(playerId, games.keys).timeout(timeout);
    } catch (e) {
      debugPrint('LeaderboardService: çevrimiçi kayıt silinemedi — $e');
    }
  }
}
