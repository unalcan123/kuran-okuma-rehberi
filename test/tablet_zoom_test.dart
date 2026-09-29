// Tablet ve masaüstünde ders/sure/dua ekranlarının gövdesi ~%20 büyük
// (TabletZoom); ders içindeki Arapça toplam ~%30 büyük (ArabicScale).
// Telefonda (dikey ya da yatay) hiçbir şey değişmez.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/helpers/colored_arabic_text.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/elifba_lessons_screen.dart';
import 'package:kuran_okuma_rehberi/widgets/arabic_scale.dart';
import 'package:kuran_okuma_rehberi/widgets/tablet_zoom.dart';

import 'book_pages_test.dart' show RecordingAudio, app, setSize;

void main() {
  test('yalnız tablet ve masaüstü büyür', () {
    for (final size in const [Size(360, 800), Size(393, 852), Size(800, 360)]) {
      expect(TabletZoom.zoomFor(size), 1, reason: '$size');
      expect(ArabicScale.lessonFactorFor(size), 1, reason: '$size');
    }
    for (final size in const [
      Size(800, 1280),
      Size(1280, 800),
      Size(1920, 1080),
    ]) {
      expect(TabletZoom.zoomFor(size), 1.2, reason: '$size');
      expect(
        TabletZoom.zoomFor(size) * ArabicScale.lessonFactorFor(size),
        closeTo(1.3, 1e-9),
        reason: '$size',
      );
    }
  });

  testWidgets('telefonda ders listesi aynen, masaüstünde %20 büyük', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
    await tester.pumpAndSettle();
    final phone = find.byKey(
      const ValueKey('lesson-card-giris-harflerin-cikis-yerleri'),
    );
    // Telefonda gerçek boyut = düzen boyutu (büyütme yok).
    expect(tester.getRect(phone).size, tester.getSize(phone));

    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
    await tester.pumpAndSettle();
    final desk = find.byKey(
      const ValueKey('lesson-card-giris-harflerin-cikis-yerleri'),
    );
    final onScreen = tester.getRect(desk).width;
    expect(onScreen, closeTo(tester.getSize(desk).width * 1.2, 0.5));
    // Eski düzende masaüstü kartı ~340 px idi: en az %15 büyük.
    expect(onScreen, greaterThan(340 * 1.15));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ders Arapçası: telefonda aynı, masaüstünde toplam %30', (
    tester,
  ) async {
    double glyphFont(WidgetTester tester) {
      final cell = find.descendant(
        of: find.byKey(const ValueKey('book-cell-1')),
        matching: find.byType(ColoredArabicText),
      );
      final text = find.descendant(of: cell, matching: find.byType(Text));
      final style = tester.widget<Text>(text.first).style!;
      return style.fontSize!;
    }

    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
    await tester.pumpAndSettle();
    expect(
      ArabicScale.of(tester.element(find.byKey(const ValueKey('book-cell-1')))),
      1,
    );
    final phoneFont = glyphFont(tester);
    expect(phoneFont, greaterThan(20));

    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
    await tester.pumpAndSettle();
    expect(
      ArabicScale.of(tester.element(find.byKey(const ValueKey('book-cell-1')))),
      closeTo(1.3 / 1.2, 1e-9),
    );
    expect(tester.takeException(), isNull);
  });
}
