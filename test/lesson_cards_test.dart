// Ders listesi kartları: master görselden kırpılmış PNG'ler
// (tool/crop_lesson_cards.py). Görselde ders adı zaten yazılı; Flutter ikinci
// kez yazmaz. Ders 30 master'da yok, kendi görselinden kırpıldı.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/lesson_card_images.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/elifba_lessons_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_card.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:provider/provider.dart';

import 'support/silent_audio.dart';

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('her ders kendi kart görseline bağlı, dosyalar var', () {
    final ids = kElifbaAllLessons.map((l) => l.id).toSet();
    expect(ids.containsAll(kLessonCardImages.keys), isTrue);
    expect(kLessonCardImages, hasLength(kElifbaAllLessons.length)); // 35
    expect(kLessonCardImages.values.toSet(), hasLength(35)); // tekrar yok
    for (final lesson in kElifbaAllLessons) {
      final path = kLessonCardImages[lesson.id]!;
      expect(File(path).existsSync(), isTrue, reason: path);
      // Dosya adı ders numarasıyla aynı (lesson_NN / intro).
      final number = lesson.label.replaceFirst('Ders ', '');
      expect(
        path,
        lesson.label == 'Giriş'
            ? endsWith('intro_harflerin_cikis_yerleri.png')
            : endsWith('lesson_${number.padLeft(2, '0')}.png'),
      );
    }
    // Pakete girer (master görsel girmez).
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/images/lessons/cards/'));
    expect(pubspec, isNot(contains('lesson_cards_master')));
  });

  testWidgets('görselli kartta başlık yazılmaz; Arapça önizleme yok', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
    await tester.pumpAndSettle();
    final first = find.byKey(const ValueKey('lesson-card-harfleri-taniyalim'));
    expect(first, findsOneWidget);
    expect(
      find.descendant(of: first, matching: find.byType(Text)),
      findsNothing,
    );
    expect(find.text(kHarfleriTaniyalimLesson.title), findsNothing);
    // Aynı oran: yan yana kartlar aynı boyda.
    final size = tester.getSize(first);
    expect(size.width / size.height, closeTo(LessonCard.aspectRatio, 0.01));
    expect(
      tester.getSize(find.byKey(const ValueKey('lesson-card-ustun'))),
      size,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ders 30 da görselli kart, aynı şekil', (tester) async {
    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('lesson-card-kelime-sonu-duraklar'));
    await tester.scrollUntilVisible(card, 300);
    await tester.pumpAndSettle();
    expect(find.descendant(of: card, matching: find.byType(Text)), findsNothing);
    expect(
      find.byKey(
        const ValueKey(
          'lesson-card-image-assets/images/lessons/cards/lesson_30.png',
        ),
      ),
      findsOneWidget,
    );
    final size = tester.getSize(card);
    expect(size.width / size.height, closeTo(LessonCard.aspectRatio, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('karta dokununca ders açılır (aynı gezinme)', (tester) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      ChangeNotifierProvider<AudioService>.value(
        value: SilentAudio(),
        child: const MaterialApp(home: ElifbaLessonsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('lesson-card-harfleri-taniyalim'));
    await tester.scrollUntilVisible(card, 200);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    final screen = tester.widget<LessonLettersScreen>(
      find.byType(LessonLettersScreen),
    );
    expect(screen.lesson, same(kHarfleriTaniyalimLesson));
  });

  for (final size in const [
    Size(360, 800),
    Size(800, 1280),
    Size(1280, 800),
    Size(800, 360),
    Size(1920, 1080),
  ]) {
    testWidgets('$size: liste taşmaz', (tester) async {
      setSize(tester, size);
      await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
      await tester.pumpAndSettle();
      for (var i = 0; i < 30; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
