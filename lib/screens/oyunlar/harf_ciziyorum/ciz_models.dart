import 'dart:math' as math;
import 'dart:ui';

import 'ciz_models_data.dart';

/// Harf Çiziyorum'un harf modelleri.
///
/// Her harf için AYRI tutulanlar:
///  * kimlik: [LetterTraceModel.letterId] (= `kArabicLetters` sırası, Harf
///    Dedektifi ile aynı; ad ve ses oradan gelir),
///  * çizim yolları: [LetterTraceModel.strokes] — kalın glifin dış hattı değil,
///    kalemin gittiği MERKEZ ÇİZGİ,
///  * önerilen sıra/yön: hareketlerin listedeki sırası ve noktaların sırası,
///  * noktalar: [LetterTraceModel.dots] (yalnızca imla noktaları; kef'in iç
///    işareti gibi işaretler hareket olarak durur, nokta sayılmaz),
///  * kılavuz görünümü: [LetterTraceModel.penWidth] ile aynı yolların çizimi.
/// Kılavuz ve değerlendirme aynı yolları kullanır.
///
/// Koordinatlar harf kutusuna göre 0–1'dir (y aşağı doğru); harf, noktaları
/// dahil, kutuya kenarlardan %12 boşlukla oturur. Böylece kutu hangi boyutta
/// çizilirse çizilsin model ve dokunma aynı yerde kalır.
///
/// KAYNAK: yollar ve noktalar projenin Hasenat yazı tipinden
/// `tool/harf_ciziyorum/extract_centerlines.py` ile çıkarıldı (glif iskeleti);
/// kontrol görüntüleri o araçla yeniden üretilir. Başlangıç noktası, yön ve
/// sıra ise projede doğrulanmış bir kaynağa dayanmaz (Elifba kitabında yazım
/// yönü yok): genel el yazısı alışkanlığına göre seçilmiş ÖNERİDİR. Bu yüzden
/// ekranda "bir yol" diye gösterilir ve değerlendirme yöne/sıraya bakmaz.
const bool kTraceDirectionVerified = false;

class TraceStroke {
  const TraceStroke(this.points);

  /// Önerilen yazış yönünde sıralı noktalar.
  final List<Offset> points;

  double get length {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }

  /// Yolu [spacing] aralıklarla örnekler (uçlar dahil).
  List<Offset> sample(double spacing) => resamplePolyline(points, spacing);
}

class TraceDot {
  const TraceDot(this.center, this.size);

  final Offset center;

  /// Glifteki noktanın yaklaşık çapı (kutu oranı).
  final double size;
}

enum DotSide { above, below }

class LetterTraceModel {
  const LetterTraceModel({
    required this.letterId,
    required this.penWidth,
    required this.strokes,
    this.dots = const [],
  });

  final int letterId;

  /// Glifin kalem kalınlığı (kutu oranı); kılavuz bu kalınlıkta çizilir.
  final double penWidth;
  final List<TraceStroke> strokes;
  final List<TraceDot> dots;

  bool get hasDots => dots.isNotEmpty;

  double get length => strokes.fold(0.0, (a, s) => a + s.length);

  Rect get bodyBounds {
    var r = Rect.fromPoints(
      strokes.first.points.first,
      strokes.first.points.first,
    );
    for (final s in strokes) {
      for (final p in s.points) {
        r = r.expandToInclude(Rect.fromPoints(p, p));
      }
    }
    return r;
  }

  /// Noktalar gövdenin üstünde mi altında mı (gövdenin dikey ortasına göre).
  DotSide? get dotSide {
    if (dots.isEmpty) return null;
    final mid = bodyBounds.center.dy;
    final y = dots.fold(0.0, (a, d) => a + d.center.dy) / dots.length;
    return y < mid ? DotSide.above : DotSide.below;
  }
}

LetterTraceModel? traceModelFor(int letterId) => kLetterTraceModels[letterId];

/// Çoklu çizgiyi eşit aralıklı noktalara çevirir. Yavaş çizilen (çok noktalı)
/// ile hızlı çizilen (seyrek) iz aynı ağırlıkta değerlendirilsin diye.
List<Offset> resamplePolyline(List<Offset> points, double spacing) {
  if (points.isEmpty) return const [];
  if (points.length == 1) return [points.first];
  final out = <Offset>[points.first];
  var need = spacing; // bir sonraki örneğe kalan yol
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final seg = (b - a).distance;
    var pos = 0.0;
    while (seg - pos >= need) {
      pos += need;
      out.add(Offset.lerp(a, b, pos / seg)!);
      need = spacing;
    }
    need -= seg - pos;
  }
  if ((out.last - points.last).distance > spacing * 0.25) out.add(points.last);
  return out;
}

/// Noktanın çoklu çizgiye en kısa uzaklığı.
double distanceToPolyline(Offset p, List<Offset> line) {
  if (line.length == 1) return (p - line.first).distance;
  var best = double.infinity;
  for (var i = 1; i < line.length; i++) {
    best = math.min(best, _distanceToSegment(p, line[i - 1], line[i]));
  }
  return best;
}

double _distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (len2 == 0) return (p - a).distance;
  final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}
