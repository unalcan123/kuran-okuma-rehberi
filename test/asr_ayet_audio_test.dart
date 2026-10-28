// Asr Suresi: üç tekrarlı ezber kaydından (H:\Music\sureler\tekrarli\asr.mp3,
// tool/ezber_split) her ayetin tek ve en temiz okunuşu; zil yok. Kartın
// tamamına dokununca yalnız o ayet baştan çalar, kart vurgulanır, ses bitince
// normale döner.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/full_reading_audio.dart';
import 'package:kuran_okuma_rehberi/data/supplementary_sureler_data.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/services/reading_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dualar_test.dart' show TestAudioService, harness;

const _dir = 'audio/sureler/22_asr';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReadingSettings.instance.resetForTest();
  });

  test('3 ayet, her biri kendi tek kaydına bağlı; besmele ayrı', () {
    final asr = kSupplementAsr;
    expect(asr.ayetler.map((a) => a.number), [1, 2, 3]);
    expect(asr.ayetler.map((a) => a.audioAsset), [
      '$_dir/01_ayet.mp3',
      '$_dir/02_ayet.mp3',
      '$_dir/03_ayet.mp3',
    ]);
    expect(asr.besmeleAudioAsset, '$_dir/00_besmele.mp3');
    // Dinle ayet ayet çalar (uzun tam kayıt yerine).
    expect(kFullReadingAudio.containsKey('asr'), isFalse);
    final files =
        Directory('assets/$_dir').listSync().map((f) => f.uri.pathSegments.last).toList()
          ..sort();
    expect(files, ['00_besmele.mp3', '01_ayet.mp3', '02_ayet.mp3', '03_ayet.mp3']);
    final sizes = [
      for (final a in asr.ayetler) File('assets/${a.audioAsset}').lengthSync(),
    ];
    // Ayet 1 kısa (وَالْعَصْرِ), ayet 3 uzun; üç tekrarın üçü birden
    // dosyada olsaydı ~3 kat büyük olurdu (48 kbps: ~6 KB/sn).
    expect(sizes[0], lessThan(sizes[1]));
    expect(sizes[1], lessThan(sizes[2]));
    expect(sizes[0], lessThan(15 * 1024)); // ~1,5 sn
    expect(sizes[2], lessThan(80 * 1024)); // ~10 sn, tek okuma
    expect(sizes.toSet(), hasLength(3));
  });

  testWidgets('karta dokununca yalnız o ayet çalar; başka kart öncekini '
      'durdurur; aynı kart baştan çalar; bitince vurgu kalkar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(SurahDetailScreen(surah: kSupplementAsr), audio),
    );
    await tester.pumpAndSettle();

    // Segment 0 = besmele, 1-3 = ayetler.
    Future<void> tapCard(int i) async {
      final card = find.byKey(ValueKey('reading-segment-$i'));
      await tester.scrollUntilVisible(card, 120);
      await tester.pumpAndSettle();
      // Kartın Arapça metnine (düğmeye değil) dokun.
      await tester.tapAt(tester.getCenter(card));
      await tester.pump();
    }

    Finder mark(int i) => find.byKey(ValueKey('reading-active-mark-$i'));

    // Boştaki kartta ses simgesi: dokununca okunacağı belli.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reading-play-1')),
        matching: find.byIcon(Icons.volume_up_rounded),
      ),
      findsOneWidget,
    );
    bool glows(int i) {
      final box = tester.widget<AnimatedContainer>(
        find.byKey(ValueKey('reading-segment-$i')),
      );
      final shadows = (box.decoration! as BoxDecoration).boxShadow!;
      return shadows.any((s) => s.color.g > s.color.r && s.blurRadius >= 20);
    }

    await tapCard(2);
    expect(audio.played, ['$_dir/02_ayet.mp3']);
    expect(mark(2), findsOneWidget);
    expect(mark(1), findsNothing);
    expect(glows(2), isTrue, reason: 'okunan ayet yeşil ışıkla çevrili');
    expect(glows(1), isFalse);

    await tapCard(3);
    expect(audio.played.last, '$_dir/03_ayet.mp3');
    expect(audio.currentAsset, '$_dir/03_ayet.mp3');
    expect(mark(3), findsOneWidget);
    expect(mark(2), findsNothing);

    // Aynı kart: duraklamaz, baştan çalar.
    await tapCard(3);
    expect(audio.played, [
      '$_dir/02_ayet.mp3',
      '$_dir/03_ayet.mp3',
      '$_dir/03_ayet.mp3',
    ]);
    expect(audio.isPlaying, isTrue);
    expect(mark(3), findsOneWidget);

    audio.complete();
    await tester.pumpAndSettle();
    expect(mark(3), findsNothing);
    expect(glows(3), isFalse, reason: 'ses bitince kart normale döner');
    expect(audio.played, hasLength(3), reason: 'tek ayet, tekrar yok');

    await tapCard(1);
    expect(audio.played.last, '$_dir/01_ayet.mp3');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
