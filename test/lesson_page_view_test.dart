// Pilot: Ders 3 (Üstün) kitabın sayfaları gibi açılır ("Sayfa", kitap
// s. 14-16, sayfa sayfa) ve "Grid" / "Tekli / Büyük" görünümlerine
// geçilebilir. Üç görünüm de aynı Lesson.letters listesini ve öğenin kitap
// sayfasındaki renk profilini kullanır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/helpers/colored_arabic_text.dart';
import 'package:kuran_okuma_rehberi/models/lesson_page_layout.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_page_view.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/single_letter_pager.dart';

import 'book_pages_test.dart' show RecordingAudio, app, setSize;

Finder _arabic(String text) =>
    find.byWidgetPredicate((w) => w is ColoredArabicText && w.text == text);

Future<void> _mode(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  test('sayfa düzeni dersin bütün öğelerini gösterir', () {
    for (final lesson in kElifbaLessons) {
      final layout = lesson.pageLayout;
      if (layout == null) continue;
      // Items taken in order never run past the lesson; every item is on
      // some page (in order or by reference).
      expect(layout.itemCount, lessThanOrEqualTo(lesson.letters.length),
          reason: lesson.id);
      expect(layout.shownItems,
          {for (var i = 0; i < lesson.letters.length; i++) i},
          reason: lesson.id);
    }
    final pages = kUstunPageLayout.pages;
    expect(pages.map((p) => p.bookPage), [14, 15, 16]);
    expect(pages.map((p) => p.type), [
      LessonPageType.lesson,
      LessonPageType.examples,
      LessonPageType.examples,
    ]);
    expect(pages.map((p) => p.itemCount), [28, 28, 36]);
    // Kitaptaki ilk/son öğeler.
    final items = kUstunLesson.letters;
    expect(items[1].isolatedForm, 'بَ'); // s. 14, sağdan 2.
    expect(items[28].isolatedForm, 'أَكَلَ'); // s. 15 ilk kelime
    expect(items[56].isolatedForm, 'عَمَلَ'); // s. 16 ilk kelime
    expect(items[91].isolatedForm, 'لَبَرَزَ'); // s. 16 son kelime
  });

  testWidgets('Üstün her açılışta Sayfa görünümünde, s. 14 ile açılır', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    final audio = RecordingAudio();
    await tester.pumpWidget(app(audio, kUstunLesson));
    await tester.pumpAndSettle();

    expect(find.byType(LessonPageView), findsOneWidget);
    for (final label in ['📖 Sayfa', '▦ Grid', '🔎 Tekli / Büyük']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Sayfa 14'), findsOneWidget);
    expect(find.text('ÜSTÜN'), findsOneWidget);
    expect(find.textContaining('Harekeler, Türkçe'), findsOneWidget);

    // İlk hücre kitaptaki gibi sağ üstte.
    final first = tester.getRect(find.byKey(const ValueKey('book-cell-0')));
    final second = tester.getRect(find.byKey(const ValueKey('book-cell-1')));
    expect(first.left, greaterThan(second.left));
    expect(first.top, second.top);
    expect(first.height, greaterThan(40));

    await tester.tap(find.byKey(const ValueKey('book-cell-1')));
    await tester.pump();
    expect(audio.played.single.isolatedForm, 'بَ');

    // Başka görünüme geçip dersi yeniden açınca yine Sayfa.
    await _mode(tester, '▦ Grid');
    expect(find.byType(AllLettersGrid), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(audio, kUstunLesson));
    await tester.pumpAndSettle();
    expect(find.byType(LessonPageView), findsOneWidget);
  });

  testWidgets('sayfalar arasında düğme, kaydırma ve klavye ile gezilir', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('page-next')));
    await tester.pumpAndSettle();
    expect(find.text('Sayfa 15'), findsOneWidget);
    expect(find.text('ÖRNEKLER'), findsOneWidget);
    expect(find.text('Örnekler · 2 / 3'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Sayfa 16'), findsOneWidget);
    final next = tester.widget<TextButton>(
      find.byKey(const ValueKey('page-next')),
    );
    expect(next.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('page-previous')));
    await tester.pumpAndSettle();
    expect(find.text('Sayfa 15'), findsOneWidget);

    // Tekli / Büyük, bulunulan sayfanın ilk öğesinden açılır.
    await _mode(tester, '🔎 Tekli / Büyük');
    expect(find.text('29 / 92'), findsOneWidget);
  });

  testWidgets('üç görünüm aynı öğeyi aynı sayfa renkleriyle gösterir', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1280));
    await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
    await tester.pumpAndSettle();
    final p14 = kUstunPageLayout.pages[0].colorProfile;
    final p15 = kUstunPageLayout.pages[1].colorProfile;

    ColoredArabicText widgetOf(String text) =>
        tester.widget<ColoredArabicText>(_arabic(text).first);

    expect(widgetOf('خَ').profile, p14); // Sayfa
    await _mode(tester, '▦ Grid');
    expect(widgetOf('خَ').profile, p14);
    expect(widgetOf('أَبَقَ').profile, p15);

    // Basılı tutunca Tekli / Büyük'te açılır.
    await _mode(tester, '📖 Sayfa');
    await tester.longPress(find.byKey(const ValueKey('book-cell-6')));
    await tester.pumpAndSettle();
    expect(find.byType(SingleLetterPager), findsOneWidget);
    expect(find.text('7 / 92'), findsOneWidget);
    expect(
      tester
          .widget<ColoredArabicText>(
            find.descendant(
              of: find.byType(SingleLetterPager),
              matching: _arabic('خَ'),
            ),
          )
          .profile,
      p14,
    );

    await tester.tap(find.byKey(const ValueKey('single-next')));
    await tester.pumpAndSettle();
    expect(find.text('8 / 92'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('9 / 92'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('single-previous')));
    await tester.pumpAndSettle();
    expect(find.text('8 / 92'), findsOneWidget);

    // Tekli'de s. 15'in öğesine gelip Sayfa'ya dönünce s. 15 açılır.
    for (var i = 0; i < 25; i++) {
      await tester.tap(find.byKey(const ValueKey('single-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('33 / 92'), findsOneWidget);
    await _mode(tester, '📖 Sayfa');
    expect(find.text('Sayfa 15'), findsOneWidget);
  });

  for (final size in const [
    Size(360, 800),
    Size(800, 1280),
    Size(1280, 800),
    Size(800, 360),
    Size(1920, 1080),
  ]) {
    testWidgets('$size: üç görünümde de taşma yok, hücreler okunabilir', (
      tester,
    ) async {
      setSize(tester, size);
      await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final cell = tester.getRect(find.byKey(const ValueKey('book-cell-0')));
      expect(cell.width, greaterThanOrEqualTo(64));
      expect(cell.height, greaterThanOrEqualTo(40));
      expect(cell.right, lessThanOrEqualTo(size.width));

      for (var page = 0; page < 2; page++) {
        await tester.tap(find.byKey(const ValueKey('page-next')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      final last = tester.getRect(find.byKey(const ValueKey('book-cell-56')));
      expect(last.width, greaterThanOrEqualTo(90));

      await _mode(tester, '▦ Grid');
      expect(tester.takeException(), isNull);
      await _mode(tester, '🔎 Tekli / Büyük');
      expect(tester.takeException(), isNull);
    });
  }
}
