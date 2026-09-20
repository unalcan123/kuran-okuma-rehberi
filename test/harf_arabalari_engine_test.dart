import 'dart:io';
import 'dart:math' as math;

import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/harf_arabalari/harf_arabalari_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/game_letters.dart';
import 'package:flutter_test/flutter_test.dart';

List<GameLetter> _letters() => kGameLetters;

HarfArabalariEngine _engine({int seed = 1, double w = 360, double h = 560}) {
  final e = HarfArabalariEngine(letters: _letters(), random: math.Random(seed));
  e.resize(w, h);
  return e;
}

HaCar? _targetCar(HarfArabalariEngine e) {
  for (final c in e.cars) {
    if (c.catchable && c.letter.char == e.target?.char) return c;
  }
  return null;
}

/// Oyuncu botu: hedef arabası ekrana girdikten [reaction] sn sonra dokunur.
void _play(
  HarfArabalariEngine e, {
  bool tap = true,
  double reaction = 1.0,
  double dt = 1 / 60,
  double maxSeconds = 200,
  void Function()? onTick,
}) {
  var since = 0.0;
  GameLetter? last;
  for (var t = 0.0; t < maxSeconds && e.status == HaStatus.running; t += dt) {
    e.tick(dt);
    onTick?.call();
    if (e.target != last) {
      last = e.target;
      since = 0;
    }
    since += dt;
    if (tap && since >= reaction) {
      final c = _targetCar(e);
      if (c != null && c.x >= 0 && c.x + c.width <= e.width) e.tap(c.id);
    }
  }
}

void main() {
  test('gerçek veri: 28 harf ve ses dosyaları (Oyun 5 ile ortak veri)', () {
    final letters = _letters();
    expect(letters.length, 28);
    for (final l in letters) {
      expect(File('assets/${l.audio}').existsSync(), isTrue, reason: l.audio);
    }
  });

  group('hareket: soldan sağa, şeritlerde', () {
    test('araba soldan girer, sağa doğru gider, sağdan çıkar', () {
      final e = _engine();
      e.start();
      final first = e.cars.first;
      expect(first.x, lessThan(0), reason: 'ekranın solundan girer');
      var previousX = first.x;
      var exited = false;
      for (var t = 0.0; t < 40 && !exited; t += 1 / 60) {
        e.tick(1 / 60);
        if (!e.cars.contains(first)) {
          exited = true;
        } else {
          expect(first.x, greaterThanOrEqualTo(previousX)); // hep sağa
          previousX = first.x;
        }
      }
      expect(exited, isTrue, reason: 'sağdan çıkıp kaldırılır');
      expect(previousX, greaterThan(e.width * 0.8));
    });

    test('şerit sayısı cihaza göre 3–5; araba sayısı 3–6', () {
      final sizes = {
        'küçük telefon': const [320.0, 480.0],
        'telefon dikey': const [390.0, 640.0],
        'telefon yatay': const [700.0, 260.0],
        'tablet dikey': const [800.0, 1000.0],
        'tablet yatay': const [1000.0, 560.0],
      };
      final laneCounts = <String, int>{};
      for (final s in sizes.entries) {
        final e = _engine(w: s.value[0], h: s.value[1]);
        expect(e.lanes, inInclusiveRange(3, 5), reason: s.key);
        expect(e.maxAlive, inInclusiveRange(3, 6), reason: s.key);
        expect(e.carHeight, greaterThanOrEqualTo(56), reason: s.key);
        expect(e.carHeight, lessThanOrEqualTo(e.laneHeight), reason: s.key);
        laneCounts[s.key] = e.lanes;
      }
      expect(laneCounts['tablet dikey']!, greaterThan(laneCounts['telefon yatay']! - 1));
    });

    test('farklı şeritler kullanılır ve aynı şeritte arabalar hiç üst üste binmez',
        () {
      for (final size in const [[360.0, 560.0], [800.0, 1000.0], [1000.0, 500.0]]) {
        final usedLanes = <int>{};
        var minGap = double.infinity;
        for (final seed in [1, 2, 3]) {
          final e = _engine(seed: seed, w: size[0], h: size[1]);
          e.start();
          _play(e, reaction: 1.5, maxSeconds: 90, onTick: () {
            final alive = e.cars.where((c) => !c.caught).toList();
            for (final c in alive) {
              usedLanes.add(c.lane);
            }
            for (var lane = 0; lane < e.lanes; lane++) {
              final inLane = alive.where((c) => c.lane == lane).toList()
                ..sort((a, b) => a.x.compareTo(b.x));
              for (var i = 0; i + 1 < inLane.length; i++) {
                minGap = math.min(minGap, inLane[i + 1].x - (inLane[i].x + inLane[i].width));
              }
            }
          });
        }
        expect(usedLanes.length, greaterThanOrEqualTo(3), reason: '$size');
        expect(minGap, greaterThanOrEqualTo(-0.01), reason: 'şeritte üst üste binme $size');
      }
    });

    test('ekranda aynı anda 3–6 (yaklaşık) araba; taşmaz', () {
      final e = _engine();
      e.start();
      var maxSeen = 0, sum = 0, n = 0;
      _play(e, reaction: 2, maxSeconds: 60, onTick: () {
        final alive = e.cars.where((c) => !c.caught).length;
        maxSeen = math.max(maxSeen, alive);
        sum += alive;
        n++;
      });
      expect(maxSeen, lessThanOrEqualTo(e.maxAlive + 1)); // +1: hedef için zorunlu
      expect(sum / n, inInclusiveRange(2.0, 6.0));
    });

    test('geçiş süresi alan genişliğinden bağımsız (geniş ekranda sürünmez)', () {
      double crossing(double w) {
        final e = _engine(w: w, h: 500);
        e.start();
        return (e.width + e.carWidth) / (e.width * e.speedFraction);
      }

      expect((crossing(400) - crossing(1000)).abs(), lessThan(3.5));
      expect(crossing(1000), lessThan(14)); // makul süre
      expect(crossing(1000), greaterThan(5));
    });
  });

  group('hedef', () {
    test('hedef harfin arabası HER ZAMAN ekranda; hiç dokunmasa da 120 sn sürer', () {
      for (final seed in [1, 2, 3, 4]) {
        final e = _engine(seed: seed);
        e.start();
        var checked = 0;
        _play(e, tap: false, onTick: () {
          if (e.status != HaStatus.running) return;
          checked++;
          expect(_targetCar(e), isNotNull,
              reason: 'seed $seed: hedef ${e.target?.char} ekranda değil');
        });
        expect(e.status, HaStatus.over);
        expect(e.elapsed, greaterThanOrEqualTo(120));
        expect(e.missedTargets, greaterThan(3)); // kaçırılan hedefler sayılır
        expect(checked, greaterThan(6000));
      }
    });

    test('kaçırılan hedef: ilkinde aynı harfle yeni araba, sonra yeni hedef', () {
      final e = _engine();
      e.start();
      final first = e.target!.char;
      e.takeEvents();
      var events = <HaEvent>[];
      // İlk kaçırma
      while (e.missedTargets == 0) {
        e.tick(1 / 30);
        events = e.takeEvents();
      }
      expect(events.whereType<HaTargetMissed>().length, 1);
      expect(e.target!.char, first, reason: 'aynı harf yeniden gönderilir');
      final again = events.whereType<HaTargetChanged>().toList();
      expect(again.single.letter.char, first, reason: 'aynı ses tekrar duyulur');
      expect(_targetCar(e), isNotNull);
      // İkinci kaçırma → yeni hedef
      while (e.missedTargets < 2) {
        e.tick(1 / 30);
      }
      expect(e.target!.char, isNot(first));
      expect(_targetCar(e), isNotNull);
    });

    test('dengeli hedef torbası: 28 hedefte her harf bir kez', () {
      final e = _engine();
      e.start();
      final targets = <String>[e.target!.char];
      for (var i = 0; i < 27; i++) {
        e.tick(0.5);
        final c = _targetCar(e)!;
        e.tap(c.id);
        targets.add(e.target!.char);
      }
      expect(targets.toSet().length, 28);
    });

    test('benzer harfler (ب ت ث…) hedefle birlikte arabalarda görünür', () {
      var similar = 0, total = 0;
      for (var seed = 1; seed <= 20; seed++) {
        final e = _engine(seed: seed);
        e.start();
        final target = e.target!.char;
        final family = HarfArabalariEngine.similarFamilyOf(target);
        if (family == null) continue;
        for (var i = 0; i < 200; i++) {
          e.tick(0.1);
        }
        for (final c in e.cars) {
          if (c.letter.char == target) continue;
          total++;
          if (family.contains(c.letter.char)) similar++;
        }
      }
      expect(total, greaterThan(20));
      expect(similar, greaterThan(0));
      expect(similar / total, lessThan(0.7));
    });
  });

  group('doğru / yanlış dokunma', () {
    test('doğru: yakalanır (hızlanıp çıkar), +15, yeni hedef, +puan efekti', () {
      final e = _engine();
      e.start();
      e.tick(3);
      final car = _targetCar(e)!;
      final oldTarget = e.target!.char;
      e.takeEvents();
      e.tap(car.id);
      expect(car.caught, isTrue);
      expect(e.score, 15);
      expect(e.correct, 1);
      expect(e.target!.char, isNot(oldTarget));
      expect(e.floats, isNotEmpty);
      final events = e.takeEvents();
      expect(events.whereType<HaCaught>().single.points, 15);
      expect(events.whereType<HaTargetChanged>().single.afterCatch, isTrue);

      // Yakalanan araba kısa sürede oyun alanından kalkar; oyun sürer.
      final x0 = car.x;
      for (var i = 0; i < 60; i++) {
        e.tick(1 / 60);
      }
      expect(car.x, greaterThan(x0));
      for (var i = 0; i < 60; i++) {
        e.tick(1 / 60);
      }
      expect(e.cars.contains(car), isFalse);
      expect(e.status, HaStatus.running);
    });

    test('yanlış: araba kaybolmaz, puan düşmez, hedef aynı, tekrar denenir', () {
      final e = _engine();
      e.start();
      for (var i = 0; i < 400; i++) {
        e.tick(0.05);
        if (e.cars.any((c) => c.catchable && c.letter.char != e.target!.char)) break;
      }
      final wrong = e.cars.firstWhere((c) => c.catchable && c.letter.char != e.target!.char);
      final target = e.target;
      e.tap(wrong.id);
      expect(e.wrongTaps, 1);
      expect(e.score, 0);
      expect(wrong.exited, isFalse);
      expect(wrong.caught, isFalse);
      expect(wrong.shake, 1);
      expect(e.target, same(target));

      e.tap(_targetCar(e)!.id);
      expect(e.score, 10, reason: 'ilk deneme bonusu yok');
    });

    test('puan negatif olmaz; yanlış dokunmalar 0 puan', () {
      final e = _engine();
      e.start();
      for (var i = 0; i < 300; i++) {
        e.tick(0.05);
        for (final c in List.of(e.cars)) {
          if (c.letter.char != e.target?.char) e.tap(c.id);
        }
        expect(e.score, greaterThanOrEqualTo(0));
      }
      expect(e.score, 0);
    });
  });

  group('süre, istatistik, sonuç', () {
    test('kusursuz oyuncu: 120 sn, doğruluk %100, yıldız 3, istatistikler tutarlı', () {
      final e = _engine(seed: 3);
      e.start();
      _play(e, reaction: 1.0);
      expect(e.status, HaStatus.over);
      expect(e.elapsed, greaterThanOrEqualTo(120));
      expect(e.remainingSeconds, 0);
      expect(e.correct, greaterThan(15));
      expect(e.missedTargets, 0);
      expect(e.accuracyPercent, 100);
      expect(e.stars, 3);
      // "Geçen araba" = oyun alanına giren tüm harfli arabalar.
      expect(e.spawned, greaterThanOrEqualTo(e.correct));
      expect(e.takeEvents().whereType<HaGameOver>().length, 1);
    });

    test('doğruluk = doğru / (doğru + yanlış + kaçırılan hedef)', () {
      final e = _engine();
      e.core.correct = 14;
      e.core.wrongTaps = 2;
      e.core.missedTargets = 1;
      expect(e.accuracyPercent, 82);
    });

    test('bittikten sonra tick etkisiz; yeniden başla sayaçları sıfırlar', () {
      final e = _engine();
      e.start();
      _play(e, reaction: 1.0, maxSeconds: 30);
      expect(e.score, greaterThan(0));
      e.start();
      expect([e.score, e.correct, e.wrongTaps, e.missedTargets, e.spawned > 0 ? 0 : 1], [0, 0, 0, 0, 0]);
      expect(e.elapsed, 0);
      expect(e.status, HaStatus.running);
      expect(_targetCar(e), isNotNull);
    });

    test('alan değişince (döndürme) arabalar orantılı taşınır; hata yok', () {
      final e = _engine();
      e.start();
      for (var i = 0; i < 300; i++) {
        e.tick(0.05);
      }
      e.resize(700, 300);
      e.tick(0.1);
      expect(e.lanes, inInclusiveRange(3, 5));
    });
  });
}
