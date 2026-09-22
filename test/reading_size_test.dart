import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/letter_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/silent_audio.dart';
import 'package:kuran_okuma_rehberi/widgets/reading_text_settings.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/data/letter_forms_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/letter_forms_page.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/letter_forms_table.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_one_book.dart';

void main() {
  testWidgets('Enlarged long words remain entirely inside their cards', (
    tester,
  ) async {
    final font = FontLoader('Hasenat')
      ..addFont(rootBundle.load('assets/fonts/Hasenat.ttf'));
    await font.load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ValueNotifier<double>(1.8);
    addTearDown(controller.dispose);
    for (final width in [280.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingTextScale(
              controller: controller,
              child: AllLettersGrid(
                letters: const [
                  ArabicLetter(order: 1, isolatedForm: 'لِلْمَلَائِكَةِ'),
                ],
                onTapLetter: (_) {},
                onOpenLetter: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(LetterCard));
      // Hareke/kalın harf renklendirmesi olan kelimeler için ArabicGlyph
      // içeride birkaç RichText (taban + renk katmanları) üretebilir; hepsi
      // aynı boyut/konumdadır, ilki bu ölçüm için yeterli.
      final text = tester.renderObject<RenderBox>(
        find
            .descendant(
              of: find.byType(LetterCard),
              matching: find.byType(RichText),
            )
            .first,
      );
      final topLeft = text.localToGlobal(Offset.zero);
      final bottomRight = text.localToGlobal(
        text.size.bottomRight(Offset.zero),
      );
      expect(topLeft.dx, greaterThanOrEqualTo(card.left));
      expect(bottomRight.dx, lessThanOrEqualTo(card.right));
      expect(topLeft.dy, greaterThanOrEqualTo(card.top));
      expect(bottomRight.dy, lessThanOrEqualTo(card.bottom));
      expect(
        find.descendant(
          of: find.byType(LetterCard),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Lesson layouts fit at both reading size limits', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ValueNotifier<double>(1);
    addTearDown(controller.dispose);
    for (final size in [const Size(320, 700), const Size(740, 360)]) {
      tester.view.physicalSize = size;
      for (final factor in [0.8, 1.8]) {
        controller.value = factor;
        for (final child in <Widget>[
          LetterFormsPage(letter: kLetterFormLetters[26], onPlay: () {}),
          LetterFormsTable(
            letters: kLetterFormLetters,
            onTapLetter: (_) {},
            onOpenLetter: (_) {},
          ),
          LessonOneBook(letters: kArabicLetters, onTapLetter: (_) {}),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ReadingTextScale(controller: controller, child: child),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${child.runtimeType} at $size, scale $factor',
          );
        }
      }
    }
  });
  testWidgets('Each lesson owns its reading size', (tester) async {
    await tester.pumpWidget(
      withAudio(
        MaterialApp(home: LessonLettersScreen(lesson: kElifbaLessons.first)),
      ),
    );
    final first =
        tester
            .widget<ReadingTextSettingsButton>(
              find.byType(ReadingTextSettingsButton),
            )
            .controller;
    first.value = 1.8;
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(LessonLettersScreen));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonLettersScreen(lesson: kElifbaLessons.last),
      ),
    );
    await tester.pumpAndSettle();
    final second =
        tester
            .widget<ReadingTextSettingsButton>(
              find.byType(ReadingTextSettingsButton),
            )
            .controller;
    expect(second.value, 1);
    expect(identical(first, second), isFalse);
    second.value = 0.8;
    expect(first.value, 1.8);
    Navigator.of(tester.element(find.byType(LessonLettersScreen))).pop();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ReadingTextSettingsButton>(
            find.byType(ReadingTextSettingsButton),
          )
          .controller
          .value,
      1.8,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fitted letters visibly grow and shrink', (tester) async {
    final controller = ValueNotifier<double>(1);
    addTearDown(controller.dispose);
    const glyphKey = ValueKey('glyph');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ReadingTextScale(
              controller: controller,
              child: const SizedBox(
                width: 160,
                height: 180,
                child: ReadingFittedBox(
                  child: Text(
                    'هـ',
                    key: glyphKey,
                    style: TextStyle(fontSize: 440),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    double visualWidth() {
      final box = tester.renderObject<RenderBox>(find.byKey(glyphKey));
      return (box.localToGlobal(Offset(box.size.width, 0)) -
              box.localToGlobal(Offset.zero))
          .distance;
    }

    final normal = visualWidth();
    controller.value = 1.8;
    await tester.pumpAndSettle();
    expect(visualWidth(), closeTo(normal * 1.8, 0.1));
    controller.value = 0.8;
    await tester.pumpAndSettle();
    expect(visualWidth(), closeTo(normal * 0.8, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enlarged portrait lessons use one column', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ValueNotifier<double>(1.8);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingTextScale(
            controller: controller,
            child: AllLettersGrid(
              letters: kArabicLetters,
              onTapLetter: (_) {},
              onOpenLetter: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .mainAxisExtent,
      lessThanOrEqualTo(200),
    );
    expect(tester.takeException(), isNull);
  });
}
