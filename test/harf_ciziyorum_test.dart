import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_ciziyorum/ciz_evaluator.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_ciziyorum/ciz_models.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_ciziyorum/ciz_models_data.dart';

/// Modeli takip eden "iyi" çizim. [jitter]: elin yavaş dalgalanan sapması
/// (en çok bu kadar) + her noktada küçük titreme.
List<List<Offset>> traceOf(
  LetterTraceModel m, {
  double jitter = 0,
  int seed = 1,
  bool reversed = false,
  double spacing = 0.01,
}) {
  final r = math.Random(seed);
  final strokes = <List<Offset>>[];
  for (final s in m.strokes) {
    final pts = resamplePolyline(s.points, spacing);
    final p1 = r.nextDouble() * 6.3;
    final p2 = r.nextDouble() * 6.3;
    strokes.add([
      for (var i = 0; i < pts.length; i++)
        pts[i] +
            Offset(
              jitter * 0.8 * math.sin(i * spacing / 0.11 * 6.28 + p1) +
                  (r.nextDouble() * 2 - 1) * jitter * 0.15,
              jitter * 0.8 * math.cos(i * spacing / 0.08 * 6.28 + p2) +
                  (r.nextDouble() * 2 - 1) * jitter * 0.15,
            ),
    ]);
  }
  if (!reversed) return strokes;
  return [for (final s in strokes.reversed) s.reversed.toList()];
}

void main() {
  test('28 harfin modeli var; kılavuz ve değerlendirme aynı yol', () {
    expect(kLetterTraceModels.keys.toSet(), {for (var i = 1; i <= 28; i++) i});
    for (final m in kLetterTraceModels.values) {
      expect(m.strokes, isNotEmpty);
      for (final s in m.strokes) {
        for (final p in s.points) {
          expect(p.dx, inInclusiveRange(0.0, 1.0));
          expect(p.dy, inInclusiveRange(0.0, 1.0));
        }
      }
    }
  });

  test('doğru çizim kabul', () {
    for (final m in kLetterTraceModels.values) {
      final a = assessTrace(m, traceOf(m));
      expect(a.verdict, TraceVerdict.complete, reason: '${m.letterId}');
    }
  });

  test('titrek ama doğru çizim kabul', () {
    for (final m in kLetterTraceModels.values) {
      for (final seed in [1, 2, 3]) {
        final a = assessTrace(m, traceOf(m, jitter: 0.03, seed: seed));
        expect(
          a.verdict,
          TraceVerdict.complete,
          reason:
              '${m.letterId} cov ${a.coverage} prec ${a.precision} '
              'ink ${a.inkRatio} gap ${a.largestGap} ${a.strokeCoverage}',
        );
      }
    }
  });

  test('ters yön ve farklı sıra yanlış sayılmaz', () {
    for (final m in kLetterTraceModels.values) {
      expect(
        assessTrace(m, traceOf(m, reversed: true)).verdict,
        TraceVerdict.complete,
      );
    }
  });

  test('yavaş çizim (çok sık nokta) de kabul', () {
    for (final m in kLetterTraceModels.values) {
      expect(
        assessTrace(m, traceOf(m, spacing: 0.001)).verdict,
        TraceVerdict.complete,
      );
    }
  });

  test('yalnızca başa ve sona dokunmak kabul değil', () {
    for (final m in kLetterTraceModels.values) {
      final taps = [
        for (final s in m.strokes) ...[
          [s.points.first],
          [s.points.last],
        ],
      ];
      expect(assessTrace(m, taps).isComplete, isFalse, reason: '${m.letterId}');
    }
  });

  test('yarım harf tamam sayılmaz; eksik yer gösterilir', () {
    for (final m in kLetterTraceModels.values) {
      final full = traceOf(m);
      final all = [for (final s in full) ...s];
      final half = [all.sublist(0, all.length ~/ 2)];
      final a = assessTrace(m, half);
      expect(a.isComplete, isFalse, reason: '${m.letterId}');
      expect(a.missing, isNotEmpty);
    }
  });

  test('aynı küçük yeri defalarca boyamak tamamlamaz', () {
    for (final m in kLetterTraceModels.values) {
      final s = resamplePolyline(m.strokes.first.points, 0.01);
      final bit = s.sublist(0, math.min(8, s.length));
      final a = assessTrace(m, [for (var i = 0; i < 30; i++) bit]);
      expect(a.isComplete, isFalse, reason: '${m.letterId}');
    }
  });

  test('bütün alanı karalamak kabul değil', () {
    final scribble = <Offset>[];
    for (var i = 0; i <= 40; i++) {
      scribble.add(Offset(0.05, 0.05 + i * 0.0225));
      scribble.add(Offset(0.95, 0.05 + i * 0.0225));
    }
    for (final m in kLetterTraceModels.values) {
      final a = assessTrace(m, [scribble]);
      expect(a.verdict, TraceVerdict.offPath, reason: '${m.letterId}');
    }
  });

  test(
    'yolun üstünde ileri geri sık karalama (aşırı mürekkep) kabul değil',
    () {
      final m = kLetterTraceModels[2]!;
      final path = resamplePolyline(m.strokes.first.points, 0.01);
      final zig = <Offset>[];
      for (var i = 0; i < path.length; i++) {
        for (var k = 0; k < 6; k++) {
          zig.add(path[i] + Offset(0, k.isEven ? 0.05 : -0.05));
        }
      }
      expect(assessTrace(m, [zig]).isComplete, isFalse);
    },
  );

  test('tolerans harf boyutuna göre: aynı çizim her ölçekte aynı sonuç', () {
    // Ekran boyutu değişince çizim kutuya göre normalleşir; burada iki farklı
    // kutu boyutundan (300 ve 700 px) normalleştirilmiş aynı çizim.
    final m = kLetterTraceModels[5]!;
    for (final side in [300.0, 700.0]) {
      final px = [
        for (final s in traceOf(m, jitter: 0.03)) [for (final p in s) p * side],
      ];
      final back = [
        for (final s in px) [for (final p in s) p / side],
      ];
      final a = assessTrace(m, back);
      expect(
        a.isComplete,
        isTrue,
        reason: 'cov ${a.coverage} prec ${a.precision} ink ${a.inkRatio}',
      );
    }
  });

  group('Noktalar', () {
    test('doğru sayı ve yer kabul; sıra önemsiz', () {
      for (final m in kLetterTraceModels.values.where((m) => m.hasDots)) {
        final placed = [for (final d in m.dots.reversed) d.center];
        expect(
          assessDots(m, placed).isCorrect,
          isTrue,
          reason: '${m.letterId}',
        );
        final near = [
          for (final d in m.dots) d.center + const Offset(0.03, -0.02),
        ];
        expect(assessDots(m, near).isCorrect, isTrue);
      }
    });

    test('eksik / fazla nokta', () {
      final te = kLetterTraceModels[3]!;
      expect(assessDots(te, [te.dots.first.center]).verdict, DotVerdict.tooFew);
      expect(
        assessDots(te, [
          ...te.dots.map((d) => d.center),
          const Offset(0.5, 0.2),
        ]).verdict,
        DotVerdict.tooMany,
      );
    });

    test('yanlış taraf (üst/alt) başarı değil', () {
      final be = kLetterTraceModels[2]!; // altta 1 nokta
      final body = be.bodyBounds;
      final above = Offset(be.dots.first.center.dx, body.top - 0.05);
      expect(assessDots(be, [above]).verdict, DotVerdict.wrongSide);
      final ye = kLetterTraceModels[28]!; // altta 2 nokta
      final yeAbove = [
        for (final d in ye.dots) Offset(d.center.dx, ye.bodyBounds.top),
      ];
      expect(assessDots(ye, yeAbove).verdict, DotVerdict.wrongSide);
    });

    test('doğru tarafta ama uzak nokta başarı değil', () {
      final nun = kLetterTraceModels[25]!;
      final far = nun.dots.first.center + const Offset(0.3, 0);
      final a = assessDots(nun, [far]);
      expect(a.isCorrect, isFalse);
    });

    test('nokta sayıları ve yerleri imlaya uygun', () {
      const expected = {
        2: (1, DotSide.below),
        3: (2, DotSide.above),
        4: (3, DotSide.above),
        5: (1, DotSide.below),
        7: (1, DotSide.above),
        9: (1, DotSide.above),
        11: (1, DotSide.above),
        13: (3, DotSide.above),
        15: (1, DotSide.above),
        17: (1, DotSide.above),
        19: (1, DotSide.above),
        20: (1, DotSide.above),
        21: (2, DotSide.above),
        25: (1, DotSide.above),
        28: (2, DotSide.below),
      };
      for (final m in kLetterTraceModels.values) {
        final e = expected[m.letterId];
        if (e == null) {
          expect(m.dots, isEmpty, reason: '${m.letterId} noktasız');
        } else {
          expect(m.dots.length, e.$1, reason: '${m.letterId}');
          expect(m.dotSide, e.$2, reason: '${m.letterId}');
        }
      }
    });
  });
}
