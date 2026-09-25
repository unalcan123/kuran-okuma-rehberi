import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/arapca_yaziyorum/png_saver.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/arapca_yaziyorum/widgets/writing_pad.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/arapca_yaziyorum/yazi_data.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/arapca_yaziyorum/yazi_mode_screens.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/arapca_yaziyorum/yazi_store.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/arapca_yaziyorum/yazi_text.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/dedektif_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harf_dedektifi_test.dart' show FakeAudio, harness, setSize;

TextEditingValue v(String text, [int? base, int? extent]) => TextEditingValue(
  text: text,
  selection:
      base == null
          ? TextSelection.collapsed(offset: text.length)
          : TextSelection(baseOffset: base, extentOffset: extent ?? base),
);

Future<void> loadHasenat() async {
  final bytes = File('assets/fonts/Hasenat.ttf').readAsBytesSync();
  await (FontLoader('Hasenat')
    ..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

Future<void> tapKey(WidgetTester tester, String ch) async {
  await tester.tap(find.byKey(ValueKey('key-$ch')));
  await tester.pump();
}

TextEditingController fieldController(WidgetTester tester) =>
    tester
        .widget<TextField>(find.byKey(const ValueKey('writing-field')))
        .controller!;

/// Yazı alanının gerçek görüntüsündeki büyük mürekkep parçaları (noktalar
/// hariç): birleşik harfler tek parça, bağlantısı kesilenler ayrı parça.
Future<int> inkPieces(WidgetTester tester, GlobalKey boundaryKey) async {
  final field = tester.getRect(find.byKey(const ValueKey('writing-field')));
  final root = tester.getRect(find.byKey(boundaryKey));
  late int pieces;
  await tester.runAsync(() async {
    final b =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 1);
    final data = (await img.toByteData())!;
    final w = img.width;
    final left = (field.left - root.left).round() + 6;
    final top = (field.top - root.top).round() + 6;
    final right = (field.right - root.left).round() - 6;
    final bottom = (field.bottom - root.top).round() - 26;
    // Lacivert yazı pikselleri (koyu).
    bool ink(int x, int y) {
      final i = (y * w + x) * 4;
      return data.getUint8(i) < 110 && data.getUint8(i + 2) < 150;
    }

    final seen = <int>{};
    final sizes = <int>[];
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        if (!ink(x, y) || !seen.add(y * w + x)) continue;
        var n = 0;
        final stack = [(x, y)];
        while (stack.isNotEmpty) {
          final (cx, cy) = stack.removeLast();
          n++;
          for (final (dx, dy) in const [
            (1, 0),
            (-1, 0),
            (0, 1),
            (0, -1),
            (1, 1),
            (-1, -1),
            (1, -1),
            (-1, 1),
          ]) {
            final nx = cx + dx, ny = cy + dy;
            if (nx < left || nx >= right || ny < top || ny >= bottom) continue;
            if (ink(nx, ny) && seen.add(ny * w + nx)) stack.add((nx, ny));
          }
        }
        sizes.add(n);
      }
    }
    final biggest = sizes.fold(0, math.max);
    pieces = sizes.where((s) => s >= biggest * 0.2).length;
  });
  return pieces;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Metin işlemleri', () {
    test('imleçteki yere yazar; seçimi değiştirir; ters çevirmez', () {
      var r = insertAtCursor(v('بت', 1), 'ن')!;
      expect(r.text, 'بنت');
      expect(r.selection, const TextSelection.collapsed(offset: 2));
      r = insertAtCursor(v('باب', 0, 3), 'ت')!;
      expect(r.text, 'ت');
      r =
          insertAtCursor(
            const TextEditingValue(text: 'ب'),
            'ت',
          )!; // geçersiz seçim → sona
      expect(r.text, 'بت');
      expect(r.text.codeUnits, [0x0628, 0x062A], reason: 'mantıksal sıra');
      expect(insertAtCursor(v('بت'), 'ن', maxLength: 2), isNull);
    });

    test('silme: önce son hareke, sonra harf; seçim; vekil çift', () {
      var s = applyHaraka(v('ب'), kShadda).$1;
      s = applyHaraka(s, kFatha).$1;
      expect(s.text, 'بَّ');
      s = deleteBackward(s);
      expect(s.text, 'بّ');
      s = deleteBackward(s);
      expect(s.text, 'ب');
      s = deleteBackward(s);
      expect(s.text, '');
      expect(deleteBackward(v('باب', 1, 3)).text, 'ب');
      expect(deleteBackward(v('ب😀')).text, 'ب');
      expect(deleteBackward(v('بت', 0)).text, 'بت');
    });

    test('hareke boş yere yazılmaz; önceki harfe uygulanır', () {
      expect(applyHaraka(v(''), kFatha).$2, HarakaResult.noLetter);
      expect(applyHaraka(v('ب '), kFatha).$2, HarakaResult.noLetter);
      expect(applyHaraka(v('abc'), kFatha).$2, HarakaResult.noLetter);
      final (a, ra) = applyHaraka(v('بت', 1), kKasra);
      expect(ra, HarakaResult.applied);
      expect(a.text, 'بِت');
      expect(a.selection.baseOffset, 2);
      final (b, rb) = applyHaraka(v('بَ'), kDamma);
      expect(rb, HarakaResult.replaced);
      expect(b.text, 'بُ');
      expect(applyHaraka(v('بَ'), kFatha).$2, HarakaResult.alreadyThere);
      expect(applyHaraka(v('بَ'), kShadda).$1.text, 'بَّ');
    });

    test('normalleştirme: aynı yazılar eşit, farklı harfler farklı', () {
      expect(sameArabic('أ', 'أ'), isTrue);
      expect(sameArabic('آ', 'آ'), isTrue);
      expect(sameArabic('بَّ', 'بَّ'), isTrue);
      expect(sameArabic('  باب \n', 'باب'), isTrue);
      expect(sameArabic('في', 'فى'), isFalse);
      expect(sameArabic('ة', 'ه'), isFalse);
      expect(sameArabic('أ', 'ا'), isFalse);
      expect(sameArabic('بت', 'تب'), isFalse);
    });

    test('ipucu: sıradaki harf ya da yanlış yer', () {
      expect(nextNeeded('', 'باب').next, 'ب');
      expect(nextNeeded('با', 'باب').next, 'ب');
      expect(nextNeeded('بت', 'باب').wrongFrom, 1);
      expect(nextNeeded('باب', 'باب').next, isNull);
    });

    test(
      'Bak ve Yaz: tek harf → iki harf → kısa kelime; harekesiz, havuzdan',
      () {
        final pool = {for (final w in kDetectiveWords) w.text};
        final letters = {for (final l in kDetectiveLetters) l.char};
        for (var seed = 0; seed < 20; seed++) {
          final tasks = buildCopyTasks(math.Random(seed));
          expect(tasks.map((t) => t.stage).toList(), [
            CopyStage.letter,
            CopyStage.letter,
            CopyStage.letter,
            CopyStage.twoLetters,
            CopyStage.twoLetters,
            CopyStage.word,
            CopyStage.word,
            CopyStage.word,
          ]);
          for (final t in tasks) {
            expect(t.text.codeUnits.any(isArabicMark), isFalse);
            expect(
              t.stage == CopyStage.letter ? letters : pool,
              contains(t.text),
            );
            // Her karakter klavyede var.
            for (final ch in t.text.split('')) {
              expect(sectionOf(ch), isNotNull, reason: t.text);
            }
          }
        }
      },
    );
  });

  group('Yazı alanı ve klavye', () {
    Future<(TextEditingController, GlobalKey)> pumpPad(
      WidgetTester tester, {
      Size size = const Size(360, 800),
      int maxLength = 50,
      FakeAudio? audio,
      bool muted = false,
    }) async {
      setSize(tester, size);
      final c = TextEditingController();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: harness(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: WritingPad(
                  controller: c,
                  maxLength: maxLength,
                  muted: muted,
                ),
              ),
            ),
            audio ?? FakeAudio(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (c, key);
    }

    testWidgets('harfler gerçekten birleşiyor (yazı alanının görüntüsü)', (
      tester,
    ) async {
      await loadHasenat();
      final (c, key) = await pumpPad(tester, size: const Size(800, 1280));
      Future<int> piecesOf(String text) async {
        c.value = TextEditingValue(text: text);
        FocusManager.instance.primaryFocus?.unfocus(); // imleç çizgisi olmasın
        await tester.pump();
        return inkPieces(tester, key);
      }

      expect(await piecesOf('بت'), 1, reason: 'ب + ت birleşir');
      expect(await piecesOf('ب ت'), 2, reason: 'boşluklu kontrol');
      expect(await piecesOf('رب'), 2, reason: 'ر sonrasına bağlanmaz');
      expect(await piecesOf('باب'), 2, reason: 'ا sonrasına bağlanmaz');
      expect(await piecesOf('لا'), 1, reason: 'lam-elif tek bitişik');
      expect(await piecesOf('بَت'), 1, reason: 'hareke birleşmeyi bozmaz');
      expect(c.text.codeUnits, [0x0628, 0x064E, 0x062A]);
    });

    testWidgets('tuşlar imleçte yazar, seçimi değiştirir, odağı kaybettirmez', (
      tester,
    ) async {
      final audio = FakeAudio();
      final (c, _) = await pumpPad(tester, audio: audio);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('writing-field')),
      );
      expect(
        field.keyboardType,
        TextInputType.none,
        reason: 'cihaz klavyesi açılmaz',
      );
      await tapKey(tester, 'ب');
      await tapKey(tester, 'ت');
      expect(c.text, 'بت');
      expect(audio.played, hasLength(2), reason: 'harf sesleri');
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      c.selection = const TextSelection.collapsed(offset: 1);
      await tapKey(tester, 'ن');
      expect(c.text, 'بنت');
      expect(c.selection.baseOffset, 2);
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      await tapKey(tester, 'م');
      expect(c.text, 'م');
      await tester.tap(find.byKey(const ValueKey('key-space')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('key-newline')));
      await tester.pump();
      expect(c.text, 'م \n');
      await tester.tap(find.byKey(const ValueKey('key-backspace')));
      await tester.pump();
      expect(c.text, 'م ');
    });

    testWidgets(
      'harekeler: bölüm, önceki harfe uygulama, boş yerde yönlendirme',
      (tester) async {
        final (c, _) = await pumpPad(tester);
        await tester.tap(find.byKey(const ValueKey('section-haraka')));
        await tester.pump();
        await tapKey(tester, kFatha);
        expect(c.text, '');
        expect(
          find.text('Önce bir harf yaz, sonra harekeyi ekle.'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('section-letters')));
        await tester.pump();
        await tapKey(tester, 'ب');
        await tester.tap(find.byKey(const ValueKey('section-haraka')));
        await tester.pump();
        await tapKey(tester, kShadda);
        await tapKey(tester, kFatha);
        expect(c.text, 'بَّ');
        await tester.tap(find.byKey(const ValueKey('key-backspace')));
        await tester.pump();
        expect(c.text, 'بّ');
        // Ek harfler kendi karakterleridir.
        await tester.tap(find.byKey(const ValueKey('section-extra')));
        await tester.pump();
        await tapKey(tester, 'ة');
        expect(c.text, 'بّة');
      },
    );

    testWidgets('fiziksel klavye / yapıştırma: Latin harf dönüştürülmez', (
      tester,
    ) async {
      final (c, _) = await pumpPad(tester);
      await tester.enterText(
        find.byKey(const ValueKey('writing-field')),
        'Ali علي',
      );
      expect(c.text, 'Ali علي');
    });

    testWidgets('uzunluk sınırı ve kalan gösterge', (tester) async {
      final (c, _) = await pumpPad(tester, maxLength: 3);
      for (final ch in ['ب', 'ت', 'ث', 'ج']) {
        await tapKey(tester, ch);
      }
      expect(c.text, 'بتث');
      expect(find.textContaining('Yazı sınırına geldin'), findsOneWidget);
      expect(find.text('Kalan: 0'), findsOneWidget);
    });

    testWidgets(
      'cihaz klavyesine geçiş; tercih saklanır; ses kapalıyken ses yok',
      (tester) async {
        final audio = FakeAudio();
        final (c, _) = await pumpPad(tester, audio: audio, muted: true);
        await tapKey(tester, 'ب');
        expect(audio.played, isEmpty);
        await tester.tap(find.byKey(const ValueKey('device-keyboard-toggle')));
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(
          find.byKey(const ValueKey('writing-field')),
        );
        expect(field.keyboardType, TextInputType.multiline);
        expect(find.byKey(const ValueKey('key-ب')), findsNothing);
        expect(
          (await SharedPreferences.getInstance()).getBool(
            YaziStore.deviceKeyboardKey,
          ),
          isTrue,
        );
        expect(c.text, 'ب');
      },
    );

    for (final size in const [
      Size(360, 800),
      Size(800, 1280),
      Size(1280, 800),
      Size(800, 360),
      Size(1920, 1080),
    ]) {
      testWidgets('klavye ve alan birlikte sığar: $size', (tester) async {
        await pumpPad(tester, size: size);
        expect(tester.takeException(), isNull);
        final key = tester.getRect(find.byKey(const ValueKey('key-ب')));
        expect(key.width, greaterThanOrEqualTo(44));
        expect(key.height, greaterThanOrEqualTo(44));
        final field = tester.getRect(
          find.byKey(const ValueKey('writing-field')),
        );
        expect(field.height, greaterThanOrEqualTo(60), reason: '$size');
        expect(
          tester.getRect(find.byKey(const ValueKey('key-backspace'))).bottom,
          lessThanOrEqualTo(size.height),
        );
      });
    }
  });

  group('Modlar', () {
    testWidgets('Adını Yaz: boşsa kart yok; kart ekranda; kaydet', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      Uint8List? saved;
      await tester.pumpWidget(
        harness(
          NameModeScreen(
            saver: (bytes, name) async {
              saved = bytes;
              return const SaveResult(SaveOutcome.saved, 'test');
            },
          ),
          FakeAudio(),
        ),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'ب');
      await tester.tap(find.byKey(const ValueKey('key-backspace')));
      await tester.tap(find.byKey(const ValueKey('key-space')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('done-button')));
      await tester.pumpAndSettle();
      expect(find.text('Önce adını yaz.'), findsOneWidget);
      expect(find.byKey(const ValueKey('card-name')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('key-backspace')));
      for (final ch in ['ع', 'ل', 'ي']) {
        await tapKey(tester, ch);
      }
      await tester.tap(find.byKey(const ValueKey('done-button')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('card-name'))).data,
        'علي',
      );
      await tester.tap(find.byKey(const ValueKey('palette-2')));
      await tester.tap(find.byKey(const ValueKey('frame-stars')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('save-card-button')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      final codec = await tester.runAsync(
        () => ui.instantiateImageCodec(saved!),
      );
      final frame = await tester.runAsync(() => codec!.getNextFrame());
      expect(frame!.image.width, greaterThan(300));
      expect(find.textContaining('Kaydedildi'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('Adını Yaz: bu cihazda kaydetme yoksa açıkça söylenir', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      await tester.pumpWidget(
        harness(
          NameModeScreen(
            saver: (_, _) async => const SaveResult(SaveOutcome.unsupported),
          ),
          FakeAudio(),
        ),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'ن');
      await tester.tap(find.byKey(const ValueKey('done-button')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('save-card-button')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('kaydetme henüz yok'), findsOneWidget);
      expect(find.textContaining('Kaydedildi'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets(
      'Bak ve Yaz: ipucu tuşu parlatır; yanlışta yazı silinmez; ipucuyla ayrı kayıt',
      (tester) async {
        setSize(tester, const Size(360, 800));
        await tester.pumpWidget(
          harness(CopyModeScreen(random: math.Random(2)), FakeAudio()),
        );
        await tester.pumpAndSettle();
        var target =
            tester
                .widget<Text>(find.byKey(const ValueKey('example-text')))
                .data!;
        // Yanlış: başka bir harf.
        final wrong = target == 'ب' ? 'ت' : 'ب';
        await tapKey(tester, wrong);
        await tester.tap(find.byKey(const ValueKey('check-button')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Bir daha bakalım'), findsOneWidget);
        expect(fieldController(tester).text, wrong);
        await tester.tap(find.byKey(const ValueKey('key-backspace')));
        await tester.pump();
        // İpucu: sıradaki harfin tuşu belirginleşir.
        await tester.tap(find.byKey(const ValueKey('hint-button')));
        await tester.pumpAndSettle();
        final pad = tester.widget<WritingPad>(find.byType(WritingPad));
        expect(pad.highlight, target);
        await tapKey(tester, target);
        await tester.tap(find.byKey(const ValueKey('check-button')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Harika'), findsOneWidget);
        // Kendi başına: sonraki görevleri tuşlarla yaz.
        for (var i = 1; i < 8; i++) {
          await tester.tap(find.byKey(const ValueKey('next-button')));
          await tester.pumpAndSettle();
          target =
              tester
                  .widget<Text>(find.byKey(const ValueKey('example-text')))
                  .data!;
          for (final ch in target.split('')) {
            await tapKey(tester, ch);
          }
          await tester.tap(find.byKey(const ValueKey('check-button')));
          await tester.pumpAndSettle();
          expect(find.textContaining('Harika'), findsOneWidget, reason: target);
        }
        await tester.tap(find.byKey(const ValueKey('next-button')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Kendi başına: 7 · İpucuyla: 1'),
          findsOneWidget,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('game_history.$kBakYazGameKey.plays'), 1);
        expect(prefs.getString(YaziStore.statsKey(null)), isNotNull);
      },
    );

    testWidgets(
      'Serbest Yaz: kopyala (başarı/başarısızlık), temizle + geri al, taslak',
      (tester) async {
        setSize(tester, const Size(360, 800));
        String? clipboard;
        var fail = false;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              if (fail) throw PlatformException(code: 'denied');
              clipboard = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(harness(const FreeModeScreen(), FakeAudio()));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('copy-button')));
        await tester.pumpAndSettle();
        expect(find.text('Kopyalanacak yazı yok.'), findsOneWidget);
        for (final ch in ['ب', 'ا', 'ب']) {
          await tapKey(tester, ch);
        }
        await tester.tap(find.byKey(const ValueKey('copy-button')));
        await tester.pumpAndSettle();
        expect(clipboard, 'باب');
        expect(clipboard!.codeUnits, [0x0628, 0x0627, 0x0628]);
        expect(find.text('Kopyalandı.'), findsOneWidget);
        fail = true;
        await tester.tap(find.byKey(const ValueKey('copy-button')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Kopyalanamadı'), findsOneWidget);
        expect(find.text('Kopyalandı.'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('clear-button')));
        await tester.pumpAndSettle();
        expect(fieldController(tester).text, '');
        await tester.tap(find.text('Geri Al'));
        await tester.pumpAndSettle();
        expect(fieldController(tester).text, 'باب');

        // Taslak cihazda kalır: ekranı kapatıp açınca geri gelir.
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.pumpWidget(harness(const FreeModeScreen(), FakeAudio()));
        await tester.pumpAndSettle();
        expect(fieldController(tester).text, 'باب');
      },
    );

    testWidgets('bozuk kayıtla açılır', (tester) async {
      SharedPreferences.setMockInitialValues({YaziStore.statsKey(null): '{x'});
      setSize(tester, const Size(360, 800));
      await tester.pumpWidget(
        harness(CopyModeScreen(random: math.Random(1)), FakeAudio()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('example-text')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
