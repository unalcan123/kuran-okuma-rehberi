import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bir harfin çizim ilerlemesi. Yalnızca öğrenme özeti tutulur; çizimin
/// kendisi (koordinatlar) hiçbir yere kaydedilmez ya da gönderilmez.
class LetterDrawProgress {
  const LetterDrawProgress({
    this.guided = false,
    this.lessHelp = false,
    this.struggle = 0,
  });

  /// Kılavuzla tamamladı (gövde + noktalar) → 1. yıldız.
  final bool guided;

  /// Daha az yardımla (silik kılavuz) tamamladı → 2. yıldız.
  final bool lessHelp;

  /// Zorlanma sayacı (0–5): zorlanılan her çalışma +1, daha az yardımla
  /// başarı −1. "Zorlandıklarımı Çalış" buna bakar.
  final int struggle;

  /// Yıldızlar bayraklardan hesaplanır: aynı harfi tekrar çizmek yıldızı
  /// artırmaz (en çok 2).
  int get stars => (guided ? 1 : 0) + (lessHelp ? 1 : 0);

  LetterDrawProgress copyWith({bool? guided, bool? lessHelp, int? struggle}) =>
      LetterDrawProgress(
        guided: guided ?? this.guided,
        lessHelp: lessHelp ?? this.lessHelp,
        struggle: (struggle ?? this.struggle).clamp(0, 5),
      );

  Map<String, Object> toJson() => {'g': guided, 'l': lessHelp, 's': struggle};

  static LetterDrawProgress fromJson(Object? raw) {
    if (raw is! Map) return const LetterDrawProgress();
    final s = raw['s'];
    return LetterDrawProgress(
      guided: raw['g'] == true,
      lessHelp: raw['l'] == true,
      struggle: s is num ? s.toInt().clamp(0, 5) : 0,
    );
  }
}

/// Cihazda, oyuncuya bağlı kayıt: `harf_ciziyorum.v1.<oyuncuId|cihaz>` →
/// `{"2": {"g": true, "l": false, "s": 1}, ...}`. Bozuk kayıt → boş başlar.
class DrawProgressStore {
  static const String mutedKey = 'harf_ciziyorum.ses_kapali';

  static String keyFor(String? profileId) =>
      'harf_ciziyorum.v1.${profileId ?? 'cihaz'}';

  Future<Map<int, LetterDrawProgress>> load(String? profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyFor(profileId));
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <int, LetterDrawProgress>{};
      decoded.forEach((key, value) {
        final id = int.tryParse('$key');
        if (id != null && id >= 1 && id <= 28) {
          result[id] = LetterDrawProgress.fromJson(value);
        }
      });
      return result;
    } catch (error) {
      debugPrint('Harf Çiziyorum: kayıt okunamadı — $error');
      return {};
    }
  }

  /// [letterId]'nin kaydını [change] ile günceller ve yeni hâlini döndürür.
  /// Yazımlar sıraya girer: üst üste gelen iki güncellemeden biri kaybolmaz.
  Future<LetterDrawProgress> update(
    String? profileId,
    int letterId,
    LetterDrawProgress Function(LetterDrawProgress old) change,
  ) {
    final result = _queue.then((_) => _update(profileId, letterId, change));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _queue = Future.value();

  Future<LetterDrawProgress> _update(
    String? profileId,
    int letterId,
    LetterDrawProgress Function(LetterDrawProgress old) change,
  ) async {
    final all = await load(profileId);
    final next = change(all[letterId] ?? const LetterDrawProgress());
    all[letterId] = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        keyFor(profileId),
        jsonEncode({for (final e in all.entries) '${e.key}': e.value.toJson()}),
      );
    } catch (error) {
      debugPrint('Harf Çiziyorum: kayıt yazılamadı — $error');
    }
    return next;
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
      debugPrint('Harf Çiziyorum: ses tercihi yazılamadı — $error');
    }
  }
}
