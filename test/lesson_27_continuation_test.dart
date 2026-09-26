import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/book_highlights.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/zamir_he_uzatilmasi_data.dart';
import 'package:kuran_okuma_rehberi/data/zamir_he_uzatma_med_data.dart';
import 'package:kuran_okuma_rehberi/data/zamir_he_uzatma_yok_data.dart';
import 'package:kuran_okuma_rehberi/data/zamir_he_uzatma_yok_cezimli_data.dart';
import 'package:kuran_okuma_rehberi/data/zamir_he_uzatma_yok_cezimli_seddeli_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/book_page.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_page_view.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/single_letter_pager.dart';

import 'book_pages_test.dart' show RecordingAudio, app, setSize;

// PDF pp. 54–55, visually verified row by row, right to left.
const expected = [
  'لَمْ يَرَهُٓ أَحَدٌ',
  'رَبُّهُٓ أَسْلِمْ',
  'مَالُهُٓ إِذَا',
  'عَهْدَهُٓ أَمْ',
  'وَلَهُٓ أُخْتٌ',
  'عِلْمِهِٓ إِلَّا',
  'وَإِنَّهُ عَلَى',
  'فَأُمُّهُ هَاوِيَةٌ',
  'مَالُهُ وَمَا كَسَبَ',
  'وَامْرَأَتُهُ حَمَّالَةَ',
  'وَلَمْ يَكُنْ لَهُ كُفُوًا',
  'حَوْلَهُ ذَهَبَ',
  'رَدَدْنَاهُ أَسْفَلَ',
  'أَنْزَلْنَاهُ فِى',
  'فِيهِ هُدًى',
  'بَنِيهِ وَيَعْقُوبُ',
  'عَقَلُوهُ وَهُمْ',
  'تَكْتُبُوهُ صَغِيرًا',
  'إِلَيْهِ رَاجِعُونَ',
  'تَلْقَوْهُ فَقَدْ',
  'فَلْيَصُمْهُ وَمَنْ',
  'مِنْهُ أَكْبَرُ',
  'يُدْخِلْهُ جَنَّاتٍ',
  'أَهْلَكَتْهُ وَمَا',
  'أَنَّهُ الْحَقُّ',
  'لَهُ الْمُلْكُ',
  'لَهُ اتَّقِ اللَّهَ',
  'هَذِهِ الْقَرْيَةِ',
  'لِقَوْمِهِ اسْتَعِينُوا',
  'بِهِ الْمَآءَ',
];

void main() {
  final lesson = kZamirHeUzatilmasiLesson;
  final layout = lesson.pageLayout!;

  test('Ders 27 contains five tables, with the correct PDF page boundary', () {
    expect(lesson.letters.map((w) => w.isolatedForm), expected);
    expect(layout.pages.map((p) => p.bookPage), [54, 55]);
    expect(layout.pages.map((p) => p.totalItems), [18, 12]);
    expect(layout.pages.map((p) => p.sections.length), [3, 2]);
    expect(layout.itemCount, 30);
    expect(layout.shownItems, {for (var i = 0; i < 30; i++) i});
    expect(layout.firstItemOf(1), 18);
    expect(layout.pageIndexOf(17), 0);
    expect(layout.pageIndexOf(18), 1);
    expect(layout.pageIndexOf(29), 1);
    final intros = layout.pages
        .expand((p) => p.sections)
        .expand((s) => s.intro)
        .join('\n');
    expect('Örnekler:'.allMatches(intros), hasLength(5));
    for (final phrase in [
      '4 hareke',
      '2 hareke',
      'uzatma harflerinden biri',
      'cezimli herhangi bir harf',
      'cezimli veya şeddeli',
    ]) {
      expect(intros, contains(phrase));
    }
    expect(intros, isNot(contains('UZUN MED')));
  });

  test('merged items retain their existing identity, audio and color rules', () {
    final continuation = [
      ...kZamirHeUzatmaYokWords,
      ...kZamirHeUzatmaYokCezimliWords,
      ...kZamirHeUzatmaYokCezimliSeddeliWords,
    ];
    for (var i = 0; i < 18; i++) {
      expect(lesson.letters[12 + i], same(continuation[i]));
    }
    for (var i = 0; i < 30; i++) {
      final oldProfile = bookHighlightProfile(lesson.id, lesson.letters[i], i)!;
      final profile = layout.colorProfileOf(i);
      expect(profile.clusterBodies, oldProfile.clusterBodies);
      expect(profile.clusterMarks, oldProfile.clusterMarks);
      if (i < 12) {
        expect(
          lesson.letters[i].audioAsset,
          'audio/elifba/ders_27_zamir_he_uzatilmasi/${'${i + 1}'.padLeft(2, '0')}_kelime.mp3',
        );
      }
    }
  });

  test(
    'merged menu entries are removed and Ders 28 starts on shared page 55',
    () {
      final index = kElifbaLessons.indexOf(lesson);
      expect(kElifbaLessons[index + 1], same(kZamirHeUzatmaMedLesson));
      for (final id in [
        'zamir-he-uzatma-yok',
        'zamir-he-uzatma-yok-cezimli',
        'zamir-he-uzatma-yok-cezimli-seddeli',
      ]) {
        expect(kElifbaLessons.any((l) => l.id == id), isFalse);
      }
      expect(kBookPageNumbers[kZamirHeUzatmaMedLesson.id], '55');
      expect(
        kZamirHeUzatmaMedLesson.letters.first.isolatedForm,
        'اَلْمَلٓئِكَةُ',
      );
      expect(kZamirHeUzatmaMedLesson.letters, hasLength(6));
    },
  );

  for (final size in const [Size(360, 800), Size(852, 393), Size(1280, 1000)]) {
    testWidgets('Ders 27 all 30 cells and page transition at $size', (
      tester,
    ) async {
      setSize(tester, size);
      final audio = RecordingAudio();
      await tester.pumpWidget(app(audio, lesson));
      await tester.pumpAndSettle();
      expect(find.byType(LessonPageView), findsOneWidget);
      expect(find.text('Sayfa 54'), findsOneWidget);
      for (var i = 0; i < 30; i++) {
        if (i == 18) {
          await tester.tap(find.byKey(const ValueKey('page-next')));
          await tester.pumpAndSettle();
          expect(find.text('Sayfa 55'), findsOneWidget);
        }
        final cell = find.byKey(ValueKey('book-cell-$i'));
        await tester.ensureVisible(cell);
        await tester.pumpAndSettle();
        await tester.tap(cell);
        await tester.pump();
        expect(audio.played.last, same(lesson.letters[i]));
        expect(tester.takeException(), isNull);
      }
      expect(audio.played, lesson.letters);
      expect(find.text('UZUN MED İŞARETİ'), findsNothing);
      final next = tester.widget<TextButton>(
        find.byKey(const ValueKey('page-next')),
      );
      expect(next.onPressed, isNull);
      await tester.longPress(find.byKey(const ValueKey('book-cell-29')));
      await tester.pumpAndSettle();
      expect(find.byType(SingleLetterPager), findsOneWidget);
      expect(find.text('30 / 30'), findsOneWidget);
    });
  }

  testWidgets(
    'Grid and Single share all 30 items and cross 54 to 55 in order',
    (tester) async {
      setSize(tester, const Size(1280, 1000));
      await tester.pumpWidget(app(RecordingAudio(), lesson));
      await tester.pumpAndSettle();
      await tester.tap(find.text('▦ Grid'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AllLettersGrid>(find.byType(AllLettersGrid)).letters,
        same(lesson.letters),
      );
      await tester.tap(find.text('🔎 Tekli / Büyük'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SingleLetterPager>(find.byType(SingleLetterPager))
            .letters,
        same(lesson.letters),
      );
      for (var i = 0; i < 30; i++) {
        expect(find.text('${i + 1} / 30'), findsOneWidget);
        if (i < 29) {
          await tester.tap(find.byKey(const ValueKey('single-next')));
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.text('📖 Sayfa'));
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 55'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(RecordingAudio(), kZamirHeUzatmaMedLesson));
      await tester.pumpAndSettle();
      expect(find.byType(BookPage), findsOneWidget);
      expect(find.text('UZUN MED İŞARETİ'), findsOneWidget);
      expect(
        find.textContaining('Tecvid derslerinde', findRichText: true),
        findsOneWidget,
      );
    },
  );
}
