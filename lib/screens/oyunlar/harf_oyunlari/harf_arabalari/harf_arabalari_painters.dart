import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'harf_arabalari_engine.dart';

/// Yumuşak pastel araba renkleri (neon yok): gök mavisi, kiremit, mat altın,
/// turkuaz, adaçayı, lila.
const List<Color> kCarColors = [
  Color(0xFF8CC4E8), // sky blue
  Color(0xFFE5A48F), // soft terracotta
  Color(0xFFE6CB82), // muted gold
  Color(0xFF8FD3C8), // soft turquoise
  Color(0xFFB4CDA6), // sage
  Color(0xFFC6B5DD), // soft lilac
];

const Color kCarLetterColor = Color(0xFF0B2452);

/// Yandan görünüşlü, sağa bakan sevimli araba (harf plakası ayrıca widget'la).
/// Boyut = (genişlik, yükseklik) = (1.85·h, h).
class CarPainter extends CustomPainter {
  const CarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size box) {
    final w = box.width;
    final h = box.height;
    final dark = Color.lerp(color, const Color(0xFF3B4A5A), 0.28)!;
    final light = Color.lerp(color, Colors.white, 0.35)!;

    // Yer gölgesi
    canvas.drawOval(
      Rect.fromLTWH(w * 0.04, h * 0.90, w * 0.92, h * 0.10),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Kabin (üst kısım)
    final cabin =
        Path()
          ..moveTo(w * 0.20, h * 0.46)
          ..quadraticBezierTo(w * 0.24, h * 0.14, w * 0.40, h * 0.12)
          ..lineTo(w * 0.62, h * 0.12)
          ..quadraticBezierTo(w * 0.78, h * 0.16, w * 0.84, h * 0.46)
          ..close();
    canvas.drawPath(cabin, Paint()..color = light);
    canvas.drawPath(
      cabin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = dark.withValues(alpha: 0.6),
    );

    // Camlar
    final glass = Paint()..color = const Color(0xFFE3F1F7);
    final windowL =
        Path()
          ..moveTo(w * 0.26, h * 0.44)
          ..quadraticBezierTo(w * 0.29, h * 0.21, w * 0.40, h * 0.20)
          ..lineTo(w * 0.47, h * 0.20)
          ..lineTo(w * 0.47, h * 0.44)
          ..close();
    final windowR =
        Path()
          ..moveTo(w * 0.53, h * 0.20)
          ..lineTo(w * 0.61, h * 0.20)
          ..quadraticBezierTo(w * 0.73, h * 0.24, w * 0.78, h * 0.44)
          ..lineTo(w * 0.53, h * 0.44)
          ..close();
    canvas.drawPath(windowL, glass);
    canvas.drawPath(windowR, glass);

    // Gövde
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.42, w, h * 0.40),
      Radius.circular(h * 0.16),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light, color, dark],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = dark.withValues(alpha: 0.7),
    );

    // Farlar
    canvas.drawCircle(
      Offset(w * 0.955, h * 0.56),
      h * 0.055,
      Paint()..color = const Color(0xFFFFF3C4),
    );
    canvas.drawCircle(
      Offset(w * 0.045, h * 0.56),
      h * 0.04,
      Paint()..color = const Color(0xFFE9A5A0),
    );

    // Tekerlekler
    final r = h * 0.155;
    for (final cx in [w * 0.24, w * 0.76]) {
      final c = Offset(cx, h * 0.83);
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFF3B4550));
      canvas.drawCircle(c, r * 0.55, Paint()..color = const Color(0xFFD7DEE4));
      canvas.drawCircle(c, r * 0.18, Paint()..color = const Color(0xFF3B4550));
    }
  }

  @override
  bool shouldRepaint(CarPainter old) => old.color != color;
}

/// Sade yol: yumuşak şeritler, kesik çizgiler, alt-üst kenar.
class RoadPainter extends CustomPainter {
  const RoadPainter(this.lanes);

  final int lanes;

  @override
  void paint(Canvas canvas, Size size) {
    final laneH = size.height / lanes;
    for (var i = 0; i < lanes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * laneH, size.width, laneH),
        Paint()
          ..color =
              i.isEven ? const Color(0xFFC3CDD7) : const Color(0xFFBBC6D1),
      );
    }
    // Şerit çizgileri (kesik)
    final dash =
        Paint()
          ..color = const Color(0xFFF3EBD5).withValues(alpha: 0.9)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    for (var i = 1; i < lanes; i++) {
      final y = i * laneH;
      var x = 8.0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 26, size.width), y),
          dash,
        );
        x += 50;
      }
    }
    // Üst/alt kenar (adaçayı yeşili)
    final edge = Paint()..color = const Color(0xFFA8C3A0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 5), edge);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 5, size.width, 5), edge);
  }

  @override
  bool shouldRepaint(RoadPainter old) => old.lanes != lanes;
}

/// Yakalanan arabanın "+puan" ve ♪ efekti; dokunuşları engellemez.
class CatchFxPainter extends CustomPainter {
  CatchFxPainter(this.floats, {super.repaint});

  final List<HaFloat> floats;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in floats) {
      final t = (f.age / HaFloat.lifetime).clamp(0.0, 1.0);
      final fade = 1 - Curves.easeIn.transform(t);
      final rise = 46 * Curves.easeOut.transform(t);

      final points = TextPainter(
        text: TextSpan(
          text: '+${f.points}',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2E7D6E).withValues(alpha: fade),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      points.paint(canvas, Offset(f.cx - points.width / 2, f.cy - 24 - rise));
      points.dispose();

      final note = TextPainter(
        text: TextSpan(
          text: '♪',
          style: TextStyle(
            fontSize: 22,
            color: const Color(0xFF0B2452).withValues(alpha: 0.7 * fade),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      note.paint(canvas, Offset(f.cx + 26, f.cy - 30 - rise * 0.8));
      note.dispose();
    }
  }

  @override
  bool shouldRepaint(CatchFxPainter old) => true;
}
