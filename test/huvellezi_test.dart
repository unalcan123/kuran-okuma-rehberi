// Hüvellezî (Fetih 28-29): 2011 kaydının 13 bölümü (H:\Music\sureler\4),
// Arapça kullanıcının kuran.docx'inden; bazı bölümler kayıttaki gibi bir
// öncekinin son kelimesini tekrarlar.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/ayetel_kursi_data.dart';

void main() {
  test('13 bölüm, her biri ayetinin parçası; ayetler baştan sona kapsanır', () {
    final source =
        jsonDecode(File('tool/sources/kuran_docx_fetih.json').readAsStringSync())
            as Map;
    final parts = kHuvellezi.ayetler;
    expect(parts.map((a) => a.number), List.generate(13, (i) => i + 1));
    expect(parts.map((a) => a.verse).toSet(), {28, 29});
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
    expect(File('assets/${kHuvellezi.besmeleAudioAsset}').existsSync(), isTrue);
  });
}
