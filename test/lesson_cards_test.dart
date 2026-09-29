// Ders listesi kartları: master görselden kırpılmış PNG'ler
// (tool/crop_lesson_cards.py). Görseldeki başlık/Arapça yazı güvenilmez
// (bazıları yanlıştı): kart onları örter, dersin kendi etiketini, başlığını ve
// konuya uygun Arapça örneği yazar (kLessonCardArt). Ders 30 master'da yok,
// kendi görselinden kırpıldı.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/kelime_sonu_duraklar_data.dart';
import 'package:kuran_okuma_rehberi/data/lesson_card_images.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
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

  test('her görselin örtü verisi var, boyutu dosyayla aynı', () {
    expect(kLessonCardArt.keys.toSet(), kLessonCardImages.keys.toSet());
    for (final MapEntry(key: id, value: art) in kLessonCardArt.entries) {
      final bytes = File(kLessonCardImages[id]!).readAsBytesSync();
      // PNG IHDR: genişlik bayt 16-19, yükseklik 20-23 (big-endian).
      int u32(int o) =>
          bytes[o] << 24 |
          bytes[o + 1] << 16 |
          bytes[o + 2] << 8 |
          bytes[o + 3];
      expect(
        art.size,
        Size(u32(16).toDouble(), u32(20).toDouble()),
        reason: id,
      );
      for (final r in [art.title, ...art.tiles.map((t) => t.rect)]) {
        expect(
          r.left >= 0 && r.top >= 0 && r.right <= 1 && r.bottom <= 1,
          isTrue,
          reason: id,
        );
        expect(r.width > 0 && r.height > 0, isTrue, reason: id);
      }
    }
  });

  test('kartın Arapça örneği dersin konusuyla eşleşir', () {
    // Ders kimliği → örnekte bulunması gereken işaret/harf.
    const required = {
      'ustun': 'َ', // üstün
      'esre': 'ِ', // esre
      'otre': 'ُ', // ötre
      'cezm': 'ْ', // cezm
      'harekeler-alistirmalari': 'ْ', // kitapta Cezim örnekleri
      'sedde': 'ّ',
      'uzatma-elif': 'ا',
      'uzatma-elif-alistirmalari': 'ا',
      'uzatma-ya': 'ي',
      'uzatma-ya-alistirmalari': 'ي',
      'uzatma-vav': 'و',
      'uzatma-vav-alistirmalari': 'و',
      'ceker-ustun': 'ٰ', // çeker üstün
      'ceker-esre': 'ٖ', // çeker esre
      'tenvin-iki-ustun': 'ً',
      'tenvin-iki-esre': 'ٍ',
      'tenvin-iki-otre': 'ٌ',
      'el-takisi-okunan': 'لْ', // okunan (cezimli) lâm
      'el-takisi-okunmayan': 'ل',
      'el-takisi-hemze': 'ال',
      'el-takisi-hemze-vasil': 'ٱ',
      'zamir-he-uzatilmasi': 'هُٓ',
      'zamir-he-uzatma-med': 'ٓ', // uzun med işareti
      'kapali-te': 'ة',
    };
    // Tek harekenin dersi: örnek "ب + o hareke", başka işaret yok.
    const only = {
      'ustun': 'َ',
      'esre': 'ِ',
      'otre': 'ُ',
      'cezm': 'ْ',
      'tenvin-iki-ustun': 'ً',
      'tenvin-iki-esre': 'ٍ',
      'tenvin-iki-otre': 'ٌ',
    };
    for (final MapEntry(key: id, value: mark) in required.entries) {
      final tiles = kLessonCardArt[id]!.tiles;
      expect(tiles, isNotEmpty, reason: id);
      for (final tile in tiles) {
        expect(tile.arabic, contains(mark), reason: id);
        if (only[id] case final m?) {
          expect(tile.arabic, 'ب$m', reason: id);
        }
      }
    }
    // Harf yazılışları: bitişik biçimler, hareke yok.
    final forms = kLessonCardArt['harflerin-yazilislari']!.tiles.single;
    expect(forms.arabic, contains('ـ'));
    expect(RegExp('[ً-ٓ]').hasMatch(forms.arabic), isFalse);
    // Kelime örnekleri dersin kendi listesinden gelir.
    for (final lesson in kElifbaLessons) {
      final tiles = kLessonCardArt[lesson.id]?.tiles ?? const [];
      if (tiles.length != 1 || tiles.single.arabic.length < 5) continue;
      if (lesson.id == 'harflerin-yazilislari') continue;
      expect(
        lesson.letters.any((l) => l.isolatedForm.contains(tiles.single.arabic)),
        isTrue,
        reason: '${lesson.id}: ${tiles.single.arabic}',
      );
    }
  });

  test('Ders 28 başlığı "Uzun Med İşareti", kartında uzun med var', () {
    final lesson = kElifbaLessons.firstWhere(
      (l) => l.id == 'zamir-he-uzatma-med',
    );
    expect(lesson.label, 'Ders 28');
    expect(lesson.title, 'Uzun Med İşareti');
    expect(kLessonCardArt[lesson.id]!.tiles.single.arabic, contains('ٓ'));
  });

  test('kullanıcıya görünen "Alıştırma" kalmadı', () {
    for (final lesson in kElifbaAllLessons) {
      final texts = <String>[lesson.title, lesson.subtitle];
      for (final page in lesson.pageLayout?.pages ?? const []) {
        texts.add(page.type.label);
        for (final t in [page.heading, page.kicker, page.subheading]) {
          if (t != null) texts.add(t);
        }
      }
      for (final text in texts) {
        expect(text.toLowerCase(), isNot(contains('alıştırma')), reason: text);
      }
    }
  });

  testWidgets('görselli kart dersin kendi başlığını ve örneğini yazar', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
    await tester.pumpAndSettle();
    final ustun = find.byKey(const ValueKey('lesson-card-ustun'));
    expect(ustun, findsOneWidget);
    final title = find.descendant(
      of: ustun,
      matching: find.text(kUstunLesson.title),
    );
    expect(title, findsOneWidget);
    expect(
      find.descendant(of: ustun, matching: find.text('Ders 3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: ustun, matching: find.text('بَ')),
      findsOneWidget,
    );
    // Yazı kartın içinde ve görünür boyda.
    final titleRect = tester.getRect(title);
    expect(titleRect.height, greaterThan(4));
    expect(tester.getRect(ustun).contains(titleRect.center), isTrue);
    // Aynı oran: yan yana kartlar aynı boyda.
    final first = find.byKey(const ValueKey('lesson-card-harfleri-taniyalim'));
    final size = tester.getSize(first);
    expect(size.width / size.height, closeTo(LessonCard.aspectRatio, 0.01));
    expect(tester.getSize(ustun), size);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ders 30 da görselli kart, aynı şekil', (tester) async {
    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(const MaterialApp(home: ElifbaLessonsScreen()));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('lesson-card-kelime-sonu-duraklar'));
    await tester.scrollUntilVisible(card, 300);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: card,
        matching: find.text(kKelimeSonuDuraklarLesson.title),
      ),
      findsOneWidget,
    );
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
