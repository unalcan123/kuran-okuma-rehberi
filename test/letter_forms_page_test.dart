import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letter_forms_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/letter_forms_page.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/nav_arrow_button.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/single_letter_pager.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/letter_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Hasenat')
      ..addFont(rootBundle.load('assets/fonts/Hasenat.ttf'));
    await loader.load();
  });

  for (final width in [320.0, 390.0, 800.0, 1280.0, 1440.0]) {
    testWidgets('Large grid cards fit at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var plays = 0;
      int? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllLettersGrid(
              letters: kLetterFormLetters,
              onTapLetter: (_) => plays++,
              onOpenLetter: (index) => opened = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byType(LetterCard).first;
      expect(
        tester
            .getCenter(find.descendant(of: card, matching: find.text('Başta')))
            .dx,
        greaterThan(
          tester
              .getCenter(
                find.descendant(of: card, matching: find.text('Sonda')),
              )
              .dx,
        ),
      );
      await tester.tap(card);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(plays, 1);
      await tester.longPress(card);
      await tester.pumpAndSettle();
      expect(opened, 0);
      for (var i = 0; i < 20; i++) {
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(
        find
            .byWidgetPredicate(
              (widget) => widget is LetterCard && widget.letter.order == 29,
            )
            .hitTestable(),
        findsOneWidget,
      );
    });
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(1440, 900),
  ]) {
    testWidgets('All 29 forms fit $size and preserve RTL order', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var plays = 0;
      final captureKey = GlobalKey();
      for (final letter in kLetterFormLetters) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                toolbarHeight: 116,
                title: const Text('Harflerin Yazılışları'),
              ),
              body: RepaintBoundary(
                key: captureKey,
                child: LetterFormsPage(
                  letter: letter,
                  onPlay: () => plays++,
                  navigationControls: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NavArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed: () {},
                      ),
                      NavArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: letter.turkishName);
        if (size.width >= 350) {
          expect(
            tester.getCenter(find.text('Başta')).dx,
            greaterThan(tester.getCenter(find.text('Ortada')).dx),
          );
          expect(
            tester.getCenter(find.text('Ortada')).dx,
            greaterThan(tester.getCenter(find.text('Sonda')).dx),
          );
        }
        expect(find.text('Dinle').hitTestable(), findsOneWidget);
        for (final word in letter.positionExamples!) {
          expect(find.text(word).hitTestable(), findsWidgets);
        }
        if (letter.order == 2) {
          await tester.tap(find.text('Dinle'));
          await tester.tap(find.byKey(const ValueKey('forms-hero-glyph')));
          expect(plays, 2);
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              '.dart_tool/forms_preview_${size.width.toInt()}.png',
            );
            await file.writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    });
  }

  testWidgets('Pager preserves full pages, arrows, swipe and keyboard', (
    tester,
  ) async {
    var index = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleLetterPager(
            letters: kLetterFormLetters,
            initialIndex: index,
            onIndexChanged: (value) => index = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final page = tester.widget<PageView>(find.byType(PageView));
    expect(page.controller!.viewportFraction, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(index, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(index, 1);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded).hitTestable());
    await tester.pumpAndSettle();
    expect(index, 2);
    await tester.drag(find.byType(PageView), const Offset(700, 0));
    await tester.pumpAndSettle();
    expect(index, 3);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded).hitTestable());
    await tester.pumpAndSettle();
    expect(index, 2);
  });
}
