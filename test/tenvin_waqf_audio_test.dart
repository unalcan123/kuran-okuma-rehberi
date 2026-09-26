import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/tenvin_iki_ustun_data.dart';
import 'package:kuran_okuma_rehberi/data/uzatma_elif_data.dart';
import 'package:kuran_okuma_rehberi/helpers/colored_arabic_text.dart';

import 'book_pages_test.dart' show RecordingAudio, app, setSize;

void main() {
  final section =
      kTenvinIkiUstunPageLayout.pages
          .singleWhere((p) => p.bookPage == 41)
          .sections
          .single;
  // Transcribed from PDF pp. 32 and 41, row by row, right to left.
  const expected = [
    'ءَا',
    'بَا',
    'تَا',
    'ثَا',
    'جَا',
    'حَا',
    'خَا',
    'دَا',
    'ذَا',
    'رَا',
    'زَا',
    'سَا',
    'شَا',
    'صَا',
    'ضَا',
    'طَا',
    'ظَا',
    'عَا',
    'غَا',
    'فَا',
    'قَا',
    'كَا',
    'لَا',
    'مَا',
    'نَا',
    'وَا',
    'هَا',
    'يَا',
  ];

  test('page 41 reuses all 28 verified page 32 recordings in PDF order', () {
    expect(section.refs, List.generate(28, (i) => i));
    expect(section.derivedAudioItems, hasLength(expected.length));
    expect(kUzatmaElifLetters, hasLength(expected.length));
    for (var i = 0; i < expected.length; i++) {
      final passing = kTenvinIkiUstunLesson.letters[section.refs![i]];
      final source = kUzatmaElifLetters[i];
      final stopped = section.derivedAudioItems![i];
      expect(section.derived!.apply(passing.isolatedForm), expected[i]);
      expect(source.isolatedForm.replaceAll('ـ', ''), expected[i]);
      expect(identical(stopped, source), isTrue);
      expect(stopped.audioAsset, isNotEmpty);
      final number = '${i + 1}'.padLeft(2, '0');
      expect(
        stopped.audioAsset,
        'audio/elifba/ders_11_uzatma_elif/${number}_uzatma.mp3',
      );
      expect(
        passing.audioAsset,
        'audio/elifba/ders_20_tenvin_iki_ustun/${number}_tenvin.mp3',
      );
      for (final item in [stopped, passing]) {
        final file = File('assets/${item.audioAsset}');
        expect(file.existsSync(), isTrue, reason: file.path);
        expect(file.lengthSync(), greaterThan(0));
      }
    }
  });

  testWidgets(
    'every stopped and passing cell uses the central audio callback',
    (tester) async {
      setSize(tester, const Size(1280, 2400));
      final audio = RecordingAudio();
      await tester.pumpWidget(app(audio, kTenvinIkiUstunLesson));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('page-next')));
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 41'), findsOneWidget);
      for (var i = 0; i < expected.length; i++) {
        final source = kUzatmaElifLetters[i];
        final stopped = find.byKey(
          ValueKey('book-derived-cell-${source.audioAsset}'),
        );
        await tester.ensureVisible(stopped);
        await tester.tap(stopped);
        await tester.pump();
        expect(audio.played.last, same(source));
        expect(
          find.descendant(
            of: stopped,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is ColoredArabicText &&
                  w.text == expected[i] &&
                  w.profile == section.derivedProfile,
            ),
          ),
          findsOneWidget,
        );
        final passing = find.byKey(ValueKey('book-cell-$i'));
        await tester.tap(passing);
        await tester.pump();
        expect(audio.played.last, same(kTenvinIkiUstunLetters[i]));
      }
      expect(audio.played, hasLength(56));
    },
  );
}
