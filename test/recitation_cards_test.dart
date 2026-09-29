// Sure ve dua listeleri: master görsellerden kırpılmış kartlar
// (tool/crop_lesson_cards.py), Elifba ders kartlarıyla aynı PictureCard.
// "Sure 1" … "Sure 11" = kSureler sırası (Fatiha … Kafirun), kart kart
// kontrol edildi.
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
      expect(image, endsWith('dua_${dua.order.toString().padLeft(2, '0')}.png'));
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
      'fatiha', 'fil', 'kureysh', 'maun', 'ihlas', 'kevser', //
      'nas', 'felak', 'nasr', 'tebbet', 'kafirun',
    ]);
    for (final surah in kSureler) {
      final image = kSurahCardImages[surah.id]!;
      expect(
        image,
        endsWith('sure_${surah.order.toString().padLeft(2, '0')}.png'),
      );
      expect(File(image).existsSync(), isTrue, reason: image);
    }
    expect(kSurahCardImages.values.toSet(), hasLength(11));
    final files = Directory('assets/images/lessons/sureler')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .toList()
      ..sort();
    expect(files, [
      for (var n = 1; n <= 11; n++) 'sure_${n.toString().padLeft(2, '0')}.png',
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
    expect(find.descendant(of: card, matching: find.byType(Text)), findsNothing);
    final size = tester.getSize(card);
    expect(size.width / size.height, closeTo(kDuaCardAspectRatio, 0.01));
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DuaDetailScreen>(find.byType(DuaDetailScreen)).dua,
      same(kDualar[6]),
    );
  });

  testWidgets('sure kartları görselli, başlık yazılmaz; dokununca o sure '
      'açılır', (tester) async {
    setSize(tester, const Size(1280, 800));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const SurelerListScreen(), audio));
    await tester.pumpAndSettle();
    final fatiha = find.byKey(const ValueKey('surah-card-fatiha'));
    expect(
      find.descendant(of: fatiha, matching: find.byType(Text)),
      findsNothing,
    );
    final fil = find.byKey(const ValueKey('surah-card-fil'));
    expect(find.descendant(of: fil, matching: find.byType(Text)), findsNothing);
    expect(tester.getSize(fatiha), tester.getSize(fil)); // aynı şekil
    final size = tester.getSize(fatiha);
    expect(size.width / size.height, closeTo(kSurahCardAspectRatio, 0.01));

    await tester.tap(fatiha);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SurahDetailScreen>(find.byType(SurahDetailScreen)).surah,
      same(kSureler.first),
    );
    await tester.pageBack();
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
