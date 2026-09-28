import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A very light children's-book backdrop for the lessons' Grid view, after
/// the home illustrations: pale blue sky, soft clouds, small stars, a faint
/// rainbow at each side, green hills with grass, and a few little flowers and
/// trees in the bottom corners.
///
/// Drawn only with gradients and shapes (no picture file, no Arabic letters,
/// so nothing mixes with the lesson's letters): crisp at any size, light, and
/// nothing to license. Everything is pale and kept to the edges and corners;
/// the letter cards (opaque) sit on top, so the Arabic letters are never
/// drawn over a pattern. Purely ornamental: never takes touches. Use it as
/// the first child of a [Stack].
class LessonGridBackground extends StatelessWidget {
  const LessonGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: ValueKey('lesson-grid-background'),
            painter: LessonGridBackgroundPainter(),
          ),
        ),
      ),
    );
  }
}

/// Also the toolbox of the app's other children's-book backdrops (see
/// `HolyPlacesPainter`): its `draw…` shapes are shared.
class LessonGridBackgroundPainter extends CustomPainter {
  const LessonGridBackgroundPainter();

  // Pastel tones (low contrast on purpose).
  static const Color skyTop = Color(0xFFE3F2FC);
  static const Color skyMiddle = Color(0xFFF1F8FD);
  static const Color cloud = Color(0xFFFFFFFF);
  static const Color star = Color(0xFFF2CF63);
  static const Color hillBack = Color(0xFFD5EDC9);
  static const Color hillFront = Color(0xFFC3E4B4);
  static const Color grass = Color(0xFFA9D79A);
  static const Color trunk = Color(0xFFCBB08C);
  static const Color treeTop = Color(0xFFB5DCA5);
  static const Color ink = Color(0xFF8A7B6E); // soft outlines, eyes
  static const Color bunny = Color(0xFFFFFFFF);
  static const Color bunnyEar = Color(0xFFF8C9D4);
  static const Color beeYellow = Color(0xFFFFD86B);
  static const Color wing = Color(0xFFFFFFFF);
  static const List<Color> rainbow = [
    Color(0xFFF7A8B8), // pink
    Color(0xFFFFD98A), // yellow
    Color(0xFFB9E4A3), // green
    Color(0xFFA9D8F5), // blue
    Color(0xFFCDB8F0), // lilac
  ];
  static const List<Color> petals = [
    Color(0xFFF8BBD0), // pink
    Color(0xFFFFFFFF), // white
    Color(0xFFFFE08A), // yellow
    Color(0xFFD7C4F2), // lilac
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Sky: pale blue at the top fading into the app's cream.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyMiddle, AppColors.background],
          stops: [0, 0.45, 1],
        ).createShader(rect),
    );

    // Scale for the decorations: phones get smaller ones.
    final unit = (math.min(w, h) / 600).clamp(0.55, 1.2).toDouble();

    // Rainbows peeking in from each side, low on the screen.
    drawRainbow(canvas, Offset(-40 * unit, h * 0.78), 150 * unit);
    drawRainbow(canvas, Offset(w + 40 * unit, h * 0.70), 130 * unit);

    // Clouds: in the corners and along the sides, never in the middle.
    const clouds = <(double, double, double)>[
      (0.07, 0.07, 1.0),
      (0.90, 0.10, 1.15),
      (0.02, 0.42, 0.8),
      (0.97, 0.47, 0.85),
      (0.30, 0.03, 0.6),
      (0.70, 0.02, 0.65),
    ];
    for (final (x, y, s) in clouds) {
      drawCloud(canvas, Offset(x * w, y * h + 24 * unit), 46 * unit * s);
    }

    // Small stars, scattered near the top and the sides.
    const stars = <(double, double, double)>[
      (0.18, 0.12, 1.0),
      (0.82, 0.22, 0.8),
      (0.05, 0.24, 0.7),
      (0.94, 0.30, 1.0),
      (0.44, 0.06, 0.6),
      (0.58, 0.09, 0.8),
      (0.10, 0.60, 0.65),
      (0.91, 0.62, 0.7),
      (0.26, 0.20, 0.55),
      (0.74, 0.15, 0.6),
    ];
    for (final (x, y, s) in stars) {
      drawStar(canvas, Offset(x * w, y * h), 7 * unit * s);
    }

    // Hills along the bottom, with little trees on the back hill.
    final hillHeight = math.min(h * 0.14, 130.0);
    drawHill(canvas, size, hillHeight, hillBack, phase: 0.2);
    final treeBase = h - hillHeight * 0.55;
    drawTree(canvas, Offset(w * 0.035, treeBase), 34 * unit);
    drawTree(canvas, Offset(w * 0.085, treeBase + 6 * unit), 24 * unit);
    drawTree(canvas, Offset(w * 0.955, treeBase), 32 * unit);
    drawHill(canvas, size, hillHeight * 0.62, hillFront, phase: 0.65);

    // Little animals, at the edges only: butterflies along the sides, bees
    // near the top corners, a bunny on the bottom-left hill.
    drawButterfly(
      canvas,
      Offset(w * 0.045, h * 0.34),
      16 * unit,
      const Color(0xFFF7A8C8),
      tilt: -0.25,
    );
    drawButterfly(
      canvas,
      Offset(w * 0.955, h * 0.38),
      15 * unit,
      const Color(0xFFBBA7EE),
      tilt: 0.3,
    );
    drawButterfly(
      canvas,
      Offset(w * 0.93, h * 0.80),
      12 * unit,
      const Color(0xFFFFC98A),
      tilt: -0.15,
    );
    drawBee(canvas, Offset(w * 0.12, h * 0.17), 10 * unit);
    drawBee(canvas, Offset(w * 0.88, h * 0.06 + 14 * unit), 9 * unit);
    drawBunny(canvas, Offset(w * 0.14, h - hillHeight * 0.34), 16 * unit);

    // Grass tufts and flowers along the very bottom edge, corners only.
    final ground = h - hillHeight * 0.18;
    for (final x in [0.02, 0.06, 0.13, 0.87, 0.93, 0.98]) {
      drawGrass(canvas, Offset(x * w, ground + 4 * unit), 9 * unit);
    }
    const flowers = <(double, double)>[
      (0.04, 0.0),
      (0.10, 0.4),
      (0.16, 0.1),
      (0.84, 0.3),
      (0.90, 0.0),
      (0.965, 0.5),
    ];
    for (var i = 0; i < flowers.length; i++) {
      final (x, dy) = flowers[i];
      drawFlower(
        canvas,
        Offset(x * w, ground - dy * 10 * unit),
        6 * unit,
        petals[i % petals.length],
      );
    }
  }

  @protected
  void drawRainbow(Canvas canvas, Offset center, double radius) {
    final band = radius * 0.1;
    for (var i = 0; i < rainbow.length; i++) {
      canvas.drawCircle(
        center,
        radius - i * band,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = band
          ..color = rainbow[i].withValues(alpha: 0.35),
      );
    }
  }

  @protected
  void drawHill(
    Canvas canvas,
    Size size,
    double height, // how far up from the bottom the hills reach
    Color color, {
    required double phase,
  }) {
    final w = size.width, h = size.height;
    final base = h - height;
    final path = Path()..moveTo(0, h);
    path.lineTo(0, base + height * 0.35);
    const humps = 3;
    for (var i = 0; i < humps; i++) {
      final x0 = w * i / humps;
      final x1 = w * (i + 1) / humps;
      final top = base + height * (0.1 + 0.25 * ((i + phase * 3) % 2));
      path.quadraticBezierTo(
        (x0 + x1) / 2 + w * 0.04 * (phase - 0.5),
        top - height * 0.3,
        x1,
        base + height * 0.35,
      );
    }
    path
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.75));
  }

  @protected
  void drawCloud(Canvas canvas, Offset c, double r) {
    final paint = Paint()..color = cloud.withValues(alpha: 0.8);
    canvas
      ..drawCircle(c, r * 0.55, paint)
      ..drawCircle(c + Offset(-r * 0.55, r * 0.15), r * 0.4, paint)
      ..drawCircle(c + Offset(r * 0.6, r * 0.12), r * 0.45, paint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(c.dx - r * 0.95, c.dy, c.dx + r * 1.05, c.dy + r * 0.5),
          Radius.circular(r * 0.25),
        ),
        paint,
      );
  }

  @protected
  void drawStar(Canvas canvas, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = star.withValues(alpha: 0.55));
  }

  /// A small round tree standing on [base] (bottom of the trunk).
  @protected
  void drawTree(Canvas canvas, Offset base, double r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base.translate(0, -r * 0.45),
          width: r * 0.22,
          height: r * 0.9,
        ),
        Radius.circular(r * 0.08),
      ),
      Paint()..color = trunk.withValues(alpha: 0.7),
    );
    final leaves = Paint()..color = treeTop.withValues(alpha: 0.8);
    final top = base.translate(0, -r * 1.2);
    canvas
      ..drawCircle(top, r * 0.55, leaves)
      ..drawCircle(top.translate(-r * 0.35, r * 0.18), r * 0.38, leaves)
      ..drawCircle(top.translate(r * 0.35, r * 0.18), r * 0.38, leaves);
  }

  @protected
  void drawGrass(Canvas canvas, Offset c, double r) {
    final paint =
        Paint()
          ..color = grass.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.28
          ..strokeCap = StrokeCap.round;
    for (final dx in [-0.6, 0.0, 0.6]) {
      canvas.drawLine(
        c.translate(dx * r * 0.5, 0),
        c.translate(dx * r, -r * (dx == 0 ? 1.4 : 1.0)),
        paint,
      );
    }
  }

  /// A small butterfly (two pairs of round wings), [r] ≈ half its span.
  @protected
  void drawButterfly(
    Canvas canvas,
    Offset c,
    double r,
    Color color, {
    double tilt = 0,
  }) {
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(tilt);
    final wings = Paint()..color = color.withValues(alpha: 0.8);
    final spots = Paint()..color = wing.withValues(alpha: 0.7);
    for (final side in [-1.0, 1.0]) {
      final upper = Offset(side * r * 0.55, -r * 0.35);
      final lower = Offset(side * r * 0.42, r * 0.38);
      canvas
        ..drawOval(
          Rect.fromCenter(center: upper, width: r * 1.0, height: r * 0.85),
          wings,
        )
        ..drawOval(
          Rect.fromCenter(center: lower, width: r * 0.75, height: r * 0.65),
          wings,
        )
        ..drawCircle(upper, r * 0.14, spots);
    }
    final line =
        Paint()
          ..color = ink.withValues(alpha: 0.7)
          ..strokeWidth = r * 0.12
          ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(0, -r * 0.55), Offset(0, r * 0.6), line)
      ..drawLine(Offset(0, -r * 0.55), Offset(-r * 0.3, -r * 0.95), line)
      ..drawLine(Offset(0, -r * 0.55), Offset(r * 0.3, -r * 0.95), line)
      ..restore();
  }

  /// A round little bee with striped body and two light wings.
  @protected
  void drawBee(Canvas canvas, Offset c, double r) {
    final wings = Paint()..color = wing.withValues(alpha: 0.85);
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(-r * 0.35, -r * 0.8),
          width: r * 0.9,
          height: r * 1.1,
        ),
        wings,
      )
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(r * 0.3, -r * 0.85),
          width: r * 0.9,
          height: r * 1.1,
        ),
        wings,
      );
    final body = Rect.fromCenter(center: c, width: r * 2.1, height: r * 1.5);
    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.75)))
      ..drawRect(body, Paint()..color = beeYellow.withValues(alpha: 0.9));
    final stripe = Paint()..color = ink.withValues(alpha: 0.55);
    for (final dx in [-0.25, 0.3]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: c.translate(dx * r, 0),
          width: r * 0.28,
          height: r * 1.6,
        ),
        stripe,
      );
    }
    canvas
      ..restore()
      ..drawCircle(
        c.translate(-r * 0.7, -r * 0.12),
        r * 0.1,
        Paint()..color = ink.withValues(alpha: 0.8),
      );
  }

  /// A sitting white bunny seen from the side, [r] ≈ its body radius.
  @protected
  void drawBunny(Canvas canvas, Offset feet, double r) {
    final fur = Paint()..color = bunny.withValues(alpha: 0.92);
    final pink = Paint()..color = bunnyEar.withValues(alpha: 0.9);
    final body = feet.translate(0, -r * 0.7);
    final head = body.translate(r * 0.75, -r * 0.8);
    // Ears
    for (final (dx, tilt) in [(-0.12, -0.25), (0.22, 0.12)]) {
      canvas
        ..save()
        ..translate(head.dx + dx * r, head.dy - r * 0.55)
        ..rotate(tilt);
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: Offset(0, -r * 0.4),
            width: r * 0.36,
            height: r * 1.0,
          ),
          fur,
        )
        ..drawOval(
          Rect.fromCenter(
            center: Offset(0, -r * 0.38),
            width: r * 0.16,
            height: r * 0.7,
          ),
          pink,
        )
        ..restore();
    }
    canvas
      ..drawOval(
        Rect.fromCenter(center: body, width: r * 2.0, height: r * 1.55),
        fur,
      )
      ..drawCircle(body.translate(-r * 0.95, -r * 0.1), r * 0.3, fur) // tail
      ..drawCircle(head, r * 0.6, fur)
      ..drawCircle(
        head.translate(r * 0.2, -r * 0.08),
        r * 0.08,
        Paint()..color = ink.withValues(alpha: 0.85),
      )
      ..drawCircle(head.translate(r * 0.52, r * 0.12), r * 0.08, pink)
      ..drawCircle(
        head.translate(r * 0.25, r * 0.22),
        r * 0.12,
        Paint()..color = bunnyEar.withValues(alpha: 0.5),
      );
  }

  @protected
  void drawFlower(Canvas canvas, Offset c, double r, Color petal) {
    canvas.drawLine(
      c,
      c.translate(0, r * 2.2),
      Paint()
        ..color = grass.withValues(alpha: 0.8)
        ..strokeWidth = r * 0.3,
    );
    final paint = Paint()..color = petal.withValues(alpha: 0.9);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      canvas.drawCircle(
        c + Offset(math.cos(a) * r * 0.6, math.sin(a) * r * 0.6),
        r * 0.45,
        paint,
      );
    }
    canvas.drawCircle(
      c,
      r * 0.35,
      Paint()..color = star.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(LessonGridBackgroundPainter oldDelegate) => false;
}
