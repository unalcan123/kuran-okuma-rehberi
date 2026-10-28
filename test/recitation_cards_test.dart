import 'package:kuran_okuma_rehberi/data/supplementary_sureler_data.dart';
// Sure ve dua listeleri: master görsellerden kırpılmış kartlar
// (tool/crop_lesson_cards.py), Elifba ders kartlarıyla aynı PictureCard.
// Sureler Kur’an sırasındadır; kart numaraları 1–11 olarak gösterilir.
// Görsel dosyaları eski kimlik eşleşmelerini korur.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/recitation_card_images.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dua_detail_screen.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dualar_list_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/sureler_list_screen.dart';
import 'package:kuran_okuma_rehberi/widgets/picture_card.dart';

import 'dualar_test.dart' show TestAudioService, harness;

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('dualar: 9 kart, sırayla, dosyalar var; başlık kimlikten ayrı', () {
    expect(kDualar, hasLength(9));
    for (final dua in kDualar) {
      final image = kDuaCardImages[dua.id]!;
      expect(
        image,
        endsWith('dua_${dua.order.toString().padLeft(2, '0')}.png'),
      );
      expect(File(image).existsSync(), isTrue, reason: image);
      expect(kDuaDisplayTitles[dua.id], isNotNull, reason: dua.id);
    }
    expect(kDuaCardImages.values.toSet(), hasLength(9));
    expect(kDuaDisplayTitles['7_kunut1_duasi'], contains('Kunut 1'));
    expect(kDuaDisplayTitles['8_kunut2_duasi'], contains('Kunut 2'));
    // Kunut 1 / 2 metinle uyumlu (görseldeki başlıklar).
    expect(
      kDualar.firstWhere((d) => d.id == '7_kunut1_duasi').segments.first.arabic,
      contains('نَسْتَعِينُكَ'),
    );
    expect(
      kDualar.firstWhere((d) => d.id == '8_kunut2_duasi').segments.first.arabic,
      contains('اِيَّاكَ نَعْبُدُ'),
    );
  });

  test('sureler: 11 kart, uygulamanın sırasıyla, dosyalar var', () {
    expect(kSureler.map((s) => s.id), [
      'fatiha',
      'fil',
      'kureysh',
      'maun',
      'kevser',
      'kafirun',
      'nasr',
      'tebbet',
      'ihlas',
      'felak',
      'nas',
    ]);
    expect(kSureler.map((s) => s.order), List.generate(11, (i) => i + 1));
    const originalImages = {
      'fatiha': 1,
      'fil': 2,
      'kureysh': 3,
      'maun': 4,
      'ihlas': 5,
      'kevser': 6,
      'nas': 7,
      'felak': 8,
      'nasr': 9,
      'tebbet': 10,
      'kafirun': 11,
    };
    for (final surah in kSureler) {
      final image = kSurahCardImages[surah.id]!;
      expect(
        image,
        endsWith(
          'sure_${originalImages[surah.id].toString().padLeft(2, '0')}.png',
        ),
      );
      expect(File(image).existsSync(), isTrue, reason: image);
    }
    // Kartlar 12-23: kAllNamazTexts'in kSureler'den sonrası, sırayla.
    for (var i = kSureler.length; i < kAllNamazTexts.length; i++) {
      final image = kSurahCardImages[kAllNamazTexts[i].id]!;
      expect(image, endsWith('sure_${i + 1}.png'), reason: image);
      expect(File(image).existsSync(), isTrue, reason: image);
    }
    expect(kAllNamazTexts, hasLength(23));
    expect(kSurahCardImages.values.toSet(), hasLength(23));
    final files =
        Directory(
            'assets/images/lessons/sureler',
          ).listSync().map((f) => f.uri.pathSegments.last).toList()
          ..sort();
    expect(files, [
      for (var n = 1; n <= 23; n++) 'sure_${n.toString().padLeft(2, '0')}.png',
    ]);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/images/lessons/sureler/'));
    expect(pubspec, contains('assets/images/lessons/dualar/'));
  });

  testWidgets('dua kartı: başlık yazılmaz, dokununca o dua açılır', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const DualarListScreen(), audio));
    await tester.pumpAndSettle();
    final card = find.byKey(ValueKey('dua-card-${kDualar[6].id}'));
    await tester.scrollUntilVisible(card, 200);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.byType(Text)),
      findsNothing,
    );
    final size = tester.getSize(card);
    expect(size.width / size.height, closeTo(kDuaCardAspectRatio, 0.01));
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DuaDetailScreen>(find.byType(DuaDetailScreen)).dua,
      same(kDualar[6]),
    );
  });

  testWidgets('sure kartları görselli, numara güncel; dokununca o sure '
      'açılır', (tester) async {
    setSize(tester, const Size(1280, 800));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const SurelerListScreen(), audio));
    await tester.pumpAndSettle();
    final fatiha = find.byKey(const ValueKey('surah-card-fatiha'));
    expect(
      find.descendant(of: fatiha, matching: find.text('Sure 1')),
      findsOneWidget,
    );
    final fil = find.byKey(const ValueKey('surah-card-fil'));
    await tester.scrollUntilVisible(fil, 150);
    expect(
      find.descendant(of: fil, matching: find.text('Sure 2')),
      findsOneWidget,
    );
    for (var i = 0; i < kSureler.length; i++) {
      final card = find.byKey(ValueKey('surah-card-${kSureler[i].id}'));
      await tester.scrollUntilVisible(card, 150);
      expect(
        find.descendant(
          of: card,
          matching: find.text(
            'Sure ${kAllNamazTexts.indexOf(kSureler[i]) + 1}',
          ),
        ),
        findsOneWidget,
      );
    }
    await tester.scrollUntilVisible(fatiha, -150);
    // Each original image retains the same aspect ratio.
    final size = tester.getSize(fatiha);
    expect(size.width / size.height, closeTo(kSurahCardAspectRatio, 0.01));

    await tester.ensureVisible(fatiha);
    await tester.pumpAndSettle();
    await tester.tap(fatiha);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SurahDetailScreen>(find.byType(SurahDetailScreen)).surah,
      same(kSureler.first),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(fil, 150);
    await tester.ensureVisible(fil);
    await tester.pumpAndSettle();
    await tester.tap(fil);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SurahDetailScreen>(find.byType(SurahDetailScreen)).surah,
      same(kSureler[1]),
    );
  });

  for (final size in const [
    Size(360, 800),
    Size(800, 1280),
    Size(1280, 800),
    Size(800, 360),
    Size(1920, 1080),
  ]) {
    testWidgets('$size: sure ve dua listeleri taşmaz, kartlar okunur boyda', (
      tester,
    ) async {
      setSize(tester, size);
      final audio = TestAudioService();
      addTearDown(audio.dispose);
      for (final screen in const [SurelerListScreen(), DualarListScreen()]) {
        await tester.pumpWidget(harness(screen, audio));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // On screen (TabletZoom enlarges it on a tablet or a desktop).
        final first = tester.getRect(find.byType(PictureCard).first).size;
        expect(first.width, greaterThanOrEqualTo(200), reason: '$screen');
        for (var i = 0; i < 10; i++) {
          await tester.drag(find.byType(GridView), const Offset(0, -300));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}

