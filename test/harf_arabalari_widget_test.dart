import 'dart:math' as math;

import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/harf_arabalari/harf_arabalari_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/harf_arabalari/harf_arabalari_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/oyunlar_screen.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harf_oyunlari_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpTestEnvironment);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.clear();
  });

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<HarfArabalariOyunuState> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    int seed = 11,
    PlayerRepository? players,
  }) async {
    useSize(tester, size);
    await tester.pumpWidget(
      gameApp(HarfArabalariOyunu(random: math.Random(seed)), players: players),
    );
    for (var i = 0; i < 40 && find.text('BAŞLA').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    return tester.state<HarfArabalariOyunuState>(
      find.byType(HarfArabalariOyunu),
    );
  }

  Future<void> start(WidgetTester tester) async {
    // Seviye seçiciyle giriş paneli küçük ekranda kaydırılabilir.
    await tester.ensureVisible(find.text('BAŞLA'));
    await tester.pump();
    await tester.tap(find.text('BAŞLA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> play(WidgetTester tester, double seconds) async {
    for (var t = 0.0; t < seconds; t += 0.1) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Hedef arabası tamamen ekranda görünene kadar oynar.
  Future<HaCar> waitTargetCar(
    WidgetTester tester,
    HarfArabalariEngine e,
  ) async {
    for (var i = 0; i < 120; i++) {
      final c = e.cars.where(
        (c) =>
            c.catchable &&
            c.letter.char == e.target!.char &&
            c.x >= 0 &&
            c.x + c.width <= e.width,
      );
      if (c.isNotEmpty) return c.first;
      await tester.pump(const Duration(milliseconds: 100));
    }
    throw StateError('hedef araba görünmedi');
  }

  Future<void> finish(
    WidgetTester tester,
    HarfArabalariEngine engine, {
    bool perfect = false,
  }) async {
    while (engine.status == HaStatus.running) {
      engine.tick(0.1);
      if (perfect) {
        final t = engine.cars.where(
          (c) => c.catchable && c.letter.char == engine.target?.char && c.x > 0,
        );
        if (t.isNotEmpty) engine.tap(t.first.id);
      }
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('başlangıç: kısa açıklama, oyuncu etiketi ve BAŞLA', (
    tester,
  ) async {
    final state = await open(tester);
    expect(find.text('Harf Arabaları'), findsWidgets);
    expect(
      find.text('Sesi dinle, doğru harfli arabayı yakala!'),
      findsOneWidget,
    );
    expect(find.text('BAŞLA'), findsOneWidget);
    expect(find.text('Oyuncu seç'), findsOneWidget);
    expect(state.engineForTest!.status, HaStatus.ready);
  });

  testWidgets('BAŞLA: süre, hedef ses, arabalar soldan sağa geçer', (
    tester,
  ) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    expect(engine.status, HaStatus.running);
    expect(find.text('2:00'), findsOneWidget);
    expect(find.text('Puan 0'), findsOneWidget);

    for (var i = 0; i < 10 && gameAudio.currentAsset == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(gameAudio.currentAsset, engine.target!.audio);

    final x0 = engine.cars.first.x;
    expect(x0, lessThan(0), reason: 'soldan girer');
    await play(tester, 2.0);
    expect(engine.cars.first.x, greaterThan(x0));
    expect(engine.cars.length, greaterThan(1));
    // Farklı şeritlerde.
    expect(engine.cars.map((c) => c.lane).toSet().length, greaterThan(1));
  });

  testWidgets('doğru araba: +15, yeni hedef, oyun akışı SÜRER, diyalog yok', (
    tester,
  ) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    final car = await waitTargetCar(tester, engine);
    final first = engine.target!.char;

    await tester.tap(find.text(first));
    await tester.pump();
    expect(car.caught, isTrue);
    expect(engine.score, 15);
    expect(engine.correct, 1);
    expect(engine.target!.char, isNot(first));
    expect(find.byType(AlertDialog), findsNothing);

    final elapsed = engine.elapsed;
    await play(tester, 2.0);
    expect(engine.elapsed, greaterThan(elapsed + 1));
    expect(engine.status, HaStatus.running);
    expect(gameAudio.currentAsset, engine.target!.audio);
  });

  testWidgets(
    'yanlış araba: kaybolmaz, puan düşmez, hedef aynı, tekrar denenir',
    (tester) async {
      final state = await open(tester);
      await start(tester);
      final engine = state.engineForTest!;
      Iterable<HaCar> visibleWrong() => engine.cars.where(
        (c) =>
            c.catchable &&
            c.letter.char != engine.target!.char &&
            c.x >= 0 &&
            c.x + c.width <= engine.width,
      );
      for (var i = 0; i < 150 && visibleWrong().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final wrong = visibleWrong().first;
      final target = engine.target;

      await tester.tap(find.text(wrong.letter.char));
      await tester.pump(const Duration(milliseconds: 50));
      expect(engine.wrongTaps, 1);
      expect(engine.score, 0);
      expect(wrong.caught, isFalse);
      expect(engine.cars.contains(wrong), isTrue);
      expect(engine.target, same(target));

      final car = await waitTargetCar(tester, engine);
      await tester.tap(find.text(car.letter.char));
      await tester.pump();
      expect(engine.score, 10);
    },
  );

  testWidgets('Sesi tekrar dinle: sesi çalar, puanı etkilemez', (tester) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    await play(tester, 1.0);
    gameAudio.stop();
    await tester.pump();
    expect(gameAudio.currentAsset, isNull);

    await tester.tap(find.text('Sesi tekrar dinle'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(gameAudio.currentAsset, engine.target!.audio);
    expect(engine.score, 0);
    expect(engine.wrongTaps, 0);
  });

  testWidgets('web/masaüstü: fare tıklamasıyla araba yakalanır', (
    tester,
  ) async {
    final state = await open(tester, size: const Size(1440, 900));
    await start(tester);
    final engine = state.engineForTest!;
    final car = await waitTargetCar(tester, engine);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final at = tester.getCenter(find.text(car.letter.char));
    await mouse.moveTo(at);
    await mouse.down(at);
    await mouse.up();
    await tester.pump();
    expect(engine.correct, 1);
  });

  testWidgets(
    'arka plana alınca oyun/süre durur, ses susar; dönünce devam eder',
    (tester) async {
      final state = await open(tester);
      await start(tester);
      final engine = state.engineForTest!;
      await play(tester, 2.0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final elapsed = engine.elapsed;
      final x = engine.cars.first.x;
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      expect(engine.elapsed, elapsed);
      expect(engine.cars.first.x, x);
      expect(gameAudio.currentAsset, isNull);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await play(tester, 1.0);
      expect(engine.elapsed, greaterThan(elapsed + 0.5));
      expect(gameAudio.currentAsset, engine.target!.audio);
    },
  );

  testWidgets(
    '120 sn dolunca sonuç: puan, doğru, geçen araba, kaçırılan, yanlış, doğruluk, en iyi',
    (tester) async {
      final state = await open(tester);
      await start(tester);
      final engine = state.engineForTest!;
      await finish(tester, engine, perfect: true);

      expect(engine.status, HaStatus.over);
      expect(find.text('Harf Arabaları Tamamlandı'), findsOneWidget);
      for (final label in [
        'Puan',
        'Doğru',
        'Geçen Araba',
        'Kaçırılan Hedef',
        'Yanlış',
        'Doğruluk',
        'En İyi',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('%100'), findsOneWidget);
      expect(find.text('${engine.spawned}'), findsWidgets);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(find.text('Tekrar Oyna'), findsOneWidget);
      expect(find.text('Oyunlara Dön'), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
      expect(gameAudio.currentAsset, isNull);

      // Tekrar oyna: sıfırdan başlar.
      await tester.tap(find.text('Tekrar Oyna'));
      await tester.pump();
      expect(engine.status, HaStatus.running);
      expect([engine.score, engine.correct, engine.missedTargets], [0, 0, 0]);
      expect(find.text('Harf Arabaları Tamamlandı'), findsNothing);
    },
  );

  testWidgets('sonuç aktif oyuncuya yazılır; başka oyuncunun skoru değişmez', (
    tester,
  ) async {
    late PlayerRepository repo;
    late PlayerProfile elif, ahmet;
    await tester.runAsync(() async {
      repo = PlayerRepository();
      await repo.load();
      elif = (await repo.createProfile('Elif', 'star'))!;
      ahmet = (await repo.createProfile('Ahmet', 'note'))!;
      await repo.recordResult(
        PlayerGameResult(
          playerId: ahmet.id,
          gameId: GameIds.harfArabalari,
          score: 999,
          correctAnswers: 1,
          wrongAnswers: 0,
          missedTargets: 0,
          totalItems: 1,
          playedAt: DateTime(2026),
        ),
      );
      await repo.selectProfile(elif.id);
      repo.promptedThisSession = true;
    });

    final state = await open(tester, players: repo);
    await start(tester);
    final engine = state.engineForTest!;
    await finish(tester, engine, perfect: true);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    final e = repo.statsFor(elif.id, GameIds.harfArabalari);
    expect(e.gamesPlayed, 1);
    expect(e.bestScore, engine.score);
    expect(e.totalCorrect, engine.correct);
    expect(e.totalItems, engine.spawned);
    expect(
      repo.bestScore(ahmet.id, GameIds.harfArabalari),
      999,
      reason: 'Ahmet\'in skoru Elif\'in oyunundan etkilenmez',
    );
    expect(
      find.text('Elif'),
      findsWidgets,
      reason: 'sonuç panelinde oyuncu adı',
    );
  });

  testWidgets(
    'aktif oyuncu yoksa BAŞLA bir kez "Kim oynuyor?" sorar; profil sonra hatırlanır',
    (tester) async {
      late PlayerRepository repo;
      await tester.runAsync(() async {
        repo = PlayerRepository();
        await repo.load();
      });
      final state = await open(tester, players: repo);

      await tester.tap(find.text('BAŞLA'));
      await tester.pumpAndSettle();
      expect(find.text('Kim oynuyor?'), findsOneWidget);
      expect(state.engineForTest!.status, HaStatus.ready);

      await tester.enterText(
        find.byKey(const Key('player-name-field')),
        'Elif',
      );
      await tester.tap(find.byKey(const Key('avatar-moon')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('create-player')));
      // pumpAndSettle KULLANILMAZ: oyun başlayınca ticker sürekli kare ister.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.activePlayer!.displayName, 'Elif');
      expect(repo.activePlayer!.avatarId, 'moon');
      expect(
        state.engineForTest!.status,
        HaStatus.running,
        reason: 'profilden sonra başlar',
      );
      expect(find.text('Kim oynuyor?'), findsNothing);
    },
  );

  testWidgets('geri: ekrandan çıkınca ticker, zamanlayıcı ve ses temizlenir', (
    tester,
  ) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      gameApp(
        Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    HarfArabalariOyunu(random: math.Random(2)),
                          ),
                        ),
                    child: const Text('git'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('git'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 40 && find.text('BAŞLA').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await start(tester);
    await play(tester, 2.0);
    expect(gameAudio.currentAsset, isNotNull);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(HarfArabalariOyunu), findsNothing);
    expect(gameAudio.currentAsset, isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'oyun listesinde Harf Arabaları ve Skor Tablosu kartları; oyuncu etiketi',
    (tester) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(gameApp(const OyunlarScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Oyuncu seç'), findsOneWidget);
      expect(find.text('Skor Tablosu'), findsOneWidget);
      await tester.tap(find.text('Harf Arabaları'));
      await tester.pumpAndSettle();
      expect(find.byType(HarfArabalariOyunu), findsOneWidget);
    },
  );

  group('responsive: taşma yok', () {
    final sizes = <String, Size>{
      'küçük telefon 320x568': const Size(320, 568),
      'telefon 390x844': const Size(390, 844),
      'yatay telefon 844x390': const Size(844, 390),
      'tablet dikey 800x1280': const Size(800, 1280),
      'tablet yatay 1280x800': const Size(1280, 800),
      'masaüstü 1440x900': const Size(1440, 900),
    };
    for (final s in sizes.entries) {
      testWidgets(s.key, (tester) async {
        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError =
            (d) => errors.add(
              d.exceptionAsString().split(String.fromCharCode(10)).first,
            );
        addTearDown(() => FlutterError.onError = old);

        final state = await open(tester, size: s.value);
        await start(tester);
        await play(tester, 8.0);
        final engine = state.engineForTest!;
        final carCount = engine.cars.length;
        final heights = [for (final c in engine.cars) c.height];
        final lanes = engine.lanes;

        await finish(tester, engine);
        final resultShown =
            find.text('Harf Arabaları Tamamlandı').evaluate().length;
        FlutterError.onError = old;

        expect(errors, isEmpty, reason: errors.join(String.fromCharCode(10)));
        expect(carCount, inInclusiveRange(1, 7));
        expect(lanes, inInclusiveRange(3, 5));
        for (final h in heights) {
          expect(h, greaterThanOrEqualTo(56)); // dokunma alanı
        }
        expect(resultShown, 1);
      });
    }
  });

  testWidgets('seviye seçici: 3 seviye; seçim oyuna uygulanır ve hatırlanır', (
    tester,
  ) async {
    final state = await open(tester);
    expect(find.text('Seviye 1 · Yavaş'), findsOneWidget);
    expect(find.text('Seviye 2 · Biraz Hızlı'), findsOneWidget);
    expect(find.text('Seviye 3 · Hızlı'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level-3')));
    await tester.pump();
    await start(tester);
    final engine = state.engineForTest!;
    expect(engine.level, 3);
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('harf_arabalari_level_v1'), 3);
    });

    // Bitince sonuç panelinde seviye değiştirilip tekrar oynanır; her seviyenin
    // "Sonuçlarım" geçmişi ayrıdır (seviye 2 eski anahtarı kullanır).
    while (engine.status == HaStatus.running) {
      engine.tick(0.1);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final history = await tester.runAsync(
      () => GameScoreStore().historyOf('${GameIds.harfArabalari}.l3'),
    );
    expect(history!.plays, 1);
    expect(HarfArabalariOyunuState.storeKeyFor(2), GameIds.harfArabalari);

    await tester.ensureVisible(find.byKey(const Key('level-1')));
    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pump();
    await tester.ensureVisible(find.text('Tekrar Oyna'));
    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pump();
    expect(engine.level, 1);
    expect(engine.status, HaStatus.running);
  });

  testWidgets('kayıtlı seviye açılışta seçili gelir', (tester) async {
    SharedPreferences.setMockInitialValues({'harf_arabalari_level_v1': 1});
    final state = await open(tester);
    await start(tester);
    expect(state.engineForTest!.level, 1);
  });
}
