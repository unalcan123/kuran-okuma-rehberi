import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/drag_drop_game_data.dart';
import 'package:kuran_okuma_rehberi/data/memory_game_data.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/memory/memory_game_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/memory/memory_levels_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/memory/widgets/memory_card.dart';
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

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

MemoryLevel level(String id) => kMemoryLevels.firstWhere((l) => l.id == id);

List<MemoryCard> cards(WidgetTester tester) =>
    tester.widgetList<MemoryCard>(find.byType(MemoryCard)).toList();

Finder cardFinder(int i) => find.descendant(
  of: find.byKey(ValueKey('card-$i')),
  matching: find.byType(InkWell),
);

MemoryCard cardAt(WidgetTester tester, int i) =>
    tester.widget<MemoryCard>(find.byKey(ValueKey('card-$i')));

Future<void> tapCard(WidgetTester tester, int i) async {
  await tester.tap(cardFinder(i));
  await tester.pump();
}

/// Where each letter's two cards are: letter -> [first index, second index].
Map<String, List<int>> pairsOf(WidgetTester tester) {
  final map = <String, List<int>>{};
  final all = cards(tester);
  for (var i = 0; i < all.length; i++) {
    map.putIfAbsent(all[i].letter.isolatedForm, () => []).add(i);
  }
  return map;
}

Future<void> startPlaying(WidgetTester tester) async {
  await tester.tap(find.text('Hazırım'));
  await tester.pumpAndSettle();
}

/// Finds every pair with perfect memory; the game then ends by itself.
Future<void> solve(WidgetTester tester) async {
  for (final pair in pairsOf(tester).values) {
    await tapCard(tester, pair[0]);
    await tapCard(tester, pair[1]);
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Levels keep the old groups: 3 easy, 4 hard, 2 very hard', () {
    expect(kMemoryLevels.length, 9);
    expect(
      [for (final t in MemoryTier.values) t.label],
      ['Kolay', 'Zor', 'Çok Zor'],
    );
    List<int> counts(MemoryTier tier) => [
      for (final l in kMemoryLevels.where((l) => l.tier == tier)) l.pairCount,
    ];
    expect(counts(MemoryTier.easy), [4, 4, 5]);
    expect(counts(MemoryTier.hard), [6, 7, 7, 7]);
    expect(counts(MemoryTier.veryHard), [10, 10]);
    expect(kMemoryLevels.map((l) => l.title).toList(), [
      'Kolay 1',
      'Kolay 2',
      'Kolay 3',
      'Zor 1',
      'Zor 2',
      'Zor 3',
      'Zor 4',
      'Çok Zor 1',
      'Çok Zor 2',
    ]);
    expect(kMemoryLevels.map((l) => l.gameKey).toSet().length, 9);
    for (final l in kMemoryLevels) {
      expect(l.letters.map((x) => x.isolatedForm).toSet().length, l.pairCount);
      for (final letter in l.letters) {
        expect(File('assets/${letter.audioAsset}').lengthSync(), greaterThan(0));
        expect(letter.turkishName, isNotNull);
      }
    }
  });

  testWidgets('Oyunlar lists Hafıza; its levels show tiers and best stars', (
    tester,
  ) async {
    setSize(tester, const Size(800, 2200));
    SharedPreferences.setMockInitialValues({
      'game_score.memory.hard2.best_score': 90,
      'game_score.memory.hard2.best_stars': 2,
    });
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const OyunlarScreen(), audio));
    await tester.pumpAndSettle();
    expect(find.text('Hafıza'), findsOneWidget);
    expect(find.text('Aynı harfleri bul'), findsOneWidget);
    await tester.tap(find.text('Hafıza'));
    await tester.pumpAndSettle();
    expect(find.byType(MemoryLevelsScreen), findsOneWidget);
    for (final tier in ['Kolay', 'Zor', 'Çok Zor']) {
      expect(find.text(tier), findsOneWidget);
    }
    expect(find.text('Kolay 1 · 4 çift'), findsOneWidget);
    expect(find.text('Çok Zor 2 · 10 çift'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(1));

    await tester.tap(find.text('Kolay 2 · 4 çift'));
    await tester.pumpAndSettle();
    expect(find.byType(MemoryGameScreen), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MemoryLevelsScreen), findsOneWidget);
  });

  testWidgets('Preview: cards are face up, tapping one says its letter, then they turn', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final lvl = level('easy1');
    await tester.pumpWidget(harness(MemoryGameScreen(level: lvl), audio));
    expect(audio.preloaded.first, [
      kGameCorrectSound,
      for (final l in lvl.letters) l.audioAsset,
    ]);
    expect(cards(tester).length, 8);
    expect(cards(tester).every((c) => c.faceUp), isTrue);
    expect(find.text('Hazırım'), findsOneWidget);
    expect(
      find.text('Harfleri ve yerlerini aklında tut. Dokununca sesini dinlersin.'),
      findsOneWidget,
    );

    await tapCard(tester, 0);
    expect(audio.played.single, [cards(tester)[0].letter.audioAsset]);
    expect(find.text('0 / 4'), findsOneWidget, reason: 'preview taps are free');

    await startPlaying(tester);
    expect(cards(tester).every((c) => !c.faceUp), isTrue);
    expect(find.text('Hazırım'), findsNothing);
    expect(find.text('Aynı harfleri bul.'), findsOneWidget);
    expect(find.text('Deneme: 0'), findsOneWidget);
  });

  testWidgets('Without pressing Hazırım the cards turn by themselves', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(MemoryGameScreen(level: level('easy1')), audio),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(cards(tester).every((c) => c.faceUp), isTrue, reason: '2 + 4 pairs = 6 s');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(cards(tester).every((c) => !c.faceUp), isTrue);
  });

  testWidgets('A flipped card says its letter; a pair earns points and the cheer', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(MemoryGameScreen(level: level('easy1')), audio),
    );
    await startPlaying(tester);
    final pair = pairsOf(tester).values.first;
    final letter = cardAt(tester, pair[0]).letter;

    await tapCard(tester, pair[0]);
    await tester.pump(const Duration(milliseconds: 400));
    expect(cardAt(tester, pair[0]).faceUp, isTrue);
    expect(audio.played.last, [letter.audioAsset]);
    expect(find.text('0 / 4'), findsOneWidget);

    await tapCard(tester, pair[1]);
    await tester.pump(const Duration(milliseconds: 400));
    expect(audio.played.last, [kGameCorrectSound, letter.audioAsset]);
    expect(cardAt(tester, pair[0]).matched, isTrue);
    expect(cardAt(tester, pair[1]).matched, isTrue);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Deneme: 1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text(letter.turkishName!), findsNWidgets(2), reason: 'found cards name the letter');
    await tester.pumpAndSettle();
  });

  testWidgets('A wrong guess costs no points, shows the second letter, then turns back', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(MemoryGameScreen(level: level('easy1')), audio),
    );
    await startPlaying(tester);
    final pairs = pairsOf(tester).values.toList();
    final a = pairs[0][0];
    final b = pairs[1][0];

    await tapCard(tester, a);
    await tapCard(tester, b);
    await tester.pump(const Duration(milliseconds: 400));
    expect(audio.played.last, [cardAt(tester, b).letter.audioAsset],
        reason: 'the child hears which letter that was');
    expect(cardAt(tester, a).faceUp && cardAt(tester, b).faceUp, isTrue);
    expect(find.text('0'), findsOneWidget, reason: 'nothing taken away, never negative');
    expect(find.text('Deneme: 1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(cardAt(tester, a).faceUp || cardAt(tester, b).faceUp, isFalse);
    expect(audio.played.every((p) => !p.contains(kGameCorrectSound)), isTrue);
  });

  testWidgets('Tapping another card while two wrong ones show turns them back at once', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(MemoryGameScreen(level: level('easy1')), audio),
    );
    await startPlaying(tester);
    final pairs = pairsOf(tester).values.toList();
    await tapCard(tester, pairs[0][0]);
    await tapCard(tester, pairs[1][0]);
    await tester.pump(const Duration(milliseconds: 100));
    // 100 ms in, well before the 1.1 s timer: tap a third card.
    await tapCard(tester, pairs[2][0]);
    await tester.pump(const Duration(milliseconds: 400));
    expect(cardAt(tester, pairs[0][0]).faceUp, isFalse);
    expect(cardAt(tester, pairs[1][0]).faceUp, isFalse);
    expect(cardAt(tester, pairs[2][0]).faceUp, isTrue, reason: 'the new tap counts');
    // ...and it can be completed to a pair.
    await tapCard(tester, pairs[2][1]);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1 / 4'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Perfect memory: 65 points, 3 stars, result page stays, best is saved', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(MemoryGameScreen(level: level('easy1')), audio),
    );
    await startPlaying(tester);
    final pairs = pairsOf(tester).values.toList();
    for (var i = 0; i < 3; i++) {
      await tapCard(tester, pairs[i][0]);
      await tapCard(tester, pairs[i][1]);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tapCard(tester, pairs[3][0]);
    await tapCard(tester, pairs[3][1]);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tebrikler!'), findsNothing, reason: 'a beat to see the last pair');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Tebrikler!'), findsOneWidget);
    expect(find.text('Bütün çiftleri buldun.'), findsOneWidget);
    // 4 x 15 + a streak bonus at the third first-try pair
    expect(find.text('65 Puan'), findsOneWidget);
    expect(find.text('4 / 4 İlk Denemede Doğru'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.text('En İyi: 65'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Tebrikler!'), findsOneWidget, reason: 'never restarts by itself');
    expect(find.text('Tekrar Oyna'), findsOneWidget);
    expect(find.text('Oyun Seç'), findsOneWidget);

    final store = GameScoreStore();
    expect((await store.recordOf('memory.easy1')).bestScore, 65);
    expect((await store.historyOf('memory.easy1')).recent, [65]);
    expect((await store.historyOf('memory.easy2')).hasPlayed, isFalse);
  });

  testWidgets('Pairs that were part of a wrong guess lose the first-try bonus only', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(MemoryGameScreen(level: level('easy1')), audio),
    );
    await startPlaying(tester);
    final pairs = pairsOf(tester).values.toList();
    // One wrong guess between pair 0 and pair 1...
    await tapCard(tester, pairs[0][0]);
    await tapCard(tester, pairs[1][0]);
    await tester.pump(const Duration(milliseconds: 1300));
    // ...then everything is found.
    for (final pair in pairs) {
      await tapCard(tester, pair[0]);
      await tapCard(tester, pair[1]);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // 10 + 10 (missed pairs) + 15 + 15 (first try, streak only 2)
    expect(find.text('50 Puan'), findsOneWidget);
    expect(find.text('2 / 4 İlk Denemede Doğru'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
  });

  testWidgets('Replay reshuffles and previews again; Oyun Seç returns to the list', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1600));
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const MemoryLevelsScreen(), audio));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kolay 3 · 5 çift'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 5'), findsOneWidget);
    await startPlaying(tester);
    await solve(tester);
    expect(find.text('Tebrikler!'), findsOneWidget);

    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 5'), findsOneWidget);
    expect(find.text('Hazırım'), findsOneWidget, reason: 'preview again');
    expect(cards(tester).every((c) => c.faceUp && !c.matched), isTrue);
    await startPlaying(tester);
    await solve(tester);
    expect(
      (await GameScoreStore().historyOf('memory.easy3')).plays,
      2,
    );

    await tester.tap(find.text('Oyun Seç'));
    await tester.pumpAndSettle();
    expect(find.byType(MemoryLevelsScreen), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
  });

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(800, 360),
    const Size(1920, 1080),
  ]) {
    testWidgets('Every level fits $size with usable cards', (tester) async {
      setSize(tester, size);
      final audio = FakeAudio();
      addTearDown(audio.dispose);
      for (final lvl in kMemoryLevels) {
        await tester.pumpWidget(
          harness(MemoryGameScreen(key: UniqueKey(), level: lvl), audio),
        );
        await tester.pumpAndSettle();
        expect(cards(tester).length, lvl.pairCount * 2);
        for (var i = 0; i < cards(tester).length; i++) {
          final rect = tester.getRect(find.byKey(ValueKey('card-$i')));
          expect(rect.shortestSide, greaterThanOrEqualTo(44), reason: '$size ${lvl.title}');
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        final before = tester.getSize(find.byKey(const ValueKey('card-0')));
        await startPlaying(tester);
        expect(
          tester.getSize(find.byKey(const ValueKey('card-0'))),
          before,
          reason: 'cards keep their size when the preview ends',
        );
        await solve(tester);
        expect(find.text('Tebrikler!'), findsOneWidget, reason: '$size ${lvl.title}');
        expect(tester.takeException(), isNull, reason: '$size ${lvl.title}');
      }
    });
  }
}
