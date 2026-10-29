// Bütün sure ve dualar: ayet / bölüm sesi bağlanan her öğe tutarlı olmalı.
// Ek sureler (12+) üç tekrarlı ezber kayıtlarından ayrıldı (tool/ezber_split);
// bir surenin ayetlerinden biri eksikse hiçbiri bağlanmaz (yanlış ayete ses
// atanmaz, metin kartı ve tam kayıt kalır).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/additional_dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/full_reading_audio.dart';
import 'package:kuran_okuma_rehberi/data/supplementary_sureler_data.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/services/reading_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dualar_test.dart' show TestAudioService, harness;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReadingSettings.instance.resetForTest();
  });

  test('ayet sesleri: hepsi ya da hiçbiri, sırayla, kendi dosyası', () {
    for (final surah in kAllNamazTexts) {
      final assets = surah.ayetler.map((a) => a.audioAsset).toList();
      if (assets.every((a) => a.isEmpty)) continue;
      expect(assets.where((a) => a.isEmpty), isEmpty, reason: surah.id);
      expect(assets.toSet(), hasLength(assets.length), reason: surah.id);
      for (final (i, ayet) in surah.ayetler.indexed) {
        expect(File('assets/${ayet.audioAsset}').existsSync(), isTrue,
            reason: ayet.audioAsset);
        // Dosya adı ayet numarasını taşır: 1. ayete besmele bağlanamaz.
        final number = ayet.number.toString().padLeft(2, '0');
        expect(ayet.audioAsset, endsWith('/${number}_ayet.mp3'),
            reason: '${surah.id} ${i + 1}');
      }
      if (surah.besmeleAudioAsset.isNotEmpty) {
        expect(surah.besmeleAudioAsset, endsWith('/00_besmele.mp3'));
        expect(assets, isNot(contains(surah.besmeleAudioAsset)));
        expect(File('assets/${surah.besmeleAudioAsset}').existsSync(), isTrue);
      }
      // Her ayetin sesi varsa Dinle ayet ayet çalar; uzun kayıt (zilli) yok.
      if (surah.besmeleAudioAsset.isNotEmpty) {
        expect(kFullReadingAudio.containsKey(surah.id), isFalse,
            reason: surah.id);
      }
    }
    for (final dua in [...kDualar, ...kAdditionalDualar]) {
      for (final part in dua.segments) {
        if (part.audioAsset.isEmpty) continue;
        expect(File('assets/${part.audioAsset}').existsSync(), isTrue,
            reason: part.audioAsset);
      }
    }
  });

  testWidgets('her sesli surede karta dokununca o ayetin kendi sesi çalar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    for (final surah in kAllNamazTexts.skip(11)) {
      if (surah.ayetler.first.audioAsset.isEmpty) continue;
      await tester.pumpWidget(harness(SurahDetailScreen(surah: surah), audio));
      await tester.pumpAndSettle();
      final hasOpening = surah.besmele.isNotEmpty;
      for (final i in {0, surah.ayetler.length - 1}) {
        final index = i + (hasOpening ? 1 : 0);
        final card = find.byKey(ValueKey('reading-segment-$index'));
        // Card's top at the top of the list (never under the bottom bar).
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        // Near the card's top (a long verse is taller than the screen):
        // the free space of its number row, not a button.
        final rect = tester.getRect(card);
        await tester.tapAt(Offset(rect.center.dx, rect.top + 28));
        await tester.pump();
        expect(audio.currentAsset, surah.ayetler[i].audioAsset,
            reason: '${surah.id} ayet ${surah.ayetler[i].number}');
        audio.complete();
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });
}
