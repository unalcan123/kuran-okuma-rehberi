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
      Directory(
        'assets/audio',
      ).listSync(recursive: true).whereType<File>().toList()
        ..sort((a, b) => _norm(a.path).compareTo(_norm(b.path)));
  final files = all.where((f) => f.path.endsWith('.mp3')).toList();

  test('there are recordings, and every one is small', () {
    expect(files.length, greaterThan(1000));
    for (final file in files) {
      expect(
        file.lengthSync(),
        lessThan(250 * 1024),
        reason: '${file.path} is too big for a web download',
      );
    }
  });

  test('all recordings together stay light enough to download', () {
    final total = files.fold<int>(0, (sum, f) => sum + f.lengthSync());
    expect(total, lessThan(30 * 1024 * 1024));
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
      final line =
          '${file.path.replaceAll('\\', '/')}:${file.lengthSync()}\n';
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
