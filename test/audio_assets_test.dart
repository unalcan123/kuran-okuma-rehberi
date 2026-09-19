import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/drag_drop_game_data.dart';

// On the web every sound is downloaded, so the recordings are kept small:
// mono, 64-80 kbps mp3 (they were 320 kbps stereo). This stops full-size
// files from sneaking back in and making taps slow again.
void main() {
  final files =
      Directory('assets/audio')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp3'))
          .toList();

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
    final elifba = files.where((f) => f.path.replaceAll('\\', '/').contains('audio/elifba/'));
    final biggest = elifba.map((f) => f.lengthSync()).reduce((a, b) => a > b ? a : b);
    expect(biggest, lessThan(60 * 1024));
  });

  test('the cheer sound is a small mp3', () {
    final cheer = File('assets/$kGameCorrectSound');
    expect(kGameCorrectSound, endsWith('.mp3'));
    expect(cheer.lengthSync(), lessThan(30 * 1024));
  });
}
