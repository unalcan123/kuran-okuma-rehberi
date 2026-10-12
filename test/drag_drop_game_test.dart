import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/drag_drop_game_data.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/drag_drop_game_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/drag_drop_home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/learning/learning_repository.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/learning/learning_session.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/learning/letter_learning.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/widgets/draggable_letter.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/widgets/fly_back.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/widgets/sound_slot.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/oyunlar_screen.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/theme/app_colors.dart';
import 'package:kuran_okuma_rehberi/widgets/game_meadow_background.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudio extends ChangeNotifier implements AudioService {
  @override
  String? get currentAsset => null;
  @override
  bool get isPlaying => false;
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
    // Oyunlar menüsü ad sormasın (ad akışı player_ui_test.dart).
    ChangeNotifierProvider(
      create: (_) => PlayerRepository()..promptedThisSession = true,
    ),
  ],
  child: MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
    home: child,
  ),
);

final _engine = LetterLearningEngine();

/// A session over [state] (fresh = Aşama 1, the first three letters).
LearningSession session({
  LearningState? state,
  DragDropDifficulty difficulty = DragDropDifficulty.easy,
  int seed = 1,
}) => LearningSession(
  engine: _engine,
  repository: LearningRepository(engine: _engine),
  state: (state ?? LearningState())..difficulty = difficulty,
  random: math.Random(seed),
);

Widget game(LearningSession s, {Key? key}) =>
    DragDropGameScreen(key: key, session: s);

List<ArabicLetter> get firstGroup => _engine.groups[0];

Finder tileOf(ArabicLetter letter) => find.byWidgetPredicate(
  (w) => w is DraggableLetter && w.letter.isolatedForm == letter.isolatedForm,
);

Finder slotOf(ArabicLetter letter) => find.byWidgetPredicate(
  (w) => w is SoundSlot && w.letter.isolatedForm == letter.isolatedForm,
);

/// The letters this round deals (read from the screen).
List<ArabicLetter> dealt(WidgetTester tester) =>
    tester
        .widgetList<SoundSlot>(find.byType(SoundSlot))
        .map((s) => s.letter)
        .toList();

Future<void> dragTo(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await gesture.moveBy(const Offset(0, 24));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

/// Places every letter correctly; the round then ends by itself.
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

/// The glow under a tray letter (selected or hinted).
bool glowing(WidgetTester tester, ArabicLetter letter) {
  final box = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(ValueKey('tile-tap-${letter.isolatedForm}')),
      matching: find.byType(AnimatedContainer),
    ),
  );
  final shadows = (box.decoration as BoxDecoration?)?.boxShadow ?? const [];
  return shadows.isNotEmpty;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Letters reuse Elifba recordings', () {
    expect(kDragDropAllLetters.length, 29);
    for (final letter in kDragDropAllLetters) {
      expect(File('assets/${letter.audioAsset}').lengthSync(), greaterThan(0));
    }
    expect(File('assets/$kGameCorrectSound').lengthSync(), greaterThan(0));
  });

  testWidgets('Home → Oyunlar → Sürükle & Bırak opens the letter journey', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1400));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const HomeScreen(), audio));
    await tester.tap(find.byKey(const ValueKey('home-card-image-Oyunlar')));
    await tester.pumpAndSettle();
    expect(find.byType(OyunlarScreen), findsOneWidget);
    await tester.tap(find.text('Sürükle & Bırak'));
    await tester.pumpAndSettle();
    expect(find.byType(DragDropHomeScreen), findsOneWidget);
    // Sabit "Oyun 1-7" listesi yok.
    expect(find.text('Oyun 1'), findsNothing);
    expect(find.text('Harf Yolculuğu'), findsOneWidget);
    expect(find.text('0 / 29 harf öğrenildi'), findsOneWidget);
    expect(find.text('Aşama 1 / 10 · Yeni harfler'), findsOneWidget);
    expect(find.text('Bugün tekrar edilecek harf yok'), findsOneWidget);
    expect(find.byKey(const ValueKey('total-stars')), findsOneWidget);
    for (final letter in kDragDropAllLetters) {
      expect(find.byKey(ValueKey('map-${letter.isolatedForm}')), findsOneWidget);
    }
    expect(find.byType(GameMeadowBackground), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('continue-learning')));
    await tester.pumpAndSettle();
    expect(find.byType(DragDropGameScreen), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('Sesi dinle, harfi doğru yere sürükle.'), findsOneWidget);
    expect(dealt(tester).toSet(), firstGroup.toSet());
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DragDropHomeScreen), findsOneWidget);
  });

  testWidgets('Correct drop fills the slot and plays cheer then letter', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(game(session()), audio));
    final letter = firstGroup[2];
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
        matching: find.byIcon(Icons.music_note_rounded),
      ),
      findsWidgets,
    );
    await tester.pumpAndSettle();
    expect(audio.played, [
      [kGameCorrectSound, letter.audioAsset],
    ]);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
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
    await tester.pumpWidget(harness(game(session()), audio));
    final letter = firstGroup[0];
    final other = firstGroup[1];
    final home = tester.getCenter(tileOf(letter));
    final gesture = await tester.startGesture(home);
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(slotOf(other)));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(FlyBack), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(FlyBack), findsNothing);
    expect(audio.played, isEmpty);
    expect(tester.widget<SoundSlot>(slotOf(other)).placed, isFalse);
    expect(tester.getCenter(tileOf(letter)), home);
    await dragTo(tester, tileOf(letter), slotOf(letter));
    expect(tester.widget<SoundSlot>(slotOf(letter)).placed, isTrue);
  });

  testWidgets(
    'Dropping in empty space or on a filled slot returns the letter',
    (tester) async {
      setSize(tester, const Size(360, 800));
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      await tester.pumpWidget(harness(game(session()), audio));
      final a = firstGroup[0];
      final b = firstGroup[1];
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
    },
  );

  testWidgets('The whole cell around a letter is a drag handle', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(game(session()), audio));
    final letter = firstGroup[1];
    final cell = tester.getRect(tileOf(letter));
    expect(cell.shortestSide, greaterThanOrEqualTo(96));
    final gesture = await tester.startGesture(
      cell.topLeft + const Offset(3, 3),
    );
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(slotOf(letter)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<SoundSlot>(slotOf(letter)).placed, isTrue);
  });

  testWidgets('Tap the letter, then the card — like dragging it there', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(game(session()), audio));
    expect(find.text('Ya da önce harfe, sonra karta dokun.'), findsOneWidget);
    final a = firstGroup[0];
    final b = firstGroup[1];
    await tester.tap(tileOf(a));
    await tester.pumpAndSettle();
    expect(glowing(tester, a), isTrue, reason: 'selected letter glows');
    // Wrong card: soft shake, nothing placed, selection cleared.
    await tester.tap(slotOf(b));
    await tester.pumpAndSettle();
    expect(tester.widget<SoundSlot>(slotOf(b)).placed, isFalse);
    expect(audio.played, isEmpty);
    await tester.tap(tileOf(a));
    await tester.pump();
    await tester.tap(slotOf(a));
    await tester.pumpAndSettle();
    expect(tester.widget<SoundSlot>(slotOf(a)).placed, isTrue);
    expect(audio.played.last, [kGameCorrectSound, a.audioAsset]);
  });

  testWidgets('Tapping a card with nothing selected plays its letter', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(game(session()), audio));
    final letter = firstGroup[2];
    await tester.tap(slotOf(letter));
    await tester.pump();
    expect(audio.played, [
      [letter.audioAsset],
    ]);
  });

  testWidgets('Easy: after a miss the right letter glows; hard: no hint', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1280));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(game(session()), audio));
    final a = firstGroup[0];
    final b = firstGroup[1];
    expect(glowing(tester, b), isFalse);
    await dragTo(tester, tileOf(a), slotOf(b));
    expect(glowing(tester, b), isTrue, reason: 'hint for card b');

    final learned = _engine.migrateFromOldLevels([3, 3, 3, 3], DateTime.now());
    final hard = session(state: learned, difficulty: DragDropDifficulty.hard);
    await tester.pumpWidget(harness(game(hard, key: UniqueKey()), audio));
    await tester.pumpAndSettle();
    final letters = dealt(tester);
    await dragTo(tester, tileOf(letters[0]), slotOf(letters[1]));
    await dragTo(tester, tileOf(letters[0]), slotOf(letters[1]));
    expect(glowing(tester, letters[1]), isFalse);
  });

  testWidgets("Fetches the round's sounds at once, the next round's too", (
    tester,
  ) async {
    setSize(tester, const Size(800, 1400));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(game(session()), audio));
    expect(audio.preloaded.first.first, kGameCorrectSound);
    expect(audio.preloaded.first.toSet(), {
      kGameCorrectSound,
      for (final letter in dealt(tester)) letter.audioAsset,
    });
    await solve(tester);
    audio.preloaded.clear();
    await tester.tap(find.byKey(const ValueKey('continue-round')));
    await tester.pumpAndSettle();
    final asked = audio.preloaded
        .lastWhere((assets) => assets.contains(kGameCorrectSound))
        .whereType<String>()
        .toSet();
    expect(dealt(tester).every((l) => asked.contains(l.audioAsset)), isTrue);
  });

  testWidgets(
    'Points: first try 15; a miss keeps the score and the retry earns 10',
    (tester) async {
      setSize(tester, const Size(360, 800));
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      await tester.pumpWidget(harness(game(session()), audio));
      final r = firstGroup;
      expect(find.text('0'), findsOneWidget);
      await dragTo(tester, tileOf(r[0]), slotOf(r[0]));
      expect(find.text('15'), findsOneWidget);
      await dragTo(tester, tileOf(r[1]), slotOf(r[2]));
      expect(find.text('15'), findsOneWidget);
      await dragTo(tester, tileOf(r[1]), slotOf(r[1]));
      expect(find.text('25'), findsOneWidget);
      await dragTo(tester, tileOf(r[2]), slotOf(r[2]));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      // 15 + 10 + 15: the miss broke the streak, so no bonus.
      expect(find.text('40 Puan'), findsOneWidget);
      expect(find.text('2 / 3 İlk Denemede Doğru'), findsOneWidget);
    },
  );

  testWidgets(
    'Ends a beat after the last letter; result waits for the child',
    (tester) async {
      setSize(tester, const Size(360, 800));
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      await tester.pumpWidget(harness(game(session()), audio));
      final r = firstGroup;
      for (var i = 0; i < 2; i++) {
        await dragTo(tester, tileOf(r[i]), slotOf(r[i]));
      }
      final gesture = await tester.startGesture(tester.getCenter(tileOf(r[2])));
      await gesture.moveBy(const Offset(0, 24));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(slotOf(r[2])));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('3 / 3'), findsOneWidget, reason: 'last letter settling');
      expect(find.text('Tur tamamlandı'), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Tur tamamlandı'), findsOneWidget);
      // 3 x 15 + streak bonus at the third first-try letter.
      expect(find.text('50 Puan'), findsOneWidget);
      expect(find.text('Güzel gidiyorsun!'), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);
      expect(find.text('Ara ver'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Tur tamamlandı'), findsOneWidget);
      final store = GameScoreStore();
      expect((await store.recordOf(kDragDropLearnKey)).bestScore, 50);
    },
  );

  testWidgets('Two perfect learning rounds lead to the mixed review', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1280));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final s = session();
    await tester.pumpWidget(harness(game(s), audio));
    await solve(tester);
    await tester.tap(find.byKey(const ValueKey('continue-round')));
    await tester.pumpAndSettle();
    await solve(tester);
    expect(
      find.text('Yeni harfleri öğrendin! Şimdi eskilerle karışık tekrar.'),
      findsOneWidget,
    );
    expect(s.state.phase, LearnPhase.review);
    await tester.tap(find.byKey(const ValueKey('continue-round')));
    await tester.pumpAndSettle();
    expect(find.text('Aşama 1 / 10 · Karışık tekrar'), findsOneWidget);
    // Saved on the device right away.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LearningRepository.keyFor(null)), isNotNull);
  });

  testWidgets('Medium shows six cards mixing old and new letters', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final state = _engine.migrateFromOldLevels([3, 3, 3], DateTime.now());
    await tester.pumpWidget(
      harness(
        game(session(state: state, difficulty: DragDropDifficulty.medium)),
        audio,
      ),
    );
    final letters = dealt(tester);
    expect(letters.length, 6);
    final newOnes = _engine.currentGroup(state);
    expect(letters.where(newOnes.contains).length, newOnes.length);
    expect(letters.where((l) => !newOnes.contains(l)), isNotEmpty);
  });

  testWidgets('Progress survives a restart; daily review offered next day', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1400));
    // Eski "Oyun 1-2" iyi oynanmış: 6 harf öğrenilmiş başlar.
    SharedPreferences.setMockInitialValues({
      'game_score.drag_drop.1.best_score': 65,
      'game_score.drag_drop.1.best_stars': 3,
      'game_score.drag_drop.2.best_score': 50,
      'game_score.drag_drop.2.best_stars': 3,
    });
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final today = DateTime(2026, 10, 12, 9);
    await tester.pumpWidget(
      harness(DragDropHomeScreen(clock: () => today), audio),
    );
    await tester.pumpAndSettle();
    expect(find.text('6 / 29 harf öğrenildi'), findsOneWidget);
    expect(find.text('Aşama 3 / 10 · Yeni harfler'), findsOneWidget);
    // Migrated letters are due now: a short review comes first.
    expect(find.byKey(const ValueKey('daily-review')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('daily-review')));
    await tester.pumpAndSettle();
    expect(find.text('Aşama 3 / 10 · Günlük tekrar'), findsOneWidget);
    await solve(tester);
    expect(find.text('Günlük tekrarı bitirdin!'), findsOneWidget);
    await tester.tap(find.text('Ara ver'));
    await tester.pumpAndSettle();
    expect(find.text('Bugünkü tekrar tamam!'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-review')), findsNothing);

    // Same device, app reopened two days later.
    await tester.pumpWidget(const SizedBox());
    final later = today.add(const Duration(days: 2));
    await tester.pumpWidget(
      harness(DragDropHomeScreen(key: UniqueKey(), clock: () => later), audio),
    );
    await tester.pumpAndSettle();
    expect(find.text('6 / 29 harf öğrenildi'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-review')), findsOneWidget);
    // Old scores are untouched.
    expect((await GameScoreStore().recordOf('drag_drop.1')).bestScore, 65);
  });

  testWidgets('Difficulty choice is kept', (tester) async {
    setSize(tester, const Size(800, 1400));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const DragDropHomeScreen(), audio));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zor'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '6 kart, bütün öğrendiğin harflerden; benzer harfler yan yana.',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      harness(DragDropHomeScreen(key: UniqueKey()), audio),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        '6 kart, bütün öğrendiğin harflerden; benzer harfler yan yana.',
      ),
      findsOneWidget,
    );
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
    testWidgets('Every difficulty fits $size with big touch targets', (
      tester,
    ) async {
      setSize(tester, size);
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      final learned = _engine.migrateFromOldLevels(
        [3, 3, 3, 3],
        DateTime.now(),
      );
      for (final difficulty in DragDropDifficulty.values) {
        final s = session(
          state: LearningState.fromJson(learned.toJson()),
          difficulty: difficulty,
        );
        await tester.pumpWidget(harness(game(s, key: UniqueKey()), audio));
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
        expect(
          find.text('Tur tamamlandı'),
          findsOneWidget,
          reason: '$size $difficulty',
        );
        expect(tester.takeException(), isNull, reason: '$size $difficulty');
      }
    });
  }

  // Home and finish panels at every size, without overflow.
  for (final size in const [Size(360, 640), Size(800, 360), Size(1920, 1080)]) {
    testWidgets('Home screen fits $size', (tester) async {
      setSize(tester, size);
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      await tester.pumpWidget(harness(const DragDropHomeScreen(), audio));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Harf Yolculuğu'), findsOneWidget);
    });
  }
}
