import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Arapça Yazıyorum'un YALNIZCA cihazdaki kayıtları (oyuncuya bağlı):
///  * taslaklar (ad ve serbest yazı) — sunucuya/sıralamaya gönderilmez,
///  * "Bak ve Yaz" alıştırma sayıları: kendi başına / ipucuyla tamamlanan,
///  * ses ve cihaz klavyesi tercihleri.
/// Okuma/yazma hatasında oyun boş kayıtla sürer.
class YaziStore {
  static const String mutedKey = 'arapca_yaziyorum.ses_kapali';
  static const String deviceKeyboardKey = 'arapca_yaziyorum.cihaz_klavyesi';

  static String draftKey(String? profileId, String mode) =>
      'arapca_yaziyorum.v1.${profileId ?? 'cihaz'}.taslak.$mode';

  static String statsKey(String? profileId) =>
      'arapca_yaziyorum.v1.${profileId ?? 'cihaz'}.bak_yaz';

  Future<String> loadDraft(String? profileId, String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(draftKey(profileId, mode)) ?? '';
    } catch (error) {
      debugPrint('Arapça Yazıyorum: taslak okunamadı — $error');
      return '';
    }
  }

  Future<void> saveDraft(String? profileId, String mode, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (text.isEmpty) {
        await prefs.remove(draftKey(profileId, mode));
      } else {
        await prefs.setString(draftKey(profileId, mode), text);
      }
    } catch (error) {
      debugPrint('Arapça Yazıyorum: taslak yazılamadı — $error');
    }
  }

  /// Alıştırma sayıları: {"باب": {"i": 2, "h": 1}} (i = kendi başına,
  /// h = ipucuyla).
  Future<Map<String, ({int independent, int withHint})>> loadStats(
    String? profileId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(statsKey(profileId));
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, ({int independent, int withHint})>{};
      decoded.forEach((k, v) {
        if (k is String && v is Map) {
          final i = v['i'];
          final h = v['h'];
          out[k] = (
            independent: i is num ? i.toInt() : 0,
            withHint: h is num ? h.toInt() : 0,
          );
        }
      });
      return out;
    } catch (error) {
      debugPrint('Arapça Yazıyorum: istatistik okunamadı — $error');
      return {};
    }
  }

  Future<void> recordCopy(
    String? profileId,
    String text, {
    required bool withHint,
  }) async {
    try {
      final stats = await loadStats(profileId);
      final old = stats[text] ?? (independent: 0, withHint: 0);
      stats[text] =
          withHint
              ? (independent: old.independent, withHint: old.withHint + 1)
              : (independent: old.independent + 1, withHint: old.withHint);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        statsKey(profileId),
        jsonEncode({
          for (final e in stats.entries)
            e.key: {'i': e.value.independent, 'h': e.value.withHint},
        }),
      );
    } catch (error) {
      debugPrint('Arapça Yazıyorum: istatistik yazılamadı — $error');
    }
  }

  Future<bool> getBool(String key) async {
    try {
      return (await SharedPreferences.getInstance()).getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBool(String key, bool value) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(key, value);
    } catch (error) {
      debugPrint('Arapça Yazıyorum: "$key" yazılamadı — $error');
    }
  }
}
