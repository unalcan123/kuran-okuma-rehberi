// Hocamızın orijinal kayıtları (harf, hareke, ders, sure, dua) asla
// değiştirilmez, silinmez, yeniden üretilmez. Liste ve parmak izleri:
// tool/original_audio_fingerprints.json. Yalnızca çalma seviyesi düzeltilecekse
// kopyası assets/audio/duzeltmeler/ altına konur ve kAudioReplacements'e
// eklenir (orijinal dosya aynen kalır).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';

/// Boyut + FNV-1a 32 (tool/original_audio_fingerprints.json ile aynı).
String _fingerprint(List<int> bytes) {
  var h = 0x811c9dc5;
  for (final b in bytes) {
    h = ((h ^ b) * 0x01000193) & 0xffffffff;
  }
  return '${bytes.length}:${h.toRadixString(16).padLeft(8, '0')}';
}

void main() {
  final listed =
      (jsonDecode(File('tool/original_audio_fingerprints.json').readAsStringSync())
              as Map)['files']
          as Map;

  test('orijinal kayıtlar değişmedi ve silinmedi', () {
    final changed = <String>[];
    listed.forEach((path, hash) {
      final file = File(path as String);
      if (!file.existsSync()) {
        changed.add('$path: silinmiş');
      } else if (_fingerprint(file.readAsBytesSync()) != hash) {
        changed.add('$path: değişmiş');
      }
    });
    expect(changed, isEmpty, reason: changed.join('\n'));
  });

  test('orijinal klasörlere listede olmayan dosya eklenmedi', () {
    final extra = [
      for (final dir in ['assets/audio/elifba', 'assets/audio/sureler', 'assets/audio/dualar'])
        for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
          if (!f.uri.pathSegments.last.startsWith('.'))
            f.path.replaceAll('\\', '/'),
    ].where((p) => !listed.containsKey(p)).toList();
    expect(extra, isEmpty, reason: extra.join('\n'));
  });

  test('düzeltilmiş kopyalar orijinalin yerine çalar, orijinal yerinde', () {
    kAudioReplacements.forEach((original, copy) {
      expect(listed.containsKey('assets/$original'), isTrue, reason: original);
      expect(File('assets/$copy').existsSync(), isTrue, reason: copy);
      expect(copy, startsWith('audio/duzeltmeler/'));
      expect(playableAsset(original), copy);
    });
    expect(playableAsset('audio/oyunlar/dogru.mp3'), 'audio/oyunlar/dogru.mp3');
  });
}
