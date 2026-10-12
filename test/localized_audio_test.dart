import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kuran_okuma_rehberi/l10n/l10n.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/turkish_audio_catalog.dart';
import 'package:kuran_okuma_rehberi/widgets/turkish_audio_block.dart';
import 'support/silent_audio.dart';
import 'book_pages_test.dart' show app, setSize;
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingPlayer extends SilentAudio {
  String? last;
  @override
  Future<void> playAsset(String assetPath) async {
    last = assetPath;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('all requested lesson translations have their recordings', () {
    final units =
        jsonDecode(File('tool/i18n/content_units.json').readAsStringSync())
            as List;
    for (final language in [
      AppLanguage.es,
      AppLanguage.fr,
      AppLanguage.en,
      AppLanguage.nl,
    ]) {
      final manifest =
          jsonDecode(
                File(
                  'tool/i18n/audio_${language.code}.json',
                ).readAsStringSync(),
              )
              as Map;
      final entries = {for (final e in manifest['entries'] as List) e['id']: e};
      for (final unit in units) {
        final locations = unit['locations'] as List;
        if (locations.every(
          (l) => (l['lesson'] as String).startsWith('giris-'),
        )) {
          continue;
        }
        expect(
          L10n.translationOf(language, unit['source']),
          isNotNull,
          reason: '${language.code}: ${unit['source']}',
        );
        final id = unit['audioId'];
        if (id == null) continue;
        expect(
          entries.containsKey(id),
          isTrue,
          reason: '${language.code}: $id',
        );
      }
      for (final e in entries.values) {
        expect(e['status'], 'generated', reason: e['id']);
        expect(File(e['file']).lengthSync(), greaterThan(100), reason: e['id']);
      }
    }
  });
  test('game instructions are recorded in all active languages', () {
    for (final language in AppLanguage.active) {
      final manifest =
          jsonDecode(
                File(
                  'tool/i18n/game_audio_${language.code}.json',
                ).readAsStringSync(),
              )
              as Map;
      for (final entry in manifest['entries']) {
        expect(entry['status'], 'generated');
        expect(File(entry['file']).existsSync(), isTrue, reason: entry['file']);
      }
    }
  });
  testWidgets(
    'French lesson title and page controls follow the selected language',
    (tester) async {
      setSize(tester, const Size(800, 1000));
      final controller = LanguageController(initial: AppLanguage.fr);
      TurkishAudioCatalog.debugSetAvailable({});
      await tester.pumpWidget(
        AppLanguageScope(
          controller: controller,
          child: app(_RecordingPlayer(), kHarfleriTaniyalimLesson),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Leçon 1 · Découvrons les lettres'), findsOneWidget);
      expect(find.text('📖 Page'), findsOneWidget);
      expect(find.text('Page suivante'), findsOneWidget);
      expect(find.text('Ders 1 · Harfleri Tanıyalım'), findsNothing);
    },
  );

  testWidgets('Dutch lesson title, page controls and recordings', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1000));
    final controller = LanguageController(initial: AppLanguage.nl);
    TurkishAudioCatalog.debugSetAvailable({});
    await tester.pumpWidget(
      AppLanguageScope(
        controller: controller,
        child: app(_RecordingPlayer(), kHarfleriTaniyalimLesson),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Les 1 · Laten we de letters leren kennen'), findsOneWidget);
    expect(find.text('📖 Pagina'), findsOneWidget);
    expect(find.text('Volgende pagina'), findsOneWidget);

    final player = _RecordingPlayer();
    TurkishAudioCatalog.debugSetAvailable({'audio/nl/s040_01.mp3'});
    await tester.pumpWidget(
      ChangeNotifierProvider<AudioService>.value(
        value: player,
        child: AppLanguageScope(
          controller: controller,
          child: MaterialApp(
            home: Scaffold(
              body: TurkishAudioTap(
                audioId: 's040_01',
                builder: (_, available, playing) =>
                    Text(available ? 'listen' : 'unavailable'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('listen'));
    expect(player.last, 'audio/nl/s040_01.mp3');
  });

  testWidgets(
    'switching language plays that language without Turkish fallback',
    (tester) async {
      final player = _RecordingPlayer();
      final controller = LanguageController(initial: AppLanguage.fr);
      TurkishAudioCatalog.debugSetAvailable({
        'audio/fr/s040_01.mp3',
        'audio/es/s040_01.mp3',
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<AudioService>.value(
          value: player,
          child: AppLanguageScope(
            controller: controller,
            child: MaterialApp(
              home: Scaffold(
                body: TurkishAudioTap(
                  audioId: 's040_01',
                  builder:
                      (_, available, playing) =>
                          Text(available ? 'listen' : 'unavailable'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('listen'));
      expect(player.last, 'audio/fr/s040_01.mp3');
      await tester.runAsync(() => controller.setLanguage(AppLanguage.es));
      await tester.pump();
      await tester.tap(find.text('listen'));
      expect(player.last, 'audio/es/s040_01.mp3');
      await tester.runAsync(() => controller.setLanguage(AppLanguage.en));
      await tester.pump();
      expect(find.text('unavailable'), findsOneWidget);
    },
  );
}
