import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letter_forms_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/letter_forms_table.dart';

void main() {
  testWidgets(
    'Book table fits phones and tablets and plays the selected letter',
    (tester) async {
      final font = FontLoader('Hasenat')
        ..addFont(rootBundle.load('assets/fonts/Hasenat.ttf'));
      await font.load();
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.devicePixelRatio = 1;
      for (final width in [320.0, 390.0, 800.0]) {
        tester.view.physicalSize = Size(width, 900);
        int? selected;
        final capture = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: capture,
                child: LetterFormsTable(
                  letters: kLetterFormLetters,
                  onTapLetter: (letter) => selected = letter.order,
                  onOpenLetter: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('HARF'), findsOneWidget);
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Elif harfini dinle',
          ),
        );
        expect(selected, 1);
        await tester.pumpAndSettle();
        if (width == 390) {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await tester.runAsync(() => boundary.toImage());
          final data = await tester.runAsync(
            () => image!.toByteData(format: ui.ImageByteFormat.png),
          );
          await tester.runAsync(() async {
            await Directory('build/previews').create(recursive: true);
            await File(
              'build/previews/lesson2-table.png',
            ).writeAsBytes(data!.buffer.asUint8List());
          });
          image!.dispose();
        }
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
