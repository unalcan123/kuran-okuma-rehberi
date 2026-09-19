import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/drag_drop_game_data.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/models/lesson.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/listen_pick/listen_pick_lessons_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/listen_pick/listen_pick_questions.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/listen_pick/listen_pick_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/listen_pick/widgets/option_card.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudio extends ChangeNotifier implements AudioService {
  final played = <List<String>>[];
  final preloaded = <List<String?>>[];
  int stops = 0;

  @override
  void preload(Iterable<String?> assets) => preloaded.add(assets.toList());

  @override
  String? currentAsset;
  @override
  bool get isPlaying => false;

  @override
  Future<void> playPlaylist(List<String> assets) async => played.add(assets);

  @override
  Future<void> playLetter(ArabicLetter letter) async =>
      played.add([letter.audioAsset!]);

  @override
  Future<void> stop() async => stops++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget harness(Widget child, FakeAudio audio) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioService>.value(value: audio),
        Provider<GameScoreStore>.value(value: GameScoreStore()),
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

/// Lets the auto-play beat pass and returns the item that was just played.
Future<ArabicLetter> heard(
  WidgetTester tester,
  FakeAudio audio,
  Lesson lesson,
) async {
  await tester.pump(const Duration(milliseconds: 600));
  final asset = audio.played.last.single;
  return listenPickPool(
    lesson.letters,
  ).firstWhere((item) => item.audioAsset == asset);
}

Finder cardOf(ArabicLetter item) =>
    find.byKey(ValueKey('option-${listenPickId(item)}'));

// A card's own render object is a Transform, which never reports a hit.
Finder tapTarget(ArabicLetter item) =>
    find.descendant(of: cardOf(item), matching: find.byType(InkWell));

List<ArabicLetter> shownOptions(WidgetTester tester) =>
    tester.widgetList<OptionCard>(find.byType(OptionCard)).map((c) => c.item).toList();

OptionState stateOf(WidgetTester tester, ArabicLetter item) =>
    tester.widget<OptionCard>(cardOf(item)).state;

Future<void> answerCorrectly(
  WidgetTester tester,
  FakeAudio audio,
  Lesson lesson, {
  required bool last,
}) async {
  final answer = await heard(tester, audio, lesson);
  await tester.tap(tapTarget(answer));
  await tester.pump();
  // Right answers move on by themselves after 2 s; the last one ends the game.
  if (!last) await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Every lesson yields distinct, well-formed questions', () {
    final rng = math.Random(7);
    for (final lesson in kElifbaLessons) {
      final pool = listenPickPool(lesson.letters);
      expect(pool.length, greaterThanOrEqualTo(4), reason: lesson.title);
      final questions = buildListenPickQuestions(pool, random: rng);
      expect(questions.length, kListenPickQuestionCount, reason: lesson.title);
      expect(
        questions.map((q) => listenPickId(q.answer)).toSet().length,
        questions.length,
      );
      for (final q in questions) {
        expect(q.options.length, kListenPickOptionCount);
        expect(
          q.options.map(listenPickId).toSet().length,
          kListenPickOptionCount,
        );
        expect(q.options.where((o) => identical(o, q.answer)).length, 1);
      }
    }
  });

  test('Only Ders 2 is quizzed on başta / ortada / sonda forms', () {
    for (final lesson in kElifbaLessons) {
      expect(
        listenPickUsesPositions(listenPickPool(lesson.letters)),
        lesson.id == 'harflerin-yazilislari',
        reason: lesson.title,
      );
    }
    final pool = listenPickPool(kElifbaLessons[1].letters);
    expect(pool.length, 29);
    final rng = math.Random(11);
    for (var game = 0; game < 40; game++) {
      final questions = buildListenPickQuestions(
        pool,
        positions: true,
        random: rng,
      );
      expect(questions.length, 5);
      expect(
        questions.map((q) => q.position).toSet(),
        LetterPosition.values.toSet(),
        reason: 'all three positions come up in one game',
      );
      for (final q in questions) {
        final position = q.position!;
        expect(q.options.length, 4);
        expect(q.options.where((o) => identical(o, q.answer)).length, 1);
        final texts = q.options.map(q.textOf).toList();
        expect(texts.toSet().length, 4, reason: 'choices read differently');
        expect(q.textOf(q.answer), position.formOf(q.answer).trim());
        expect(q.textOf(q.answer), isNotEmpty);
      }
    }
    // Other lessons keep plain questions.
    final plain = buildListenPickQuestions(
      listenPickPool(kElifbaLessons.first.letters),
      random: rng,
    );
    expect(plain.every((q) => q.position == null), isTrue);
  });

  test('Pool drops duplicate written forms and items without a recording', () {
    const a = ArabicLetter(order: 1, isolatedForm: 'ا', audioAsset: 'a.mp3');
    const dup = ArabicLetter(order: 2, isolatedForm: 'ا ', audioAsset: 'b.mp3');
    const silent = ArabicLetter(order: 3, isolatedForm: 'ب');
    expect(listenPickPool([a, dup, silent]), [a]);
  });

  testWidgets('Fetches every sound of the chosen lesson as soon as it opens', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lesson = kElifbaLessons[2];
    await tester.pumpWidget(harness(ListenPickScreen(lesson: lesson), audio));
    expect(audio.preloaded.length, 1);
    expect(audio.preloaded.single, [
      kGameCorrectSound,
      for (final item in listenPickPool(lesson.letters)) item.audioAsset,
    ]);
    expect(audio.played, isEmpty, reason: 'fetching is not playing');
  });

  testWidgets('Plays the question by itself, replays on the big button', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lesson = kElifbaLessons.first;
    await tester.pumpWidget(harness(ListenPickScreen(lesson: lesson), audio));
    expect(audio.played, isEmpty);
    final answer = await heard(tester, audio, lesson);
    expect(audio.played.length, 1);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.byType(OptionCard), findsNWidgets(4));
    expect(shownOptions(tester).any((o) => listenPickId(o) == listenPickId(answer)), isTrue);
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump();
    expect(audio.played.last, [answer.audioAsset]);
    expect(audio.played.length, 2);
  });

  testWidgets('Wrong pick dims softly and allows another try; first try is counted', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lesson = kElifbaLessons.first;
    await tester.pumpWidget(harness(ListenPickScreen(lesson: lesson), audio));
    final answer = await heard(tester, audio, lesson);

    // Question 1: miss once, then get it.
    final wrong = shownOptions(tester).firstWhere(
      (o) => listenPickId(o) != listenPickId(answer),
    );
    final playedBefore = audio.played.length;
    await tester.tap(tapTarget(wrong));
    await tester.pump();
    expect(audio.played.length, playedBefore, reason: 'no punishing sound');
    expect(stateOf(tester, wrong), OptionState.wrong);
    expect(stateOf(tester, answer), OptionState.idle);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget(wrong));
    await tester.pump();
    expect(audio.played.length, playedBefore, reason: 'dimmed card is inert');

    await tester.tap(tapTarget(answer));
    await tester.pump(const Duration(milliseconds: 300));
    expect(audio.played.last, [kGameCorrectSound]);
    expect(stateOf(tester, answer), OptionState.correct);
    expect(
      shownOptions(tester)
          .where((o) => listenPickId(o) != listenPickId(answer))
          .every((o) => stateOf(tester, o) == OptionState.faded),
      isTrue,
    );
    expect(find.byIcon(Icons.audiotrack_rounded), findsWidgets, reason: 'notes');
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('2 / 5'), findsOneWidget);

    for (var q = 1; q < 5; q++) {
      await answerCorrectly(tester, audio, lesson, last: q == 4);
    }
    expect(find.text('Tebrikler!'), findsOneWidget);
    // 10 (missed) + 15 + 15 + (15 + 5 streak) + 15
    expect(find.text('75 Puan'), findsOneWidget);
    expect(find.text('4 / 5 İlk Denemede Doğru'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.text('En İyi: 75'), findsOneWidget);
  });

  testWidgets('Moves on 2 s after a right answer; last one goes straight to the result', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1280));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lesson = kElifbaLessons[2];
    await tester.pumpWidget(
      harness(
        Builder(
          builder:
              (context) => TextButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ListenPickScreen(lesson: lesson),
                      ),
                    ),
                child: const Text('open'),
              ),
        ),
        audio,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Sonraki'), findsNothing, reason: 'no Next button any more');
    expect(find.text('Bitir'), findsNothing);
    var answer = await heard(tester, audio, lesson);
    await tester.tap(tapTarget(answer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('1 / 5'), findsOneWidget, reason: 'still showing the answer');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('2 / 5'), findsOneWidget, reason: 'moved on after ~2 s');
    // The new question's own sound starts by itself.
    answer = await heard(tester, audio, lesson);
    await tester.tap(tapTarget(answer));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('3 / 5'), findsOneWidget);

    // Last question: the result appears at once, and stays until the child chooses.
    for (var q = 2; q < 5; q++) {
      expect(find.text('${q + 1} / 5'), findsOneWidget);
      final a = await heard(tester, audio, lesson);
      await tester.tap(tapTarget(a));
      await tester.pump();
      if (q < 4) {
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('Tebrikler!'), findsOneWidget, reason: 'no waiting after the last answer');
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Tebrikler!'), findsOneWidget, reason: 'never leaves by itself');
    expect(find.text('Tekrar Oyna'), findsOneWidget);
    expect(find.text('Derslere Dön'), findsOneWidget);
    await tester.pumpAndSettle();
    // 5 x 15 + one streak bonus at the third first-try answer
    expect(find.text('80 Puan'), findsOneWidget);
    expect(find.text('5 / 5 İlk Denemede Doğru'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(
      (await GameScoreStore().recordOf('listen_pick.${lesson.id}')).bestScore,
      80,
    );
    final history = await GameScoreStore().historyOf(listenPickGameKey(lesson));
    expect(history.plays, 1);
    expect(history.recent, [80]);

    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.text('Tebrikler!'), findsNothing);
    await heard(tester, audio, lesson);

    // The answer is heard again after replay: 5 more questions possible.
    for (var q = 0; q < 5; q++) {
      final again = await heard(tester, audio, lesson);
      await tester.tap(tapTarget(again));
      await tester.pump();
      if (q < 4) await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Derslere Dön'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect((await GameScoreStore().historyOf(listenPickGameKey(lesson))).plays, 2);
  });

  testWidgets('Home → Oyunlar → Dinle ve Seç → lesson opens the game', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1000));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const HomeScreen(), audio));
    await tester.tap(find.text('Oyunlar'));
    await tester.pumpAndSettle();
    expect(find.text('Dinle ve Seç'), findsOneWidget);
    await tester.tap(find.text('Dinle ve Seç'));
    await tester.pumpAndSettle();
    expect(find.byType(ListenPickLessonsScreen), findsOneWidget);
    expect(find.text('Hangi dersten sorular gelsin?'), findsOneWidget);
    await tester.tap(find.text(kElifbaLessons.first.title));
    await tester.pumpAndSettle();
    expect(find.byType(ListenPickScreen), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ListenPickLessonsScreen), findsOneWidget);
  });

  testWidgets('Score shows in the strip; +15 appears then fades; streak is announced', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lesson = kElifbaLessons.first;
    await tester.pumpWidget(harness(ListenPickScreen(lesson: lesson), audio));
    expect(find.text('Puan'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Sesi dinle, doğru olanı seç.'), findsOneWidget);

    var answer = await heard(tester, audio, lesson);
    await tester.tap(tapTarget(answer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Sesi dinle, doğru olanı seç.'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('+15'), findsNothing);
    expect(find.text('Sesi dinle, doğru olanı seç.'), findsOneWidget);

    await tester.pumpAndSettle();
    for (var q = 1; q < 3; q++) {
      answer = await heard(tester, audio, lesson);
      await tester.tap(tapTarget(answer));
      await tester.pump();
      if (q == 2) {
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('+15'), findsOneWidget);
        expect(find.textContaining('Güzel gidiyorsun!'), findsOneWidget);
        expect(find.text('50'), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('A miss costs no points and never goes negative', (tester) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lesson = kElifbaLessons.first;
    await tester.pumpWidget(harness(ListenPickScreen(lesson: lesson), audio));
    final answer = await heard(tester, audio, lesson);
    for (final wrong in shownOptions(
      tester,
    ).where((o) => listenPickId(o) != listenPickId(answer))) {
      await tester.tap(tapTarget(wrong));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget, reason: 'nothing taken away');
    await tester.tap(tapTarget(answer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('+10'), findsOneWidget, reason: 'no first-try bonus');
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('New record is celebrated; a lower play keeps the old best', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final lesson = kElifbaLessons.first;
    final key = 'game_score.listen_pick.${lesson.id}';

    Future<void> playPerfect() async {
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      await tester.pumpWidget(
        harness(ListenPickScreen(key: UniqueKey(), lesson: lesson), audio),
      );
      for (var q = 0; q < 5; q++) {
        await answerCorrectly(tester, audio, lesson, last: q == 4);
      }
    }

    SharedPreferences.setMockInitialValues({
      '$key.best_score': 40,
      '$key.best_stars': 1,
    });
    await playPerfect();
    expect(find.text('Yeni rekor!'), findsOneWidget);
    expect(find.textContaining('En İyi'), findsNothing);

    SharedPreferences.setMockInitialValues({
      '$key.best_score': 500,
      '$key.best_stars': 3,
    });
    await playPerfect();
    expect(find.text('En İyi: 500'), findsOneWidget);
    expect(find.text('Yeni rekor!'), findsNothing);
  });

  testWidgets('Ders 2 asks for the başta / ortada / sonda writing, shown as such', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lesson = kElifbaLessons[1];
    await tester.pumpWidget(harness(ListenPickScreen(lesson: lesson), audio));
    final seen = <LetterPosition>{};
    for (var q = 0; q < 5; q++) {
      final answer = await heard(tester, audio, lesson);
      final label = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('position-chip')),
          matching: find.byType(Text),
        ),
      ).data!;
      final position = LetterPosition.values.firstWhere((p) => p.label == label);
      seen.add(position);
      expect(
        find.text(
          'Sesi dinle, harfin ${label.toLowerCase()} yazılışını seç.',
        ),
        findsOneWidget,
      );
      for (final card in tester.widgetList<OptionCard>(find.byType(OptionCard))) {
        expect(card.text, position.formOf(card.item).trim());
      }
      // The answer's card shows the answer's form in that position.
      expect(
        tester.widget<OptionCard>(cardOf(answer)).text,
        position.formOf(answer).trim(),
      );
      await tester.tap(tapTarget(answer));
      await tester.pump();
      if (q < 4) await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
    expect(seen, LetterPosition.values.toSet());
    expect(find.text('Tebrikler!'), findsOneWidget);
  });

  testWidgets('Other lessons show no position label', (tester) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lesson = kElifbaLessons.first;
    await tester.pumpWidget(harness(ListenPickScreen(lesson: lesson), audio));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('position-chip')), findsNothing);
    expect(find.text('Sesi dinle, doğru olanı seç.'), findsOneWidget);
  });

  // Short letters, vowel-marked syllables and long phrases each need a
  // different arrangement; all must fit every screen without scrolling.
  final lessonIds = {
    'letters': kElifbaLessons[0],
    'forms': kElifbaLessons[1],
    'hareke': kElifbaLessons[2],
    'phrases': kElifbaLessons[26],
    'longest words': kElifbaLessons[22],
    'kelime sonu': kElifbaLessons[32],
  };
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(800, 360),
    const Size(1920, 1080),
  ]) {
    testWidgets('Fits $size for every kind of lesson', (tester) async {
      setSize(tester, size);
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      for (final entry in lessonIds.entries) {
        final lesson = entry.value;
        await tester.pumpWidget(
          harness(ListenPickScreen(key: UniqueKey(), lesson: lesson), audio),
        );
        for (var q = 0; q < 5; q++) {
          await tester.pumpAndSettle();
          for (final card in tester.widgetList(find.byType(OptionCard))) {
            final rect = tester.getRect(find.byWidget(card));
            expect(rect.left, greaterThanOrEqualTo(0), reason: '$size ${entry.key}');
            expect(rect.right, lessThanOrEqualTo(size.width), reason: '$size ${entry.key}');
            expect(rect.bottom, lessThanOrEqualTo(size.height), reason: '$size ${entry.key}');
            expect(rect.shortestSide, greaterThanOrEqualTo(48), reason: '$size ${entry.key}');
          }
          await answerCorrectlyOnce(tester, audio, lesson, last: q == 4);
          expect(tester.takeException(), isNull, reason: '$size ${entry.key} q$q');
        }
        expect(find.text('Tebrikler!'), findsOneWidget);
      }
    });
  }
}

Future<void> answerCorrectlyOnce(
  WidgetTester tester,
  FakeAudio audio,
  Lesson lesson, {
  required bool last,
}) => answerCorrectly(tester, audio, lesson, last: last);
