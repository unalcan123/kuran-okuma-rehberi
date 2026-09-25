import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/games.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/dedektif_data.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/widgets/detective_card.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_treni/harf_treni_game_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_treni/harf_treni_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_treni/tren_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_treni/tren_fonts.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_treni/tren_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harf_dedektifi_test.dart' show FakeAudio, harness, setSize;

const fonts = ['Hasenat', 'NotoNaskhArabic', 'NotoSansArabic'];

Future<void> loadFonts() async {
  for (final (family, file) in const [
    ('Hasenat', 'Hasenat.ttf'),
    ('NotoNaskhArabic', 'NotoNaskhArabic-Arapca.ttf'),
    ('NotoSansArabic', 'NotoSansArabic-Arapca.ttf'),
  ]) {
    final bytes = File('assets/fonts/$file').readAsBytesSync();
    await (FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

TrainRoundFactory factory(int seed) =>
    TrainRoundFactory(math.Random(seed), fonts: fonts, baseFont: 'Hasenat');

TrainSession fixedSession(List<TrainRound> rounds) {
  final f = _FixedFactory(rounds);
  return TrainSession(
    level: rounds.first.level,
    targets: [for (final r in rounds) r.targetId],
    factory: f,
  );
}

class _FixedFactory extends TrainRoundFactory {
  _FixedFactory(this.rounds)
    : super(math.Random(1), fonts: fonts, baseFont: 'Hasenat');
  final List<TrainRound> rounds;
  int _i = 0;

  @override
  TrainRound build(TrainLevel level, int targetId) => rounds[_i++];
}

// ---- widget yardımcıları ---------------------------------------------------

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

int targetOnScreen(WidgetTester tester) {
  final t = tester.widget<Text>(
    find.descendant(
      of: find.byKey(const ValueKey('target-glyph')),
      matching: find.byType(Text),
    ),
  );
  return letterIdOfChar(t.data!)!;
}

List<DetectiveCard> cards(WidgetTester tester) =>
    tester.widgetList<DetectiveCard>(find.byType(DetectiveCard)).toList();

int cardLetter(DetectiveCard c) =>
    letterIdOfChar(c.text.replaceAll(kTatweel, ''))!;

Finder cardInk(DetectiveCard c) =>
    find.descendant(of: find.byKey(c.key!), matching: find.byType(InkWell));

String wagonText(WidgetTester tester) =>
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('wagon-progress')),
            matching: find.byType(Text),
          ),
        )
        .data!;

Future<void> closeDemoIfShown(WidgetTester tester) async {
  if (find.byKey(const ValueKey('demo-close')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const ValueKey('demo-close')));
    await settle(tester);
  }
}

Future<void> fillTrain(WidgetTester tester) async {
  final target = targetOnScreen(tester);
  for (final c in cards(tester).where((c) => cardLetter(c) == target)) {
    await tester.tap(cardInk(c));
    await tester.pump(const Duration(milliseconds: 500));
  }
  // Kart uçuşu + kalkış + kısa düğme kilidi bitene kadar.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    final next = find.byKey(const ValueKey('next-train-button'));
    if (next.evaluate().isNotEmpty &&
        tester.widget<ButtonStyleButton>(next).onPressed != null) {
      break;
    }
  }
  await tester.pumpAndSettle();
}

Future<FakeAudio> pumpGame(
  WidgetTester tester,
  TrainLevel level, {
  int seed = 3,
  List<String> fontList = fonts,
}) async {
  final audio = FakeAudio();
  await tester.pumpWidget(
    harness(
      HarfTreniGameScreen(
        key: UniqueKey(),
        level: level,
        fonts: fontList,
        random: math.Random(seed),
      ),
      audio,
    ),
  );
  // İlk kullanım örneği sürekli döner: pumpAndSettle yerine sabit süre.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  return audio;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Tur üretimi', () {
    test('bütün seviyeler, bütün hedefler: tamamlanabilir ve kurallara uygun', () {
      for (final level in TrainLevel.values) {
        for (final target in TrainRoundFactory.candidatesFor(level)) {
          for (var seed = 0; seed < 6; seed++) {
            final r = factory(seed * 31 + target).build(level, target);
            final why = '${level.name} hedef $target seed $seed';
            expect(r.cards, hasLength(level.cards), reason: why);
            expect(r.correctIds, hasLength(level.wagons), reason: why);
            expect(r.cards.map((c) => c.id).toSet(), hasLength(r.cards.length));
            final t = letterById(target);
            for (final c in r.cards) {
              // Yalnızca harfin gerçek biçimleri (bağlanmayana yapay biçim yok).
              expect(
                letterById(c.letterId).forms,
                contains(c.form),
                reason: why,
              );
              if (c.letterId == target) continue;
              switch (level) {
                case TrainLevel.l1:
                case TrainLevel.l2:
                case TrainLevel.l4:
                  expect(looksAlike(c.letterId, target), isFalse, reason: why);
                case TrainLevel.l3:
                  expect(
                    similarGroupOf(target),
                    contains(c.letterId),
                    reason: why,
                  );
              }
            }
            final correct = r.cards.where((c) => c.letterId == target).toList();
            final wrong = r.cards.where((c) => c.letterId != target).toList();
            switch (level) {
              case TrainLevel.l1:
                expect(
                  r.cards.every(
                    (c) => c.form == LetterForm.isolated && c.font == 'Hasenat',
                  ),
                  isTrue,
                );
                expect(
                  wrong.map((c) => c.letterId).toSet(),
                  hasLength(wrong.length),
                );
              case TrainLevel.l2:
                expect(
                  correct.map((c) => c.form).toSet(),
                  t.joinsNext ? LetterForm.values.toSet() : t.forms.toSet(),
                  reason: why,
                );
                expect(r.cards.every((c) => c.font == 'Hasenat'), isTrue);
              case TrainLevel.l3:
                // Çeldiriciler doğru kartlarla karşılaştırılabilir biçimlerde.
                final forms = correct.map((c) => c.form).toSet();
                expect(
                  wrong.every((c) => forms.contains(c.form)),
                  isTrue,
                  reason: why,
                );
              case TrainLevel.l4:
                // Önce yalnızca yazı tipi değişir.
                expect(
                  r.cards.every((c) => c.form == LetterForm.isolated),
                  isTrue,
                );
                expect(
                  correct.map((c) => c.font).toSet().length,
                  greaterThanOrEqualTo(2),
                  reason: why,
                );
            }
          }
        }
      }
    });

    test('kart sırası karışır; doğrular sabit yerde değil', () {
      final layouts = {
        for (var seed = 0; seed < 12; seed++)
          [
            for (final c in factory(seed).build(TrainLevel.l1, 2).cards)
              c.letterId == 2 ? 1 : 0,
          ].join(),
      };
      expect(layouts.length, greaterThan(6));
    });

    test('art arda aynı hedef yok; Seviye 3 yalnızca benzer gruplar', () {
      for (var seed = 0; seed < 50; seed++) {
        for (final level in TrainLevel.values) {
          final t = factory(seed).pickTargets(level);
          expect(t, hasLength(kTrainCount));
          for (var i = 1; i < t.length; i++) {
            expect(t[i], isNot(t[i - 1]));
          }
          if (level == TrainLevel.l3) {
            expect(t.every((id) => similarGroupOf(id) != null), isTrue);
          }
        }
      }
    });
  });

  group('Oturum', () {
    TrainRound r(int seed) => factory(seed).build(TrainLevel.l2, 2);

    test('çift dokunma ikinci vagonu doldurmaz, ikinci puan vermez', () {
      final s = fixedSession([r(1)]);
      final id = s.current.round.correctIds.first;
      expect(s.tap(id), TrainTap.placed);
      expect(s.tap(id), TrainTap.alreadyPlaced);
      expect(s.current.placed, [id]);
      expect(s.points, 10);
    });

    test('yanlış kart vagona girmez, puan silinmez, tekrar sayılmaz', () {
      final s = fixedSession([r(2)]);
      final right = s.current.round.correctIds;
      final wrong = s.current.round.cards.firstWhere((c) => c.letterId != 2).id;
      s.tap(right.first);
      expect(s.tap(wrong), TrainTap.wrong);
      expect(s.tap(wrong), TrainTap.repeatWrong);
      expect(s.current.placed, [right.first]);
      expect(s.points, 10);
      expect(s.current.wrong, {wrong});
      expect(s.current.hintSuggested, isFalse);
    });

    test(
      'ilk deneme / tekrar deneyerek / ipucuyla ayrı; tur bitince dokunma yok',
      () {
        final s = fixedSession([r(3), r(4)]);
        final round = s.current.round;
        final right = round.correctIds;
        final wrongs = [
          for (final c in round.cards)
            if (c.letterId != 2) c.id,
        ];
        s.tap(right[0]); // ilk deneme
        s.tap(wrongs[0]);
        s.tap(wrongs[1]);
        expect(s.current.hintSuggested, isTrue);
        s.tap(right[1]); // tekrar deneyerek
        final h = s.hint(math.Random(1))!;
        s.tap(h); // ipucuyla
        for (final id in right) {
          s.tap(id);
        }
        expect(s.current.complete, isTrue);
        expect(s.tap(wrongs[2]), TrainTap.ignored);
        expect(s.countOf(TrainFind.firstTry), 2);
        expect(s.countOf(TrainFind.afterRetry), 1);
        expect(s.countOf(TrainFind.withHint), 1);
        expect(s.points, 40);
        expect(s.trainsDone, 1);
        expect(s.next(), isTrue);
        expect(s.current.placed, isEmpty);
        expect(s.current.wrong, isEmpty);
        expect(s.weakLetters(), [2]);
        expect(s.struggledTargets, {2});
      },
    );
  });

  group('Yazı tipleri', () {
    testWidgets('yüklenmemiş yazı tipi Seviye 4\'te kullanılmaz', (
      tester,
    ) async {
      // Test ortamında yazı tipleri yüklenmemiştir: hepsi yedeğe düşer.
      expect(verifiedTrainFonts().length, lessThan(2));
      await loadFonts();
      expect(verifiedTrainFonts(), fonts);
    });

    testWidgets('yazı tipleri harfleri gerçekten farklı çiziyor', (
      tester,
    ) async {
      await loadFonts();
      Future<List<bool>> mask(String family, String ch) async {
        final p = TextPainter(
          text: TextSpan(
            text: ch,
            style: TextStyle(
              fontFamily: family,
              fontSize: 120,
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        final rec = ui.PictureRecorder();
        // Glifi kendi kutusuna oturt: boyut farkı değil şekil farkı ölçülsün.
        final canvas = Canvas(rec)..scale(64 / p.width, 64 / p.height);
        p.paint(canvas, Offset.zero);
        final img = await rec.endRecording().toImage(64, 64);
        final data = (await img.toByteData())!;
        return [
          for (var i = 0; i < 64 * 64; i++) data.getUint8(i * 4 + 3) > 100,
        ];
      }

      await tester.runAsync(() async {
        for (final other in ['NotoNaskhArabic', 'NotoSansArabic']) {
          var total = 0.0;
          for (final l in kDetectiveLetters) {
            final a = await mask('Hasenat', l.char);
            final b = await mask(other, l.char);
            var inter = 0, union = 0;
            for (var i = 0; i < a.length; i++) {
              if (a[i] && b[i]) inter++;
              if (a[i] || b[i]) union++;
            }
            total += 1 - inter / union;
          }
          expect(total / 28, greaterThan(0.3), reason: other);
        }
      });
    });

    test('lisans dosyası ve yazı tipleri projede', () {
      expect(File('assets/fonts/OFL-NotoArabic.txt').existsSync(), isTrue);
      expect(
        File('assets/fonts/NotoNaskhArabic-Arapca.ttf').existsSync(),
        isTrue,
      );
      expect(
        File('assets/fonts/NotoSansArabic-Arapca.ttf').existsSync(),
        isTrue,
      );
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: NotoNaskhArabic'));
      expect(pubspec, contains('family: NotoSansArabic'));
    });
  });

  test('bozuk kayıtla boş başlar', () async {
    SharedPreferences.setMockInitialValues({
      TrainProgressStore.keyFor(null): '{x',
    });
    final store = TrainProgressStore();
    expect(await store.weightsFor(TrainLevel.l1), isEmpty);
    await store.applySession(TrainLevel.l1, struggled: {5}, clean: {});
    expect(await store.weightsFor(TrainLevel.l1), {5: 1});
    expect(await store.weightsFor(TrainLevel.l2), isEmpty);
  });

  test('menüde; Sonuçlarım\'da seviyeler ayrı', () {
    final e = kGames.firstWhere((g) => g.id == kHarfTreniGameKey);
    expect(e.variants.map((v) => v.key), [
      'harf_treni.l1',
      'harf_treni.l2',
      'harf_treni.l3',
      'harf_treni.l4',
    ]);
  });

  group('Oyun ekranı', () {
    testWidgets(
      'Seviye 1 tam oturum: örnek, çift dokunma, yanlış, tek kayıt, tekrar oyna',
      (tester) async {
        setSize(tester, const Size(360, 800));
        final audio = await pumpGame(tester, TrainLevel.l1);
        expect(find.byKey(const ValueKey('demo')), findsOneWidget);
        await closeDemoIfShown(tester);
        expect(
          (await SharedPreferences.getInstance()).getBool(
            TrainProgressStore.demoKey,
          ),
          isTrue,
        );

        final target = targetOnScreen(tester);
        expect(wagonText(tester), '0 / 3 vagon hazır');
        final right =
            cards(tester).where((c) => cardLetter(c) == target).toList();
        final wrong =
            cards(tester).where((c) => cardLetter(c) != target).toList();
        expect(right, hasLength(3));

        // Çift dokunma: tek vagon.
        await tester.tap(cardInk(right[0]));
        await tester.pump(const Duration(milliseconds: 40));
        await tester.tap(cardInk(right[0]));
        await tester.pump(const Duration(milliseconds: 600));
        expect(wagonText(tester), '1 / 3 vagon hazır');
        expect(audio.played, isNotEmpty);

        // Yanlış: vagona girmez.
        await tester.tap(cardInk(wrong[0]));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('Bir daha bakalım'), findsOneWidget);
        expect(wagonText(tester), '1 / 3 vagon hazır');

        await fillTrain(tester);
        expect(find.byKey(const ValueKey('next-train-button')), findsOneWidget);
        expect(find.text('Tren istasyona vardı!'), findsOneWidget);
        for (var i = 1; i < kTrainCount; i++) {
          await tester.tap(find.byKey(const ValueKey('next-train-button')));
          await settle(tester);
          expect(wagonText(tester), '0 / 3 vagon hazır');
          await fillTrain(tester);
        }
        await tester.tap(find.byKey(const ValueKey('next-train-button')));
        await settle(tester);
        expect(find.text('Bütün trenler istasyonda!'), findsOneWidget);
        expect(find.text('5 tren dolduruldu.'), findsOneWidget);
        expect(find.text('150 Puan'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('game_history.harf_treni.l1.plays'), 1);

        await tester.tap(find.byKey(const ValueKey('replay-button')));
        await settle(tester);
        await closeDemoIfShown(tester);
        expect(wagonText(tester), '0 / 3 vagon hazır');
        expect(prefs.getInt('game_history.harf_treni.l1.plays'), 1);
      },
    );

    testWidgets('Seviye 3: benzer harf reddedilir, noktalara dair ipucu', (
      tester,
    ) async {
      setSize(tester, const Size(800, 1280));
      SharedPreferences.setMockInitialValues({
        TrainProgressStore.demoKey: true,
      });
      await pumpGame(tester, TrainLevel.l3);
      final target = targetOnScreen(tester);
      final wrong = cards(tester).firstWhere((c) => cardLetter(c) != target);
      expect(similarGroupOf(target), contains(cardLetter(wrong)));
      await tester.tap(cardInk(wrong));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('nokta'), findsOneWidget);
      expect(wagonText(tester), startsWith('0 /'));
      // İki yanlıştan sonra ipucu belirgin; ipucu bir doğru kartı gösterir.
      final wrong2 = cards(tester).lastWhere((c) => cardLetter(c) != target);
      await tester.tap(cardInk(wrong2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget(find.byKey(const ValueKey('hint-button'))),
        isA<FilledButton>(),
      );
      await tester.tap(find.byKey(const ValueKey('hint-button')));
      await tester.pump(const Duration(milliseconds: 300));
      final hinted = cards(
        tester,
      ).where((c) => c.state == DetectiveCardState.hinted);
      expect(hinted, hasLength(1));
      expect(cardLetter(hinted.first), target);
    });

    testWidgets('Seviye 4: doğru kartlar farklı yazı tiplerinde', (
      tester,
    ) async {
      await loadFonts();
      setSize(tester, const Size(1280, 800));
      SharedPreferences.setMockInitialValues({
        TrainProgressStore.demoKey: true,
      });
      await pumpGame(tester, TrainLevel.l4);
      final target = targetOnScreen(tester);
      final right = cards(tester).where((c) => cardLetter(c) == target);
      expect(
        right.map((c) => c.fontFamily).toSet().length,
        greaterThanOrEqualTo(2),
      );
      await fillTrain(tester);
      expect(find.byKey(const ValueKey('next-train-button')), findsOneWidget);
    });

    testWidgets('animasyon sırasında çıkınca zamanlayıcı ve uçan kart kalmaz', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      SharedPreferences.setMockInitialValues({
        TrainProgressStore.demoKey: true,
      });
      await tester.pumpWidget(
        harness(
          Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => HarfTreniGameScreen(
                                  level: TrainLevel.l1,
                                  fonts: fonts,
                                  random: math.Random(4),
                                ),
                          ),
                        ),
                    child: const Text('MENÜ'),
                  ),
                ),
          ),
          FakeAudio(),
        ),
      );
      await tester.tap(find.text('MENÜ'));
      await settle(tester);
      final target = targetOnScreen(tester);
      final right =
          cards(tester).where((c) => cardLetter(c) == target).toList();
      await tester.tap(cardInk(right[0]));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(cardInk(right[1]));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(cardInk(right[2]));
      await tester.pump(const Duration(milliseconds: 100)); // kart uçuyor
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.pop();
      await tester.pumpAndSettle();
      expect(find.text('MENÜ'), findsOneWidget);
      // Test çerçevesi bekleyen zamanlayıcı kalırsa testi düşürür.
    });

    testWidgets('azaltılmış hareket: kart hemen yerleşir, tren hemen varır', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      SharedPreferences.setMockInitialValues({
        TrainProgressStore.demoKey: true,
      });
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            disableAnimations: true,
          ),
          child: harness(
            HarfTreniGameScreen(
              level: TrainLevel.l1,
              fonts: fonts,
              random: math.Random(5),
            ),
            FakeAudio(),
          ),
        ),
      );
      await settle(tester);
      final target = targetOnScreen(tester);
      for (final c in cards(tester).where((c) => cardLetter(c) == target)) {
        await tester.tap(cardInk(c));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('next-train-button')), findsOneWidget);
    });

    testWidgets('klavye: kart odaklanıp Enter ile seçilir', (tester) async {
      setSize(tester, const Size(800, 1280));
      SharedPreferences.setMockInitialValues({
        TrainProgressStore.demoKey: true,
      });
      await pumpGame(tester, TrainLevel.l1);
      final target = targetOnScreen(tester);
      final right = cards(tester).firstWhere((c) => cardLetter(c) == target);
      final inside = find.descendant(
        of: cardInk(right),
        matching: find.byType(AnimatedContainer),
      );
      Focus.of(tester.element(inside)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 600));
      expect(wagonText(tester), '1 / 3 vagon hazır');
    });

    testWidgets('ses kapalıyken ses çalmaz', (tester) async {
      setSize(tester, const Size(360, 800));
      SharedPreferences.setMockInitialValues({
        TrainProgressStore.demoKey: true,
        TrainProgressStore.mutedKey: true,
      });
      final audio = await pumpGame(tester, TrainLevel.l2);
      await fillTrain(tester);
      expect(audio.played, isEmpty);
    });

    for (final level in TrainLevel.values) {
      testWidgets('${level.title}: 5 ekran boyutunda tren ve kartlar sığar', (
        tester,
      ) async {
        await loadFonts();
        SharedPreferences.setMockInitialValues({
          TrainProgressStore.demoKey: true,
        });
        for (final size in const [
          Size(360, 800),
          Size(800, 1280),
          Size(1280, 800),
          Size(800, 360),
          Size(1920, 1080),
        ]) {
          setSize(tester, size);
          await pumpGame(tester, level);
          expect(tester.takeException(), isNull, reason: '$size');
          for (final c in cards(tester)) {
            final rect = tester.getRect(find.byKey(c.key!));
            expect(rect.width, greaterThanOrEqualTo(44), reason: '$size');
            expect(
              rect.bottom,
              lessThanOrEqualTo(size.height),
              reason: '$size',
            );
          }
          final glyph = tester.getRect(
            find.byKey(const ValueKey('target-glyph')),
          );
          expect(glyph.left, greaterThanOrEqualTo(0), reason: '$size');
          expect(glyph.height, greaterThanOrEqualTo(30), reason: '$size');
        }
      });
    }

    testWidgets(
      'başlangıç: Seviye 1 önerilir; yazı tipi yoksa Seviye 4 kapalı',
      (tester) async {
        setSize(tester, const Size(360, 800));
        await tester.pumpWidget(
          harness(const HarfTreniScreen(fonts: []), FakeAudio()),
        );
        await settle(tester);
        expect(
          find.text('Aynı harfleri bul, vagonları doldur!'),
          findsOneWidget,
        );
        expect(find.text('Önerilen'), findsOneWidget);
        await tester.scrollUntilVisible(
        find.byKey(const ValueKey('fonts-missing')),
        100,
      );
      expect(find.byKey(const ValueKey('fonts-missing')), findsOneWidget);
        final l4 = tester.widget<InkWell>(
          find.byKey(const ValueKey('level-4')),
        );
        expect(l4.onTap, isNull);
      },
    );
  });
}
