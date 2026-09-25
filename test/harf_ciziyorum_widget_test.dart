import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_ciziyorum/ciz_models.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_ciziyorum/ciz_progress_store.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_ciziyorum/harf_ciziyorum_game_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_ciziyorum/harf_ciziyorum_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_ciziyorum/widgets/trace_pad.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harf_dedektifi_test.dart' show FakeAudio, harness, setSize;

Rect padBox(WidgetTester tester) {
  final r = tester.getRect(find.byType(TracePad).first);
  final side = math.min(r.width, r.height);
  return Rect.fromLTWH(
    r.left + (r.width - side) / 2,
    r.top + (r.height - side) / 2,
    side,
    side,
  );
}

Offset toScreen(Rect box, Offset n) => box.topLeft + n * box.width;

/// Modelin hareketlerini parmakla çizer (isteğe bağlı: yalnızca bir kısmı).
Future<void> drawStrokes(
  WidgetTester tester,
  List<List<Offset>> strokes, {
  int pointer = 1,
}) async {
  final box = padBox(tester);
  for (final s in strokes) {
    if (s.isEmpty) continue;
    final g = await tester.startGesture(
      toScreen(box, s.first),
      pointer: pointer,
    );
    for (final p in s.skip(1)) {
      await g.moveTo(toScreen(box, p));
    }
    await g.up();
    await tester.pump();
  }
}

List<List<Offset>> modelPath(LetterTraceModel m, {double spacing = 0.02}) => [
  for (final s in m.strokes) resamplePolyline(s.points, spacing),
];

Future<void> tapDot(WidgetTester tester, Offset n) async {
  await tester.tapAt(toScreen(padBox(tester), n));
  await tester.pump();
}

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await settle(tester);
}

String messageText(WidgetTester tester) =>
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('message')),
            matching: find.byType(Text),
          ),
        )
        .data!;

Future<Map<String, dynamic>> savedProgress() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(DrawProgressStore.keyFor(null));
  return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
}

Future<FakeAudio> pumpGame(WidgetTester tester, List<int> letters) async {
  final audio = FakeAudio();
  await tester.pumpWidget(
    harness(
      HarfCiziyorumGameScreen(key: UniqueKey(), letterIds: letters),
      audio,
    ),
  );
  await settle(tester);
  return audio;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Be: izle → çiz → noktalar → az yardım; yıldızlar bir kez', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = await pumpGame(tester, [2, 3]);
    final be = traceModelFor(2)!;
    expect(audio.played, isNotEmpty, reason: 'harfin sesi çaldı');

    // İzle: animasyon oynar, atlanabilir.
    await tester.tap(find.byKey(const ValueKey('howto-button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Atla'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('howto-button')));
    await settle(tester);
    await tapKey(tester, 'start-trace-button');

    // Yalnızca başa ve sona dokunmak yetmez.
    await drawStrokes(tester, [
      [be.strokes.first.points.first],
      [be.strokes.first.points.last],
    ]);
    expect(find.byKey(const ValueKey('pad-trace')), findsOneWidget);
    await tapKey(tester, 'clear-button');

    // Yarısı: devam et önerisi, eksik yer gösterilir.
    final path = modelPath(be).first;
    await drawStrokes(tester, [path.sublist(0, path.length ~/ 2)]);
    expect(messageText(tester), contains('Biraz daha devam et'));
    final pad = tester.widget<TracePad>(find.byType(TracePad));
    expect(pad.missing, isNotEmpty);
    expect(pad.strokes, hasLength(1), reason: 'parmak kalkınca iz silinmez');

    // Geri kalanını çiz → noktalar.
    await drawStrokes(tester, [path.sublist(path.length ~/ 2 - 1)]);
    await settle(tester);
    expect(find.byKey(const ValueKey('pad-dots')), findsOneWidget);
    expect(messageText(tester), contains('noktaları ekle'));
    expect(find.byKey(const ValueKey('dot-compare')), findsOneWidget);

    // Yanlış taraf (üst) → başarı değil; noktaya dokununca geri alınır.
    final above = Offset(be.dots.first.center.dx, be.bodyBounds.top - 0.05);
    await tapDot(tester, above);
    expect(messageText(tester), contains('altta'));
    await tapDot(tester, above); // kaldır
    expect(tester.widget<TracePad>(find.byType(TracePad)).dots, isEmpty);
    await tapDot(tester, be.dots.first.center);
    await settle(tester);
    expect(find.byKey(const ValueKey('less-help-button')), findsOneWidget);
    var saved = await savedProgress();
    expect(saved['2'], {'g': true, 'l': false, 's': 0});

    // Daha az yardımla.
    await tapKey(tester, 'less-help-button');
    expect(
      tester.widget<TracePad>(find.byType(TracePad)).guideOpacity,
      lessThan(0.2),
    );
    await drawStrokes(tester, modelPath(be));
    await settle(tester);
    await tapDot(tester, be.dots.first.center);
    await settle(tester);
    expect(find.byKey(const ValueKey('free-button')), findsOneWidget);
    saved = await savedProgress();
    expect(saved['2']['g'], isTrue);
    expect(saved['2']['l'], isTrue);

    // Kılavuzsuz deneme değerlendirilmez, kaydı değiştirmez.
    await tapKey(tester, 'free-button');
    expect(tester.widget<TracePad>(find.byType(TracePad)).guideOpacity, 0);
    await drawStrokes(tester, [
      [const Offset(0.2, 0.2), const Offset(0.8, 0.8)],
    ]);
    await tapKey(tester, 'free-done-button');
    expect(find.text('Senin çizimin'), findsOneWidget);
    expect(find.text('Örnek harf'), findsOneWidget);
    expect(messageText(tester), contains('Birlikte bakalım'));
    expect(await savedProgress(), saved);

    // Sonraki harf: temiz başlar.
    await tapKey(tester, 'next-letter-button');
    expect(find.byKey(const ValueKey('pad-watch')), findsOneWidget);
    await tapKey(tester, 'start-trace-button');
    expect(tester.widget<TracePad>(find.byType(TracePad)).strokes, isEmpty);

    // Te: aynı gövde, 2 nokta üstte; aynı Be çizimi Te'yi de geçer.
    final te = traceModelFor(3)!;
    await drawStrokes(tester, modelPath(te));
    await settle(tester);
    await tapDot(tester, te.dots.first.center);
    expect(messageText(tester), contains('Bir nokta daha'));
    await tapDot(tester, te.dots.last.center);
    await settle(tester);
    await tapKey(tester, 'next-letter-button');

    // Özet: çalışılan harfler ve yıldızlar.
    expect(
      find.textContaining('2 harf çalıştın, 3 yeni yıldız'),
      findsOneWidget,
    );
  });

  testWidgets('aynı harfi yeniden tamamlamak yıldız eklemez', (tester) async {
    SharedPreferences.setMockInitialValues({
      DrawProgressStore.keyFor(null): '{"1": {"g": true, "l": false, "s": 0}}',
    });
    setSize(tester, const Size(800, 1280));
    await pumpGame(tester, [1]);
    await tapKey(tester, 'start-trace-button');
    await drawStrokes(tester, modelPath(traceModelFor(1)!));
    await settle(tester);
    // Elif noktasız: nokta aşaması yok.
    expect(find.byKey(const ValueKey('pad-dots')), findsNothing);
    expect(find.byKey(const ValueKey('less-help-button')), findsOneWidget);
    await tapKey(tester, 'next-letter-button');
    expect(find.textContaining('1 harf çalıştın.'), findsOneWidget);
    expect((await savedProgress())['1'], {'g': true, 'l': false, 's': 0});
  });

  testWidgets('ikinci parmak çizimi bozmaz; alandan çıkmak kilitlemez', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await pumpGame(tester, [10]); // Ra
    await tapKey(tester, 'start-trace-button');
    final ra = traceModelFor(10)!;
    final box = padBox(tester);
    final path = modelPath(ra).first;
    final g1 = await tester.startGesture(toScreen(box, path.first), pointer: 1);
    final g2 = await tester.startGesture(
      toScreen(box, const Offset(0.1, 0.9)),
      pointer: 2,
    );
    for (var i = 1; i < path.length; i++) {
      await g1.moveTo(toScreen(box, path[i]));
      await g2.moveTo(toScreen(box, Offset(0.1 + i * 0.02, 0.1)));
    }
    await g2.up();
    // Parmak alanın dışına çıkar ve orada kalkar.
    await g1.moveTo(box.bottomLeft + const Offset(-30, 60));
    await g1.up();
    await settle(tester);
    // Ra noktasız: tamamlandı; ikinci parmak iz bırakmadı.
    expect(find.byKey(const ValueKey('less-help-button')), findsOneWidget);
    expect(
      tester.widget<TracePad>(find.byType(TracePad)).strokes,
      hasLength(1),
    );
  });

  testWidgets('karalama başarı değil; Geri Al ve Temizle', (tester) async {
    setSize(tester, const Size(360, 800));
    await pumpGame(tester, [24]); // Mim
    await tapKey(tester, 'start-trace-button');
    final scribble = [
      for (var i = 0; i <= 30; i++) ...[
        Offset(0.08, 0.08 + i * 0.028),
        Offset(0.92, 0.08 + i * 0.028),
      ],
    ];
    await drawStrokes(tester, [scribble]);
    expect(find.byKey(const ValueKey('pad-trace')), findsOneWidget);
    expect(messageText(tester), contains('Çizginin üstünden'));
    await drawStrokes(tester, [
      [const Offset(0.5, 0.5), const Offset(0.55, 0.55)],
    ]);
    expect(
      tester.widget<TracePad>(find.byType(TracePad)).strokes,
      hasLength(2),
    );
    await tapKey(tester, 'undo-button');
    expect(
      tester.widget<TracePad>(find.byType(TracePad)).strokes,
      hasLength(1),
    );
    await tapKey(tester, 'clear-button');
    expect(tester.widget<TracePad>(find.byType(TracePad)).strokes, isEmpty);
    await drawStrokes(tester, modelPath(traceModelFor(24)!));
    await settle(tester);
    expect(find.byKey(const ValueKey('less-help-button')), findsOneWidget);
  });

  testWidgets('yanlış nokta sayısı / uzak nokta başarı değil (Se, Ye)', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1280));
    await pumpGame(tester, [4, 28]);
    await tapKey(tester, 'start-trace-button');
    final se = traceModelFor(4)!;
    await drawStrokes(tester, modelPath(se));
    await settle(tester);
    // Üç nokta ama biri çok uzakta.
    await tapDot(tester, se.dots[0].center);
    await tapDot(tester, se.dots[1].center);
    await tapDot(tester, se.dots[2].center + const Offset(0.25, 0));
    expect(messageText(tester), contains('yaklaştır'));
    expect(find.byKey(const ValueKey('pad-dots')), findsOneWidget);
    // Fazla nokta.
    await tapDot(tester, const Offset(0.15, 0.15));
    expect(messageText(tester), contains('Fazla nokta'));
    // Düzelt: uzak ve fazla noktaları kaldır, doğru yere koy.
    await tapKey(tester, 'undo-button');
    await tapKey(tester, 'undo-button');
    await tapDot(tester, se.dots[2].center);
    await settle(tester);
    expect(find.byKey(const ValueKey('less-help-button')), findsOneWidget);
  });

  testWidgets('çizim ve hedef her ekran boyutunda aynı yerde', (tester) async {
    for (final size in const [
      Size(360, 800),
      Size(800, 360),
      Size(800, 1280),
      Size(1280, 800),
      Size(1920, 1080),
    ]) {
      setSize(tester, size);
      await pumpGame(tester, [5]); // Cim
      expect(tester.takeException(), isNull, reason: '$size');
      await tapKey(tester, 'start-trace-button');
      final box = padBox(tester);
      expect(box.width, greaterThan(150), reason: '$size');
      expect(box.bottom, lessThanOrEqualTo(size.height));
      final cim = traceModelFor(5)!;
      await drawStrokes(tester, modelPath(cim));
      await settle(tester);
      await tapDot(tester, cim.dots.first.center);
      await settle(tester);
      expect(
        find.byKey(const ValueKey('less-help-button')),
        findsOneWidget,
        reason: '$size',
      );
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('çizim alanı sayfayı kaydırmaz, dışı kaydırır', (tester) async {
    setSize(tester, const Size(360, 800));
    final controller = ScrollController();
    final strokes = <List<Offset>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 100),
              SizedBox(
                height: 300,
                child: StatefulBuilder(
                  builder:
                      (context, setState) => TracePad(
                        model: traceModelFor(1)!,
                        strokes: strokes,
                        dots: const [],
                        input: PadInput.draw,
                        onStrokeEnd: (s) => setState(() => strokes.add(s)),
                      ),
                ),
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(180, 250), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    expect(strokes, hasLength(1));
    await tester.dragFrom(const Offset(180, 600), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
  });

  testWidgets('ses kapalıyken ses çalmaz; eksik ses oyunu durdurmaz', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({DrawProgressStore.mutedKey: true});
    setSize(tester, const Size(360, 800));
    final audio = await pumpGame(tester, [8]);
    await tapKey(tester, 'start-trace-button');
    await drawStrokes(tester, modelPath(traceModelFor(8)!));
    await settle(tester);
    expect(audio.played, isEmpty);
    expect(find.byKey(const ValueKey('less-help-button')), findsOneWidget);
  });

  testWidgets('başlangıç: bozuk kayıtla açılır; Sırayla Öğren 5 harf', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      DrawProgressStore.keyFor(null): '{bozuk',
    });
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(harness(const HarfCiziyorumScreen(), FakeAudio()));
    await settle(tester);
    expect(
      find.text('İzini takip et, noktalarını koy, harfi öğren!'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('letter-12')));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('in-order-button')),
      100,
    );
    expect(find.textContaining('Sin harfinden'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('practice-start-button')),
      100,
    );
    final practice = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('practice-start-button')),
    );
    expect(practice.onPressed, isNull, reason: 'henüz zorlanılan yok');
    await tester.tap(find.byKey(const ValueKey('in-order-button')));
    await settle(tester);
    final game = tester.widget<HarfCiziyorumGameScreen>(
      find.byType(HarfCiziyorumGameScreen),
    );
    expect(game.letterIds, [12, 13, 14, 15, 16]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Yardım zorlanma kaydeder; Zorlandıklarımı Çalış onu önerir', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await pumpGame(tester, [6]);
    await tapKey(tester, 'start-trace-button');
    await tapKey(tester, 'help-button');
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    await drawStrokes(tester, modelPath(traceModelFor(6)!));
    await settle(tester);
    await tapKey(tester, 'next-letter-button');
    expect((await savedProgress())['6']['s'], 1);
    expect(find.byKey(const ValueKey('practice-button')), findsOneWidget);
  });
}
