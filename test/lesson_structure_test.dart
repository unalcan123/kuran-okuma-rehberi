// Ders yapısı ve sayfa gezinmesi (2026-09-29):
// - GİRİŞ "Harflerin Çıkış Yerleri" (s. 3-5) derslerden ayrı; Ders 1 = s. 6-7.
// - Bütün sayfalar Arapça kitap gibi: parmak soldan sağa = sonraki sayfa.
// - Grid de kitap sayfası sayfa (Sayfa ile aynı sayfa sınırları).
// - Üç görünüm aynı etkin kitap sayfasını paylaşır.
// - Ders başlığı ve Sayfa / Grid / Tekli seçicisi sabit değil, kayar.
// - Ders 2 Lâm-Elif şekillerinin her okunuşu kendi kaydını çalar.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letter_forms_data.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/models/lesson_page_layout.dart';
import 'package:kuran_okuma_rehberi/models/lesson_position.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/elifba_lessons_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_card.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_grid_pager.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_mode_toggle.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_page_view.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/single_letter_pager.dart';
import 'package:kuran_okuma_rehberi/widgets/book_pager.dart';

import 'support/lesson_scroll.dart';
import 'book_pages_test.dart' show RecordingAudio, app, setSize;

Future<void> _mode(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Lesson item indices of the Sayfa view's cells on screen.
Set<int> _bookCellItems(WidgetTester tester) => {
  for (final e in find.byType(InkWell).evaluate())
    if (e.widget.key case ValueKey<String>(
      :final value,
    ) when value.startsWith('book-cell-'))
      int.parse(value.substring('book-cell-'.length)),
};

void main() {
  group('Giriş ve Ders 1', () {
    test('Giriş normal bir ders değildir; s. 3-5', () {
      final giris = kCikisYerleriGirisLesson;
      expect(kElifbaIntroLessons, [giris]);
      expect(kElifbaLessons, isNot(contains(giris)));
      expect(giris.label, 'Giriş');
      expect(giris.label, isNot(startsWith('Ders')));
      expect(giris.title, 'Harflerin Çıkış Yerleri');
      expect(giris.letters, isEmpty);
      expect(giris.pageLayout!.pages.map((p) => p.bookPage), [3, 4, 5]);
      expect(
        giris.pageLayout!.pages.map((p) => p.type),
        everyElement(LessonPageType.info),
      );
      // Numaralar kaymadı: ilk ders yine "Ders 1", kimliği aynı.
      expect(kElifbaLessons.first.label, 'Ders 1');
      expect(kElifbaLessons.first.id, 'harfleri-taniyalim');
      expect(kElifbaAllLessons.first, same(giris));
    });

    test('Ders 1: ilk sayfa PDF 6, ikinci sayfa PDF 7', () {
      final pages = kHarfleriTaniyalimLesson.pageLayout!.pages;
      expect(pages.map((p) => p.bookPage), [6, 7]);
      expect(pages[0].heading, 'HARFLER');
      expect(pages[1].heading, 'YAZILIŞ VE OKUNUŞLARI');
    });

    testWidgets('ders listesi GİRİŞ ile başlar, sonra Ders 1', (tester) async {
      setSize(tester, const Size(1280, 800));
      await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
      await tester.pumpAndSettle();
      final giris = find.byKey(
        const ValueKey('lesson-card-giris-harflerin-cikis-yerleri'),
      );
      final ders1 = find.byKey(
        const ValueKey('lesson-card-harfleri-taniyalim'),
      );
      expect(find.text('GİRİŞ'), findsOneWidget);
      expect(find.text('DERSLER'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('GİRİŞ')).dy,
        lessThan(tester.getTopLeft(giris).dy),
      );
      expect(
        tester.getTopLeft(giris).dy,
        lessThan(tester.getTopLeft(find.text('DERSLER')).dy),
      );
      expect(
        tester.getTopLeft(find.text('DERSLER')).dy,
        lessThan(tester.getTopLeft(ders1).dy),
      );
      expect(tester.widget<LessonCard>(giris).lesson.label, 'Giriş');
    });

    testWidgets(
      'Giriş açılır: yalnız sayfalar (s. 3 → 4 → 5), Grid/Tekli yok',
      (tester) async {
        setSize(tester, const Size(360, 800));
        await tester.pumpWidget(
          app(RecordingAudio(), kCikisYerleriGirisLesson),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LessonPageView), findsOneWidget);
        expect(find.text('Sayfa 3'), findsOneWidget);
        expect(find.text('▦ Grid'), findsNothing);
        expect(find.text('🔎 Tekli / Büyük'), findsNothing);
        await tester.fling(find.byType(PageView), const Offset(300, 0), 1500);
        await tester.pumpAndSettle();
        expect(find.text('Sayfa 4'), findsOneWidget);
        await tester.fling(find.byType(PageView), const Offset(300, 0), 1500);
        await tester.pumpAndSettle();
        expect(find.text('Sayfa 5'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Ders 1 s. 6 ile açılır, soldan sağa kaydırınca s. 7', (
      tester,
    ) async {
      setSize(tester, const Size(1280, 800));
      await tester.pumpWidget(app(RecordingAudio(), kHarfleriTaniyalimLesson));
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 6'), findsOneWidget);
      expect(find.text('HARFLER'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(500, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 7'), findsOneWidget);
      // Sağdan sola: geri.
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 6'), findsOneWidget);
    });
  });

  group('kaydırma yönü ve sayfa çevirme', () {
    testWidgets('parmağı takip eder; bırakmadan önce yarım sayfa', (
      tester,
    ) async {
      setSize(tester, const Size(800, 1280));
      await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
      await tester.pumpAndSettle();
      final pageView = find.byType(PageView);
      final gesture = await tester.startGesture(tester.getCenter(pageView));
      await gesture.moveBy(const Offset(40, 0));
      await gesture.moveBy(const Offset(160, 0));
      await tester.pump();
      final controller = tester.widget<PageView>(pageView).controller!;
      // Soldan sağa sürükleme sonraki sayfaya doğru ilerletir.
      expect(controller.page, greaterThan(0.1));
      expect(controller.page, lessThan(1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 14'), findsOneWidget); // az sürükleme: geri döner
    });

    test('sayfa çevirme efekti: alttaki sabit ve kararır, üstteki gölgeli', () {
      const w = 400.0;
      final idle = BookPager.turnEffect(0, w);
      expect((idle.dx, idle.shade, idle.edgeShadow), (0.0, 0.0, 0.0));
      final lower = BookPager.turnEffect(-0.5, w);
      expect(lower.dx, -200); // PageView'ın kaydırmasını geri alır
      expect(lower.shade, greaterThan(0));
      expect(lower.scale, lessThan(1));
      final upper = BookPager.turnEffect(0.5, w);
      expect(upper.dx, 0);
      expect(upper.edgeShadow, closeTo(1, 1e-9));
      expect(BookPager.turnEffect(1, w).edgeShadow, 0);
      expect(BookPager.turnEffect(-1, w).shade, 0);
    });

    testWidgets('bütün görünümler aynı merkezi sayfalayıcıyı kullanır', (
      tester,
    ) async {
      setSize(tester, const Size(800, 1280));
      await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
      await tester.pumpAndSettle();
      for (final label in ['📖 Sayfa', '▦ Grid', '🔎 Tekli / Büyük']) {
        await _mode(tester, label);
        expect(find.byType(BookPager), findsOneWidget, reason: label);
        expect(tester.widget<PageView>(find.byType(PageView)).reverse, isTrue);
      }
    });
  });

  group('Ders 3: PDF 14 / 15 / 16', () {
    test('üç ayrı fiziksel sayfa, öğe aralıkları', () {
      final layout = kUstunPageLayout;
      expect(layout.pages.map((p) => p.bookPage), [14, 15, 16]);
      expect(layout.itemsOf(0), [for (var i = 0; i < 28; i++) i]);
      expect(layout.itemsOf(1), [for (var i = 28; i < 56; i++) i]);
      expect(layout.itemsOf(2), [for (var i = 56; i < 92; i++) i]);
    });

    testWidgets('Sayfa ve Grid aynı sayfa sınırlarını kullanır', (
      tester,
    ) async {
      setSize(tester, const Size(1920, 1080));
      await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
      await tester.pumpAndSettle();
      final letters = kUstunLesson.letters;
      for (var p = 0; p < 3; p++) {
        final page = kUstunPageLayout.pages[p];
        await _mode(tester, '📖 Sayfa');
        expect(find.text('Sayfa ${page.bookPage}'), findsOneWidget);
        final expected = kUstunPageLayout.itemsOf(p).toSet();
        expect(
          _bookCellItems(tester),
          expected,
          reason: 'Sayfa s. ${page.bookPage}',
        );

        await _mode(tester, '▦ Grid');
        expect(find.text('Sayfa ${page.bookPage}'), findsOneWidget);
        final grid = tester.widget<AllLettersGrid>(find.byType(AllLettersGrid));
        expect(grid.letters, hasLength(expected.length));
        for (final (i, item) in kUstunPageLayout.itemsOf(p).indexed) {
          // Aynı nesne: içerik kopyalanmadı, Lesson.letters tek kaynak.
          expect(grid.letters[i], same(letters[item]));
        }
        if (p < 2) {
          // Grid'de de soldan sağa = sonraki sayfa.
          await tester.fling(find.byType(PageView), const Offset(600, 0), 1500);
          await tester.pumpAndSettle();
        }
      }
      // Grid s. 16'da; sağdan sola geri.
      await tester.fling(find.byType(PageView), const Offset(-600, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 15'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bütün dersler: Sayfa hücreleri = Grid sayfası öğeleri', (
      tester,
    ) async {
      // Sayfa sınırları tek yerden (LessonPageLayout.itemsOf) gelir; kitap
      // tablosu hücreleri (dizi ya da referans) bununla aynıdır.
      for (final lesson in kElifbaLessons) {
        final layout = lesson.pageLayout;
        if (layout == null) continue;
        for (var p = 0; p < layout.pages.length; p++) {
          final items = layout.itemsOf(p);
          expect(items.toSet(), hasLength(items.length), reason: lesson.id);
          expect(
            items.every((i) => i >= 0 && i < lesson.letters.length),
            isTrue,
            reason: '${lesson.id} s. ${layout.pages[p].bookPage}',
          );
          final start = layout.firstItemOf(p);
          final run = layout.pages[p].totalItems;
          expect(items.take(run), [
            for (var i = 0; i < run; i++) start + i,
          ], reason: '${lesson.id} s. ${layout.pages[p].bookPage}');
        }
      }
    });
  });

  group('görünümler aynı etkin sayfayı paylaşır', () {
    test('LessonPosition', () {
      final position = LessonPosition(kUstunPageLayout);
      expect((position.page, position.item), (0, 0));
      position.showPage(1);
      expect((position.page, position.item), (1, 28));
      position.showItem(60);
      expect((position.page, position.item), (2, 60));
      expect(position.pageLabelOf(60), 'Sayfa 16');
      position.showPage(2); // öğe sayfada: yerinde kalır
      expect(position.item, 60);

      // Ders 1: aynı harfler s. 6 ve s. 7'de; s. 7'deyken sayfa değişmez.
      final ders1 = LessonPosition(kHarfleriTaniyalimLesson.pageLayout);
      ders1.showPage(1);
      ders1.showItem(5);
      expect(ders1.page, 1);
      expect(ders1.pageLabelOf(5), 'Sayfa 7');
    });

    testWidgets('Sayfa s. 15 → Grid s. 15 → Grid s. 16 → Sayfa s. 16 → Tekli', (
      tester,
    ) async {
      setSize(tester, const Size(1280, 800));
      await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('page-next')));
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 15'), findsOneWidget);

      await _mode(tester, '▦ Grid');
      expect(find.byType(LessonGridPager), findsOneWidget);
      expect(find.text('Sayfa 15'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('page-next')));
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 16'), findsOneWidget);

      await _mode(tester, '📖 Sayfa');
      expect(find.byType(LessonPageView), findsOneWidget);
      expect(find.text('Sayfa 16'), findsOneWidget);

      await _mode(tester, '🔎 Tekli / Büyük');
      expect(find.byType(SingleLetterPager), findsOneWidget);
      expect(find.text('57 / 92'), findsOneWidget); // s. 16'nın ilk öğesi
      expect(find.text('Sayfa 16'), findsOneWidget);

      // Tekli'de s. 15'e geri dönünce Grid de s. 15.
      await tester.tap(find.byKey(const ValueKey('single-previous')));
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 15'), findsOneWidget);
      await _mode(tester, '▦ Grid');
      expect(find.text('Sayfa 15'), findsOneWidget);
    });
  });

  group('başlık ve seçici sabit değil', () {
    testWidgets('yukarı kaydırınca ders başlığı ve seçici ekrandan çıkar', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
      await tester.pumpAndSettle();
      final selector = find.descendant(
        of: find.byKey(const ValueKey('lesson-mode-header')),
        matching: find.byType(LessonModeToggle),
      );
      final title = find.text('${kUstunLesson.label} · ${kUstunLesson.title}');
      bool onScreen(Finder f) =>
          f.evaluate().isNotEmpty && tester.getRect(f).bottom > 0;

      for (final label in ['📖 Sayfa', '▦ Grid']) {
        if (label != '📖 Sayfa') await _mode(tester, label);
        expect(onScreen(selector), isTrue, reason: label);
        expect(onScreen(title), isTrue, reason: label);
        final top = tester.getTopLeft(selector).dy;

        // İçerik yukarı: seçici de başlık da kayıp gider (yapışık değil).
        await tester.drag(find.byType(PageView), const Offset(0, -30));
        await tester.pump();
        expect(tester.getTopLeft(selector).dy, lessThan(top), reason: label);
        await tester.drag(find.byType(PageView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(onScreen(selector), isFalse, reason: label);
        expect(onScreen(title), isFalse, reason: label);

        // Biraz geri kaydırmak getirmez (yüzen başlık değil) ...
        await tester.drag(find.byType(PageView), const Offset(0, 60));
        await tester.pumpAndSettle();
        expect(onScreen(selector), isFalse, reason: label);

        // ... en üste dönünce normal akışta yine görünür.
        await tester.drag(find.byType(PageView), const Offset(0, 3000));
        await tester.pumpAndSettle();
        expect(onScreen(selector), isTrue, reason: label);
        expect(tester.getTopLeft(selector).dy, top, reason: label);
      }
    });
  });

  group('Ders 2 Lâm-Elif sesleri', () {
    final page8 = kHarflerinYazilislariPageLayout.pages.first;
    final section = page8.sections.single;

    test('her şekil kendi okunuşunun kaydına bağlı; eksik yok', () {
      expect(page8.bookPage, 8);
      expect(section.texts, [
        'لا',
        'ـلا',
        'لآ',
        'ـلآ',
        'لأ',
        'ـلأ',
        'لإ',
        'ـلإ',
      ]);
      // Her hücrenin bir kaydı var.
      expect(section.textAudio.keys.toSet(), {0, 1, 2, 3, 4, 5, 6, 7});
      // Ayrı/bitişik aynı okunur, aynı kayıt; dört okunuş = dört ayrı kayıt.
      final byRow = [
        for (var row = 0; row < 4; row++)
          section.textAudio[row * 2]!.audioAsset,
      ];
      for (var row = 0; row < 4; row++) {
        expect(section.textAudio[row * 2 + 1]!.audioAsset, byRow[row]);
      }
      expect(byRow.toSet(), hasLength(4));
      // Başka harfin sesi kullanılmıyor.
      final otherLetters = {
        for (final l in kLetterFormLetters) l.audioAsset,
        for (final l in kArabicLetters) l.audioAsset,
      };
      for (final asset in byRow) {
        expect(otherLetters, isNot(contains(asset)));
        expect(File('assets/$asset').existsSync(), isTrue, reason: asset);
      }
      // Dersin Lâm-Elif öğesi (adı: "Lâm Elif") kendi kaydını korur.
      expect(kLetterFormLetters[27].isolatedForm, 'لا');
      expect(
        kLetterFormLetters[27].audioAsset,
        'audio/elifba/ders_2_harfler/28_lamelif.mp3',
      );
      // Ön yüklemeye girer.
      expect(
        kHarflerinYazilislariPageLayout.extraAudioAssets.toSet(),
        containsAll(byRow),
      );
    });

    testWidgets('s. 8: dokununca her şekil kendi kaydını çalar', (
      tester,
    ) async {
      setSize(tester, const Size(1280, 800));
      final audio = RecordingAudio();
      await tester.pumpWidget(app(audio, kHarflerinYazilislariLesson));
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 8'), findsOneWidget);
      for (var i = 0; i < 8; i++) {
        final cell = find.byKey(ValueKey('book-text-cell-$i'));
        await revealInLesson(tester, cell);
        await tester.tap(cell);
        await tester.pump();
        expect(audio.played.last, same(section.textAudio[i]), reason: '$i');
      }
      // لا hücresi basılı tutulunca dersin Lâm-Elif öğesi Tekli'de açılır.
      await tester.longPress(find.byKey(const ValueKey('book-text-cell-0')));
      await tester.pumpAndSettle();
      expect(find.byType(SingleLetterPager), findsOneWidget);
      expect(find.text('28 / 29'), findsOneWidget);
    });
  });

  testWidgets('ekran boyutlarında Grid sayfaları taşmaz', (tester) async {
    for (final size in const [
      Size(360, 800),
      Size(800, 1280),
      Size(1280, 800),
      Size(800, 360),
      Size(1920, 1080),
    ]) {
      setSize(tester, size);
      for (final lesson in [kHarflerinYazilislariLesson, kUstunLesson]) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey('$size${lesson.id}'),
            child: app(RecordingAudio(), lesson),
          ),
        );
        await tester.pumpAndSettle();
        await _mode(tester, '▦ Grid');
        for (var p = 0; p < lesson.pageLayout!.pages.length; p++) {
          expect(
            tester.takeException(),
            isNull,
            reason: '$size ${lesson.id} $p',
          );
          if (p < lesson.pageLayout!.pages.length - 1) {
            await tester.tap(find.byKey(const ValueKey('page-next')));
            await tester.pumpAndSettle();
          }
        }
      }
    }
  });
}
