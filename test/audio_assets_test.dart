import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/drag_drop_game_data.dart';
import 'package:kuran_okuma_rehberi/services/sound_cache.dart';

// On the web every sound is downloaded, so the recordings are kept small:
// mono, 64-80 kbps mp3 (they were 320 kbps stereo). This stops full-size
// files from sneaking back in and making taps slow again.
String _norm(String path) => path.replaceAll(r'\', '/');

void main() {
  final all =
      Directory('assets/audio')
          .listSync(recursive: true)
          .whereType<File>()
          // Hidden placeholder files (e.g. .gitkeep) are not sounds.
          .where((f) => !_norm(f.path).split('/').last.startsWith('.'))
          .toList()
        ..sort((a, b) => _norm(a.path).compareTo(_norm(b.path)));
  final files = all.where((f) => f.path.endsWith('.mp3')).toList();

  // Âyetel Kürsî is one verse, read very slowly in the teaching recording
  // (~139 s): its single card clip has its own, duration-based budget
  // (48 kbps mono = ~6 KB/s); it loads only when that card is played.
  const longVerses = {
  };

  test('there are recordings, and every one is small', () {
    expect(files.length, greaterThan(1000));
    for (final file in files.where((f) => !_norm(f.path).contains('/full_readings/'))) {
      expect(
        file.lengthSync(),
        lessThan(longVerses[_norm(file.path)] ?? 250 * 1024),
        reason: '${file.path} is too big for a web download',
      );
    }
  });

  test('all recordings together stay light enough to download', () {
    // Arabic and effects are shared; explanation clips load on demand only
    // in the selected language, never all language folders at once.
    const languages = ['tr', 'es', 'fr', 'en', 'de', 'bs', 'nl'];
    for (final language in languages) {
      final selected = files.where((file) {
        final path = _norm(file.path);
        if (path.contains('/full_readings/')) return false;
        if (longVerses.containsKey(path)) return false; // loads on play
        return !languages.any(
              (code) => path.startsWith('assets/audio/$code/'),
            ) ||
            path.startsWith('assets/audio/$language/');
      });
      final total = selected.fold<int>(0, (sum, f) => sum + f.lengthSync());
      // 30 MB idi; sesli öğretmen konuşmalarıyla (2026-10-12) Türkçe ~30,03 MB
      // oldu. Sesler ihtiyaç oldukça indirilir; sınır 32 MB idi. 2026-10-29:
      // ek surelerin ayet klipleri (+~2,9 MB) geldi, karşılığında bu
      // hesaba hiç girmeyen ~28 MB'lık uzun zilli kayıtlar silindi; sınır 36 MB.
      // 2026-10-31: Nebe 31-40 ayet ayet (+0,78 MB, 48 kbps); sınır 37 MB.
      // Aynı gün Hüvellezî (Fetih 28-29, 13 bölüm, +0,75 MB); sınır 38 MB.
      expect(total, lessThan(38 * 1024 * 1024), reason: language);
    }
  });

  test('Complete teaching recordings have a separate duration-based budget', () {
    final rows = jsonDecode(File('tool/sources/audio_import_manifest.json').readAsStringSync()) as List;
    // Surahs with verse clips from the repeat recordings (tool/ezber_split)
    // no longer need one (Kadir too: "selâm", read at the end of verse 4's
    // clip, was moved to the start of verse 5) nor the Ezan and Yemek
    // Duası (sentence clips): no long recording ships now.
    expect(rows, isEmpty);
    var total = 0;
    for (final row in rows) {
      final file = File('assets/${row['asset']}');
      final bytes = file.lengthSync(); total += bytes;
      // 48 kbps mono plus MP3 frame/header overhead. Long tracks load on play.
      expect(bytes, lessThan((row['seconds'] as num) * 6100 + 2048));
      expect(bytes, lessThan(row['sourceBytes'] as int));
    }
    expect(total, lessThan(40 * 1024 * 1024));
  });

  test('Elifba letter clips are tiny (one tap = a few KB)', () {
    final elifba = files.where(
      (f) => f.path.replaceAll('\\', '/').contains('audio/elifba/'),
    );
    final biggest = elifba
        .map((f) => f.lengthSync())
        .reduce((a, b) => a > b ? a : b);
    expect(biggest, lessThan(60 * 1024));
  });

  test('the cheer sound is a small mp3', () {
    final cheer = File('assets/$kGameCorrectSound');
    expect(kGameCorrectSound, endsWith('.mp3'));
    expect(cheer.lengthSync(), lessThan(30 * 1024));
  });

  // Visitors keep the recordings on their device under kSoundCacheVersion.
  // If a recording changes without a new version they would keep hearing
  // the old one, so any change to the audio files must bump the version.
  test('kSoundCacheVersion matches the current audio files', () {
    var hash = 0x811c9dc5; // FNV-1a, 32 bit
    for (final file in all) {
      final line = '${file.path.replaceAll('\\', '/')}:${file.lengthSync()}\n';
      for (final unit in line.codeUnits) {
        hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
      }
    }
    final fingerprint = hash.toRadixString(16).padLeft(8, '0');
    expect(
      kSoundCacheVersion,
      fingerprint,
      reason:
          'Ses dosyaları değişti. lib/services/sound_cache.dart içinde '
          "kSoundCacheVersion = '$fingerprint' yap.",
    );
  });
}
