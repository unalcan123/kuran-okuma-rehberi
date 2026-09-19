import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/silent_audio.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/letter_forms_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_view_mode.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_one_book.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/single_letter_pager.dart';

void main() {
  testWidgets(
    'Book is exclusive to lesson one and existing modes remain available',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(740, 360);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        withAudio(
          MaterialApp(home: LessonLettersScreen(lesson: kElifbaLessons.first)),
        ),
      );
      expect(find.byType(AllLettersGrid), findsOneWidget);
      final lessonScroll = find.descendant(
        of: find.byType(AllLettersGrid),
        matching: find.byType(CustomScrollView),
      );
      final header = find.byTooltip('Görünüm seç');
      final headerTop = tester.getTopLeft(header).dy;
      await tester.drag(lessonScroll, const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(header, findsNothing);
      await tester.drag(lessonScroll, const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(header).dy, closeTo(headerTop, 1));
      expect(tester.widget<AppBar>(find.byType(AppBar)).bottom, isNull);
      await tester.tap(find.byTooltip('Görünüm seç'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<LessonViewMode>, 'Kitap Modu'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LessonOneBook), findsOneWidget);
      await tester.tap(find.byTooltip('Görünüm seç'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<LessonViewMode>, 'Tek Harf'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SingleLetterPager), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(tester.widget<AppBar>(find.byType(AppBar)).bottom, isNull);
      expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 48);
      await tester.tap(find.byTooltip('Okuma ayarları'));
      await tester.pumpAndSettle();
      expect(find.text('Meali göster'), findsNothing);
      await tester.tap(find.byTooltip('Harfleri büyüt'));
      await tester.pumpAndSettle();
      expect(find.text('%110'), findsOneWidget);
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(SingleLetterPager)),
        ).scale(100),
        closeTo(110, 0.01),
      );
      await tester.tap(find.text('Varsayılan boyut'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(Slider))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Görünüm seç'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<LessonViewMode>,
          'Tüm Harfler',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AllLettersGrid), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        withAudio(
          MaterialApp(
            home: LessonLettersScreen(lesson: kHarflerinYazilislariLesson),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Görünüm seç'));
      await tester.pumpAndSettle();
      expect(find.text('Kitap Modu'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Four-column book fits phone, tablet and landscape; taps return original data',
    (tester) async {
      final font = FontLoader('Hasenat')
        ..addFont(rootBundle.load('assets/fonts/Hasenat.ttf'));
      await font.load();
      // Optional local font for readable QA captures; layout tests also run without it.
      final uiFont = File('C:/Windows/Fonts/segoeui.ttf');
      if (uiFont.existsSync()) {
        final loader = FontLoader('BookPreviewUI')..addFont(
          Future.value(ByteData.sublistView(uiFont.readAsBytesSync())),
        );
        await loader.load();
      }
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [
        const Size(320, 700),
        const Size(390, 844),
        const Size(800, 1280),
        const Size(1280, 800),
      ]) {
        tester.view.physicalSize = size;
        final capture = GlobalKey();
        Object? selected;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'BookPreviewUI'),
            home: Scaffold(
              body: RepaintBoundary(
                key: capture,
                child: LessonOneBook(
                  letters: kArabicLetters,
                  onTapLetter: (letter) => selected = letter,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final grid = tester.widget<GridView>(find.byType(GridView));
        expect(
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          4,
        );
        final first = find.byKey(const ValueKey('book-letter-1'));
        final second = find.byKey(const ValueKey('book-letter-2'));
        expect(
          tester.getCenter(first).dx,
          greaterThan(tester.getCenter(second).dx),
        );
        await tester.tap(second);
        expect(identical(selected, kArabicLetters[1]), isTrue);
        await tester.pumpAndSettle();
        if (size.width == 390 || size.width == 800) {
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
              'build/previews/lesson1-book-${size.width.toInt()}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
          });
          image!.dispose();
        }
        await tester.ensureVisible(
          find.byKey(const ValueKey('book-letter-28')),
        );
        await tester.tap(find.byKey(const ValueKey('book-letter-28')));
        expect(identical(selected, kArabicLetters.last), isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
