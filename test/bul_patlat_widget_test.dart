import 'dart:math' as math;

import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/bul_patlat/bul_patlat_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/bul_patlat/bul_patlat_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/oyunlar_screen.dart';

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

  Future<BulPatlatOyunuState> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    int seed = 11,
  }) async {
    useSize(tester, size);
    await tester.pumpWidget(gameApp(BulPatlatOyunu(random: math.Random(seed))));
    for (var i = 0; i < 40 && find.text('BAŞLA').evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    return tester.state<BulPatlatOyunuState>(find.byType(BulPatlatOyunu));
  }

  Future<void> start(WidgetTester tester) async {
    // Küçük ekranlarda giriş paneli kaydırılabilir; BAŞLA görünür alanın
    // dışında kalabilir (ör. seviye seçiciyle birlikte).
    await tester.ensureVisible(find.text('BAŞLA'));
    await tester.pump();
    await tester.tap(find.text('BAŞLA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Ekranda görünen (alan içinde) balonun harfine dokunur.
  Finder letterFinder(String char) => find.text(char);

  Future<void> play(WidgetTester tester, double seconds) async {
    // Ticker karelerini ilerletir (her kare en çok 0.1 sn oyun zamanı).
    for (var t = 0.0; t < seconds; t += 0.1) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('başlangıç: kısa açıklama ve BAŞLA; harf adı yazılmaz', (tester) async {
    final state = await open(tester);
    expect(find.text('Bul & Patlat'), findsWidgets);
    expect(find.text('Sesi dinle, doğru harfi bul ve balonu patlat!'), findsOneWidget);
    expect(find.text('BAŞLA'), findsOneWidget);
    expect(state.engineForTest!.status, BpStatus.ready);
    expect(state.engineForTest!.balloons, isEmpty);
  });

  testWidgets('BAŞLA: süre başlar, hedef seçilir, hedef harfin SESİ çalar, balonlar yükselir',
      (tester) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    expect(engine.status, BpStatus.running);
    expect(find.text('BAŞLA'), findsNothing);
    expect(find.text('2:00'), findsOneWidget);
    expect(find.text('Puan 0'), findsOneWidget);

    // Hedefin gerçek ses dosyası konuşma kanalında çalıyor.
    for (var i = 0; i < 10 && gameAudio.currentAsset == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(gameAudio.currentAsset, engine.target!.audio);

    // Hedef harf ekranda görünür bir balonda (ekranda harf adı yazılmaz).
    expect(letterFinder(engine.target!.char), findsOneWidget);
    final y0 = engine.balloons.first.y;
    await play(tester, 1.0);
    expect(engine.balloons.first.y, lessThan(y0));
    expect(engine.elapsed, greaterThan(0.5));
  });

  testWidgets('doğru balon: patlar, +15 puan, yeni hedef, oyun akışı SÜRER', (tester) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    await play(tester, 3.0); // balon ekrana girsin
    final first = engine.target!.char;

    await tester.tap(letterFinder(first));
    await tester.pump();
    expect(engine.correct, 1);
    expect(engine.score, 15);
    expect(engine.pops, isNotEmpty); // pop animasyonu
    expect(engine.target!.char, isNot(first)); // hemen yeni hedef
    expect(letterFinder(first), findsNothing); // balon gitti

    // Diyalog yok; balonlar hareket etmeye devam eder.
    expect(find.byType(AlertDialog), findsNothing);
    final elapsed = engine.elapsed;
    await play(tester, 2.0);
    expect(engine.elapsed, greaterThan(elapsed + 1));
    expect(engine.status, BpStatus.running);
    expect(engine.balloons, isNotEmpty);

    // Yeni hedefin sesi (pop sesi bittikten sonra) çalar.
    expect(gameAudio.currentAsset, engine.target!.audio);
  });

  testWidgets('yanlış balon: patlamaz, puan düşmez, hedef aynı, tekrar denenir',
      (tester) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    await play(tester, 5.0);
    final wrong = engine.balloons.firstWhere(
        (b) => b.letter.char != engine.target!.char && b.y > 0 && b.y < 400);
    final target = engine.target;

    await tester.tap(letterFinder(wrong.letter.char));
    await tester.pump(const Duration(milliseconds: 50));
    expect(engine.wrongTaps, 1);
    expect(engine.score, 0);
    expect(wrong.alive, isTrue);
    expect(engine.target, same(target));
    expect(engine.pops, isEmpty);

    // Tekrar deneyebilir: doğru balon +10 (ilk deneme bonusu yok).
    await tester.tap(letterFinder(target!.char));
    await tester.pump();
    expect(engine.score, 10);
  });

  testWidgets('Sesi tekrar dinle: sesi çalar, puanı etkilemez', (tester) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    await play(tester, 1.0);
    // await edilmez: tekil servisin oynatıcısı önceki testin zamanında doğmuş olabilir.
    gameAudio.stop();
    await tester.pump();
    expect(gameAudio.currentAsset, isNull);

    await tester.tap(find.text('Sesi tekrar dinle'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(gameAudio.currentAsset, engine.target!.audio);
    expect(engine.score, 0);
    expect(engine.wrongTaps, 0);
  });

  testWidgets('web/masaüstü: fare tıklamasıyla balon patlatılır', (tester) async {
    final state = await open(tester, size: const Size(1440, 900));
    await start(tester);
    final engine = state.engineForTest!;
    await play(tester, 3.0);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(letterFinder(engine.target!.char)));
    await mouse.down(tester.getCenter(letterFinder(engine.target!.char)));
    await mouse.up();
    await tester.pump();
    expect(engine.correct, 1);
  });

  testWidgets('arka plana alınca oyun ve süre durur, ses susar; dönünce devam eder',
      (tester) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    await play(tester, 2.0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final elapsed = engine.elapsed;
    final y = engine.balloons.first.y;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    expect(engine.elapsed, elapsed, reason: '2 dakikalık süre arka planda işlemez');
    expect(engine.balloons.first.y, y);
    expect(gameAudio.currentAsset, isNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await play(tester, 1.0);
    expect(engine.elapsed, greaterThan(elapsed + 0.5));
    // Dönüşte hedef yeniden duyurulur.
    expect(gameAudio.currentAsset, engine.target!.audio);
  });

  testWidgets('5 kaçan hedef → oyun biter: sonuç paneli, puan kaydı, tekrar oyna',
      (tester) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    while (engine.status == BpStatus.running) {
      engine.tick(0.1);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(engine.endReason, BpEndReason.missed);
    expect(find.text('Bul & Patlat Tamamlandı'), findsOneWidget);
    expect(find.text('Tekrar Oyna'), findsOneWidget);
    expect(find.text('Oyunlara Dön'), findsOneWidget);
    expect(find.text('Doğruluk'), findsOneWidget);
    expect(find.text('En İyi'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets); // en az 1 yıldız
    expect(gameAudio.currentAsset, isNull);

    final history = await tester.runAsync(() => GameScoreStore()
        .historyOf('${GameIds.bulPatlat}.l${engine.level}'));
    expect(history!.plays, 1);

    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pump();
    expect(engine.status, BpStatus.running);
    expect(engine.score, 0);
    expect(engine.missedTargets, 0);
    expect(find.text('Bul & Patlat Tamamlandı'), findsNothing);
    await play(tester, 1.0);
    expect(engine.elapsed, greaterThan(0.5));
  });

  testWidgets('2 dakika dolunca oyun biter (süre)', (tester) async {
    final state = await open(tester);
    await start(tester);
    final engine = state.engineForTest!;
    // Mükemmel oyuncu: hedef balonuna hemen dokunur.
    while (engine.status == BpStatus.running) {
      engine.tick(0.1);
      final t = engine.balloons
          .where((b) => b.letter.char == engine.target?.char && b.y < 500)
          .toList();
      if (t.isNotEmpty) engine.tap(t.first.id);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.endReason, BpEndReason.time);
    expect(find.text('Bul & Patlat Tamamlandı'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(engine.stars, 3);
  });

  testWidgets('geri: ekrandan çıkınca ticker, zamanlayıcı ve ses temizlenir',
      (tester) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(gameApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => BulPatlatOyunu(random: math.Random(2)))),
            child: const Text('git'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('git'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 40 && find.text('BAŞLA').evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await start(tester);
    await play(tester, 2.0);
    expect(gameAudio.currentAsset, isNotNull);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(BulPatlatOyunu), findsNothing);
    expect(gameAudio.currentAsset, isNull);
    // Bekleyen ticker/timer kalsaydı test çerçevesi burada hata verirdi.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('oyun listesinde görünür ve açılır', (tester) async {
    useSize(tester, const Size(390, 844));
    await tester.pumpWidget(gameApp(const OyunlarScreen()));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Bul & Patlat'));
    await tester.pumpAndSettle();
    expect(find.byType(BulPatlatOyunu), findsOneWidget);
  });


  testWidgets('seviye seçici: 3 seviye; seçim oyuna uygulanır ve hatırlanır',
      (tester) async {
    final state = await open(tester);
    expect(find.byKey(const Key('level-1')), findsOneWidget);
    expect(find.byKey(const Key('level-2')), findsOneWidget);
    expect(find.byKey(const Key('level-3')), findsOneWidget);
    expect(find.text('Seviye 1 · Yavaş'), findsOneWidget);
    expect(find.text('Seviye 2 · Biraz Hızlı'), findsOneWidget);
    expect(find.text('Seviye 3 · Hızlı'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level-3')));
    await tester.pump();
    await start(tester);
    final engine = state.engineForTest!;
    expect(engine.level, 3);

    // Seçim cihazda saklanır (sonraki açılışta hatırlanır).
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('bul_patlat_level_v1'), 3);
    });

    // Bitince sonuç panelinde seviye değiştirilip aynı ekrandan tekrar oynanır.
    while (engine.status == BpStatus.running) {
      engine.tick(0.1);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pump();
    await tester.tap(find.text('Tekrar Oyna'));
    await tester.pump();
    expect(engine.level, 1);
    expect(engine.status, BpStatus.running);
  });

  testWidgets('kayıtlı seviye açılışta seçili gelir', (tester) async {
    SharedPreferences.setMockInitialValues({'bul_patlat_level_v1': 1});
    final state = await open(tester);
    await start(tester);
    expect(state.engineForTest!.level, 1);
  });

  group('responsive: taşma yok, dokunma alanı yeterli', () {
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
        FlutterError.onError = (d) => errors
            .add(d.exceptionAsString().split(String.fromCharCode(10)).first);
        addTearDown(() => FlutterError.onError = old);

        final state = await open(tester, size: s.value);
        await start(tester); // giriş paneli → oyun
        await play(tester, 6.0);
        final engine = state.engineForTest!;
        final sizes = [for (final b in engine.balloons) b.size];
        final alive = engine.balloons.length;

        // Sonuç paneli de taşmasın.
        while (engine.status == BpStatus.running) {
          engine.tick(0.1);
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final resultShown = find.text('Bul & Patlat Tamamlandı').evaluate().length;
        FlutterError.onError = old;

        expect(errors, isEmpty, reason: errors.join(String.fromCharCode(10)));
        expect(alive, inInclusiveRange(1, 8));
        // Dokunma alanı: her balon en az 72 mantıksal piksel.
        for (final size in sizes) {
          expect(size, greaterThanOrEqualTo(72));
        }
        expect(resultShown, 1);
      });
    }
  });
}
