import 'dart:io';
import 'dart:math' as math;

import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/bul_patlat/bul_patlat_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/game_letters.dart';
import 'package:flutter_test/flutter_test.dart';

List<BpLetter> _realLetters() => kGameLetters;

BulPatlatEngine _engine({int seed = 1, double w = 360, double h = 560}) {
  final e = BulPatlatEngine(letters: _realLetters(), random: math.Random(seed));
  e.resize(w, h);
  return e;
}

BpBalloon? _targetBalloon(BulPatlatEngine e) {
  for (final b in e.balloons) {
    if (b.alive && b.letter.char == e.target?.char) return b;
  }
  return null;
}

/// Oyuncu botu: hedef balonuna [reaction] saniye sonra dokunur.
void _play(
  BulPatlatEngine e, {
  bool tap = true,
  double reaction = 1.0,
  double dt = 1 / 60,
  double maxSeconds = 200,
  void Function()? onTick,
}) {
  var since = 0.0;
  BpLetter? last;
  for (var t = 0.0; t < maxSeconds && e.status == BpStatus.running; t += dt) {
    e.tick(dt);
    onTick?.call();
    if (e.target != last) {
      last = e.target;
      since = 0;
    }
    since += dt;
    if (tap && since >= reaction) {
      final b = _targetBalloon(e);
      if (b != null && b.y < e.height * 0.9) {
        e.tap(b.id);
      }
    }
  }
}

void main() {
  test('gerçek veri: 28 harf ve her birinin ses dosyası diskte var', () {
    final letters = _realLetters();
    expect(letters.length, 28);
    for (final l in letters) {
      expect(File('assets/${l.audio}').existsSync(), isTrue,
          reason: l.audio);
    }
  });

  group('hedef seçimi (torba)', () {
    test('28 harf 28 hedefte birer kez, sonra yeniden karıştırılır', () {
      final e = _engine();
      e.start();
      final targets = <String>[e.target!.char];
      for (var i = 0; i < 83; i++) {
        e.tick(0.01);
        final b = _targetBalloon(e)!;
        e.tap(b.id);
        targets.add(e.target!.char);
      }
      for (var bag = 0; bag < 3; bag++) {
        final slice = targets.sublist(bag * 28, bag * 28 + 28);
        expect(slice.toSet().length, 28,
            reason: 'torba $bag: her harf tam bir kez');
      }
      // Torba sınırında aynı harf art arda gelmez.
      for (var i = 1; i < targets.length; i++) {
        expect(targets[i], isNot(targets[i - 1]));
      }
    });
  });

  group('hedef harf her zaman ekranda', () {
    test('hiç dokunmayan oyuncuda bile hedefin balonu var; 5 kaçan → oyun biter',
        () {
      for (final seed in [1, 2, 3, 4, 5]) {
        final e = _engine(seed: seed);
        e.start();
        var checked = 0;
        _play(e, tap: false, onTick: () {
          if (e.status != BpStatus.running) return;
          checked++;
          expect(_targetBalloon(e), isNotNull,
              reason: 'seed $seed: hedef ${e.target?.char} ekranda değil');
        });
        expect(e.status, BpStatus.over);
        expect(e.endReason, BpEndReason.missed);
        expect(e.missedTargets, 5);
        expect(checked, greaterThan(300));
      }
    });

    test('hedef balon tavana ulaşınca yeni hedef seçilir (kaybolmuş harf aranmaz)',
        () {
      final e = _engine();
      e.start();
      final first = e.target!.char;
      while (e.missedTargets == 0 && e.status == BpStatus.running) {
        e.tick(1 / 30);
      }
      expect(e.missedTargets, 1);
      expect(e.target!.char, isNot(first));
      expect(_targetBalloon(e), isNotNull);
    });
  });

  group('kaçan sayımı', () {
    test('yalnızca HEDEF balonun kaçması sayılır; diğer balonlar sayılmaz', () {
      final e = _engine(seed: 7);
      e.start();
      _play(e, tap: true, reaction: 0.8, maxSeconds: 60);
      expect(e.missedTargets, 0);
      expect(e.spawned, greaterThan(e.correct)); // dokunulmayan balonlar kaçtı
      expect(e.status, BpStatus.running);
    });
  });

  group('puan', () {
    test('ilk denemede doğru +15; seri: her 3. ilk-deneme doğruda +5', () {
      final e = _engine();
      e.start();
      final gained = <int>[];
      for (var i = 0; i < 6; i++) {
        e.tick(0.01);
        final before = e.score;
        e.tap(_targetBalloon(e)!.id);
        gained.add(e.score - before);
      }
      expect(gained, [15, 15, 20, 15, 15, 20]);
    });

    test('yanlış dokunma: puan düşmez, balon patlamaz, hedef aynı kalır; sonra +10',
        () {
      final e = _engine();
      e.start();
      e.tick(2);
      for (var i = 0;
          i < 300 &&
              e.balloons.where((b) => b.letter.char != e.target!.char).isEmpty;
          i++) {
        e.tick(0.05);
      }
      final wrong =
          e.balloons.firstWhere((b) => b.letter.char != e.target!.char);
      final target = e.target;
      final scoreBefore = e.score;
      e.tap(wrong.id);
      expect(e.score, scoreBefore);
      expect(e.wrongTaps, 1);
      expect(wrong.alive, isTrue);
      expect(wrong.shake, 1);
      expect(e.target, same(target));

      final before = e.score;
      e.tap(_targetBalloon(e)!.id);
      expect(e.score - before, 10, reason: 'ilk deneme bonusu yok');
    });

    test('puan hiçbir zaman negatif olmaz; yanlış dokunmalar 0 puan', () {
      final e = _engine();
      e.start();
      for (var i = 0; i < 400; i++) {
        e.tick(0.05);
        for (final b in List.of(e.balloons)) {
          if (b.letter.char != e.target?.char) e.tap(b.id);
        }
        expect(e.score, greaterThanOrEqualTo(0));
      }
      expect(e.score, 0);
    });
  });

  group('süre ve bitiş', () {
    test('mükemmel oyuncu 120 sn oynar: bitiş nedeni süre, istatistikler tutarlı',
        () {
      final e = _engine(seed: 3);
      e.start();
      var maxAliveSeen = 0;
      _play(e, reaction: 1.2, onTick: () {
        maxAliveSeen = math.max(maxAliveSeen, e.balloons.length);
      });
      expect(e.status, BpStatus.over);
      expect(e.endReason, BpEndReason.time);
      expect(e.elapsed, greaterThanOrEqualTo(120));
      expect(e.remainingSeconds, 0);
      expect(e.missedTargets, 0);
      expect(e.correct, greaterThan(15));
      expect(e.accuracyPercent, 100);
      expect(e.stars, 3);
      // +1: hedef balonu zorunlu üretilebilir
      expect(maxAliveSeen, lessThanOrEqualTo(e.maxAlive + 1));
      final events = e.takeEvents();
      expect(events.whereType<BpGameOver>().length, 1);
    });

    test('bittikten sonra tick hiçbir şeyi değiştirmez', () {
      final e = _engine();
      e.start();
      _play(e, tap: false);
      final score = e.score, elapsed = e.elapsed;
      e.tick(5);
      expect(e.elapsed, elapsed);
      expect(e.score, score);
    });

    test('yeniden başla: tüm sayaçlar sıfırlanır', () {
      final e = _engine();
      e.start();
      _play(e, reaction: 0.5, maxSeconds: 30);
      expect(e.score, greaterThan(0));
      e.start();
      expect([e.score, e.correct, e.wrongTaps, e.missedTargets, e.streak],
          [0, 0, 0, 0, 0]);
      expect(e.elapsed, 0);
      expect(e.status, BpStatus.running);
      expect(_targetBalloon(e), isNotNull);
    });

    test('hız: yavaştan biraz daha hareketliye, ılımlı', () {
      final e = _engine();
      e.start();
      final start = e.speedFraction;
      e.elapsed = 60;
      final mid = e.speedFraction;
      e.elapsed = 120;
      final end = e.speedFraction;
      expect(start, lessThan(mid));
      expect(mid, lessThan(end));
      expect(end / start, lessThan(1.6)); // refleks oyununa dönmez
    });
  });

  group('üretim ve yerleşim', () {
    test('balon boyutu ve sayısı cihaza göre: 4–7 balon, dokunma alanı ≥ 78 px',
        () {
      final sizes = {
        'küçük telefon': const [320.0, 480.0],
        'telefon': const [390.0, 640.0],
        'yatay telefon': const [700.0, 260.0],
        'tablet dikey': const [800.0, 1000.0],
        'tablet yatay': const [900.0, 560.0],
      };
      for (final s in sizes.entries) {
        final e = _engine(w: s.value[0], h: s.value[1]);
        e.start();
        for (var i = 0; i < 400; i++) {
          e.tick(0.05);
        }
        for (final b in e.balloons) {
          expect(b.size, greaterThanOrEqualTo(72), reason: '${s.key}: dokunma alanı');
        }
        expect(e.baseSize, inInclusiveRange(78, 170), reason: s.key);
        expect(e.maxAlive, inInclusiveRange(4, 7), reason: s.key);
      }
      expect(_engine(w: 800, h: 1000).baseSize,
          greaterThan(_engine(w: 360, h: 560).baseSize));
    });

    test('spawn aralığı 1.2–2.2 sn: düzenli, ekranı doldurmayan üretim', () {
      final e = _engine(seed: 5);
      e.start();
      // Hiç dokunulmayan ilk 9 sn (ilk hedef henüz kaçmadı): 1 hedef balonu +
      // ~9 / 1.7 ≈ 5 düzenli balon.
      _play(e, tap: false, maxSeconds: 9);
      expect(e.spawned, inInclusiveRange(4, 10));
      expect(e.balloons.length, lessThanOrEqualTo(e.maxAlive + 1));
    });

    test('yatay çakışma az: harf alanı üst üste binen balon nadir', () {
      var pairs = 0, heavy = 0;
      for (final seed in [1, 2, 3, 4, 5, 6]) {
        final e = _engine(seed: seed);
        e.start();
        _play(e, reaction: 1.5, maxSeconds: 60, onTick: () {
          final alive = e.balloons.where((b) => b.alive).toList();
          for (var i = 0; i < alive.length; i++) {
            for (var j = i + 1; j < alive.length; j++) {
              final a = alive[i], b = alive[j];
              final dx = ((a.x + a.size / 2) - (b.x + b.size / 2)).abs();
              final dy =
                  ((a.y + a.bodyHeight / 2) - (b.y + b.bodyHeight / 2)).abs();
              if (dy < a.bodyHeight) {
                pairs++;
                if (dx < (a.size + b.size) / 2 * 0.6 &&
                    dy < a.bodyHeight * 0.6) {
                  heavy++;
                }
              }
            }
          }
        });
      }
      expect(pairs, greaterThan(0));
      expect(heavy / pairs, lessThan(0.08), reason: 'ağır çakışma oranı');
    });

    test('balonlar alanın içinde doğar; alan değişince orantılı taşınır', () {
      final e = _engine();
      e.start();
      for (var i = 0; i < 300; i++) {
        e.tick(0.05);
      }
      for (final b in e.balloons) {
        expect(b.x, greaterThanOrEqualTo(0));
        expect(b.x + b.size, lessThanOrEqualTo(e.width + 0.01));
      }
      e.resize(700, 300); // döndürme
      for (final b in e.balloons) {
        expect(b.x + b.size, lessThanOrEqualTo(700.01));
      }
      e.tick(0.1); // hata vermeden devam eder
    });

    test('benzer harf aileleri: hedefin benzerleri de balonlarda görünür', () {
      var similar = 0, total = 0;
      for (var seed = 1; seed <= 20; seed++) {
        final e = _engine(seed: seed);
        e.start();
        final target = e.target!.char;
        final family = BulPatlatEngine.similarFamilies.firstWhere(
          (f) => f.contains(target),
          orElse: () => '',
        );
        if (family.isEmpty) continue;
        for (var i = 0; i < 40; i++) {
          e.tick(0.1);
        }
        for (final b in e.balloons) {
          if (b.letter.char == target) continue;
          total++;
          if (family.contains(b.letter.char)) similar++;
        }
      }
      expect(total, greaterThan(20));
      expect(similar, greaterThan(0));
      expect(similar / total, lessThan(0.7)); // her round aşırı zor değil
    });
  });

  group('seviyeler (1 yavaş, 2 biraz hızlı, 3 hızlı)', () {
    test('hız her seviyede artar; oyun boyunca hafif hızlanır, refleks oyununa dönmez',
        () {
      double speedAt(int level, double elapsed) {
        final e = _engine();
        e.start(level: level);
        e.elapsed = elapsed;
        return e.speedFraction;
      }

      for (final t in [0.0, 60.0, 120.0]) {
        expect(speedAt(1, t), lessThan(speedAt(2, t)), reason: 'sn $t');
        expect(speedAt(2, t), lessThan(speedAt(3, t)), reason: 'sn $t');
      }
      for (final level in [1, 2, 3]) {
        expect(speedAt(level, 0), lessThan(speedAt(level, 120)));
        expect(speedAt(level, 120) / speedAt(level, 0), lessThan(1.6));
      }
      // Balonun alanı geçme süresi (sn): seviye 1 yavaş, 3 hızlı ama okunabilir.
      double crossing(int level) => 1 / speedAt(level, 0);
      expect(crossing(1), greaterThan(9));
      expect(crossing(3), greaterThan(4));
      expect(crossing(3), lessThan(crossing(1) / 1.5));
    });

    test('daha hızlı seviyede balonlar daha sık gelir', () {
      int spawnedIn(int level) {
        final e = _engine(seed: 5);
        e.start(level: level);
        _play(e, tap: true, reaction: 0.8, maxSeconds: 40);
        return e.spawned;
      }

      expect(spawnedIn(3), greaterThan(spawnedIn(1)));
    });

    test('her seviyede hedef her zaman ekranda; dikkatli oyuncu hiç kaçırmaz', () {
      for (final level in [1, 2, 3]) {
        for (final seed in [1, 2, 3]) {
          final e = _engine(seed: seed);
          e.start(level: level);
          _play(e, reaction: 2.2, onTick: () {
            if (e.status != BpStatus.running) return;
            expect(_targetBalloon(e), isNotNull,
                reason: 'seviye $level seed $seed: hedef ekranda değil');
          });
          expect(e.endReason, BpEndReason.time, reason: 'seviye $level seed $seed');
          expect(e.missedTargets, 0, reason: 'seviye $level seed $seed');
        }
      }
    });

    test('hiç dokunmayan oyuncu her seviyede 5 kaçanla biter', () {
      for (final level in [1, 2, 3]) {
        final e = _engine();
        e.start(level: level);
        _play(e, tap: false);
        expect(e.endReason, BpEndReason.missed, reason: 'seviye $level');
        expect(e.level, level);
      }
    });

    test('seviye 1–3 aralığına sınırlanır; start seviyeyi korur/yeniler', () {
      final e = _engine();
      e.start(level: 9);
      expect(e.level, 3);
      e.start(level: 0);
      expect(e.level, 1);
      e.start(); // seviye verilmezse önceki seviye korunur
      expect(e.level, 1);
    });
  });
}
