import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/drag_drop_game_data.dart';
import '../../../../services/game_score_store.dart';
import 'letter_learning.dart';

/// Öğrenme durumunun bulut kopyası (Firestore: `learning_progress`).
/// Uygulama ondan bağımsız çalışır; her çağrı başarısız olabilir.
abstract class LearningCloud {
  /// Oyuncunun kayıtlı durumu (yoksa null).
  Future<Map<String, Object?>?> fetch(String profileId);

  Future<void> push(String profileId, Map<String, Object?> state);
}

/// Sürükle & Bırak öğrenme durumunu oyuncu başına saklar.
///
/// * Cihazda: `SharedPreferences` `drag_drop_learning_v1.<profil>` (ad
///   verilmemişse `.local`; ad verilince o kayıt profile geçer). Sayfa
///   yenilense de durum kaybolmaz.
/// * Bulutta ([LearningCloud], varsa): her kayıttan sonra gönderilir;
///   açılışta iki kopyadan `updatedAt`'i yeni olan kullanılır.
/// * Hiç kayıt yoksa eski "Oyun 1-7" sonuçlarından güvenli başlangıç
///   ([LetterLearningEngine.migrateFromOldLevels]); skor kayıtlarına dokunulmaz.
class LearningRepository {
  LearningRepository({
    required this.engine,
    this.cloud,
    this.cloudTimeout = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const String keyPrefix = 'drag_drop_learning_v1';
  static const String localProfile = 'local';

  final LetterLearningEngine engine;
  final LearningCloud? cloud;
  final Duration cloudTimeout;
  final DateTime Function() _clock;

  static String keyFor(String? profileId) =>
      '$keyPrefix.${profileId ?? localProfile}';

  Future<LearningState> load({
    String? profileId,
    GameScoreStore? scores,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(keyFor(profileId));
    if (raw == null && profileId != null) {
      // Ad verilmeden oynanan ilerleme profile geçer.
      raw = prefs.getString(keyFor(null));
    }
    LearningState? local;
    if (raw != null) {
      try {
        local = LearningState.fromJson(
          jsonDecode(raw),
          groupCount: engine.groups.length,
        );
      } catch (_) {
        local = null; // bozuk kayıt: aşağıda güvenli başlangıç
      }
    }
    LearningState? remote;
    if (profileId != null && cloud != null) {
      try {
        final data = await cloud!.fetch(profileId).timeout(cloudTimeout);
        if (data != null) {
          remote = LearningState.fromJson(
            data,
            groupCount: engine.groups.length,
          );
        }
      } catch (error) {
        debugPrint('LearningRepository: bulut okunamadı — $error');
      }
    }
    var state = switch ((local, remote)) {
      (final l?, final r?) => r.updatedAt > l.updatedAt ? r : l,
      (final l?, null) => l,
      (null, final r?) => r,
      (null, null) => await _fresh(scores),
    };
    // Kopyalar farklıysa ikisini de eşitle.
    if (remote == null || remote.updatedAt != state.updatedAt) {
      await save(state, profileId: profileId);
    } else if (local == null || local.updatedAt != state.updatedAt) {
      await _saveLocal(prefs, state, profileId);
    }
    return state;
  }

  Future<LearningState> _fresh(GameScoreStore? scores) async {
    final now = _clock();
    if (scores == null) {
      return LearningState(updatedAt: now.millisecondsSinceEpoch);
    }
    final stars = <int?>[];
    for (final level in kDragDropLevels.where((l) => !l.isRandom)) {
      try {
        stars.add((await scores.recordOf(level.gameKey)).bestStars);
      } catch (_) {
        stars.add(null);
      }
    }
    return engine.migrateFromOldLevels(stars, now);
  }

  Future<void> _saveLocal(
    SharedPreferences prefs,
    LearningState state,
    String? profileId,
  ) => prefs.setString(keyFor(profileId), jsonEncode(state.toJson()));

  /// Cihaza yazar, sonra (beklemeden) buluta gönderir.
  Future<void> save(LearningState state, {String? profileId}) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveLocal(prefs, state, profileId);
    if (profileId != null && cloud != null) {
      unawaited(
        cloud!
            .push(profileId, state.toJson())
            .timeout(cloudTimeout)
            .catchError((Object error) {
              debugPrint('LearningRepository: buluta yazılamadı — $error');
            }),
      );
    }
  }
}
