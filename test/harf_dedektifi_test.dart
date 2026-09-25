import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letter_forms_data.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/games.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/dedektif_data.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/dedektif_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/dedektif_progress_store.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/harf_dedektifi_game_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/harf_dedektifi_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/widgets/detective_card.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_dedektifi/widgets/tappable_word.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudio extends ChangeNotifier implements AudioService {
  final played = <String>[];
  final effects = <String>[];

  @override
  bool get isPlaying => false;

  @override
  void preload(Iterable<String?> assets) {}

  @override
  Future<void> playAsset(String asset) async => played.add(asset);

  @override
  Future<void> playEffect(String asset) async => effects.add(asset);

  @override
  Future<void> stopEffect() async {}

  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget harness(Widget child, FakeAudio audio) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AudioService>.value(value: audio),
    Provider<GameScoreStore>.value(value: GameScoreStore()),
    ChangeNotifierProvider(
      create: (_) => PlayerRepository()..promptedThisSession = true,
    ),
  ],
  child: MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
    home: child,
  ),
);

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> loadHasenat() async {
  final font = File('assets/fonts/Hasenat.ttf').readAsBytesSync();
  final loader = FontLoader('Hasenat')
    ..addFont(Future.value(ByteData.view(font.buffer)));
  await loader.load();
}

WordRound wordRound(int target, List<String> texts) => WordRound(target, [
  for (final t in texts) DetectiveWord.tryParse(t)!,
]);

/// Oturumu belirli turlarla kurar (fabrika yerine sabit tur).
class FixedFactory extends DetectiveRoundFactory {
  FixedFactory(this.rounds) : super(math.Random(1));
  final List<DetectiveRound> rounds;

  @override
  DetectiveRound build(DetectiveMode mode, int targetId, int roundIndex) =>
      rounds[roundIndex];
}

DetectiveSession sessionOf(DetectiveMode mode, List<DetectiveRound> rounds) =>
    DetectiveSession(
      mode: mode,
      targets: [for (final r in rounds) r.targetId],
      factory: FixedFactory(rounds),
    );

// ---------------------------------------------------------------------------
// Widget testi yardımcıları

int targetIdOnScreen(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byKey(const ValueKey('target-glyph')),
      matching: find.byType(Text),
    ),
  );
  return letterIdOfChar(text.data!)!;
}

Finder cardInk(int i) => find.descendant(
  of: find.byKey(ValueKey('card-$i')),
  matching: find.byType(InkWell),
);

List<int> correctCardIndexes(WidgetTester tester) {
  final target = letterById(targetIdOnScreen(tester));
  final texts = {for (final f in target.forms) target.display(f)};
  final cards = tester.widgetList<DetectiveCard>(find.byType(DetectiveCard));
  return [
    for (final card in cards)
      if (texts.contains(card.text))
        int.parse((card.key! as ValueKey<String>).value.substring(5)),
  ];
}

List<int> wrongCardIndexes(WidgetTester tester) {
  final right = correctCardIndexes(tester).toSet();
  final count = find.byType(DetectiveCard).evaluate().length;
  return [
    for (var i = 0; i < count; i++)
      if (!right.contains(i)) i,
  ];
}

String counterText(WidgetTester tester) =>
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('found-counter')),
            matching: find.byType(Text),
          ),
        )
        .data!;

Future<void> startSearchIfIntro(WidgetTester tester) async {
  if (find.byKey(const ValueKey('start-search')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const ValueKey('start-search')));
    await tester.pumpAndSettle();
  }
}

Future<void> solveCardRound(WidgetTester tester) async {
  await startSearchIfIntro(tester);
  for (final i in correctCardIndexes(tester)) {
    await tester.tap(cardInk(i));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<Widget> pumpGame(
  WidgetTester tester,
  DetectiveMode mode, {
  FakeAudio? audio,
  int seed = 7,
}) async {
  final game = HarfDedektifiGameScreen(
    mode: mode,
    choice: kLetterChoices.first,
    random: math.Random(seed),
  );
  await tester.pumpWidget(harness(game, audio ?? FakeAudio()));
  await tester.pumpAndSettle();
  return game;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Harf kimliği ve bağlantı biçimleri', () {
    test('28 harf, her biri tek temel Unicode harfi (sunum biçimi yok)', () {
      expect(kDetectiveLetters, hasLength(28));
      for (final l in kDetectiveLetters) {
        expect(l.char.length, 1, reason: l.name);
        final cu = l.char.codeUnitAt(0);
        expect(cu >= 0x0621 && cu <= 0x064A, isTrue, reason: l.name);
        expect(letterIdOfChar(l.char), l.id);
      }
      expect(letterById(27).char, 'ه'); // veride 'هـ' yazılır
    });

    test('ا د ذ ر ز و yalnızca iki görünüm; sonraki harfe bağlanmaz', () {
      for (final id in kNonJoiningLetterIds) {
        final l = letterById(id);
        expect(l.forms, [LetterForm.isolated, LetterForm.finalForm]);
        for (final f in l.forms) {
          expect(l.display(f).endsWith(kTatweel), isFalse, reason: l.name);
        }
      }
      expect(kNonJoiningLetterIds.map((id) => letterById(id).char).toSet(), {
        'ا',
        'د',
        'ذ',
        'ر',
        'ز',
        'و',
      });
    });

    test('bağlanan harflerin biçimleri Ders 2 verisiyle aynı', () {
      for (final letter in kLetterFormLetters) {
        final id = letterIdOfChar(letter.isolatedForm.replaceAll(kTatweel, ''));
        if (id == null) continue; // lam-elif
        final l = letterById(id);
        if (!l.joinsNext) continue;
        expect(l.display(LetterForm.initial), letter.initialForm);
        expect(l.display(LetterForm.medial), letter.medialForm);
        expect(l.display(LetterForm.finalForm), letter.finalForm);
      }
    });

    test('elif/hemze varyantları sessizce elife indirgenmez', () {
      for (final c in ['أ', 'إ', 'آ', 'ٱ', 'ء', 'ؤ', 'ئ', 'ى', 'ة', kTatweel]) {
        expect(letterIdOfChar(c), isNull, reason: c);
      }
    });

    test('harf seçimi grupları lam-elifi içermez', () {
      for (final c in kLetterChoices) {
        expect(c.ids, isNotEmpty);
        expect(c.ids.every((id) => id >= 1 && id <= 28), isTrue);
      }
      expect(kLetterChoices.first.ids, hasLength(28));
    });
  });

  group('Kelime havuzu', () {
    test('yalnızca projedeki Ders 2 örnek kelimeleri; zor durumlar dışarıda', () {
      final source = {
        for (final l in kLetterFormLetters) ...?l.positionExamples,
      };
      final pool = {for (final w in kDetectiveWords) w.text};
      expect(pool.difference(source), isEmpty);
      for (final excluded in [
        'أب',
        'مرآة',
        'مزرعة',
        'حائط',
        'لاعب',
        'سلام',
        'إلا',
      ]) {
        expect(pool.contains(excluded), isFalse, reason: excluded);
      }
      expect(pool.length, greaterThanOrEqualTo(60));
      for (final w in kDetectiveWords) {
        expect(w.text.contains(kTatweel), isFalse, reason: w.text);
      }
    });

    test('tekrarlanan harf ayrı ayrı sayılır', () {
      final bab = DetectiveWord.tryParse('باب')!;
      expect(bab.occurrencesOf(2), [0, 2]);
      final round = wordRound(2, ['باب', 'كتب']);
      expect(round.correctIds, ['w0.0', 'w0.2', 'w1.2']);
    });

    test('harekeler ayrı harf değil, önündeki harfle birlikte', () {
      final word = DetectiveWord.tryParse('بَابٌ')!;
      expect(word.letters, hasLength(3));
      expect(word.letters[0].end - word.letters[0].start, 2);
      expect(word.letters[2].end - word.letters[2].start, 2);
    });

    test('kelime modunda en az birkaç hedef harf var', () {
      expect(wordModeLetterIds().length, greaterThanOrEqualTo(20));
      for (final id in wordModeLetterIds()) {
        final round = DetectiveRoundFactory(math.Random(id)).wordsRound(id);
        expect(round.words.length, inInclusiveRange(2, 3));
        expect(round.correctIds, isNotEmpty);
      }
    });
  });

  group('Tur üretimi', () {
    test('Şekilleri Tanı: 6 → 9 kart, kimlikle doğru, ilk turlarda benzersiz', () {
      for (var seed = 0; seed < 40; seed++) {
        final f = DetectiveRoundFactory(math.Random(seed));
        for (var r = 0; r < 5; r++) {
          final target = 1 + seed % 28;
          final round = f.shapesRound(target, r);
          expect(round.cards.length, DetectiveRoundFactory.shapeCardCount(r));
          expect(round.correctIds.length, letterById(target).forms.length);
          final texts = round.cards.map((c) => c.text).toSet();
          expect(texts.length, round.cards.length, reason: 'aynı kart yok');
          if (r < 2) {
            for (final c in round.cards) {
              if (c.letterId != target) {
                expect(looksAlike(c.letterId, target), isFalse);
              }
            }
          }
        }
      }
      expect(DetectiveRoundFactory.shapeCardCount(0), 6);
      expect(DetectiveRoundFactory.shapeCardCount(4), 9);
    });

    test('kartların sırası değişir', () {
      final orders = {
        for (var seed = 0; seed < 10; seed++)
          DetectiveRoundFactory(math.Random(seed))
              .shapesRound(2, 0)
              .correctIds
              .join(','),
      };
      expect(orders.length, greaterThan(3));
    });

    test('Benzer Harfler: aynı grup, aynı bağlantı biçimleri', () {
      for (final group in kSimilarGroups) {
        for (final target in group) {
          final round = DetectiveRoundFactory(math.Random(target))
              .similarRound(target);
          expect(round.cards.map((c) => c.letterId).toSet(), group.toSet());
          final formsByLetter = {
            for (final id in group)
              (round.cards
                      .where((c) => c.letterId == id)
                      .map((c) => c.form.index)
                      .toList()
                    ..sort())
                  .join(','),
          };
          expect(formsByLetter, hasLength(1));
          expect(round.correctIds.length, greaterThanOrEqualTo(2));
        }
      }
    });

    test('zorlanılan harf daha sık gelir, diğerleri de gelir', () {
      final counts = <int, int>{};
      for (var seed = 0; seed < 300; seed++) {
        final targets = DetectiveRoundFactory(math.Random(seed)).pickTargets(
          [2, 3, 4, 5, 6, 7, 8, 9],
          weights: {2: 3},
        );
        expect(targets, hasLength(kDetectiveRoundCount));
        for (final t in targets) {
          counts[t] = (counts[t] ?? 0) + 1;
        }
      }
      expect(counts[2]!, greaterThan(counts[3]! * 1.3));
      for (final id in [3, 4, 5, 6, 7, 8, 9]) {
        expect(counts[id] ?? 0, greaterThan(50), reason: '$id');
      }
    });

    test('Zorlandıklarımı Çalış: turların çoğu o harfler', () {
      final targets = DetectiveRoundFactory(math.Random(3)).pickTargets(
        [for (var i = 1; i <= 28; i++) i],
        focus: [5],
      );
      expect(targets.where((t) => t == 5).length, 3);
    });
  });

  group('Oturum ve puan', () {
    test('doğru her yeni örnek 10 puan; aynı doğruya tekrar basmak puan vermez', () {
      final s = sessionOf(DetectiveMode.words, [
        wordRound(2, ['باب', 'كتب']),
      ]);
      expect(s.tap('w0.0'), TapResult.found);
      expect(s.points, 10);
      expect(s.tap('w0.0'), TapResult.alreadyFound);
      expect(s.points, 10);
      expect(s.current.found.length, 1);
      expect(s.tap('w0.2'), TapResult.found);
      expect(s.tap('w1.2'), TapResult.found);
      expect(s.current.complete, isTrue);
      expect(s.points, 30);
      expect(s.tap('w0.1'), TapResult.ignored);
    });

    test('yanlış turu bitirmez, puan silmez; aynı yanlış tekrar sayılmaz', () {
      final s = sessionOf(DetectiveMode.words, [
        wordRound(2, ['باب', 'كتب']),
      ]);
      s.tap('w0.0');
      expect(s.tap('w0.1'), TapResult.wrong);
      for (var i = 0; i < 5; i++) {
        expect(s.tap('w0.1'), TapResult.repeatWrong);
      }
      expect(s.points, 10);
      expect(s.current.complete, isFalse);
      expect(s.current.wrong, {'w0.1'});
      expect(s.current.hintSuggested, isFalse);
      expect(s.weakSpots().single.letterId, 2);
      s.tap('w1.0');
      expect(s.current.hintSuggested, isTrue);
    });

    test('ilk deneme / tekrar deneyerek / ipucuyla ayrı sayılır', () {
      final s = sessionOf(DetectiveMode.words, [
        wordRound(2, ['باب', 'كتب']),
      ]);
      s.tap('w0.0'); // ilk deneme
      s.tap('w0.1'); // yanlış
      s.tap('w0.2'); // tekrar deneyerek
      final hinted = s.hint(math.Random(1));
      expect(hinted, 'w1.2');
      expect(s.hint(math.Random(2)), hinted, reason: 'aynı ipucu');
      s.tap(hinted!);
      expect(s.countOf(FindKind.firstTry), 1);
      expect(s.countOf(FindKind.afterRetry), 1);
      expect(s.countOf(FindKind.withHint), 1);
      expect(s.foundCount, 3);
      expect(s.points, 30);
    });

    test('yeni tur önceki turun durumunu taşımaz', () {
      final s = sessionOf(DetectiveMode.words, [
        wordRound(2, ['باب', 'كتب']),
        wordRound(2, ['باب', 'كتب']),
      ]);
      expect(s.next(), isFalse, reason: 'tur bitmeden geçilmez');
      s.tap('w0.1');
      s.tap('w0.0');
      s.tap('w0.2');
      s.hint(math.Random(1));
      s.tap('w1.2');
      expect(s.next(), isTrue);
      expect(s.current.found, isEmpty);
      expect(s.current.wrong, isEmpty);
      expect(s.current.hintedId, isNull);
      expect(s.tap('w0.0'), TapResult.found);
      expect(s.points, 40);
    });

    test('şekil kartlarında doğruluk metinle değil kimlikle', () {
      final round = CardRound(2, const [
        ShapeCard(2, LetterForm.initial),
        ShapeCard(3, LetterForm.initial),
        ShapeCard(25, LetterForm.initial),
        ShapeCard(2, LetterForm.finalForm),
      ]);
      expect(round.correctIds, ['c0', 'c3']);
      final s = sessionOf(DetectiveMode.similar, [round]);
      s.tap('c1');
      expect(s.weakSpots().single, const WeakSpot(2, LetterForm.initial));
    });

    test('zorlanılanlar en fazla 3 ve kalıcı ağırlık', () {
      final s = sessionOf(DetectiveMode.words, [
        wordRound(2, ['باب', 'كتب']),
      ]);
      s.tap('w0.1');
      s.tap('w1.0');
      s.tap('w1.1');
      s.tap('w0.0');
      s.tap('w0.2');
      s.tap('w1.2');
      s.finish();
      s.finish();
      expect(s.weakSpots().length, lessThanOrEqualTo(3));
      expect(s.weakLetterIds(), [2]);
      expect(s.struggledTargets, {2});
      expect(s.cleanTargets, isEmpty);
    });
  });

  group('Yerel kayıt', () {
    test('bozuk kayıtla boş başlar, sonra düzgün yazar', () async {
      SharedPreferences.setMockInitialValues({
        DetectiveProgressStore.keyFor(null): '{bozuk json',
      });
      final store = DetectiveProgressStore();
      expect(await store.weightsFor(DetectiveMode.shapes), isEmpty);
      await store.applySession(
        DetectiveMode.shapes,
        struggled: {2, 5},
        clean: {7},
      );
      expect(await store.weightsFor(DetectiveMode.shapes), {2: 1, 5: 1});
      await store.applySession(
        DetectiveMode.shapes,
        struggled: {},
        clean: {2},
      );
      expect(await store.weightsFor(DetectiveMode.shapes), {5: 1});
      expect(await store.weightsFor(DetectiveMode.words), isEmpty);
    });

    test('yanlış türde değerler yok sayılır', () async {
      SharedPreferences.setMockInitialValues({
        DetectiveProgressStore.keyFor('p1'):
            '{"sekiller": {"2": "x", "3": 99, "a": 1}, "kelime": 5}',
      });
      final store = DetectiveProgressStore();
      expect(await store.weightsFor(DetectiveMode.shapes, profileId: 'p1'), {
        3: DetectiveProgressStore.maxWeight,
      });
    });
  });

  test('her hedef harfin ses dosyası var', () {
    for (final l in kDetectiveLetters) {
      expect(l.audio, isNotNull, reason: l.name);
      expect(File('assets/${l.audio}').existsSync(), isTrue, reason: l.audio);
    }
  });

  test('menüde ve Sonuçlarım\'da modlar ayrı oyun', () {
    final entry = kGames.firstWhere((g) => g.id == kHarfDedektifiGameKey);
    expect(entry.variants.map((v) => v.key), [
      'harf_dedektifi.sekiller',
      'harf_dedektifi.benzer',
      'harf_dedektifi.kelime',
    ]);
  });

  group('Kelime içinde dokunma (gerçek Hasenat yazı tipiyle)', () {
    testWidgets('her harfin kendi kutusu var; RTL sırası doğru', (
      tester,
    ) async {
      await loadHasenat();
      for (final word in kDetectiveWords) {
        final painter = TappableWord.layoutWord(word, 100);
        final boxes = TappableWord.letterBoxes(word, painter);
        for (var k = 0; k < boxes.length; k++) {
          expect(boxes[k].width, greaterThan(8), reason: '${word.text} $k');
          if (k > 0) {
            // Mantıksal olarak sonraki harf görselde SOLDA ve çakışmıyor.
            expect(
              boxes[k].right,
              lessThanOrEqualTo(boxes[k - 1].left + 0.5),
              reason: '${word.text} $k',
            );
          }
        }
        // Renk vurgusu şekillendirmeyi değiştirmez (bağlantı bozulmaz).
        for (var k = 0; k < boxes.length; k++) {
          final colored = TappableWord.layoutWord(
            word,
            100,
            colorOf: (i) => i == k ? AppColors.turquoise : null,
          );
          expect(colored.width, closeTo(painter.width, 0.01));
          final coloredBoxes = TappableWord.letterBoxes(word, colored);
          for (var i = 0; i < boxes.length; i++) {
            expect(coloredBoxes[i].left, closeTo(boxes[i].left, 0.01));
            expect(coloredBoxes[i].right, closeTo(boxes[i].right, 0.01));
          }
          colored.dispose();
        }
        painter.dispose();
      }
    });

    testWidgets('dokunulan yerdeki harf seçilir (telefon boyutunda da)', (
      tester,
    ) async {
      await loadHasenat();
      for (final size in const [Size(360, 800), Size(1280, 800)]) {
        setSize(tester, size);
        final word = DetectiveWord.tryParse('مفتاح')!;
        final taps = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: FittedBox(
                  child: TappableWord(
                    word: word,
                    fontSize: 140,
                    markOf: (_) => WordLetterMark.none,
                    onTapLetter: taps.add,
                  ),
                ),
              ),
            ),
          ),
        );
        final painter = TappableWord.layoutWord(word, 140);
        final boxes = TappableWord.letterBoxes(word, painter);
        final wordBox = tester.getRect(find.byType(TappableWord));
        final scale =
            wordBox.width /
            (painter.width + TappableWord.sidePadding * 2);
        final origin = Offset(
          TappableWord.sidePadding,
          TappableWord.topSpace(140),
        );
        for (var k = 0; k < boxes.length; k++) {
          final c = boxes[k].shift(origin).center;
          await tester.tapAt(wordBox.topLeft + c * scale);
          await tester.pump();
        }
        expect(taps, [0, 1, 2, 3, 4], reason: '$size');
        // RTL: ilk harf (م) en sağda.
        expect(boxes.first.left, greaterThan(boxes.last.left));
        painter.dispose();
      }
    });
  });

  group('Oyun ekranı', () {
    testWidgets('Şekilleri Tanı: tam oturum, çift dokunma, yanlış, tek kayıt', (
      tester,
    ) async {
      setSize(tester, const Size(800, 1280));
      final audio = FakeAudio();
      await pumpGame(tester, DetectiveMode.shapes, audio: audio);

      // İlk tur: harf önce adlarıyla tanıtılır, arama aşamasında ad yok.
      expect(find.textContaining('Tanıyalım'), findsOneWidget);
      expect(find.byKey(const ValueKey('start-search')), findsOneWidget);
      expect(find.text('Başta'), findsOneWidget);
      await startSearchIfIntro(tester);
      expect(find.text('Başta'), findsNothing);
      expect(find.byType(DetectiveCard), findsNWidgets(6));
      await tester.pump(const Duration(milliseconds: 500));
      expect(audio.played, isNotEmpty, reason: 'hedef harfin sesi');

      final right = correctCardIndexes(tester);
      final wrong = wrongCardIndexes(tester);
      expect(counterText(tester), 'Bulunan: 0 / ${right.length}');

      await tester.tap(cardInk(right.first));
      await tester.pump(const Duration(milliseconds: 300));
      expect(counterText(tester), 'Bulunan: 1 / ${right.length}');
      expect(audio.effects, hasLength(1));
      final card = tester.widget<DetectiveCard>(
        find.byKey(ValueKey('card-${right.first}')),
      );
      expect(card.state, DetectiveCardState.found);

      // Aynı karta tekrar: puan ve sayaç değişmez.
      await tester.tap(cardInk(right.first));
      await tester.pump(const Duration(milliseconds: 300));
      expect(counterText(tester), 'Bulunan: 1 / ${right.length}');
      expect(find.textContaining('zaten buldun'), findsOneWidget);

      // Yanlış: tur sürer, destekleyici mesaj.
      await tester.tap(cardInk(wrong.first));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Bir daha bakalım'), findsOneWidget);
      expect(counterText(tester), 'Bulunan: 1 / ${right.length}');

      for (final i in right.skip(1)) {
        await tester.tap(cardInk(i));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('Hepsini buldun!'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('next-button')));
      await tester.pumpAndSettle();

      for (var round = 1; round < kDetectiveRoundCount; round++) {
        expect(counterText(tester), startsWith('Bulunan: 0 /'));
        await solveCardRound(tester);
        await tester.tap(find.byKey(const ValueKey('next-button')));
        await tester.pumpAndSettle();
      }

      expect(find.text('Tebrikler, dedektif!'), findsOneWidget);
      expect(find.byKey(const ValueKey('replay-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('practice-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('exit-button')), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('game_history.harf_dedektifi.sekiller.plays'), 1);

      // Tekrar Oyna: temiz yeni oturum, eski kayıt tekrarlanmaz.
      await tester.tap(find.byKey(const ValueKey('replay-button')));
      await tester.pumpAndSettle();
      expect(find.text('Tebrikler, dedektif!'), findsNothing);
      await startSearchIfIntro(tester);
      expect(counterText(tester), startsWith('Bulunan: 0 /'));
      expect(prefs.getInt('game_history.harf_dedektifi.sekiller.plays'), 1);
      expect(
        prefs.getString(DetectiveProgressStore.keyFor(null)),
        isNotNull,
      );
    });

    testWidgets('İki yanlıştan sonra ipucu belirginleşir ve kartı gösterir', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      await pumpGame(tester, DetectiveMode.similar);
      final wrong = wrongCardIndexes(tester);
      expect(
        tester.widget(find.byKey(const ValueKey('hint-button'))),
        isA<OutlinedButton>(),
      );
      await tester.tap(cardInk(wrong[0]));
      await tester.pump(const Duration(milliseconds: 300));
      // Benzer harflerde seçilene göre nokta ipucu, genel cümle değil.
      expect(find.textContaining('nokta'), findsWidgets);
      expect(find.textContaining('Noktalarına dikkat'), findsNothing);
      expect(find.text('Aranan'), findsOneWidget);
      await tester.tap(cardInk(wrong[1]));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget(find.byKey(const ValueKey('hint-button'))),
        isA<FilledButton>(),
      );
      await tester.tap(find.byKey(const ValueKey('hint-button')));
      await tester.pump(const Duration(milliseconds: 300));
      final hinted = tester
          .widgetList<DetectiveCard>(find.byType(DetectiveCard))
          .where((c) => c.state == DetectiveCardState.hinted);
      expect(hinted, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kelime Dedektifi: kelimedeki harfe dokununca yalnızca o sayılır', (
      tester,
    ) async {
      await loadHasenat();
      setSize(tester, const Size(360, 800));
      await pumpGame(tester, DetectiveMode.words);
      final target = targetIdOnScreen(tester);
      final words = tester
          .widgetList<TappableWord>(find.byType(TappableWord))
          .toList();
      expect(words.length, inInclusiveRange(2, 3));
      final total = [
        for (final w in words) ...w.word.occurrencesOf(target),
      ].length;
      expect(counterText(tester), 'Bulunan: 0 / $total');

      // Önce hedef olmayan bir harf.
      final w0 = words.first;
      final other = List.generate(w0.word.letters.length, (i) => i)
          .firstWhere((i) => w0.word.letters[i].letterId != target);
      await tester.tap(find.byKey(ValueKey('w0.$other')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Bir daha bakalım'), findsOneWidget);

      var found = 0;
      for (final w in words) {
        for (final k in w.word.occurrencesOf(target)) {
          await tester.tap(find.byKey(ValueKey('w${w.wordIndex}.$k')));
          await tester.pump(const Duration(milliseconds: 300));
          found++;
          if (found < total) {
            expect(counterText(tester), 'Bulunan: $found / $total');
          }
          // Çift dokunma sayılmaz.
          await tester.tap(find.byKey(ValueKey('w${w.wordIndex}.$k')));
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      expect(counterText(tester), 'Bulunan: $total / $total');
      expect(find.byKey(const ValueKey('next-button')), findsOneWidget);
    });

    testWidgets('sesi kapatınca hiçbir ses çalmaz', (tester) async {
      setSize(tester, const Size(800, 1280));
      final audio = FakeAudio();
      await pumpGame(tester, DetectiveMode.similar, audio: audio);
      await tester.tap(find.byKey(const ValueKey('mute-button')));
      await tester.pumpAndSettle();
      audio.played.clear();
      await solveCardRound(tester);
      await tester.tap(find.byKey(const ValueKey('next-button')));
      await tester.pumpAndSettle();
      expect(audio.played, isEmpty);
      expect(audio.effects, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(DetectiveProgressStore.mutedKey), isTrue);
    });

    testWidgets('bozuk yerel kayıtla oyun açılır', (tester) async {
      SharedPreferences.setMockInitialValues({
        DetectiveProgressStore.keyFor(null): '[[[',
        DetectiveProgressStore.mutedKey: 'evet',
      });
      await pumpGame(tester, DetectiveMode.words);
      expect(find.byKey(const ValueKey('found-counter')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final mode in DetectiveMode.values) {
      testWidgets('${mode.title}: 5 ekran boyutunda taşma yok', (tester) async {
        await loadHasenat();
        for (final size in const [
          Size(360, 800),
          Size(800, 1280),
          Size(1280, 800),
          Size(800, 360),
          Size(1920, 1080),
        ]) {
          setSize(tester, size);
          await pumpGame(tester, mode);
          await startSearchIfIntro(tester);
          expect(tester.takeException(), isNull, reason: '$size');
          if (mode == DetectiveMode.words) {
            for (final e in find.byType(TappableWord).evaluate()) {
              final rect = tester.getRect(find.byWidget(e.widget));
              expect(rect.height, greaterThan(40), reason: '$size');
              expect(rect.right, lessThanOrEqualTo(size.width), reason: '$size');
            }
          } else {
            for (final e in find.byType(DetectiveCard).evaluate()) {
              final rect = tester.getRect(find.byWidget(e.widget));
              expect(rect.width, greaterThanOrEqualTo(44), reason: '$size');
              expect(rect.bottom, lessThanOrEqualTo(size.height), reason: '$size');
            }
          }
        }
      });
    }

    testWidgets('başlangıç ekranı: modlar, harf grupları, not', (tester) async {
      setSize(tester, const Size(360, 800));
      await tester.pumpWidget(harness(const HarfDedektifiScreen(), FakeAudio()));
      await tester.pumpAndSettle();
      expect(
        find.text('Harfleri farklı şekilleriyle ve kelimelerin içinde bul!'),
        findsOneWidget,
      );
      for (final mode in DetectiveMode.values) {
        expect(find.text(mode.title), findsOneWidget);
      }
      // Grup 7 (م ن و ه ي) benzer harf grubu içermez → not çıkar.
      await tester.tap(find.byKey(const ValueKey('mode-benzer')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('choice-g7')),
        100,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('choice-g7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choice-g7')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('detective-start')),
        100,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('detective-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('choice-note')), findsOneWidget);
      expect(find.text('5 kısa tur · süre yok'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('detective-start')));
      await tester.pumpAndSettle();
      expect(find.byType(HarfDedektifiGameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
