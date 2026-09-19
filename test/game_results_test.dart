import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/models/game_score.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/games.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/listen_pick/listen_pick_questions.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/oyunlar_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/results/game_results_screen.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget harness(Widget child) => Provider<GameScoreStore>.value(
  value: GameScoreStore(),
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

GameResult _result(int points) =>
    GameResult(points: points, firstTry: 20, total: 29);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Games list every separate game: 8 drag levels, one per lesson', () {
    final drag = kGames.firstWhere((g) => g.id == 'drag_drop');
    expect(drag.variants.map((v) => v.title).toList(), [
      for (var i = 1; i <= 7; i++) 'Oyun $i',
      'Karışık',
    ]);
    final listen = kGames.firstWhere((g) => g.id == 'listen_pick');
    expect(listen.variants.length, kElifbaLessons.length);
    final keys = [for (final g in kGames) ...g.variants.map((v) => v.key)];
    expect(keys.toSet().length, keys.length);
    expect(
      listenPickGameKey(kElifbaLessons.first),
      isNot(listenPickGameKey(kElifbaLessons[1])),
    );
  });

  testWidgets('Nothing played yet: every game says so', (tester) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(harness(const GameResultsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sonuçlarım'), findsOneWidget);
    expect(find.text('Oyun oynadıkça puanların burada görünür.'), findsOneWidget);
    for (final game in kGames) {
      expect(find.text(game.title), findsOneWidget);
    }
    expect(find.text('Henüz oynanmadı.'), findsNWidgets(kGames.length));
    expect(find.text('Ortalama'), findsNothing);
  });

  testWidgets('Lists each played game with its own plays, average and last five', (
    tester,
  ) async {
    setSize(tester, const Size(360, 1200));
    final store = GameScoreStore();
    // Oyun 1: 7 plays -> average 250, best 400, last five 300 400 250 350 150
    for (final points in [100, 200, 300, 400, 250, 350, 150]) {
      await store.submit('drag_drop.1', _result(points));
    }
    // Oyun 3 is a different game: its scores must not mix with Oyun 1's.
    for (final points in [60, 90]) {
      await store.submit('drag_drop.3', _result(points));
    }
    await store.submit(listenPickGameKey(kElifbaLessons[2]), _result(80));
    await tester.pumpWidget(harness(const GameResultsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Toplam 10 oyun oynadın.'), findsOneWidget);
    // Only played games appear, by name.
    expect(find.text('Oyun 1'), findsOneWidget);
    expect(find.text('Oyun 3'), findsOneWidget);
    expect(find.text('Oyun 2'), findsNothing);
    expect(find.text('Karışık'), findsNothing);
    expect(
      find.text('${kElifbaLessons[2].label} · ${kElifbaLessons[2].title}'),
      findsOneWidget,
    );
    expect(find.text('Henüz oynanmadı.'), findsNothing);

    // Oyun 1
    expect(find.text('7'), findsOneWidget);
    expect(find.text('250'), findsNWidgets(2), reason: 'average and one score');
    expect(find.text('400'), findsNWidgets(2), reason: 'best and one score');
    for (final points in ['300', '350', '150']) {
      expect(find.text(points), findsOneWidget);
    }
    expect(find.text('100'), findsNothing, reason: 'older than the last five');
    expect(find.text('200'), findsNothing);
    // Oyun 3: two plays, average 75, its own scores.
    expect(find.text('75'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('90'), findsNWidgets(2), reason: 'best and one score');
    expect(find.text('Son 5 oyun'), findsOneWidget);
    expect(find.text('Son 2 oyun'), findsOneWidget);
    expect(find.text('Son 1 oyun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(360, 640),
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(800, 360),
  ]) {
    testWidgets('Results page fits $size', (tester) async {
      setSize(tester, size);
      final store = GameScoreStore();
      for (final game in kGames) {
        for (final variant in game.variants.take(4)) {
          for (final points in [10, 480, 250, 300, 90, 400]) {
            await store.submit(variant.key, _result(points));
          }
        }
      }
      await tester.pumpWidget(harness(const GameResultsScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Reset button: disabled with nothing to reset', (tester) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(harness(const GameResultsScreen()));
    await tester.pumpAndSettle();
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline_rounded),
    );
    expect(button.onPressed, isNull);
    expect(find.byTooltip('Sonuçları sıfırla'), findsOneWidget);
  });

  testWidgets('Reset asks first; cancelling keeps every result', (tester) async {
    setSize(tester, const Size(360, 900));
    final store = GameScoreStore();
    await store.submit('drag_drop.2', _result(120));
    await tester.pumpWidget(harness(const GameResultsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Oyun 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Sonuçları sıfırla'));
    await tester.pumpAndSettle();
    expect(find.text('Sonuçlar silinsin mi?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Sonuçlar silinsin mi?'), findsNothing);
    expect(find.text('Oyun 2'), findsOneWidget);
    expect((await store.historyOf('drag_drop.2')).plays, 1);
  });

  testWidgets('Confirming the reset wipes all results and only those', (
    tester,
  ) async {
    setSize(tester, const Size(360, 900));
    final store = GameScoreStore();
    await store.submit('drag_drop.2', _result(120));
    await store.submit(listenPickGameKey(kElifbaLessons.first), _result(80));
    SharedPreferences.getInstance().then((p) => p.setString('other', 'keep'));
    await tester.pumpWidget(harness(const GameResultsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Toplam 2 oyun oynadın.'), findsOneWidget);

    await tester.tap(find.byTooltip('Sonuçları sıfırla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sıfırla'));
    await tester.pumpAndSettle();

    expect(find.text('Oyun oynadıkça puanların burada görünür.'), findsOneWidget);
    expect(find.text('Henüz oynanmadı.'), findsNWidgets(kGames.length));
    expect(find.text('Oyun 2'), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.delete_outline_rounded),
          )
          .onPressed,
      isNull,
      reason: 'nothing left to reset',
    );
    expect((await store.historyOf('drag_drop.2')).hasPlayed, isFalse);
    expect((await store.recordOf('drag_drop.2')).hasPlayed, isFalse);
    expect(
      (await store.recordOf(listenPickGameKey(kElifbaLessons.first))).hasPlayed,
      isFalse,
    );
    expect((await SharedPreferences.getInstance()).getString('other'), 'keep');
    // Playing again starts from a clean slate.
    final again = await store.submit('drag_drop.2', _result(50));
    expect(again.previous.hasPlayed, isFalse);
    expect((await store.historyOf('drag_drop.2')).recent, [50]);
  });

  testWidgets('Oyunlar menu opens the results page', (tester) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(harness(const OyunlarScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sonuçlarım'), findsOneWidget);
    await tester.tap(find.text('Sonuçlarım'));
    await tester.pumpAndSettle();
    expect(find.byType(GameResultsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(OyunlarScreen), findsOneWidget);
  });
}
