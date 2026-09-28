// Ders ekranının iki yanındaki süs çocuklar: yalnız içeriğin dışındaki boş
// kenarda durur, içeriğin üstüne asla binmez; masaüstünde iki, tablette bir
// (küçük), telefonda hiç; Tekli / Büyük'te yalnız çok geniş ekranda. Görseli olmayan çocuk
// çizilmez.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_page_view.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/letter_page.dart';
import 'package:kuran_okuma_rehberi/widgets/lesson_grid_background.dart';
import 'package:kuran_okuma_rehberi/widgets/lesson_kids_decoration.dart';

import 'book_pages_test.dart' show RecordingAudio, app, setSize;

const _left = ValueKey('lesson-kid-left');
const _right = ValueKey('lesson-kid-right');

Set<String> get _allKids => {
  for (final (l, r) in LessonKids.pairs) ...[l, r],
};

Future<void> _open(WidgetTester tester, Size size, {String? mode}) async {
  setSize(tester, size);
  await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
  await tester.pumpAndSettle();
  if (mode != null) {
    await tester.tap(find.text(mode));
    await tester.pumpAndSettle();
  }
}

/// The kids stay in the margins outside [content] wide content.
void _expectInMargins(WidgetTester tester, Size size, double content) {
  final margin = (size.width - content) / 2;
  for (final key in [_left, _right]) {
    final kid = find.byKey(key);
    if (kid.evaluate().isEmpty) continue;
    final r = tester.getRect(kid);
    expect(r.left, greaterThanOrEqualTo(0), reason: '$key');
    expect(r.right, lessThanOrEqualTo(size.width), reason: '$key');
    expect(r.width, lessThanOrEqualTo(LessonKidsDecoration.maxKidWidth));
    if (key == _left) {
      expect(r.right, lessThanOrEqualTo(margin), reason: 'sol çocuk içerikte');
    } else {
      expect(
        r.left,
        greaterThanOrEqualTo(size.width - margin),
        reason: 'sağ çocuk içerikte',
      );
    }
  }
}

void main() {
  setUp(() => LessonKids.debugSetAvailable(_allKids));

  test('dersler çiftleri sırayla kullanır (rastgele değil)', () {
    expect(LessonKids.pairFor(0), LessonKids.pairs[0]);
    expect(LessonKids.pairFor(1), LessonKids.pairs[1]);
    expect(LessonKids.pairFor(2), LessonKids.pairs[0]);
  });

  testWidgets('masaüstü Sayfa: iki çocuk, içeriğin dışında', (tester) async {
    const size = Size(1280, 800);
    await _open(tester, size);
    expect(find.byType(LessonPageView), findsOneWidget);
    expect(find.byKey(_left), findsOneWidget);
    expect(find.byKey(_right), findsOneWidget);
    _expectInMargins(tester, size, LessonPageView.maxSheetWidth);
  });

  testWidgets('masaüstü Grid: kenar yoksa (1280) çocuk yok, 1920\'de iki', (
    tester,
  ) async {
    await _open(tester, const Size(1280, 800), mode: '▦ Grid');
    expect(find.byType(AllLettersGrid), findsOneWidget);
    expect(find.byKey(_left), findsNothing);
    expect(find.byKey(_right), findsNothing);

    const wide = Size(1920, 1080);
    await _open(tester, wide, mode: '▦ Grid');
    expect(find.byKey(_left), findsOneWidget);
    expect(find.byKey(_right), findsOneWidget);
    _expectInMargins(tester, wide, AllLettersGrid.maxContentWidth);
  });

  testWidgets('tablet: yalnız sağda tek, küçük çocuk (kenar yetiyorsa)', (
    tester,
  ) async {
    const size = Size(1000, 800);
    await _open(tester, size);
    expect(find.byKey(_left), findsNothing);
    expect(find.byKey(_right), findsOneWidget);
    expect(
      tester.getSize(find.byKey(_right)).width,
      lessThanOrEqualTo(LessonKidsDecoration.maxTabletKidWidth),
    );
    _expectInMargins(tester, size, LessonPageView.maxSheetWidth);

    await _open(tester, const Size(800, 1280));
    expect(find.byKey(_right), findsNothing, reason: 'kenar dar');
  });

  for (final size in const [Size(360, 800), Size(800, 360)]) {
    testWidgets('telefon $size: çocuk yok', (tester) async {
      await _open(tester, size);
      expect(find.byKey(_left), findsNothing);
      expect(find.byKey(_right), findsNothing);
    });
  }

  testWidgets('Tekli / Büyük: yalnız çok geniş ekranda, harfin dışında', (
    tester,
  ) async {
    // Harf/kelime ekranın %85'ine kadar büyüyebilir: 1280'de kenar dar.
    await _open(tester, const Size(1280, 800), mode: '🔎 Tekli / Büyük');
    expect(find.byType(LetterPage), findsWidgets);
    expect(find.byKey(_left), findsNothing);
    expect(find.byKey(_right), findsNothing);

    const wide = Size(1920, 1080);
    await _open(tester, wide, mode: '🔎 Tekli / Büyük');
    expect(find.byKey(_left), findsOneWidget);
    expect(find.byKey(_right), findsOneWidget);
    _expectInMargins(tester, wide, wide.width * LetterPage.maxGlyphWidthFactor);
    // Tekli'nin arka planı da çocuk kitabı gökyüzü.
    expect(find.byType(LessonGridBackground), findsWidgets);
  });

  testWidgets('görsel yoksa çocuk yok; dokunmalar içeriğe gider', (
    tester,
  ) async {
    LessonKids.debugSetAvailable(const {});
    await _open(tester, const Size(1280, 800));
    expect(find.byKey(_left), findsNothing);
    expect(find.byKey(_right), findsNothing);

    LessonKids.debugSetAvailable(_allKids);
    await tester.pumpAndSettle();
    expect(find.byKey(_left), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(_left),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
  });
}
