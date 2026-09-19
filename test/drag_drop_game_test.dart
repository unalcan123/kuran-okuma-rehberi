import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/drag_drop_game_data.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/models/game_score.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/drag_drop_game_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/drag_drop_levels_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/widgets/draggable_letter.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/widgets/fly_back.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/widgets/sound_slot.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/oyunlar_screen.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudio extends ChangeNotifier implements AudioService {
  final played = <List<String>>[];
  final preloaded = <List<String?>>[];

  @override
  void preload(Iterable<String?> assets) => preloaded.add(assets.toList());

  @override
  Future<void> playPlaylist(List<String> assets) async => played.add(assets);

  @override
  Future<void> playLetter(ArabicLetter letter) async =>
      played.add([letter.audioAsset!]);

  @override
  Future<void> stop() async {}

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

Finder tileOf(ArabicLetter letter) => find.byWidgetPredicate(
  (w) => w is DraggableLetter && w.letter.isolatedForm == letter.isolatedForm,
);

Finder slotOf(ArabicLetter letter) => find.byWidgetPredicate(
  (w) => w is SoundSlot && w.letter.isolatedForm == letter.isolatedForm,
);

/// The letters this game deals (read from the screen — the random game
/// picks its own).
List<ArabicLetter> dealt(WidgetTester tester) =>
    tester.widgetList<SoundSlot>(find.byType(SoundSlot)).map((s) => s.letter).toList();

Future<void> dragTo(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await gesture.moveBy(const Offset(0, 24));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

/// Places every letter correctly; the game then ends by itself.
Future<void> solve(WidgetTester tester) async {
  for (final letter in dealt(tester)) {
    await dragTo(tester, tileOf(letter), slotOf(letter));
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

DragDropLevel level(int number) => kDragDropLevels[number - 1];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Groups reuse Elifba letters and existing recordings', () {
    expect(kDragDropGroups.length, 7);
    expect(kDragDropGroups.expand((r) => r).length, 29);
    for (final group in kDragDropGroups) {
      expect(group.length, inInclusiveRange(3, 5));
      for (final letter in group) {
        expect(File('assets/${letter.audioAsset}').lengthSync(), greaterThan(0));
      }
    }
    expect(File('assets/$kGameCorrectSound').lengthSync(), greaterThan(0));
  });

  test('Seven fixed games plus one random game of five letters', () {
    expect(kDragDropLevels.length, 8);
    expect(kDragDropLevels.map((l) => l.title).toList(), [
      for (var i = 1; i <= 7; i++) 'Oyun $i',
      'Karışık',
    ]);
    expect(kDragDropLevels.map((l) => l.gameKey).toSet().length, 8);
    for (var i = 0; i < 7; i++) {
      expect(kDragDropLevels[i].isRandom, isFalse);
      expect(kDragDropLevels[i].draw(math.Random()), kDragDropGroups[i]);
    }
    final random = kDragDropLevels.last;
    expect(random.isRandom, isTrue);
    final rng = math.Random(3);
    final sets = <String>{};
    for (var i = 0; i < 30; i++) {
      final letters = random.draw(rng);
      expect(letters.length, kDragDropRandomCount);
      expect(letters.map((l) => l.isolatedForm).toSet().length, 5);
      expect(kDragDropAllLetters.toSet().containsAll(letters), isTrue);
      sets.add(letters.map((l) => l.isolatedForm).join());
    }
    expect(sets.length, greaterThan(20), reason: 'a fresh hand every time');
  });

  testWidgets('Home → Oyunlar → Sürükle & Bırak lists the small games', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1400));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const HomeScreen(), audio));
    await tester.tap(find.text('Oyunlar'));
    await tester.pumpAndSettle();
    expect(find.byType(OyunlarScreen), findsOneWidget);
    expect(find.text('Harfleri doğru yerlere taşı'), findsOneWidget);
    await tester.tap(find.text('Sürükle & Bırak'));
    await tester.pumpAndSettle();
    expect(find.byType(DragDropLevelsScreen), findsOneWidget);
    expect(find.text('Hangi oyunu oynamak istersin?'), findsOneWidget);
    for (var i = 1; i <= 7; i++) {
      expect(find.text('Oyun $i'), findsOneWidget);
    }
    expect(find.text('Karışık'), findsOneWidget);
    expect(find.text('Her seferinde 5 yeni harf'), findsOneWidget);

    await tester.tap(find.text('Oyun 2'));
    await tester.pumpAndSettle();
    expect(find.byType(DragDropGameScreen), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('Sesi dinle, harfi doğru yere sürükle.'), findsOneWidget);
    expect(find.byType(SoundSlot), findsNWidgets(3));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DragDropLevelsScreen), findsOneWidget);
  });

  testWidgets('Level cards show the stars of the best play', (tester) async {
    setSize(tester, const Size(800, 1400));
    SharedPreferences.setMockInitialValues({
      'game_score.drag_drop.3.best_score': 50,
      'game_score.drag_drop.3.best_stars': 2,
    });
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const DragDropLevelsScreen(), audio));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(1));
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(7));
  });

  testWidgets('Correct drop fills the slot and plays cheer then letter', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    final letter = kDragDropGroups[0][2];
    final gesture = await tester.startGesture(tester.getCenter(tileOf(letter)));
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(slotOf(letter)));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.descendant(
        of: slotOf(letter),
        matching: find.byIcon(Icons.audiotrack_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: slotOf(letter),
        matching: find.byIcon(Icons.music_note_rounded),
      ),
      findsWidgets,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: slotOf(letter),
        matching: find.byIcon(Icons.audiotrack_rounded),
      ),
      findsNothing,
    );
    expect(audio.played, [
      [kGameCorrectSound, letter.audioAsset],
    ]);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(tester.widget<SoundSlot>(slotOf(letter)).placed, isTrue);
    expect(
      find.descendant(
        of: tileOf(letter),
        matching: find.byType(Draggable<ArabicLetter>),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wrong drop is rejected softly and the letter goes home', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    final letter = kDragDropGroups[0][0];
    final other = kDragDropGroups[0][1];
    final home = tester.getCenter(tileOf(letter));
    final gesture = await tester.startGesture(home);
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    expect(find.byType(Draggable<ArabicLetter>), findsWidgets);
    await gesture.moveTo(tester.getCenter(slotOf(other)));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(FlyBack), findsOneWidget);
    expect(tester.getCenter(tileOf(letter)), home);
    await tester.pumpAndSettle();
    expect(find.byType(FlyBack), findsNothing);
    expect(audio.played, isEmpty);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(tester.widget<SoundSlot>(slotOf(other)).placed, isFalse);
    expect(tester.getCenter(tileOf(letter)), home);
    expect(
      find.descendant(
        of: tileOf(letter),
        matching: find.byType(Draggable<ArabicLetter>),
      ),
      findsOneWidget,
    );
    // ...and it can still be solved afterwards.
    final retry = await tester.startGesture(tester.getCenter(tileOf(letter)));
    await retry.moveBy(const Offset(0, 24));
    await tester.pump();
    await retry.moveTo(tester.getCenter(slotOf(letter)));
    await tester.pump();
    await retry.up();
    await tester.pumpAndSettle();
    expect(tester.widget<SoundSlot>(slotOf(letter)).placed, isTrue);
  });

  testWidgets('Dropping in empty space or on a filled slot returns the letter', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    final a = kDragDropGroups[0][0];
    final b = kDragDropGroups[0][1];
    await dragTo(tester, tileOf(a), slotOf(a));
    audio.played.clear();
    final home = tester.getCenter(tileOf(b));
    final gesture = await tester.startGesture(home);
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(const Offset(180, 30));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getCenter(tileOf(b)), home);
    await dragTo(tester, tileOf(b), slotOf(a));
    expect(tester.getCenter(tileOf(b)), home);
    expect(audio.played, isEmpty);
    expect(tester.widget<SoundSlot>(slotOf(b)).placed, isFalse);
  });

  testWidgets('The whole cell around a letter is a drag handle', (tester) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    final letter = kDragDropGroups[0][1];
    final cell = tester.getRect(tileOf(letter));
    expect(cell.shortestSide, greaterThanOrEqualTo(96));
    // Corner of the cell: outside the drawn circle, inside the touch area.
    final gesture = await tester.startGesture(cell.topLeft + const Offset(3, 3));
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(slotOf(letter)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<SoundSlot>(slotOf(letter)).placed, isTrue);
  });

  testWidgets("Fetches the game's sounds as soon as it opens, new ones on replay", (
    tester,
  ) async {
    setSize(tester, const Size(800, 1400));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(3)), audio),
    );
    expect(audio.preloaded, isNotEmpty);
    expect(audio.preloaded.first, [
      kGameCorrectSound,
      for (final letter in kDragDropGroups[2]) letter.audioAsset,
    ]);

    // The random game deals new letters on replay - those are fetched too.
    await tester.pumpWidget(
      harness(
        DragDropGameScreen(key: UniqueKey(), level: kDragDropLevels.last),
        audio,
      ),
    );
    await solve(tester);
    audio.preloaded.clear();
    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pumpAndSettle();
    expect(audio.preloaded.length, 1);
    final asked = audio.preloaded.single.whereType<String>().toSet();
    expect(asked, contains(kGameCorrectSound));
    expect(
      dealt(tester).every((l) => asked.contains(l.audioAsset)),
      isTrue,
      reason: 'every letter now on screen was requested',
    );
  });

  testWidgets('Tapping a slot plays that letter', (tester) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    final letter = kDragDropGroups[0][3];
    await tester.tap(slotOf(letter));
    await tester.pump();
    expect(audio.played, [
      [letter.audioAsset],
    ]);
  });

  testWidgets('Points: first try 15; a miss keeps the score and the retry earns 10', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    final r = kDragDropGroups[0];
    expect(find.text('Puan'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await dragTo(tester, tileOf(r[0]), slotOf(r[0]));
    expect(find.text('15'), findsOneWidget);
    // r[1] dropped on the wrong sound: nothing is taken away...
    await dragTo(tester, tileOf(r[1]), slotOf(r[2]));
    expect(find.text('15'), findsOneWidget);
    // ...and once placed it earns the base 10 only.
    await dragTo(tester, tileOf(r[1]), slotOf(r[1]));
    expect(find.text('25'), findsOneWidget);
    await dragTo(tester, tileOf(r[2]), slotOf(r[2]));
    expect(find.text('40'), findsOneWidget);
    await dragTo(tester, tileOf(r[3]), slotOf(r[3]));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // 15 + 10 + 15 + 15: the miss broke the streak, so no bonus.
    expect(find.text('55 Puan'), findsOneWidget);
    expect(find.text('3 / 4 İlk Denemede Doğru'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
  });

  testWidgets('Third first-try answer in a row is announced quietly and fades', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    final r = kDragDropGroups[0];
    await dragTo(tester, tileOf(r[0]), slotOf(r[0]));
    await dragTo(tester, tileOf(r[1]), slotOf(r[1]));
    final gesture = await tester.startGesture(tester.getCenter(tileOf(r[2])));
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(slotOf(r[2])));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('+15'), findsOneWidget);
    expect(find.textContaining('Güzel gidiyorsun!'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Güzel gidiyorsun!'), findsNothing);
    expect(find.text('Sesi dinle, harfi doğru yere sürükle.'), findsOneWidget);
  });

  testWidgets('Ends a beat after the last letter; result stays until the child chooses', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    final r = kDragDropGroups[0];
    for (var i = 0; i < 3; i++) {
      await dragTo(tester, tileOf(r[i]), slotOf(r[i]));
    }
    final gesture = await tester.startGesture(tester.getCenter(tileOf(r[3])));
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(slotOf(r[3])));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('4 / 4'), findsOneWidget, reason: 'last letter settling');
    expect(find.text('Tebrikler!'), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Tebrikler!'), findsOneWidget);
    // 4 x 15 + one streak bonus at the third first-try letter
    expect(find.text('65 Puan'), findsOneWidget);
    expect(find.text('4 / 4 İlk Denemede Doğru'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.text('En İyi: 65'), findsOneWidget);
    expect(find.text('Tekrar Oyna'), findsOneWidget);
    expect(find.text('Oyun Seç'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Tebrikler!'), findsOneWidget, reason: 'never leaves by itself');

    final store = GameScoreStore();
    expect((await store.recordOf('drag_drop.1')).bestScore, 65);
    expect((await store.recordOf('drag_drop.2')).hasPlayed, isFalse);
    final history = await store.historyOf('drag_drop.1');
    expect(history.plays, 1);
    expect(history.recent, [65]);
    expect((await store.historyOf('drag_drop.2')).plays, 0);
  });

  testWidgets('Replay starts the same game again; Oyun Seç returns to the list', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1400));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const DragDropLevelsScreen(), audio));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oyun 6'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 5'), findsOneWidget);
    await solve(tester);
    expect(find.text('Tebrikler!'), findsOneWidget);
    // 5 x 15 + one streak bonus (third first-try letter)
    expect(find.text('80 Puan'), findsOneWidget);

    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 5'), findsOneWidget);
    expect(find.text('Tebrikler!'), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    await solve(tester);
    expect(find.text('Tebrikler!'), findsOneWidget);
    expect((await GameScoreStore().historyOf('drag_drop.6')).plays, 2);

    await tester.tap(find.text('Oyun Seç'));
    await tester.pumpAndSettle();
    expect(find.byType(DragDropLevelsScreen), findsOneWidget);
    // The card now carries the earned stars.
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
  });

  testWidgets('The random game deals five letters, and new ones on replay', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1400));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const DragDropLevelsScreen(), audio));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karışık'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 5'), findsOneWidget);
    final first = dealt(tester).map((l) => l.isolatedForm).toSet();
    expect(first.length, 5);
    await solve(tester);
    expect(find.text('Tebrikler!'), findsOneWidget);
    expect((await GameScoreStore().recordOf('drag_drop.random')).bestScore, 80);
    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pumpAndSettle();
    final second = dealt(tester).map((l) => l.isolatedForm).toSet();
    expect(second.length, 5);
    expect(second, isNot(first), reason: 'a fresh hand of letters');
  });

  testWidgets('Finish saves the best per game and celebrates a new record', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    SharedPreferences.setMockInitialValues({
      'game_score.drag_drop.1.best_score': 20,
      'game_score.drag_drop.1.best_stars': 1,
    });
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DragDropGameScreen(level: level(1)), audio),
    );
    await solve(tester);
    expect(find.text('Yeni rekor!'), findsOneWidget);
    final record = await GameScoreStore().recordOf('drag_drop.1');
    expect(record.bestScore, 65);
    expect(record.bestStars, 3);
    // A lower-scoring play later does not overwrite it.
    final lower = await GameScoreStore().submit(
      'drag_drop.1',
      const GameResult(points: 30, firstTry: 2, total: 4),
    );
    expect(lower.isNewBest, isFalse);
    expect(lower.best.bestScore, 65);
    expect(lower.best.bestStars, 3);
  });

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(800, 360),
    const Size(1440, 900),
    const Size(1920, 1080),
  ]) {
    testWidgets('Every small game fits $size with big touch targets', (
      tester,
    ) async {
      setSize(tester, size);
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      for (final game in kDragDropLevels) {
        await tester.pumpWidget(
          harness(DragDropGameScreen(key: UniqueKey(), level: game), audio),
        );
        await tester.pumpAndSettle();
        for (final letter in dealt(tester)) {
          final tile = tester.getSize(tileOf(letter));
          final slot = tester.getSize(slotOf(letter));
          expect(tile.shortestSide, greaterThanOrEqualTo(44), reason: '$size');
          expect(slot.shortestSide, greaterThanOrEqualTo(44), reason: '$size');
          final rect = tester.getRect(tileOf(letter));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
        await solve(tester);
        expect(find.text('Tebrikler!'), findsOneWidget, reason: '$size ${game.title}');
        expect(tester.takeException(), isNull, reason: '$size ${game.title}');
      }
    });
  }
}
