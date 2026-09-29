import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/elifba_lessons_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_card.dart';

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// The lesson cards ("Ders …"; not the Giriş).
final _dersCards = find.byWidgetPredicate(
  (w) => w is LessonCard && w.lesson.label.startsWith('Ders'),
);

/// Number of lesson cards on the first visible row of lessons.
Future<int> cardsPerRow(WidgetTester tester, Size size) async {
  setSize(tester, size);
  await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$size');
  // Below the Giriş section: bring the first lessons on screen.
  for (var i = 0; i < 10 && tester.widgetList(_dersCards).length < 2; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
  }
  final count = tester.widgetList(_dersCards).length;
  final tops = <double>{
    for (var i = 0; i < count; i++) tester.getTopLeft(_dersCards.at(i)).dy,
  };
  final first = tops.reduce((a, b) => a < b ? a : b);
  return [
    for (var i = 0; i < count; i++)
      if ((tester.getTopLeft(_dersCards.at(i)).dy - first).abs() < 1) i,
  ].length;
}

void main() {
  test('column rule', () {
    expect(ElifbaLessonsScreen.columnsFor(360), 1);
    expect(ElifbaLessonsScreen.columnsFor(393), 1);
    expect(ElifbaLessonsScreen.columnsFor(740), 2);
    expect(ElifbaLessonsScreen.columnsFor(852), 2);
    expect(ElifbaLessonsScreen.columnsFor(1100), 3);
  });

  final expected = <Size, int>{
    const Size(360, 800): 1, // phone, portrait
    const Size(393, 852): 1,
    const Size(852, 393): 2, // phone, landscape (reported: one huge card)
    const Size(740, 360): 2,
    const Size(800, 1280): 2, // tablet
    const Size(1280, 800): 3, // desktop
    const Size(1920, 1080): 3,
  };
  expected.forEach((size, columns) {
    testWidgets('$size shows $columns card(s) per row', (tester) async {
      expect(await cardsPerRow(tester, size), columns);
    });
  });

  testWidgets('every lesson is reachable, even when the last row is short', (
    tester,
  ) async {
    setSize(tester, const Size(852, 393));
    await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
    await tester.pumpAndSettle();
    final seen = <String>{};
    for (var i = 0; i < 40; i++) {
      for (final card in tester.widgetList<LessonCard>(find.byType(LessonCard))) {
        seen.add(card.lesson.label);
      }
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();
    }
    expect(seen.length, kElifbaIntroLessons.length + kElifbaLessons.length);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards in one row are the same height', (tester) async {
    setSize(tester, const Size(852, 393));
    await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10 && tester.widgetList(_dersCards).length < 2; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
    }
    final a = tester.getSize(_dersCards.at(0));
    final b = tester.getSize(_dersCards.at(1));
    expect(a.height, b.height);
  });
}
