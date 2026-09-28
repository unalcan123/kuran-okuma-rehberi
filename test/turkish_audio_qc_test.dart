import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/debug/turkish_audio_qc.dart';
import 'package:kuran_okuma_rehberi/debug/turkish_audio_qc_data.dart';
import 'package:kuran_okuma_rehberi/debug/turkish_audio_qc_screen.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() => ChangeNotifierProvider(
  create: (_) => AudioService(),
  child: const MaterialApp(home: TurkishAudioQcScreen()),
);

void main() {
  test(
    'kontrol listesi = manifest\'teki üretilmiş kayıtlar, PDF sırasıyla',
    () {
      final manifest = jsonDecode(
        File('tool/turkish_audio/manifest.json').readAsStringSync(),
      );
      final generated = [
        for (final e in manifest['entries'] as List)
          if (e['status'] == 'generated') e,
      ];
      expect(
        kTrAudioQcEntries.map((e) => e.id).toSet(),
        generated.map((e) => e['id']).toSet(),
        reason: 'python tool/turkish_audio/export_qc_data.py çalıştır',
      );
      final byId = {for (final e in generated) e['id']: e};
      for (final entry in kTrAudioQcEntries) {
        final e = byId[entry.id]!;
        expect(entry.pdfPage, e['pdfPage'], reason: entry.id);
        expect(entry.text, e['text'], reason: entry.id);
        expect(entry.ttsText, e['ttsText'], reason: entry.id);
        expect(entry.spokenText, e['ttsText'] ?? e['text'], reason: entry.id);
        expect(
          File('assets/audio/tr/${entry.id}.mp3').existsSync(),
          isTrue,
          reason: entry.id,
        );
      }
      final pages = kTrAudioQcEntries.map((e) => e.pdfPage).toList();
      expect(pages, [...pages]..sort());
    },
  );

  test('rapor: ID | PDF sayfası | text | ttsText | durum', () {
    const entries = [
      TrAudioQcEntry(id: 'a', pdfPage: 3, heading: false, text: 'x | y'),
      TrAudioQcEntry(
        id: 'b',
        pdfPage: 4,
        heading: true,
        text: 'B',
        ttsText: 'Be',
      ),
    ];
    final statuses = {'b': TrAudioQcStatus.fixText};
    expect(trAudioQcReport(entries, statuses).trim().split('\n'), [
      'ID | PDF sayfası | text | ttsText | durum',
      '--- | --- | --- | --- | ---',
      r'a | 3 | x \| y | x \| y | bakilmadi',
      'b | 4 | B | Be | metin_duzelt',
    ]);
    expect(
      trAudioQcReport(
        entries,
        statuses,
        only: {TrAudioQcStatus.regenerate, TrAudioQcStatus.fixText},
      ).trim().split('\n').skip(2),
      ['b | 4 | B | Be | metin_duzelt'],
    );
  });

  testWidgets('işaretler cihazda kalır; filtreler sayar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final first = kTrAudioQcEntries.first.id;
    final second = kTrAudioQcEntries[1].id;

    expect(find.text('Tümü (${kTrAudioQcEntries.length})'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('qc-status-$first-yeniden_uret')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(ValueKey('qc-status-$second-iyi')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('qc-status-$second-iyi')));
    await tester.pumpAndSettle();
    expect(find.text('Yeniden üretilecek (1)'), findsOneWidget);
    expect(find.text('İyi (1)'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(TrAudioQcStore.key)!), {
      first: 'yeniden_uret',
      second: 'iyi',
    });

    // Yeniden açınca seçimler geri gelir.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qc-filter-regenerate')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('qc-row-$first')), findsOneWidget);
    expect(find.byKey(ValueKey('qc-row-$second')), findsNothing);

    // Seçili duruma yeniden dokunmak kaldırır.
    await tester.tap(find.byKey(ValueKey('qc-status-$first-yeniden_uret')));
    await tester.pumpAndSettle();
    expect(find.text('Bu filtrede kayıt yok.'), findsOneWidget);
  });

  for (final size in const [
    Size(360, 800),
    Size(800, 1280),
    Size(1280, 800),
    Size(800, 360),
    Size(1920, 1080),
  ]) {
    testWidgets('satırlar ve rapor sığar ($size)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final row = tester.getSize(
        find.byKey(ValueKey('qc-row-${kTrAudioQcEntries.first.id}')),
      );
      expect(row.height, greaterThan(100));
      expect(row.width, lessThanOrEqualTo(size.width));

      await tester.tap(find.byKey(const ValueKey('qc-export')));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('qc-report-text'))).height,
        greaterThan(0),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
