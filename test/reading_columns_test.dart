import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letter_forms_data.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dualar_list_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/sureler_list_screen.dart';
import 'package:kuran_okuma_rehberi/widgets/reading_text_settings.dart';

const _scales = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8];

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Column count of the first grid on screen at each reading size.
Future<List<int>> columnsAcrossSizes(
  WidgetTester tester,
  Widget Function() build,
) async {
  final controller = ValueNotifier<double>(1);
  addTearDown(controller.dispose);
  final columns = <int>[];
  for (final scale in _scales) {
    controller.value = scale;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingTextScale(controller: controller, child: build()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'scale $scale');
    final delegate =
        (tester.widget<SliverGrid>(find.byType(SliverGrid).first).gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount);
    columns.add(delegate.crossAxisCount);
  }
  return columns;
}

/// Never jumps: from one reading size to the next at most one column goes.
void expectGradual(List<int> columns, {required String reason}) {
  for (var i = 1; i < columns.length; i++) {
    expect(columns[i], lessThanOrEqualTo(columns[i - 1]), reason: '$reason $columns');
    expect(
      columns[i - 1] - columns[i],
      lessThanOrEqualTo(1),
      reason: '$reason: dropped by more than one column at scale ${_scales[i]} $columns',
    );
  }
}

void main() {
  Widget letters(List<ArabicLetter> items) => AllLettersGrid(
    letters: items,
    onTapLetter: (_) {},
    onOpenLetter: (_) {},
  );

  for (final size in [
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(1024, 1366),
    const Size(390, 844),
    const Size(740, 360),
  ]) {
    testWidgets('Letter grid loses one column at a time as letters grow at $size', (
      tester,
    ) async {
      setSize(tester, size);
      final columns = await columnsAcrossSizes(
        tester,
        () => letters(kArabicLetters),
      );
      expectGradual(columns, reason: '$size');
      expect(columns.first, greaterThan(columns.last), reason: 'grows -> fewer columns');
      if (size.width >= 800 && size.width <= 1100) {
        // The reported case: a wide screen starts with many columns.
        expect(columns.first, greaterThanOrEqualTo(5));
        expect(columns.toSet().length, greaterThanOrEqualTo(3), reason: 'passes through in-between counts, $columns');
      }
    });
  }

  testWidgets('A phone still ends on a single column at the largest size', (
    tester,
  ) async {
    setSize(tester, const Size(390, 844));
    final columns = await columnsAcrossSizes(tester, () => letters(kArabicLetters));
    expect(columns.first, 2);
    expect(columns.last, 1);
  });

  testWidgets('Letters with başta/ortada/sonda forms thin out gradually too', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 900));
    final columns = await columnsAcrossSizes(
      tester,
      () => letters(kLetterFormLetters),
    );
    expectGradual(columns, reason: 'forms');
    expect(columns.first, 3);
    expect(columns.last, lessThan(3));
  });

  testWidgets('The smallest size never adds columns beyond normal', (tester) async {
    setSize(tester, const Size(800, 1280));
    final controller = ValueNotifier<double>(0.8);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingTextScale(
            controller: controller,
            child: letters(kArabicLetters),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final small =
        (tester.widget<SliverGrid>(find.byType(SliverGrid).first).gridDelegate
                as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount;
    controller.value = 1;
    await tester.pumpAndSettle();
    final normal =
        (tester.widget<SliverGrid>(find.byType(SliverGrid).first).gridDelegate
                as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount;
    expect(small, normal);
  });

  for (final entry in <(String, Widget Function())>[
    ('sure', () => const SurelerListScreen()),
    ('dua', () => const DualarListScreen()),
  ]) {
    testWidgets('The ${entry.$1} list thins out its columns gradually with the text size', (
      tester,
    ) async {
      setSize(tester, const Size(1280, 900));
      await tester.pumpWidget(MaterialApp(home: entry.$2()));
      await tester.pumpAndSettle();
      int columns() =>
          (tester.widget<GridView>(find.byType(GridView)).gridDelegate
                  as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount;

      final seen = <int>[columns()];
      await tester.tap(find.byTooltip('Okuma ayarları'));
      await tester.pumpAndSettle();
      for (var step = 0; step < 8; step++) {
        await tester.tap(find.byTooltip('Harfleri büyüt'));
        await tester.pumpAndSettle();
        seen.add(columns());
      }
      expect(tester.takeException(), isNull);
      expectGradual(seen, reason: entry.$1);
      expect(seen.first, greaterThan(seen.last));
      expect(seen.first, 4);
    });
  }
}
