import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'bul_patlat_engine.dart';

/// Yumuşak pastel balon renkleri (Elifba/Kur'an Okuma Rehberi renk dünyası):
/// turkuaz, adaçayı, gök mavisi, mat altın, yumuşak kiremit, krem. Neon yok.
const List<Color> kBalloonColors = [
  Color(0xFF8FD3C8), // soft turquoise
  Color(0xFFB4CDA6), // sage
  Color(0xFF9CCBEA), // sky blue
  Color(0xFFE6CB82), // muted gold
  Color(0xFFE7AE9A), // soft terracotta
  Color(0xFFF1E4C6), // cream
];

/// Balon harfi: pastel zeminde okunaklı koyu lacivert.
const Color kBalloonLetterColor = Color(0xFF0B2452);

/// Bir balonun gövdesi + düğümü + kısa ipi. Boyut = (size, boxHeight).
/// Harf ayrı bir Text olarak üstüne konur (Arapça birleşimi bozulmasın).
class BalloonPainter extends CustomPainter {
  const BalloonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size box) {
    final w = box.width;
    final bodyH = w * 1.18;

    final body =
        Path()
          ..moveTo(w / 2, bodyH)
          ..cubicTo(w * 0.30, bodyH * 0.92, 0, bodyH * 0.68, 0, bodyH * 0.42)
          ..cubicTo(0, bodyH * 0.12, w * 0.24, 0, w / 2, 0)
          ..cubicTo(w * 0.76, 0, w, bodyH * 0.12, w, bodyH * 0.42)
          ..cubicTo(w, bodyH * 0.68, w * 0.70, bodyH * 0.92, w / 2, bodyH)
          ..close();

    // İp (gövdenin arkasında).
    final stringPaint =
        Paint()
          ..color = const Color(0xFF7A8794)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, w * 0.018)
          ..strokeCap = StrokeCap.round;
    final string =
        Path()
          ..moveTo(w / 2, bodyH + w * 0.05)
          ..quadraticBezierTo(w * 0.62, bodyH + w * 0.17, w * 0.47, box.height);
    canvas.drawPath(string, stringPaint);

    // Yumuşak gölge
    canvas.drawShadow(body, Colors.black.withValues(alpha: 0.35), 3, false);

    // Gövde: merkezi açık, kenarı biraz koyu (hacim hissi)
    final shader = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 1.0,
      colors: [
        Color.lerp(color, Colors.white, 0.35)!,
        color,
        Color.lerp(color, const Color(0xFF3B4A5A), 0.22)!,
      ],
      stops: const [0.0, 0.62, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, bodyH));
    canvas.drawPath(body, Paint()..shader = shader);

    // Kenar çizgisi
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.lerp(
          color,
          const Color(0xFF3B4A5A),
          0.35,
        )!.withValues(alpha: 0.7),
    );

    // Parlama
    canvas.drawOval(
      Rect.fromLTWH(w * 0.16, bodyH * 0.10, w * 0.16, bodyH * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );

    // Düğüm
    final knot =
        Path()
          ..moveTo(w / 2 - w * 0.06, bodyH + w * 0.055)
          ..lineTo(w / 2 + w * 0.06, bodyH + w * 0.055)
          ..lineTo(w / 2, bodyH - w * 0.005)
          ..close();
    canvas.drawPath(
      knot,
      Paint()..color = Color.lerp(color, const Color(0xFF3B4A5A), 0.3)!,
    );
  }

  @override
  bool shouldRepaint(BalloonPainter old) => old.color != color;
}

/// Patlayan balonların parçacıkları ve kısa nota geri bildirimi. Tek bir
/// painter tüm efektleri çizer; oyun alanının üstünde, dokunuşları engellemez.
class PopPainter extends CustomPainter {
  PopPainter(this.pops, {super.repaint});

  final List<BpPop> pops;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pops) {
      final t = (p.age / BpPop.lifetime).clamp(0.0, 1.0);
      final fade = 1 - t;
      final color = kBalloonColors[p.colorIndex % kBalloonColors.length];
      final rnd = math.Random(p.seed);

      // Yayılan halka
      canvas.drawCircle(
        Offset(p.cx, p.cy),
        20 + 46 * Curves.easeOut.transform(t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * fade + 0.5
          ..color = color.withValues(alpha: 0.55 * fade),
      );

      // Balon parçaları
      for (var i = 0; i < 12; i++) {
        final angle = i / 12 * math.pi * 2 + rnd.nextDouble() * 0.4;
        final speed = 40 + rnd.nextDouble() * 70;
        final dist = speed * Curves.easeOut.transform(t);
        final r = (3 + rnd.nextDouble() * 4) * (1 - t * 0.5);
        canvas.drawCircle(
          Offset(
            p.cx + math.cos(angle) * dist,
            p.cy + math.sin(angle) * dist + 18 * t * t,
          ),
          r,
          Paint()..color = color.withValues(alpha: 0.9 * fade),
        );
      }

      // Kısa ♪ geri bildirimi (yukarı süzülür ve kaybolur)
      final note = TextPainter(
        text: TextSpan(
          text: rnd.nextBool() ? '♪' : '♫',
          style: TextStyle(
            fontSize: 26,
            color: const Color(0xFF0B2452).withValues(alpha: 0.75 * fade),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      note.paint(canvas, Offset(p.cx - note.width / 2, p.cy - 30 - 34 * t));
      note.dispose();
    }
  }

  @override
  bool shouldRepaint(PopPainter old) => true; // her karede yaş değişir
}
