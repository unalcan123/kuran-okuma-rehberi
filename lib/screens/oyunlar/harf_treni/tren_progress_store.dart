import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tren_engine.dart';

/// Harf Treni'nin cihazdaki öğrenme kaydı (oyuncuya bağlı): seviye başına
/// harf zorluğu 0–5, ses tercihi ve örnek gösterimin görülüp görülmediği.
/// `harf_treni.v1.<oyuncuId|cihaz>` → `{"l1": {"2": 1}, ...}`. Bozuk kayıt →
/// boş başlar.
class TrainProgressStore {
  static const int maxWeight = 5;
  static const String mutedKey = 'harf_treni.ses_kapali';
  static const String demoKey = 'harf_treni.ornek_goruldu';

  static String keyFor(String? profileId) =>
      'harf_treni.v1.${profileId ?? 'cihaz'}';

  Future<Map<String, Map<int, int>>> _readAll(String? profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyFor(profileId));
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, Map<int, int>>{};
      decoded.forEach((level, value) {
        if (level is! String || value is! Map) return;
        final weights = <int, int>{};
        value.forEach((id, w) {
          final letterId = int.tryParse('$id');
          if (letterId != null && w is num && w > 0) {
            weights[letterId] = w.toInt().clamp(0, maxWeight);
          }
        });
        result[level] = weights;
      });
      return result;
    } catch (error) {
      debugPrint('Harf Treni: kayıt okunamadı — $error');
      return {};
    }
  }

  Future<Map<int, int>> weightsFor(
    TrainLevel level, {
    String? profileId,
  }) async => (await _readAll(profileId))['l${level.number}'] ?? {};

  Future<void> applySession(
    TrainLevel level, {
    String? profileId,
    required Set<int> struggled,
    required Set<int> clean,
  }) async {
    try {
      final all = await _readAll(profileId);
      final key = 'l${level.number}';
      final weights = all[key] ?? <int, int>{};
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
      all[key] = weights;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        keyFor(profileId),
        jsonEncode({
          for (final e in all.entries)
            e.key: {for (final w in e.value.entries) '${w.key}': w.value},
        }),
      );
    } catch (error) {
      debugPrint('Harf Treni: kayıt yazılamadı — $error');
    }
  }

  Future<bool> _getBool(String key) async {
    try {
      return (await SharedPreferences.getInstance()).getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(key, value);
    } catch (error) {
      debugPrint('Harf Treni: "$key" yazılamadı — $error');
    }
  }

  Future<bool> isMuted() => _getBool(mutedKey);
  Future<void> setMuted(bool v) => _setBool(mutedKey, v);
  Future<bool> demoSeen() => _getBool(demoKey);
  Future<void> setDemoSeen() => _setBool(demoKey, true);
}
