import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dedektif_engine.dart';

/// Harf Dedektifi'nin cihazdaki öğrenme kaydı: mod başına harf zorluğu
/// (0–5) ve ses tercihi. Yalnızca harf kimlikleri ve sayılar tutulur.
///
/// Kayıt, cihazın oyuncusuna ([profileId], yoksa `cihaz`) bağlıdır:
/// `harf_dedektifi.v1.<profil>` → `{"sekiller": {"2": 3}, ...}`.
/// Kayıt bozuk ya da okunamazsa oyun boş kayıtla açılır.
class DetectiveProgressStore {
  static const int maxWeight = 5;
  static const String mutedKey = 'harf_dedektifi.ses_kapali';

  static String keyFor(String? profileId) =>
      'harf_dedektifi.v1.${profileId ?? 'cihaz'}';

  Future<Map<String, Map<int, int>>> _readAll(String? profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyFor(profileId));
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, Map<int, int>>{};
      decoded.forEach((mode, value) {
        if (mode is! String || value is! Map) return;
        final weights = <int, int>{};
        value.forEach((id, weight) {
          final letterId = int.tryParse('$id');
          if (letterId != null && weight is num && weight > 0) {
            weights[letterId] = weight.toInt().clamp(0, maxWeight);
          }
        });
        result[mode] = weights;
      });
      return result;
    } catch (error) {
      debugPrint('Harf Dedektifi: kayıt okunamadı — $error');
      return {};
    }
  }

  Future<Map<int, int>> weightsFor(
    DetectiveMode mode, {
    String? profileId,
  }) async => (await _readAll(profileId))[mode.key] ?? {};

  /// Zorlanılan hedefler +1, rahat bulunanlar −1 (0'da silinir).
  Future<void> applySession(
    DetectiveMode mode, {
    String? profileId,
    required Set<int> struggled,
    required Set<int> clean,
  }) async {
    try {
      final all = await _readAll(profileId);
      final weights = all[mode.key] ?? <int, int>{};
      for (final id in struggled) {
        weights[id] = ((weights[id] ?? 0) + 1).clamp(0, maxWeight);
      }
      for (final id in clean) {
        final next = (weights[id] ?? 0) - 1;
        if (next <= 0) {
          weights.remove(id);
        } else {
          weights[id] = next;
        }
      }
      all[mode.key] = weights;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        keyFor(profileId),
        jsonEncode({
          for (final e in all.entries)
            e.key: {for (final w in e.value.entries) '${w.key}': w.value},
        }),
      );
    } catch (error) {
      debugPrint('Harf Dedektifi: kayıt yazılamadı — $error');
    }
  }

  Future<bool> isMuted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(mutedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setMuted(bool muted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(mutedKey, muted);
    } catch (error) {
      debugPrint('Harf Dedektifi: ses tercihi yazılamadı — $error');
    }
  }
}
