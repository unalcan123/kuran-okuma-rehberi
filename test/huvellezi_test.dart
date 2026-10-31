// Hüvellezî (Fetih 28-29, 2011 kaydının 13 bölümü, H:\Music\sureler\4) ve
// Hüvallâhüllezî (Haşr 22-24, kullanıcının kaydının 10 bölümü): Arapça
// kullanıcının kuran.docx'inden; bazı bölümler kayıttaki gibi bir öncekinin
// son kelimesini tekrarlar.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/ayetel_kursi_data.dart';
import 'package:kuran_okuma_rehberi/models/surah.dart';

void main() {
  for (final (Surah surah, String source, int count, Set<int> verses) in [
    (kHuvellezi, 'kuran_docx_fetih', 13, {28, 29}),
    (kHuvallahullezi, 'kuran_docx_hasr', 10, {22, 23, 24}),
  ]) {
    _check(surah, source, count, verses);
  }
}

void _check(Surah surah, String file, int count, Set<int> verses) {
  test(
    '${surah.id}: $count bölüm, her biri ayetinin parçası; ayetler baştan sona kapsanır',
    () {
      final source =
          jsonDecode(File('tool/sources/$file.json').readAsStringSync()) as Map;
      final parts = surah.ayetler;
      expect(parts.map((a) => a.number), List.generate(count, (i) => i + 1));
      expect(parts.map((a) => a.verse).toSet(), verses);
      for (final (i, part) in parts.indexed) {
        final verse = source['${part.verse}'] as String;
        expect(verse, contains(part.arabic), reason: '${part.number}');
        if (i == 0 || parts[i - 1].verse != part.verse) {
          expect(verse, startsWith(part.arabic));
        }
        if (i == parts.length - 1 || parts[i + 1].verse != part.verse) {
          expect(verse, endsWith(part.arabic));
        }
        expect(part.meaningTr, isNotEmpty);
        expect(
          File('assets/${part.audioAsset}').existsSync(),
          isTrue,
          reason: part.audioAsset,
        );
      }
      expect(File('assets/${surah.besmeleAudioAsset}').existsSync(), isTrue);
    },
  );
}
