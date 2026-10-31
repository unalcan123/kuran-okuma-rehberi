import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/additional_dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/supplementary_sureler_data.dart';
import 'package:kuran_okuma_rehberi/data/surah_meanings.dart';
import 'package:kuran_okuma_rehberi/l10n/l10n.dart';
import 'package:kuran_okuma_rehberi/models/reading_segment.dart';
import 'package:flutter/material.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dua_detail_screen.dart';
import 'package:kuran_okuma_rehberi/services/reading_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dualar_test.dart' show TestAudioService, harness;

void main() {
  testWidgets('Prayer meaning updates on screen when the language changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ReadingSettings.instance.resetForTest();
    ReadingSettings.instance.showMeaning = true;
    addTearDown(ReadingSettings.instance.resetForTest);
    final controller = LanguageController(initial: AppLanguage.nl);
    final audio = TestAudioService();
    addTearDown(controller.dispose);
    addTearDown(audio.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppLanguageScope(
        controller: controller,
        child: harness(DuaDetailScreen(dua: kDualar.first), audio),
      ),
    );
    await tester.pumpAndSettle();
    for (final language in [AppLanguage.nl, ...AppLanguage.active]) {
      await controller.setLanguage(language);
      await tester.pumpAndSettle();
      final original = kDualar.first.segments.first;
      final meaning =
          language == AppLanguage.tr
              ? original.meaningTr
              : original.meanings[language.code]!;
      expect(find.text(meaning), findsOneWidget, reason: language.code);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('All 90 prayer parts have meanings in every supported language', () {
    expect(kAllDualar, hasLength(15));
    expect(kAllDualar.expand((d) => d.segments), hasLength(90));
    for (final language in AppLanguage.active) {
      for (final dua in kAllDualar) {
        final parts = ReadingSegment.ofDua(dua, languageCode: language.code);
        expect(parts.map((p) => p.arabic), dua.segments.map((p) => p.arabic));
        expect(
          parts.map((p) => p.audioAsset),
          dua.segments.map((p) => p.audioAsset),
        );
        for (var i = 0; i < parts.length; i++) {
          final original = dua.segments[i];
          final expected =
              language == AppLanguage.tr
                  ? original.meaningTr
                  : original.meanings[language.code];
          expect(
            expected,
            isNotNull,
            reason: '${dua.id}/${original.id}/${language.code}',
          );
          expect(expected!.trim(), isNotEmpty);
          expect(parts[i].meaning, expected);
          if (language != AppLanguage.tr) {
            expect(parts[i].meaning, isNot(original.meaningTr));
          }
        }
      }
    }
    for (final dua in kDualar) {
      expect(dua.segments.every((p) => p.meaningSource.isNotEmpty), isTrue);
    }
  });

  test('All 25 Quran texts have complete verse mappings in every language', () {
    expect(kAllNamazTexts, hasLength(25));
    for (final surah in kAllNamazTexts) {
      for (final language in AppLanguage.active) {
        final published = kSurahMeanings[surah.id]?[language.code];
        expect(published, isNotNull, reason: '${surah.id}/${language.code}');
        expect(published!.url, isNotEmpty);
        final parts = ReadingSegment.ofSurah(
          surah,
          languageCode: language.code,
        );
        for (var i = 0; i < surah.ayetler.length; i++) {
          final ayet = surah.ayetler[i];
          final part = parts[i + 1];
          expect(part.audioAsset, ayet.audioAsset);
          // A single Quran verse may span several audio cards. Other languages
          // show the complete published verse only on its first phrase.
          final repeatedPhrase =
              ayet.verse != null &&
              i > 0 &&
              surah.ayetler[i - 1].verse == ayet.verse;
          if (language != AppLanguage.tr && repeatedPhrase) {
            expect(part.meaning, isEmpty);
          } else {
            expect(
              part.meaning.trim(),
              isNotEmpty,
              reason: '${surah.id}/${ayet.number}/${language.code}',
            );
            if (language != AppLanguage.tr || ayet.verse == null) {
              expect(published.verses[ayet.verse ?? part.number], isNotNull);
              expect(part.meaning, published.verses[ayet.verse ?? part.number]);
            }
          }
        }
      }
    }
  });
}
