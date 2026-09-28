import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Türkçe Ses Kontrol ekranı uygulamanın hiçbir menüsünde yoktur; ayrı giriş
// noktasıyla açılır: `flutter run -d chrome -t lib/debug/turkish_audio_qc_main.dart`.

/// Üretilmiş bir Türkçe sesin kontrol satırı (manifest'ten).
class TrAudioQcEntry {
  const TrAudioQcEntry({
    required this.id,
    required this.pdfPage,
    required this.heading,
    required this.text,
    this.ttsText,
  });

  final String id;
  final int pdfPage;
  final bool heading;

  /// Ekranda görünen metin.
  final String text;

  /// Manifest'teki ayrı okunuş metni; yoksa seslendirilen metin [text]'tir.
  final String? ttsText;

  /// Seslendirmeye gerçekten gönderilen metin (üretici: `ttsText or text`).
  String get spokenText => ttsText ?? text;
}

enum TrAudioQcStatus {
  good('iyi', '✓ İyi'),
  regenerate('yeniden_uret', '↻ Yeniden üret'),
  fixText('metin_duzelt', '✎ Metin/Telaffuz düzeltilecek');

  const TrAudioQcStatus(this.code, this.label);

  /// Kayıtta ve dışa aktarımda kullanılan kısa ad.
  final String code;
  final String label;

  static TrAudioQcStatus? fromCode(Object? code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return null;
  }
}

/// Seçimler cihazda kalır (`tr_ses_kontrol.v1` → `{"s003_01": "iyi", ...}`).
/// Bozuk kayıt → boş başlar.
class TrAudioQcStore {
  static const String key = 'tr_ses_kontrol.v1';

  Future<Map<String, TrAudioQcStatus>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, TrAudioQcStatus>{};
      decoded.forEach((id, code) {
        final status = TrAudioQcStatus.fromCode(code);
        if (id is String && status != null) result[id] = status;
      });
      return result;
    } catch (error) {
      debugPrint('Türkçe Ses Kontrol: kayıt okunamadı — $error');
      return {};
    }
  }

  Future<void> save(Map<String, TrAudioQcStatus> statuses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode({
          for (final entry in statuses.entries) entry.key: entry.value.code,
        }),
      );
    } catch (error) {
      debugPrint('Türkçe Ses Kontrol: kayıt yazılamadı — $error');
    }
  }
}

/// Kontrol raporu: `ID | PDF sayfası | text | ttsText | durum`, PDF sırasıyla.
/// ttsText sütunu seslendirmeye gönderilen metindir; durum işaretlenmemişse
/// `bakilmadi`. [only] verilirse yalnız o durumlar.
String trAudioQcReport(
  List<TrAudioQcEntry> entries,
  Map<String, TrAudioQcStatus> statuses, {
  Set<TrAudioQcStatus>? only,
}) {
  String cell(String value) =>
      value.replaceAll('|', r'\|').replaceAll(RegExp(r'\s*\n\s*'), ' ');
  final buffer =
      StringBuffer()
        ..writeln('ID | PDF sayfası | text | ttsText | durum')
        ..writeln('--- | --- | --- | --- | ---');
  for (final entry in entries) {
    final status = statuses[entry.id];
    if (only != null && (status == null || !only.contains(status))) continue;
    buffer.writeln(
      '${entry.id} | ${entry.pdfPage} | ${cell(entry.text)} | '
      '${cell(entry.spokenText)} | ${status?.code ?? 'bakilmadi'}',
    );
  }
  return buffer.toString();
}
