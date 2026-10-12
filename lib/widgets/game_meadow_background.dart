import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'holy_places_background.dart';
import 'lesson_grid_background.dart';

/// The games' backdrop, in the same children's-book style as the Dualar /
/// Sureler scene: a smiling sun, clouds and birds in the sky, soft pastel
/// mountains, green hills with a mosque, trees, grass, flowers and
/// butterflies.
///
/// Our own drawing in shapes (no photos, no picture files, no writing).
/// The middle of the screen is kept light and calm — game cards sit there —
/// so the scenery stays along the top band, the edges and the bottom.
/// Purely ornamental: never takes touches. Use it as the first child of a
/// [Stack] (see [GameScaffold]).
class GameMeadowBackground extends StatelessWidget {
  const GameMeadowBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: ValueKey('game-meadow-background'),
            painter: GameMeadowPainter(),
          ),
        ),
      ),
    );
  }
}

/// A [Scaffold] whose body stands on [GameMeadowBackground]. Every game
/// screen uses it (except Bul & Patlat and Harf Arabaları, which draw their
/// own sky and road).
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          const GameMeadowBackground(),
          if (body != null) Positioned.fill(child: body!),
        ],
      ),
    );
  }
}

class GameMeadowPainter extends HolyPlacesPainter {
  const GameMeadowPainter();

  static const Color sun = Color(0xFFFFD86B);
  static const Color sunRay = Color(0xFFFFE6A0);
  static const Color mountainBack = Color(0xFFD7D3F2);
  static const Color mountainFront = Color(0xFFC4DDF3);
  static const Color snow = Color(0xFFFFFFFF);

  /// How far up from the bottom the hills reach on a [size] screen.
  static double groundHeightFor(Size size) =>
      math.min(size.height * 0.16, 130.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HolyPlacesPainter.skyBright,
            HolyPlacesPainter.skyLight,
            HolyPlacesPainter.meadowLight,
          ],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    final unit = (math.min(w, h) / 600).clamp(0.5, 1.15).toDouble();

    // Sky: the sun on the left, clouds, birds.
    drawSun(canvas, Offset(46 * unit, 46 * unit), 26 * unit);
    drawCloud(canvas, Offset(w * 0.3, 34 * unit), 30 * unit);
    drawCloudFace(canvas, Offset(w * 0.78, 40 * unit), 34 * unit);
    drawBird(canvas, Offset(w * 0.52, 30 * unit), 9 * unit, true);
    drawBird(canvas, Offset(w * 0.6, 48 * unit), 7 * unit, true);

    // Butterflies down both edges (the middle stays free for the cards).
    final sides = <(double, double, double)>[
      (0.025, 0.3, 0.2),
      (0.975, 0.38, -0.25),
      (0.03, 0.56, -0.15),
      (0.97, 0.64, 0.2),
    ];
    for (var i = 0; i < sides.length; i++) {
      final (x, y, tilt) = sides[i];
      drawButterfly(
        canvas,
        Offset(x * w, y * h),
        12 * unit,
        HolyPlacesPainter.butterflyColors[i % 5],
        tilt: tilt,
      );
    }

    // Bottom: mountains behind green hills, a mosque on the right hill,
    // trees, grass and flowers.
    final ground = groundHeightFor(size);
    drawMountains(canvas, size, ground * 2.1, mountainBack, peaks: 4);
    drawMountains(canvas, size, ground * 1.6, mountainFront, peaks: 3, shift: 0.5);
    drawHill(canvas, size, ground, HolyPlacesPainter.hillBackBright, phase: 0.4);
    final base = h - ground * 0.55;
    final d = (w * 0.07).clamp(30.0, 64.0).toDouble();
    drawMosque(canvas, Offset(w * 0.84, base), d);
    drawTree(canvas, Offset(w * 0.06, base + 4 * unit), 30 * unit);
    drawTree(canvas, Offset(w * 0.15, base + 10 * unit), 22 * unit);
    drawTree(canvas, Offset(w * 0.66, base + 8 * unit), 24 * unit);
    drawHill(
      canvas,
      size,
      ground * 0.5,
      HolyPlacesPainter.hillFrontBright,
      phase: 0.8,
    );
    final front = h - ground * 0.14;
    final step = 28 * unit;
    var i = 0;
    for (var x = step / 2; x < w; x += step, i++) {
      drawGrass(canvas, Offset(x, front + (i.isEven ? 4 : 9) * unit), 8 * unit);
      if (i.isOdd) {
        drawFlower(
          canvas,
          Offset(x + 5 * unit, front - (i % 4 == 1 ? 2 : 9) * unit),
          6 * unit,
          HolyPlacesPainter.flowerColors[i % 5],
        );
      }
    }
    drawButterfly(
      canvas,
      Offset(w * 0.32, h - ground * 0.95),
      11 * unit,
      HolyPlacesPainter.butterflyColors[2],
      tilt: 0.2,
    );
    drawButterfly(
      canvas,
      Offset(w * 0.5, h - ground * 1.1),
      10 * unit,
      HolyPlacesPainter.butterflyColors[0],
      tilt: -0.2,
    );
  }

  /// A smiling sun with soft rounded rays.
  @protected
  void drawSun(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 2.2,
      Paint()
        ..shader = RadialGradient(
          colors: [sun.withValues(alpha: 0.35), sun.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2.2)),
    );
    final ray = Paint()
      ..color = sunRay
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * r * 1.3, c + dir * r * 1.65, ray);
    }
    canvas.drawCircle(c, r, Paint()..color = sun);
    final ink = Paint()
      ..color = LessonGridBackgroundPainter.ink.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.32, 0.32]) {
      canvas.drawArc(
        Rect.fromCircle(center: c.translate(dx * r, -r * 0.15), radius: r * 0.13),
        3.4,
        2.6,
        false,
        ink,
      );
    }
    canvas
      ..drawArc(
        Rect.fromCircle(center: c.translate(0, r * 0.12), radius: r * 0.32),
        0.4,
        2.3,
        false,
        ink,
      )
      ..drawCircle(
        c.translate(-r * 0.55, r * 0.2),
        r * 0.13,
        Paint()..color = HolyPlacesPainter.cheek.withValues(alpha: 0.7),
      )
      ..drawCircle(
        c.translate(r * 0.55, r * 0.2),
        r * 0.13,
        Paint()..color = HolyPlacesPainter.cheek.withValues(alpha: 0.7),
      );
  }

  /// A range of soft rounded mountains with snow caps, reaching [height]
  /// up from the bottom.
  @protected
  void drawMountains(
    Canvas canvas,
    Size size,
    double height,
    Color color, {
    required int peaks,
    double shift = 0,
  }) {
    final w = size.width, h = size.height;
    final step = w / peaks;
    final paint = Paint()..color = color.withValues(alpha: 0.9);
    final snowPaint = Paint()..color = snow.withValues(alpha: 0.85);
    for (var i = -1; i <= peaks; i++) {
      final cx = (i + 0.5 + shift) * step;
      final top = h - height * (0.82 + 0.18 * ((i + 7) % 2));
      final half = step * 0.7;
      final mountain = Path()
        ..moveTo(cx - half, h)
        ..quadraticBezierTo(cx - half * 0.35, top + (h - top) * 0.2, cx, top)
        ..quadraticBezierTo(cx + half * 0.35, top + (h - top) * 0.2, cx + half, h)
        ..close();
      canvas.drawPath(mountain, paint);
      final capH = (h - top) * 0.16;
      final cap = Path()
        ..moveTo(cx - half * 0.2, top + capH)
        ..quadraticBezierTo(cx - half * 0.08, top + capH * 0.2, cx, top)
        ..quadraticBezierTo(cx + half * 0.08, top + capH * 0.2, cx + half * 0.2, top + capH)
        ..quadraticBezierTo(cx, top + capH * 1.35, cx - half * 0.2, top + capH)
        ..close();
      canvas.drawPath(cap, snowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GameMeadowPainter oldDelegate) => false;
}
