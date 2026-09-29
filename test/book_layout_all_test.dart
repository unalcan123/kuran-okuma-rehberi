// Every lesson, every book page, in the three views, at phone / landscape /
// desktop sizes: nothing overflows, every page shows the book's page number,
// and every item of the lesson is on some page (the Sayfa, Grid and
// Tekli / Büyük views all read the same Lesson.letters).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/book_highlights.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/book_page.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_page_view.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/single_letter_pager.dart';

import 'book_pages_test.dart' show RecordingAudio, app, setSize;

void main() {
  test('every lesson has book pages; their numbers run 3-63 in order', () {
    var last = 0;
    for (final lesson in kElifbaAllLessons) {
      final layout = lesson.pageLayout;
      final pages = layout != null
          ? layout.pages.map((p) => p.bookPage).toList()
          : [
              for (final n in kBookPageNumbers[lesson.id]!.split('-'))
                int.parse(n),
            ];
      expect(pages, isNotEmpty, reason: lesson.id);
      for (final page in pages) {
        // Pages may be shared by neighbouring lessons (s. 39, 54, 55) but
        // never go back.
        expect(page, greaterThanOrEqualTo(last), reason: lesson.id);
        last = page;
      }
      if (layout != null) {
        expect(
          layout.shownItems,
          {for (var i = 0; i < lesson.letters.length; i++) i},
          reason: '${lesson.id}: every item on some page',
        );
      }
    }
    expect(last, 63);
  });

  test('every book page of s. 3-63 belongs to a lesson', () {
    final pages = <int>{};
    for (final lesson in kElifbaAllLessons) {
      final layout = lesson.pageLayout;
      if (layout != null) {
        pages.addAll(layout.pages.map((p) => p.bookPage));
      } else {
        final range = kBookPageNumbers[lesson.id]!.split('-').map(int.parse);
        for (var p = range.first; p <= range.last; p++) {
          pages.add(p);
        }
      }
    }
    expect(pages, {for (var p = 3; p <= 63; p++) p});
  });

  for (final size in const [Size(360, 800), Size(800, 360), Size(1280, 800)]) {
    testWidgets('$size: every lesson, every page, three views', (tester) async {
      setSize(tester, size);
      for (final lesson in kElifbaAllLessons) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(app(RecordingAudio(), lesson));
        await tester.pumpAndSettle();
        final pages = lesson.pageLayout?.pages;
        if (pages == null) {
          expect(find.byType(BookPage), findsOneWidget, reason: lesson.id);
          expect(find.byKey(const ValueKey('book-page-number')), findsOneWidget);
        } else {
          expect(find.byType(LessonPageView), findsOneWidget);
          for (var p = 0; p < pages.length; p++) {
            expect(
              find.text('Sayfa ${pages[p].bookPage}'),
              findsOneWidget,
              reason: '${lesson.id} page ${p + 1}',
            );
            expect(tester.takeException(), isNull,
                reason: '${lesson.id} s. ${pages[p].bookPage}');
            if (p < pages.length - 1) {
              await tester.tap(find.byKey(const ValueKey('page-next')));
              await tester.pumpAndSettle();
            }
          }
        }
        // The Giriş has pages only: no Grid / Tekli.
        if (lesson.letters.isEmpty) {
          expect(find.text('▦ Grid'), findsNothing);
          continue;
        }
        await tester.tap(find.text('▦ Grid'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${lesson.id} grid');
        await tester.tap(find.text('🔎 Tekli / Büyük'));
        await tester.pumpAndSettle();
        expect(find.byType(SingleLetterPager), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '${lesson.id} tekli');
      }
    });
  }
}
