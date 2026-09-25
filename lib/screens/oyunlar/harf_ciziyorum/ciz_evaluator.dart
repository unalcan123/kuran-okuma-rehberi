import 'dart:math' as math;
import 'dart:ui';

import 'ciz_models.dart';

/// Değerlendirme eşikleri — hepsi burada, hepsi HARF KUTUSUNA oranla
/// (ekran pikseli değil). Kutu telefonda 300 px, masaüstünde 600 px olsa da
/// aynı çizim aynı sonucu alır.
class TraceThresholds {
  const TraceThresholds({
    this.tolerance = 0.08,
    this.sampleSpacing = 0.008,
    this.minCoverage = 0.85,
    this.minStrokeCoverage = 0.7,
    this.maxGap = 0.12,
    this.minPrecision = 0.7,
    this.maxInkRatio = 3.0,
    this.dotTolerance = 0.1,
  });

  /// Çizilen nokta, yola bu kadar yakınsa yolu "takip etmiş" sayılır. Parmak
  /// kalınlığı ve küçük titremeler için cömert (glifin kalem kalınlığı ~0,06).
  final double tolerance;

  /// Yol da çizim de bu aralıkla eşit örneklenir: yavaş çizmek (çok nokta)
  /// ya da aynı yeri defalarca boyamak kapsamayı artırmaz.
  final double sampleSpacing;

  /// Yolun en az bu kadarı takip edilmeli.
  final double minCoverage;

  /// Her kalem hareketinin (ör. ط'nin dik çizgisi) en az bu kadarı.
  final double minStrokeCoverage;

  /// Takip edilmemiş en uzun kesintisiz parça, toplam yolun bu oranını
  /// geçmemeli (büyük eksik bölüm).
  final double maxGap;

  /// Çizilen izin en az bu kadarı yolun yakınında olmalı (karalama, taşma).
  final double minPrecision;

  /// Çizilen iz uzunluğu / yol uzunluğu en çok bu kadar (aşırı karalama).
  final double maxInkRatio;

  /// Konulan nokta hedef noktaya bu kadar yakın olmalı.
  final double dotTolerance;
}

const TraceThresholds kTraceThresholds = TraceThresholds();

enum TraceVerdict {
  /// Hiç çizilmedi.
  empty,

  /// Gövde yeterince tamamlandı.
  complete,

  /// Doğru yolda ama eksik bölüm var: eksik yeri göster, devam et.
  keepGoing,

  /// Çizginin çoğu yolun dışında ya da çok fazla karalama.
  offPath,
}

class TraceAssessment {
  const TraceAssessment({
    required this.verdict,
    required this.coverage,
    required this.strokeCoverage,
    required this.precision,
    required this.inkRatio,
    required this.largestGap,
    required this.missing,
  });

  final TraceVerdict verdict;
  final double coverage;
  final List<double> strokeCoverage;
  final double precision;
  final double inkRatio;
  final double largestGap;

  /// Takip edilmemiş yol parçaları (ekranda "buraya da devam et" diye
  /// gösterilir). Kısa kırıntılar dahil edilmez.
  final List<List<Offset>> missing;

  bool get isComplete => verdict == TraceVerdict.complete;
}

/// Çizimi modele göre değerlendirir. Yön ve sıra bağımsızdır: bir hareketi
/// ters yönden ya da hareketleri farklı sırayla çizmek yanlış sayılmaz.
TraceAssessment assessTrace(
  LetterTraceModel model,
  List<List<Offset>> drawn, {
  TraceThresholds t = kTraceThresholds,
}) {
  final ink = [
    for (final s in drawn)
      if (s.isNotEmpty) resamplePolyline(s, t.sampleSpacing),
  ];
  final inkPoints = [for (final s in ink) ...s];
  final inkLength = [
    for (final s in drawn) _length(s),
  ].fold(0.0, (a, b) => a + b);
  final modelLength = model.length;

  if (inkPoints.isEmpty) {
    return TraceAssessment(
      verdict: TraceVerdict.empty,
      coverage: 0,
      strokeCoverage: [for (final _ in model.strokes) 0],
      precision: 0,
      inkRatio: 0,
      largestGap: 1,
      missing: [for (final s in model.strokes) s.points],
    );
  }

  // Hangi yol örnekleri takip edildi?
  final strokeSamples = [
    for (final s in model.strokes) s.sample(t.sampleSpacing),
  ];
  final covered = [
    for (final samples in strokeSamples)
      [for (final p in samples) _near(p, inkPoints, t.tolerance)],
  ];
  var coveredCount = 0;
  var total = 0;
  final strokeCoverage = <double>[];
  for (final c in covered) {
    final n = c.where((x) => x).length;
    coveredCount += n;
    total += c.length;
    strokeCoverage.add(c.isEmpty ? 1 : n / c.length);
  }
  final coverage = total == 0 ? 0.0 : coveredCount / total;

  // Takip edilmemiş parçalar ve en uzunu.
  final missing = <List<Offset>>[];
  var largestGap = 0.0;
  for (var k = 0; k < covered.length; k++) {
    var run = <Offset>[];
    void close() {
      if (run.length >= 2) {
        final len = (run.length - 1) * t.sampleSpacing;
        largestGap = math.max(largestGap, len / modelLength);
        if (len >= t.tolerance * 0.5) missing.add(run);
      }
      run = <Offset>[];
    }

    for (var i = 0; i < covered[k].length; i++) {
      if (covered[k][i]) {
        close();
      } else {
        run.add(strokeSamples[k][i]);
      }
    }
    close();
  }

  // Çizilen izin ne kadarı yolun yakınında?
  final allModel = [for (final s in strokeSamples) ...s];
  final nearInk =
      inkPoints.where((p) => _near(p, allModel, t.tolerance * 1.25)).length;
  final precision = nearInk / inkPoints.length;
  final inkRatio = modelLength == 0 ? 0.0 : inkLength / modelLength;

  final TraceVerdict verdict;
  if (precision < t.minPrecision || inkRatio > t.maxInkRatio) {
    verdict = TraceVerdict.offPath;
  } else if (coverage >= t.minCoverage &&
      largestGap <= t.maxGap &&
      strokeCoverage.every((c) => c >= t.minStrokeCoverage)) {
    verdict = TraceVerdict.complete;
  } else {
    verdict = TraceVerdict.keepGoing;
  }
  return TraceAssessment(
    verdict: verdict,
    coverage: coverage,
    strokeCoverage: strokeCoverage,
    precision: precision,
    inkRatio: inkRatio,
    largestGap: largestGap,
    missing: missing,
  );
}

bool _near(Offset p, List<Offset> points, double r) {
  final r2 = r * r;
  for (final q in points) {
    final dx = p.dx - q.dx;
    final dy = p.dy - q.dy;
    if (dx * dx + dy * dy <= r2) return true;
  }
  return false;
}

double _length(List<Offset> s) {
  var total = 0.0;
  for (var i = 1; i < s.length; i++) {
    total += (s[i] - s[i - 1]).distance;
  }
  return total;
}

// ---------------------------------------------------------------------------
// Noktalar

enum DotVerdict { correct, tooFew, tooMany, wrongSide, misplaced }

class DotAssessment {
  const DotAssessment(
    this.verdict, {
    this.missingCount = 0,
    this.farIndexes = const [],
  });

  final DotVerdict verdict;

  /// Eksik (tooFew) ya da fazla (tooMany) nokta sayısı.
  final int missingCount;

  /// Yerinde olmayan konulmuş noktalar (misplaced).
  final List<int> farIndexes;

  bool get isCorrect => verdict == DotVerdict.correct;
}

/// Konulan noktaları değerlendirir: sayı, üst/alt ve yaklaşık yer.
/// Noktaların sırası önemli değildir (en iyi eşleşme aranır).
DotAssessment assessDots(
  LetterTraceModel model,
  List<Offset> placed, {
  TraceThresholds t = kTraceThresholds,
}) {
  final need = model.dots.length;
  if (placed.length < need) {
    return DotAssessment(DotVerdict.tooFew, missingCount: need - placed.length);
  }
  if (placed.length > need) {
    return DotAssessment(
      DotVerdict.tooMany,
      missingCount: placed.length - need,
    );
  }
  if (need == 0) return const DotAssessment(DotVerdict.correct);

  // Üstte mi altta mı? (Gövdenin dikey ortasına göre, ortalama.)
  final side = model.dotSide!;
  final mid = model.bodyBounds.center.dy;
  final placedY = placed.fold(0.0, (a, p) => a + p.dy) / placed.length;
  final placedSide = placedY < mid ? DotSide.above : DotSide.below;
  if (placedSide != side) return const DotAssessment(DotVerdict.wrongSide);

  // En iyi eşleşme (en çok 3 nokta: bütün sıralamalar denenir).
  List<int>? best;
  var bestCost = double.infinity;
  for (final perm in _permutations(List.generate(need, (i) => i))) {
    var cost = 0.0;
    for (var i = 0; i < need; i++) {
      cost += (placed[i] - model.dots[perm[i]].center).distance;
    }
    if (cost < bestCost) {
      bestCost = cost;
      best = perm;
    }
  }
  final far = [
    for (var i = 0; i < need; i++)
      if ((placed[i] - model.dots[best![i]].center).distance > t.dotTolerance)
        i,
  ];
  return far.isEmpty
      ? const DotAssessment(DotVerdict.correct)
      : DotAssessment(DotVerdict.misplaced, farIndexes: far);
}

Iterable<List<int>> _permutations(List<int> items) sync* {
  if (items.length <= 1) {
    yield items;
    return;
  }
  for (var i = 0; i < items.length; i++) {
    final rest = [...items]..removeAt(i);
    for (final p in _permutations(rest)) {
      yield [items[i], ...p];
    }
  }
}
