import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/additional_dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/ayetel_kursi_data.dart';
import 'package:kuran_okuma_rehberi/data/supplementary_sureler_data.dart';
import 'package:kuran_okuma_rehberi/data/dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/models/reading_segment.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dua_detail_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/widgets/reading/reading_screen.dart';
import 'package:kuran_okuma_rehberi/services/reading_settings.dart';
import 'dualar_test.dart' show TestAudioService, harness;

void main() {
  setUp(() => ReadingSettings.instance.resetForTest());
  test('Existing prayers and surah numbers are preserved', () {
    expect(kAllDualar.take(9), orderedEquals(kDualar));
    expect(kAllDualar, hasLength(14));
    expect(kAllDualar.map((d) => d.id).toSet(), hasLength(14));
    expect(kAllNamazTexts, hasLength(23));
    expect(kAllNamazTexts.take(11), orderedEquals(kSureler));
    expect(kAllNamazTexts[11], same(kAyatelKursi));
    expect(kAllNamazTexts.map((s) => s.order), List.generate(23, (i) => i + 1));
    expect(
      kAllNamazTexts.where((s) => kSureler.contains(s)),
      orderedEquals(kSureler),
    );
    expect(kAyatelKursi.ayetler.single.number, 255);
    expect(
      kAyatelKursiMeanings.keys,
      containsAll(['tr', 'es', 'fr', 'de', 'en', 'bs', 'nl']),
    );
    for (final prayer in kAdditionalDualar) {
      expect(prayer.playlist, isEmpty);
      expect(prayer.segments.every((p) => p.arabic.isNotEmpty), isTrue);
      final tr = ReadingSegment.ofDua(prayer);
      final nl = ReadingSegment.ofDua(prayer, languageCode: 'nl');
      expect(tr.map((p) => p.arabic), nl.map((p) => p.arabic));
      expect(
        nl.map((p) => p.meaning),
        prayer.segments.map((p) => p.meanings['nl']),
      );
    }
  });
  for (final size in [const Size(390, 844), const Size(800, 360)]) {
    testWidgets('New content fits $size and missing recordings cannot start', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = TestAudioService();
      addTearDown(audio.dispose);
      ReadingSettings.instance.showMeaning = true;
      ReadingSettings.instance.arabicScale = 1.9;
      final screens = <Widget>[
        for (final prayer in kAdditionalDualar) DuaDetailScreen(dua: prayer),
        for (final surah in kSupplementarySureler) SurahDetailScreen(surah: surah),
        const SurahDetailScreen(surah: kAyatelKursi),
      ];
      for (final screen in screens) {
        await tester.pumpWidget(harness(screen, audio));
        await tester.pumpAndSettle();
        expect(find.byType(ReadingScreen), findsOneWidget);
        final button = tester.widget<FilledButton>(
          find.byKey(const ValueKey('reading-listen')),
        );
        final reading = tester.widget<ReadingScreen>(
          find.byType(ReadingScreen),
        );
        expect(button.onPressed != null, reading.fullAudioAsset.isNotEmpty);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('reading-memorize')),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
      }
    });
  }
}

