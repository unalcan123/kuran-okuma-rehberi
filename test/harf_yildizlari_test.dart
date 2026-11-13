import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/l10n/l10n.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/games.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_yildizlari/harf_yildizlari_lesson_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_yildizlari/harf_yildizlari_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_yildizlari/yildiz_data.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_yildizlari/yildiz_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_yildizlari/yildiz_progress.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudio extends ChangeNotifier implements AudioService {
  final played = <String>[];
  final effects = <String>[];
  final playlists = <List<String>>[];
  var stops = 0;

  @override
  String? get currentAsset => null;
  @override
  bool get isPlaying => false;
  @override
  void preload(Iterable<String?> assets) {}
  @override
  Future<void> playAsset(String asset) async => played.add(asset);
  @override
  Future<void> playLetter(ArabicLetter letter) async =>
      played.add(letter.audioAsset!);
  @override
  Future<void> playPlaylist(List<String> assets) async {
    playlists.add(List.of(assets));
    played.addAll(assets);
  }

  @override
  Future<void> playEffect(String asset) async => effects.add(asset);
  @override
  Future<void> stop() async => stops++;
  @override
  dynamic noSuchMethod(Invocation invocation) async {}
}

YildizLesson lesson(String id) => yildizLessonById(id);

/// Oturumu bitirir; [wrongFirst] doğruysa her soruda önce yanlış basar.
void runSession(
  YildizSession s, {
  bool wrongFirst = false,
  int maxSteps = 500,
}) {
  var steps = 0;
  while (!s.isDone) {
    expect(steps++, lessThan(maxSteps), reason: 'sonsuz döngü');
    final q = s.current!;
    if (wrongFirst) {
      final wrong = [
        for (var i = 0; i < q.options.length; i++)
          if (i != q.correctIndex) i,
      ];
      s.answer(wrong.first);
    }
    if (!s.currentCompleted) s.answer(q.correctIndex);
    s.next();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ders verisi', () {
    test(
      'altı ana ders 29 benzersiz harfi boşluksuz kapsar, sonuncu 4 harf',
      () {
        final mains = kYildizLessons.where((l) => !l.isReview).toList();
        expect(mains.map((l) => l.letterCount), [5, 5, 5, 5, 5, 4]);
        final keys = [for (final l in mains) ...l.letters.map(yildizKey)];
        expect(keys.length, 29);
        expect(keys.toSet().length, 29);
        expect(mains.first.first, 1);
        for (var i = 1; i < mains.length; i++) {
          expect(mains[i].first, mains[i - 1].last + 1);
        }
        expect(mains.last.last, 29);
        expect(kYildizLetters.length, 29);
      },
    );

    test('tekrar aralıkları doğru harflerden oluşur', () {
      List<int> range(String id) => [lesson(id).first, lesson(id).last];
      expect(range('r10'), [1, 10]);
      expect(range('r15'), [1, 15]);
      expect(range('r20'), [11, 20]);
      expect(range('r14'), [16, 29]);
      expect(range('r29'), [1, 29]);
      expect(lesson('r14').letterCount, 14);
      expect(lesson('r10').title, 'İlk 10 Harf');
      expect(lesson('r29').badge, '29 Harfle Tanıştım!');
    });

    test('her harfin adı ve mevcut ses kaydı var', () {
      for (final letter in kYildizLetters) {
        expect(letter.turkishName, isNotEmpty);
        final path = letter.audioAsset;
        expect(path, isNotNull, reason: letter.turkishName);
        expect(File('assets/$path').existsSync(), isTrue, reason: path);
      }
    });

    test('açılma koşulları: ana dersler sırayla, tekrarlar engellemez', () {
      final p = YildizProgress();
      expect(p.isUnlocked(lesson('g1')), isTrue);
      expect(p.isUnlocked(lesson('g2')), isFalse);
      expect(p.isUnlocked(lesson('r10')), isFalse);
      p.completions['g1'] = 1;
      p.completions['g2'] = 1;
      expect(p.isUnlocked(lesson('r10')), isTrue);
      // Tekrar bitmeden g3 açık.
      expect(p.isUnlocked(lesson('g3')), isTrue);
      expect(p.isUnlocked(lesson('r29')), isFalse);
    });
  });

  group('soru üretimi', () {
    test('tüm dersler her harfi temsil eder; final 29 harfi', () {
      for (final l in kYildizLessons) {
        for (final preset in [0, 1, 2]) {
          final count = yildizQuestionCount(l, preset);
          expect(count, greaterThanOrEqualTo(l.letterCount));
          final base = YildizQuestions.buildBase(l, count, 7);
          expect(base.length, count);
          expect(
            base.map((q) => q.letterKey).toSet(),
            l.letters.map(yildizKey).toSet(),
            reason: '${l.id} preset $preset',
          );
        }
      }
      expect(yildizQuestionCount(lesson('g1'), 1), 8);
    });

    test('seçenekler tutarlı: doğru seçenek tek ve yazılışlar benzersiz', () {
      for (final l in kYildizLessons) {
        for (final q in YildizQuestions.buildBase(l, 40, 3)) {
          expect(q.options.length, inInclusiveRange(3, 4));
          final ids = q.options.map((o) => o.id).toList();
          expect(ids.toSet().length, ids.length);
          if (q.type != YildizQuestionType.shape) {
            expect(q.options[q.correctIndex].id, q.letterKey);
          }
        }
      }
    });

    test(
      'şekil sorusu yalnızca rehber kelimelerinden, doğru kelimede harf var',
      () {
        var shapes = 0;
        for (final q in YildizQuestions.buildBase(lesson('r29'), 87, 11)) {
          if (q.type != YildizQuestionType.shape) continue;
          shapes++;
          expect(YildizQuestions.canAskShape(q.letter), isTrue);
        }
        expect(shapes, greaterThan(0));
      },
    );
  });

  group('oturum mantığı', () {
    test('yanlış harf sonra yeniden sorulur, kuyruk biter, XP çoğalmaz', () {
      final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 1);
      runSession(s, wrongFirst: true);
      expect(s.baseDone, 8);
      expect(s.xp, 8 * YildizRewards.practiceXp);
      expect(s.assisted.values.fold<int>(0, (a, b) => a + b), 8);
    });

    test(
      'yanlış yapılan harf en az iki soru sonra, farklı türde yeniden gelir',
      () {
        final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 4);
        final first = s.current!;
        final firstType = first.type;
        final wrong =
            [
              for (var i = 0; i < first.options.length; i++)
                if (i != first.correctIndex) i,
            ].first;
        s.answer(wrong);
        s.answer(first.correctIndex);
        s.next();
        final asked = <YildizQuestion>[];
        while (!s.isDone) {
          asked.add(s.current!);
          s.answer(s.current!.correctIndex);
          s.next();
        }
        final index = asked.indexWhere(
          (q) => q.isRetry && q.letterKey == first.letterKey,
        );
        expect(
          index,
          greaterThanOrEqualTo(1),
          reason: 'ilk soru sonrası ≥ 2. soruda',
        );
        expect(asked[index].type, isNot(firstType));
      },
    );

    test(
      'aynı soruda tekrar dokunuş ve ardışık yanlış fazladan XP üretmez',
      () {
        final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 2);
        final q = s.current!;
        s.answer(q.correctIndex);
        s.answer(q.correctIndex);
        s.answer(q.correctIndex);
        expect(s.xp, YildizRewards.practiceXp);
        expect(s.baseDone, 1);
      },
    );

    test('iki yanlıştan sonra doğru cevap gösterilir (yönlendirmeli)', () {
      final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 2);
      final q = s.current!;
      final wrongs = [
        for (var i = 0; i < q.options.length; i++)
          if (i != q.correctIndex) i,
      ];
      expect(s.answer(wrongs[0]).kind, YildizAnswerKind.wrong);
      final r = s.answer(wrongs[1]);
      expect(r.kind, YildizAnswerKind.guided);
      expect(r.completed, isTrue);
      expect(s.xp, YildizRewards.practiceXp);
      expect(s.lastOutcome, YildizOutcome.assisted);
    });

    test('hep yanlış basan çocukta da oturum sonlanır (tekrar sınırlı)', () {
      final s = YildizSession(lesson: lesson('r29'), count: 29, seed: 5);
      var steps = 0;
      while (!s.isDone) {
        expect(steps++, lessThan(400));
        final q = s.current!;
        final wrong = [
          for (var i = 0; i < q.options.length; i++)
            if (i != q.correctIndex) i,
        ];
        s.answer(wrong[0]);
        s.answer(wrong[1]);
        s.next();
      }
      expect(s.xp, 29 * YildizRewards.practiceXp);
      expect(s.needsReview, isNotEmpty);
    });

    test('final tur sınırı: 29 soru 10’luk turlara bölünür', () {
      final s = YildizSession(lesson: lesson('r29'), count: 29, seed: 1);
      var breaks = 0;
      while (!s.isDone) {
        s.answer(s.current!.correctIndex);
        if (s.atTourBreak) breaks++;
        s.next();
      }
      expect(breaks, 2);
    });

    test('yarım kalan oturum aynı yerden devam eder', () {
      final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 9);
      for (var i = 0; i < 3; i++) {
        s.answer(s.current!.correctIndex);
        s.next();
      }
      final expected = s.current!.letterKey;
      final back = YildizSession.restore(lesson('g1'), s.toJson())!;
      expect(back.baseDone, 3);
      expect(back.xp, 15);
      expect(back.current!.letterKey, expected);
      runSession(back);
      expect(back.baseDone, 8);
    });

    test('öncelikli harf sırası kayıttan dönünce korunur', () {
      final priority = {yildizKey(lesson('g1').letters.last)};
      final s = YildizSession(
        lesson: lesson('g1'),
        count: 8,
        seed: 3,
        priority: priority,
      );
      s.answer(s.current!.correctIndex);
      s.next();
      final back = YildizSession.restore(lesson('g1'), s.toJson())!;
      expect(back.base.map((q) => q.letterKey), s.base.map((q) => q.letterKey));
      expect(back.current!.letterKey, s.current!.letterKey);
    });

    test('etkin tekrar sorusu ara verince kaybolmaz', () {
      final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 3);
      final key = s.current!.letterKey;
      s.answer((s.current!.correctIndex + 1) % s.current!.options.length);
      s.answer(s.current!.correctIndex);
      s.next();
      while (!s.current!.isRetry) {
        s.answer(s.current!.correctIndex);
        s.next();
      }
      final back = YildizSession.restore(lesson('g1'), s.toJson())!;
      expect(back.current!.isRetry, isTrue);
      expect(back.current!.letterKey, key);
      expect(back.baseDone, s.baseDone);
      runSession(back);
      expect(back.retryOk[key], 1);
      expect(back.xp, 8 * YildizRewards.practiceXp);
    });

    test('rastgele tohumlarda hiçbir ders sonsuza gitmez', () {
      final rng = math.Random(42);
      for (final l in kYildizLessons) {
        for (var i = 0; i < 5; i++) {
          final s = YildizSession(
            lesson: l,
            count: yildizQuestionCount(l, 1),
            seed: rng.nextInt(1000000),
          );
          runSession(s, wrongFirst: i.isEven);
          expect(s.baseDone, s.baseTotal);
        }
      }
    });
  });

  group('ilerleme kaydı', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('bitirme bonusu ve rozet yalnızca ilk kez; çift yazım yok', () async {
      var now = DateTime(2026, 11, 9, 10);
      final p = YildizProgress(clock: () => now);
      final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 1);
      runSession(s);
      final c1 = await p.complete(s);
      expect(c1.bonusXp, 20);
      expect(c1.newBadge, 'İlk 5 Harfim');
      expect(p.xp, 40 + 20);
      // Aynı oturum ikinci kez yazılamaz.
      await p.complete(s);
      expect(p.xp, 60);
      // Yeniden oynama: alıştırma XP'si var, bonus ve rozet yok.
      final again = YildizSession(lesson: lesson('g1'), count: 8, seed: 2);
      runSession(again);
      final c2 = await p.complete(again);
      expect(c2.bonusXp, 0);
      expect(c2.newBadge, isNull);
      expect(p.xp, 60 + 40);
      expect(p.completions['g1'], 2);
      expect(p.badges, {'İlk 5 Harfim'});
    });

    test('kayıt yeniden açılışta korunur; aynı gün sayacı artmaz', () async {
      var now = DateTime(2026, 11, 9, 10); // pazartesi
      final p = YildizProgress(clock: () => now);
      final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 1);
      runSession(s, wrongFirst: true);
      await p.complete(s);
      final s2 = YildizSession(lesson: lesson('g2'), count: 8, seed: 1);
      runSession(s2);
      await p.complete(s2);
      expect(p.studyDays.length, 1);
      expect(p.daysThisWeek, 1);

      final reopened = YildizProgress(clock: () => now);
      await reopened.load();
      expect(reopened.xp, p.xp);
      expect(reopened.completions, p.completions);
      expect(reopened.badges, p.badges);
      expect(reopened.studyDays, p.studyDays);
      expect(reopened.isCompleted('g1'), isTrue);

      now = DateTime(2026, 11, 10, 9);
      reopened.studyDays.add(yildizDayKey(now));
      expect(reopened.daysThisWeek, 2);
      expect(reopened.streak, 2);
      expect(reopened.weekMessage, 'Bu hafta 2 gün çalıştın!');
    });

    test('ara verince suçlayan mesaj yok', () {
      final p = YildizProgress(clock: () => DateTime(2026, 11, 20));
      p.studyDays.add('2026-11-01');
      expect(p.streak, 0);
      expect(p.weekMessage, isNot(contains('kaybet')));
      expect(p.weekMessage, contains('bekliyor'));
    });

    test('yarım kalan oturum kaydedilir ve geri yüklenir', () async {
      final p = YildizProgress();
      final s = YildizSession(lesson: lesson('g1'), count: 8, seed: 3);
      for (var i = 0; i < 2; i++) {
        s.answer(s.current!.correctIndex);
        s.next();
      }
      await p.saveSession(s);
      final reopened = YildizProgress();
      await reopened.load();
      expect(reopened.partial('g1'), (2, 8));
      expect(reopened.resume(lesson('g1'))!.baseDone, 2);
    });

    test(
      'tekrar gereken harf kaydedilir, sonra pekişince temizlenir',
      () async {
        final p = YildizProgress();
        final s = YildizSession(lesson: lesson('g1'), count: 5, seed: 1);
        runSession(s, wrongFirst: true);
        await p.complete(s);
        final keys = lesson('g1').letters.map(yildizKey).toSet();
        expect(p.letters.keys.toSet(), keys);
        expect(p.letters.values.every((r) => r.assisted > 0), isTrue);
        // Tek doğru cevap "tam öğrendi" sayılmaz.
        expect(p.letters.values.any((r) => r.solid), isFalse);
      },
    );
  });

  group('ekranlar', () {
    Future<void> pumpMap(
      WidgetTester tester,
      Size size,
      FakeAudio audio,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<AudioService>.value(
          value: audio,
          child: MaterialApp(
            home: HarfYildizlariScreen(progress: YildizProgress()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final size in const [
      Size(360, 800),
      Size(800, 1280),
      Size(1280, 800),
      Size(800, 360),
    ]) {
      testWidgets(
        'harita taşmaz ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpMap(tester, size, FakeAudio());
          expect(tester.takeException(), isNull);
          expect(find.text('Harf Yıldızları'), findsWidgets);
          expect(find.text(kYildizTagline), findsOneWidget);
          expect(
            find.byKey(const ValueKey('yildiz-lesson-g1')),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('kilitli ders açılmaz, ilk ders açılır', (tester) async {
      await pumpMap(tester, const Size(400, 900), FakeAudio());
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('yildiz-lesson-r29')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<InkWell>(find.byKey(const ValueKey('yildiz-lesson-r29')))
            .onTap,
        isNull,
      );
      await tester.fling(find.byType(ListView), const Offset(0, 3000), 3000);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('yildiz-lesson-g1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('yildiz-start')), findsOneWidget);
    });

    testWidgets('otomatik geçiş, tekrar dinleme ve arka planda bekleme', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final audio = FakeAudio();
      await tester.pumpWidget(
        ChangeNotifierProvider<AudioService>.value(
          value: audio,
          child: MaterialApp(
            home: HarfYildizlariLessonScreen(
              lesson: lesson('g1'),
              progress: YildizProgress(),
              seed: 3,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('yildiz-start')));
      await tester.pumpAndSettle();
      final session = _sessionOf(tester);
      final types = <YildizQuestionType>{};
      for (var i = 0; i < 3; i++) {
        final q = session.current!;
        types.add(q.type);
        expect(audio.played.last, q.letter.audioAsset);
        final beforeReplay = audio.played.length;
        await tester.tap(
          find.byKey(
            ValueKey(
              q.type == YildizQuestionType.listen
                  ? 'yildiz-listen'
                  : 'yildiz-glyph',
            ),
          ),
        );
        await tester.pump();
        expect(audio.played.length, beforeReplay + 1);
        if (i == 0) {
          final wrong = (q.correctIndex + 1) % q.options.length;
          await tester.tap(find.byKey(ValueKey('yildiz-option-$wrong')));
          await tester.pump(const Duration(seconds: 2));
          expect(session.current, same(q));
        }
        await tester.tap(
          find.byKey(ValueKey('yildiz-option-${q.correctIndex}')),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('yildiz-next')), findsNothing);
        if (i == 0) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump(const Duration(seconds: 3));
          expect(session.current, same(q));
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        }
        await tester.pump(const Duration(milliseconds: 500));
        expect(session.current, same(q));
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();
        expect(session.current, isNot(same(q)));
        expect(audio.played.last, session.current!.letter.audioAsset);
      }
      expect(types, YildizQuestionType.values.toSet());
      // Bekleyen otomatik geçiş çıkıştan sonra çalışmamalı.
      await tester.tap(
        find.byKey(ValueKey('yildiz-option-${session.current!.correctIndex}')),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('1. ders uçtan uca: ses, yanlış ipucu, bitiş, kayıt', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final audio = FakeAudio();
      final progress = YildizProgress();
      await tester.pumpWidget(
        ChangeNotifierProvider<AudioService>.value(
          value: audio,
          child: MaterialApp(
            home: HarfYildizlariLessonScreen(
              lesson: lesson('g1'),
              progress: progress,
              seed: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Tanışma: harfe dokununca kayıtlı ses çalar.
      await tester.tap(find.text(kYildizLetters.first.turkishName!));
      await tester.pump();
      expect(audio.played.single, kYildizLetters.first.audioAsset);
      await tester.tap(find.byKey(const ValueKey('yildiz-start')));
      await tester.pumpAndSettle();

      var wrongShown = false;
      for (var guard = 0; guard < 30; guard++) {
        if (find
            .byKey(const ValueKey('yildiz-continue'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
        final session = _sessionOf(tester);
        final q = session.current!;
        expect(tester.takeException(), isNull);
        if (!wrongShown) {
          final wrong =
              [
                for (var i = 0; i < q.options.length; i++)
                  if (i != q.correctIndex) i,
              ].first;
          await tester.tap(find.byKey(ValueKey('yildiz-option-$wrong')));
          await tester.pump();
          expect(find.byKey(const ValueKey('yildiz-feedback')), findsOneWidget);
          wrongShown = true;
        }
        await tester.tap(
          find.byKey(ValueKey('yildiz-option-${q.correctIndex}')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 950));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('yildiz-badge')), findsOneWidget);
      expect(find.text('Dinledim'), findsOneWidget);
      expect(find.text('Denedim'), findsOneWidget);
      expect(find.text('Tamamladım'), findsOneWidget);
      expect(find.byKey(const ValueKey('yildiz-replay')), findsOneWidget);
      expect(progress.isCompleted('g1'), isTrue);
      expect(progress.xp, 8 * 5 + 20);
      expect(audio.effects, isNotEmpty);

      // Çıkışta ses durdurulur.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(audio.stops, greaterThan(0));
    });
  });

  for (final size in const [Size(360, 800), Size(800, 360), Size(800, 1280)]) {
    testWidgets(
      'soru ekranları taşmaz ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ChangeNotifierProvider<AudioService>.value(
            value: FakeAudio(),
            child: MaterialApp(
              home: HarfYildizlariLessonScreen(
                lesson: lesson('r29'),
                progress: YildizProgress(),
                seed: 5,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('yildiz-start')));
        await tester.pumpAndSettle();
        final types = <YildizQuestionType>{};
        for (var i = 0; i < 9; i++) {
          final q =
              (tester.state<State>(find.byType(HarfYildizlariLessonScreen))
                          as dynamic)
                      .debugSession!
                      .current!
                  as YildizQuestion;
          types.add(q.type);
          final wrong =
              [
                for (var k = 0; k < q.options.length; k++)
                  if (k != q.correctIndex) k,
              ].first;
          await tester.ensureVisible(
            find.byKey(ValueKey('yildiz-option-$wrong')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey('yildiz-option-$wrong')));
          await tester.pump();
          await tester.ensureVisible(
            find.byKey(ValueKey('yildiz-option-${q.correctIndex}')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(ValueKey('yildiz-option-${q.correctIndex}')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 950));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(types, YildizQuestionType.values.toSet());
      },
    );
  }

  for (final language in AppLanguage.values.where((l) => l != AppLanguage.tr)) {
    testWidgets('Harf Yıldızları metinleri ve sesleri ${language.code}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = LanguageController(initial: language);
      addTearDown(controller.dispose);
      final audio = FakeAudio();
      final progress = YildizProgress();
      await tester.pumpWidget(
        AppLanguageScope(
          controller: controller,
          child: ChangeNotifierProvider<AudioService>.value(
            value: audio,
            child: MaterialApp(home: HarfYildizlariScreen(progress: progress)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(L10n.text(language, 'Harf Yıldızları')), findsWidgets);
      expect(find.text('Harf Yıldızları'), findsNothing);
      expect(
        find.text(
          L10n.text(language, 'Hazır olduğunda yıldızlar seni bekliyor.'),
        ),
        findsOneWidget,
      );
      expect(find.text(L10n.text(language, '1. Ders')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('yildiz-lesson-g1')));
      await tester.pumpAndSettle();
      expect(find.text('Yeni harflerimiz'), findsNothing);
      expect(
        find.text(L10n.text(language, 'Yeni harflerimiz')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('yildiz-start')));
      await tester.pumpAndSettle();
      while (find.byKey(const ValueKey('yildiz-continue')).evaluate().isEmpty) {
        final session = _sessionOf(tester);
        final q = session.current!;
        expect(audio.playlists.last.last, q.letter.audioAsset);
        if (AppLanguage.active.contains(language)) {
          expect(
            audio.playlists.last.first,
            'audio/${language.code}/game_76383fc2e674b663.mp3',
          );
        } else {
          expect(audio.playlists.last.length, 1);
        }
        expect(find.text('Bu harfin adı hangisi?'), findsNothing);
        await tester.tap(
          find.byKey(ValueKey('yildiz-option-${q.correctIndex}')),
        );
        await tester.pump();
        expect(find.text('Harika, doğru!'), findsNothing);
        await tester.pump(const Duration(milliseconds: 950));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text(L10n.text(language, 'Ders tamam!')), findsOneWidget);
      expect(find.text(L10n.text(language, 'Dinledim')), findsOneWidget);
      expect(find.text('Dinledim'), findsNothing);
      expect(find.text('Yeni rozet: İlk 5 Harfim'), findsNothing);
      expect(
        find.text(L10n.text(language, 'Yeni rozet: İlk 5 Harfim')),
        findsOneWidget,
      );
    });
  }

  test('dinamik Harf Yıldızları metinleri tüm dillerde çevrilir', () {
    for (final language in AppLanguage.values.where(
      (l) => l != AppLanguage.tr,
    )) {
      final samples = [
        for (final l in kYildizLessons) ...[
          l.title,
          l.rangeLabel,
          if (l.badge != null) l.badge!,
        ],
        '0 rozet',
        '3 / 29 harf pekişti',
        'Bu hafta 2 gün çalıştın!',
        'Soru 3 / 12',
        'Tur 1 / 3',
        '1. tur tamam!',
        'Yarım kaldı: 2 / 8 · devam et',
        'Ders bitirme bonusu dahil: +20',
        'Dinledim yıldızı kazanıldı',
        'Hangi kelimede Te harfi var?',
        'Normal',
        'Devam et',
        'Tekrar oyna',
        'Tekrar',
        'Karışık',
        'Türkçe Okunuş',
      ];
      for (final source in samples) {
        expect(
          L10n.translationOf(language, source),
          isNotNull,
          reason: '${language.code}: $source',
        );
      }
    }
  });

  test('Oyunlar menüsünde ve puansız sonuç listesinde', () {
    final entry = kGames.firstWhere((g) => g.id == kHarfYildizlariGameKey);
    expect(entry.title, 'Harf Yıldızları');
    expect(entry.subtitle, kYildizTagline);
    expect(entry.showInResults, isFalse);
  });
}

YildizSession _sessionOf(WidgetTester tester) {
  final state = tester.state<State>(find.byType(HarfYildizlariLessonScreen));
  // ignore: avoid_dynamic_calls
  return (state as dynamic).debugSession as YildizSession;
}
