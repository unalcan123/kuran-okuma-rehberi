import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/lesson_info_data.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/models/lesson.dart';
import 'package:kuran_okuma_rehberi/models/word_highlight.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/book_page.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/widgets/waqf_examples_table.dart';
import 'package:kuran_okuma_rehberi/widgets/word_grid_table.dart';
import 'package:provider/provider.dart';

import 'support/silent_audio.dart';

/// Silent audio that remembers what was asked to play.
class RecordingAudio extends SilentAudio {
  final played = <ArabicLetter>[];

  @override
  Future<void> playLetter(ArabicLetter letter) async => played.add(letter);
}

Widget app(AudioService audio, Lesson lesson) =>
    ChangeNotifierProvider<AudioService>.value(
      value: audio,
      child: MaterialApp(home: LessonLettersScreen(lesson: lesson)),
    );

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> scrollToEnd(WidgetTester tester, Finder scroll) async {
  for (var i = 0; i < 16; i++) {
    await tester.drag(scroll, const Offset(0, -400));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// The lessons that open as a book page (Ders 23-33):
/// id, heading, a phrase from the text, "Durulduğunda/Geçildiğinde" tables,
/// word grids.
const _pages = <(String, String, String, int, int)>[
  ('el-takisi-okunan', 'ELİF - LÂM', 'Hemze dendiğini unutmayalım', 0, 1),
  ('el-takisi-okunmayan', 'ELİF - LÂM', 'Sonraki harf mutlaka şeddeli okunur', 0, 1),
  ('el-takisi-hemze', 'EL TAKISI’NDAKİ HEMZE', 'olarak tanımlamak daha doğrudur', 0, 2),
  ('el-takisi-hemze-vasil', 'OKUNMAYAN HEMZE', 'vasıl işareti', 0, 2),
  ('zamir-he-uzatilmasi', 'UZATILMASI', 'Hangi Durumlarda Uzatılır', 0, 2),
  ('zamir-he-uzatma-med', 'UZUN MED İŞARETİ', 'Tecvid derslerinde', 0, 1),
  ('zamir-he-uzatma-yok', 'UZATILMAMASI', 'Hangi Durumlarda Uzatılmaz', 0, 1),
  ('zamir-he-uzatma-yok-cezimli', 'UZATILMAMASI', 'cezimli herhangi bir harf', 0, 1),
  ('zamir-he-uzatma-yok-cezimli-seddeli', 'UZATILMAMASI', 'şeddeli bir harfe', 0, 1),
  ('kapali-te', 'KAPALI “TE”', 'Örneklerle uygulamayı görelim', 1, 0),
  ('kelime-sonu-duraklar', 'HAREKELİ HARFTE', 'Tenvinlilerde ise uygulama şöyledir', 5, 0),
];

Lesson lessonOf(String id) => kElifbaLessons.firstWhere((l) => l.id == id);

/// All the tables on the page, in order.
Finder get allTables => find.byWidgetPredicate(
  (w) => w is WaqfExamplesTable || w is WordGridTable,
);

void main() {
  const sizes = [
    Size(360, 800), // phone, portrait
    Size(852, 393), // phone, landscape
    Size(740, 360),
    Size(800, 1280), // tablet
    Size(1280, 800), // desktop
  ];

  for (final (id, heading, phrase, stopTables, gridTables) in _pages) {
    final lesson = lessonOf(id);
    final tables = stopTables + gridTables;

    for (final size in sizes) {
      testWidgets('${lesson.label} opens as the book page and fits at $size', (
        tester,
      ) async {
        setSize(tester, size);
        await tester.pumpWidget(app(SilentAudio(), lesson));
        await tester.pumpAndSettle();

        expect(find.byType(BookPage), findsOneWidget);
        expect(find.text(heading), findsOneWidget);
        // The page already shows the explanation, so no ⓘ button.
        expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
        expect(find.byType(WaqfExamplesTable), findsNWidgets(stopTables));
        expect(find.byType(WordGridTable), findsNWidgets(gridTables));
        expect(find.textContaining(phrase, findRichText: true), findsOneWidget);

        // Every table really takes room, and so does every word in it (a
        // table whose rows collapse to zero height still "exists").
        for (var i = 0; i < tables; i++) {
          final table = allTables.at(i);
          expect(tester.getSize(table).height, greaterThan(50), reason: 'table $i');
          expect(tester.getSize(table).width, greaterThan(150), reason: 'table $i');
          final cells = find.descendant(of: table, matching: find.byType(InkWell));
          expect(cells, findsWidgets);
          for (final cell in cells.evaluate()) {
            final box = cell.renderObject! as RenderBox;
            expect(box.size.height, greaterThan(30), reason: 'word cell in table $i');
            expect(box.size.width, greaterThan(40), reason: 'word cell in table $i');
          }
        }

        await scrollToEnd(
          tester,
          find.descendant(
            of: find.byType(BookPage),
            matching: find.byType(SingleChildScrollView),
          ),
        );
        expect(
          tester.getRect(allTables.last).bottom,
          lessThanOrEqualTo(size.height + 1),
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final size in const [Size(360, 800), Size(852, 393), Size(1280, 800)]) {
      testWidgets('${lesson.label}: the ⓘ dialog (other view) scrolls and fits at $size', (
        tester,
      ) async {
        setSize(tester, size);
        await tester.pumpWidget(app(SilentAudio(), lesson));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Görünüm seç'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tüm Harfler'));
        await tester.pumpAndSettle();
        expect(find.byType(BookPage), findsNothing);

        await tester.tap(find.byIcon(Icons.info_outline_rounded));
        await tester.pumpAndSettle();
        expect(allTables, findsNWidgets(tables));

        final dialog = tester.getRect(find.byType(Dialog));
        expect(dialog.top, greaterThanOrEqualTo(0));
        expect(dialog.bottom, lessThanOrEqualTo(size.height));
        expect(find.text('Kapat').hitTestable(), findsOneWidget);
        await scrollToEnd(
          tester,
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(SingleChildScrollView),
          ),
        );
        expect(tester.getRect(allTables.last).bottom, lessThanOrEqualTo(dialog.bottom + 1));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Kapat'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);

        // The lesson remembers the chosen view for the rest of the session;
        // put it back so the next test starts on the book page.
        await tester.tap(find.byTooltip('Görünüm seç'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kitap Modu'));
        await tester.pumpAndSettle();
        expect(find.byType(BookPage), findsOneWidget);
      });
    }

    testWidgets('${lesson.label}: tapping a word plays exactly that recording', (
      tester,
    ) async {
      setSize(tester, const Size(852, 393));
      final audio = RecordingAudio();
      await tester.pumpWidget(app(audio, lesson));
      await tester.pumpAndSettle();

      final first = allTables.first;
      final cells = find.descendant(of: first, matching: find.byType(InkWell));
      await tester.ensureVisible(cells.at(0));
      await tester.pumpAndSettle();
      await tester.tap(cells.at(0));
      await tester.pump();

      final table = tester.widget(first);
      final expected = table is WaqfExamplesTable
          ? table.examples.first.stopLetter // left column = stopping
          : (table as WordGridTable).words.first; // first word at the right
      expect(audio.played, [expected]);
      expect(expected.audioAsset, isNotEmpty);
    });

    if (gridTables > 0) {
      testWidgets('${lesson.label}: the grids show every word of the lesson exactly once, '
          'each with a red part', (tester) async {
        setSize(tester, const Size(1280, 800));
        await tester.pumpWidget(app(SilentAudio(), lesson));
        await tester.pumpAndSettle();

        final shown = <ArabicLetter>[];
        for (final grid in tester.widgetList<WordGridTable>(find.byType(WordGridTable))) {
          shown.addAll(grid.words);
          for (final w in grid.words) {
            if (grid.highlight == WordHighlight.none) continue;
            expect(
              splitForHighlight(w.isolatedForm, grid.highlight).$2,
              isNotEmpty,
              reason: '${lesson.label}: ${w.isolatedForm} has nothing to mark red',
            );
          }
        }
        expect(shown.length, lesson.letters.length);
        expect({for (final w in shown) w.audioAsset}, {for (final w in lesson.letters) w.audioAsset});
      });
    }

    test('${lesson.label}: the info entry and the heading are registered', () {
      expect(kLessonInfo[id], isNotNull);
      expect(kBookPageHeadings.containsKey(id), isTrue);
    });
  }

  test('Ders 33 skips only the question its heading already asks', () {
    final info = kLessonInfo['kelime-sonu-duraklar']!;
    expect(info.firstSpanIsBookHeading, isTrue);
    expect(
      (info.body.first as TextSpan).text,
      startsWith('Kelime sonundaki harekeli harfte nasıl durulur?'),
    );
    for (final (id, _, _, _, _) in _pages.where((p) => p.$1 != 'kelime-sonu-duraklar')) {
      expect(kLessonInfo[id]!.firstSpanIsBookHeading, isFalse, reason: id);
    }
  });

  group('letters of a word', () {
    test('marks stay with their letter', () {
      expect(letterClusters('اَلْبَيْتُ'), ['اَ', 'لْ', 'بَ', 'يْ', 'تُ']);
      expect(letterClusters('مَا لُهُ').length, 5, reason: 'a space is a letter of its own');
    });

    test('the rules pick the letter the book prints red', () {
      String red(String w, WordHighlight h) => splitForHighlight(w, h).$2;
      expect(red('اَلْبَيْتُ', WordHighlight.elLam), 'لْ');
      expect(red('مَا الْقَارِعَةُ', WordHighlight.elAlif), 'ا');
      expect(splitForHighlight('مَا الْقَارِعَةُ', WordHighlight.elAlif).$1, 'مَا ');
      expect(red('وَٱللّٰهُ', WordHighlight.vasl), 'ٱ');
      expect(red('عَهْدَهُٓ أَمْ', WordHighlight.he), 'هُٓ', reason: 'the He before the space, not the one in عَهْد');
      expect(red('يٰسٓ', WordHighlight.med), 'سٓ');
      expect(red('كتاب', WordHighlight.he), '');
      // before + red + after is always the whole word.
      for (final h in WordHighlight.values) {
        final (a, b, c) = splitForHighlight('لَهُ اتَّقِ اللَّهَ', h);
        expect(a + b + c, 'لَهُ اتَّقِ اللَّهَ');
      }
    });
  });

  testWidgets('a grid uses fewer columns on a narrow screen so words stay big', (
    tester,
  ) async {
    final words = lessonOf('el-takisi-okunan').letters;
    Future<int> columnsAt(double width) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AudioService>.value(
          value: SilentAudio(),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: WordGridTable(words: words, columns: 4, minCellWidth: 90),
                ),
              ),
            ),
          ),
        ),
      );
      final table = tester.widget<Table>(find.byType(Table));
      return table.children.first.children.length;
    }

    expect(await columnsAt(700), 4);
    expect(await columnsAt(300), 3);
    expect(await columnsAt(170), 1);
  });
}
