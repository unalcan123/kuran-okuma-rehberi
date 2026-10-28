import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/fatiha_meanings.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/l10n/l10n.dart';
import 'package:kuran_okuma_rehberi/models/reading_segment.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/services/reading_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dualar_test.dart' show TestAudioService, harness;

void main() {
  final snapshot =
      jsonDecode(
            File(
              'tool/sources/fatiha_published.json',
            ).readAsStringSync().replaceFirst('\uFEFF', ''),
          )
          as Map<String, dynamic>;
  for (final language in AppLanguage.active.where((l) => l != AppLanguage.tr)) {
    test(
      '${language.code}: published text and footnotes are verbatim, final two cards match',
      () {
        final source = snapshot[language.code];
        final rows = source['data']['result'] as List;
        final published = kPublishedFatihaMeanings[language.code]!;
        expect(published.verses, rows.map((a) => a['translation']));
        expect(published.footnotes, rows.map((a) => a['footnotes'] ?? ''));
        expect(published.version, source['metadata']['version']);
        final segments = ReadingSegment.ofSurah(
          kFatiha,
          languageCode: language.code,
        );
        expect(segments.map((s) => s.number), [1, 2, 3, 4, 5, 6, 7, 7]);
        expect(segments.map((s) => s.meaning), [
          ...published.verses,
          published.verses.last,
        ]);
        expect(segments.map((s) => s.audioAsset), kFatiha.playlist);
        expect(
          segments.map((s) => s.id),
          ReadingSegment.ofSurah(kFatiha).map((s) => s.id),
        );
        expect(
          segments.every((s) => s.meaningSource.contains(published.version)),
          isTrue,
        );
      },
    );
    testWidgets(
      '${language.code}: Fatiha displays chosen language with source on a phone',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        ReadingSettings.instance.resetForTest();
        ReadingSettings.instance.showMeaning = true;
        addTearDown(ReadingSettings.instance.resetForTest);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = LanguageController(initial: language);
        addTearDown(controller.dispose);
        final audio = TestAudioService();
        addTearDown(audio.dispose);
        await tester.pumpWidget(
          AppLanguageScope(
            controller: controller,
            child: harness(const SurahDetailScreen(surah: kFatiha), audio),
          ),
        );
        await tester.pumpAndSettle();
        final published = kPublishedFatihaMeanings[language.code]!;
        expect(find.text(published.verses.first), findsOneWidget);
        expect(find.text(published.attribution), findsNothing);
        expect(find.text(published.verses.last), findsNWidgets(2));
        expect(find.text(kFatiha.ayetler.first.meaningTr), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
