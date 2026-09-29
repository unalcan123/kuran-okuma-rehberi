import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lesson_grid_background.dart';

/// A cute children's-book backdrop for the Namaz Duaları / Namaz Sureleri
/// screens: a smiling crescent moon, twinkling stars, a cloud with a face,
/// two glowing lanterns, birds, many butterflies, and along the bottom the
/// Kâbe between the green dome of Mescid-i Nebevî and a mosque with pencil
/// minarets, on green hills full of grass and flowers.
///
/// Our own drawing in shapes (no photos, no picture files, no writing or
/// Arabic letters), soft and rounded, like the home illustrations, in
/// brighter pastels. The Kâbe stands on the grass at the bottom, in the very
/// middle of the screen on every width ([HolyPlacesPainter.kaabaCenterX]);
/// birds, butterflies and clouds spread down both sides and across the
/// middle. Lists keep [HolyPlacesPainter.sceneHeightFor] of room at their
/// end so the scene can be seen. Purely ornamental: never takes touches.
/// Use it as the first child of a [Stack].
class HolyPlacesBackground extends StatelessWidget {
  const HolyPlacesBackground({super.key, this.contentWidth});

  /// How wide the page's content (cards) gets: side decorations go in the
  /// empty margins beside it when there are any.
  final double? contentWidth;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('holy-places-background'),
            painter: HolyPlacesPainter(contentWidth: contentWidth),
          ),
        ),
      ),
    );
  }
}

class HolyPlacesPainter extends LessonGridBackgroundPainter {
  const HolyPlacesPainter({this.contentWidth});

  /// See [HolyPlacesBackground.contentWidth].
  final double? contentWidth;

  static const Color skyTop = Color(0xFFDDEFFB);
  static const Color moon = Color(0xFFFFE08A);
  static const Color cheek = Color(0xFFF8B4C4);
  static const Color gold = Color(0xFFF1C75B);
  static const Color kaaba = Color(0xFF3D3B4A);
  static const Color cream = Color(0xFFF8EBCF);
  static const Color creamDark = Color(0xFFE9D3A8);
  static const Color greenDome = Color(0xFF4DBB7A);
  static const Color blueDome = Color(0xFF8FB4E3);
  static const Color blueWall = Color(0xFFD4E2F4);
  static const Color teal = Color(0xFF5CC1B5);

  /// Brighter pastel tones than the lesson grid's (still soft, not neon).
  static const Color skyBright = Color(0xFFBDE3FA);
  static const Color skyLight = Color(0xFFE2F3FC);
  static const Color meadowLight = Color(0xFFEAF7E1);
  static const Color hillBackBright = Color(0xFFB2E09A);
  static const Color hillFrontBright = Color(0xFF8FD17A);
  static const List<Color> flowerColors = [
    Color(0xFFF48FB1), // pink
    Color(0xFFFFD54F), // yellow
    Color(0xFFFFFFFF), // white
    Color(0xFFB39DDB), // lilac
    Color(0xFFFFB74D), // orange
  ];
  static const List<Color> butterflyColors = [
    Color(0xFFF7A8C8),
    Color(0xFFFFCC80),
    Color(0xFFB3A6F0),
    Color(0xFF8ED1F2),
    Color(0xFFA5DE8F),
  ];

  /// How far up from the bottom the grassy hills reach on a [size] screen.
  static double groundHeightFor(Size size) =>
      math.min(size.height * 0.2, 170.0);

  /// Width of the Kâbe on a [size] screen.
  static double kaabaWidthFor(Size size) =>
      (size.width * 0.14).clamp(60.0, 128.0).toDouble();

  /// Height of the bottom scene (the hills with the Kâbe and the mosques):
  /// a list keeps this much room at its end so, scrolled to the end, the
  /// scene is seen.
  static double sceneHeightFor(Size size) =>
      groundHeightFor(size) * 0.5 + kaabaWidthFor(size) * 1.25;

  /// X of the Kâbe's center: always the middle of the screen, the same
  /// distance from the left and the right edge.
  static double kaabaCenterX(Size size) => size.width / 2;

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
          colors: [skyBright, skyLight, meadowLight],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    final unit = (math.min(w, h) / 600).clamp(0.55, 1.2).toDouble();
    // Side decorations sit in the margins beside the content when there
    // are any, else near the edges.
    final content = contentWidth;
    final margin = content == null ? 0.0 : math.max(0.0, (w - content) / 2);
    final sideL = margin > 60 * unit ? margin / 2 : w * 0.05;
    final sideR = w - sideL;

    // Top: lanterns on the left, a smiling moon on the right, stars, clouds
    // and a few birds.
    drawLantern(canvas, Offset(w * 0.04, 0), 70 * unit, 16 * unit, gold);
    drawLantern(canvas, Offset(w * 0.085, 0), 44 * unit, 13 * unit, teal);
    drawMoon(canvas, Offset(w - 58 * unit, 62 * unit), 30 * unit);
    const stars = <(double, double, double)>[
      (0.16, 0.08, 1.0),
      (0.83, 0.20, 0.8),
      (0.40, 0.04, 0.6),
      (0.62, 0.07, 0.7),
    ];
    for (final (x, y, s) in stars) {
      drawStar(canvas, Offset(x * w, y * h), 8 * unit * s);
    }
    drawCloud(canvas, Offset(w * 0.24, 40 * unit), 44 * unit);
    drawCloud(canvas, Offset(w * 0.72, 30 * unit), 36 * unit);
    drawCloudFace(canvas, Offset(sideL, h * 0.36), 40 * unit);
    drawCloud(canvas, Offset(sideR, h * 0.44), 38 * unit);
    const birds = <(double, double, double)>[
      (0.33, 0.12, 1.0),
      (0.58, 0.16, 0.8),
      (0.47, 0.09, 0.7),
    ];
    for (final (x, y, s) in birds) {
      drawBird(canvas, Offset(x * w, y * h), 11 * unit * s, x > 0.5);
    }

    // The middle of the page: butterflies (and a bird) down both sides and
    // across, so no wide empty band is left.
    final flutter = <(double, double, double)>[
      (sideL, 0.26, 0.2),
      (sideR, 0.3, -0.3),
      (sideL + 26 * unit, 0.52, -0.2),
      (sideR - 20 * unit, 0.6, 0.25),
      (sideL, 0.7, 0.3),
      (sideR, 0.76, -0.15),
      (w * 0.36, 0.48, 0.15),
      (w * 0.66, 0.4, -0.25),
      (w * 0.5, 0.64, 0.1),
    ];
    for (var i = 0; i < flutter.length; i++) {
      final (x, y, tilt) = flutter[i];
      drawButterfly(
        canvas,
        Offset(x, y * h),
        (i < 6 ? 15 : 12) * unit,
        butterflyColors[i % butterflyColors.length],
        tilt: tilt,
      );
    }
    drawBird(canvas, Offset(sideR, h * 0.18), 12 * unit, true);

    // Bottom: grassy hills with the Kâbe in the very middle, Mescid-i
    // Nebevî on its left and a mosque on its right, trees at the edges.
    final ground = groundHeightFor(size);
    drawHill(canvas, size, ground, hillBackBright, phase: 0.3);
    final k = kaabaWidthFor(size);
    final cx = kaabaCenterX(size);
    final base = h - ground * 0.5;
    // Neighbours as far out as fits (never off screen, never on the Kâbe).
    final spread = math.min(k * 2.4, w * 0.3);
    final d = k * 0.72;
    drawTree(canvas, Offset(w * 0.035, base + 6 * unit), 34 * unit);
    drawTree(canvas, Offset(w * 0.965, base + 6 * unit), 34 * unit);
    drawNebevi(canvas, Offset(cx - spread, base), d);
    drawMosque(canvas, Offset(cx + spread, base), d);
    drawKaaba(canvas, Offset(cx, base), k);
    drawHill(canvas, size, ground * 0.5, hillFrontBright, phase: 0.7);

    // Grass tufts and flowers all along the front; the Kâbe's front is
    // kept clear.
    final front = h - ground * 0.14;
    final step = 26 * unit;
    var i = 0;
    for (var x = step / 2; x < w; x += step, i++) {
      if ((x - cx).abs() < k * 0.6) continue;
      drawGrass(
        canvas,
        Offset(x, front + (i.isEven ? 4 : 10) * unit),
        9 * unit,
      );
      if (i.isOdd) {
        drawFlower(
          canvas,
          Offset(x + 6 * unit, front - (i % 4 == 1 ? 2 : 10) * unit),
          6.5 * unit,
          flowerColors[i % flowerColors.length],
        );
      }
    }
    // Butterflies over the meadow, beside the Kâbe.
    drawButterfly(
      canvas,
      Offset(cx - k * 1.1, h - ground * 0.95),
      13 * unit,
      butterflyColors[0],
      tilt: -0.2,
    );
    drawButterfly(
      canvas,
      Offset(cx + k * 1.15, h - ground * 1.05),
      12 * unit,
      butterflyColors[2],
      tilt: 0.25,
    );
  }

  /// A round little bird with a wing, a beak and an eye, flying left or
  /// ([facingRight]) right; [r] is about its body radius.
  @protected
  void drawBird(Canvas canvas, Offset c, double r, bool facingRight) {
    final dir = facingRight ? 1.0 : -1.0;
    const body = Color(0xFF7FC4E8);
    canvas
      ..drawOval(
        Rect.fromCenter(center: c, width: r * 2.2, height: r * 1.6),
        Paint()..color = body.withValues(alpha: 0.9),
      )
      ..drawCircle(
        c.translate(dir * r * 0.95, -r * 0.45),
        r * 0.62,
        Paint()..color = body.withValues(alpha: 0.95),
      )
      ..drawPath(
        Path()
          ..moveTo(c.dx + dir * r * 1.5, c.dy - r * 0.55)
          ..lineTo(c.dx + dir * r * 1.95, c.dy - r * 0.4)
          ..lineTo(c.dx + dir * r * 1.5, c.dy - r * 0.25)
          ..close(),
        Paint()..color = const Color(0xFFFFB74D),
      )
      ..drawCircle(
        c.translate(dir * r * 1.1, -r * 0.55),
        r * 0.1,
        Paint()..color = LessonGridBackgroundPainter.ink,
      )
      // Wing, lifted.
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(-dir * r * 0.2, -r * 0.55),
          width: r * 1.2,
          height: r * 0.75,
        ),
        Paint()..color = const Color(0xFFB9E1F5),
      );
  }

  /// A hanging lantern: string of [drop] from [top], body [r] wide, soft glow.
  @protected
  void drawLantern(Canvas canvas, Offset top, double drop, double r, Color c) {
    final string =
        Paint()
          ..color = LessonGridBackgroundPainter.ink.withValues(alpha: 0.35)
          ..strokeWidth = 1.2;
    final body = top.translate(0, drop);
    canvas
      ..drawLine(top, body.translate(0, -r * 0.9), string)
      ..drawCircle(
        body,
        r * 1.6,
        Paint()
          ..shader = RadialGradient(
            colors: [gold.withValues(alpha: 0.35), gold.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: body, radius: r * 1.6)),
      );
    final paint = Paint()..color = c.withValues(alpha: 0.9);
    // Cap and bottom.
    canvas
      ..drawPath(
        Path()
          ..moveTo(body.dx - r * 0.55, body.dy - r * 0.55)
          ..lineTo(body.dx, body.dy - r * 1.0)
          ..lineTo(body.dx + r * 0.55, body.dy - r * 0.55)
          ..close(),
        paint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: body, width: r * 0.9, height: r * 1.1),
          Radius.circular(r * 0.3),
        ),
        paint,
      )
      // Warm window.
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: body, width: r * 0.45, height: r * 0.65),
          Radius.circular(r * 0.2),
        ),
        Paint()..color = const Color(0xFFFFF4C9),
      )
      ..drawRect(
        Rect.fromCenter(
          center: body.translate(0, r * 0.62),
          width: r * 0.6,
          height: r * 0.16,
        ),
        paint,
      );
  }

  /// A smiling crescent moon with a rosy cheek.
  @protected
  void drawMoon(Canvas canvas, Offset c, double r) {
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(
        Rect.fromCircle(center: c.translate(r * 0.55, -r * 0.3), radius: r),
      ),
    );
    canvas.drawPath(crescent, Paint()..color = moon.withValues(alpha: 0.95));
    final face = c.translate(-r * 0.5, r * 0.2);
    final ink =
        Paint()..color = LessonGridBackgroundPainter.ink.withValues(alpha: 0.8);
    canvas
      ..drawCircle(face.translate(0, -r * 0.18), r * 0.07, ink)
      ..drawArc(
        Rect.fromCircle(
          center: face.translate(r * 0.02, r * 0.02),
          radius: r * 0.14,
        ),
        0.3,
        2.2,
        false,
        Paint()
          ..color = LessonGridBackgroundPainter.ink.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(
        face.translate(-r * 0.12, r * 0.12),
        r * 0.1,
        Paint()..color = cheek.withValues(alpha: 0.7),
      );
  }

  /// A cloud with sleepy eyes and a smile.
  @protected
  void drawCloudFace(Canvas canvas, Offset c, double r) {
    drawCloud(canvas, c, r);
    final eye =
        Paint()
          ..color = LessonGridBackgroundPainter.ink.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..strokeCap = StrokeCap.round;
    final mid = c.translate(r * 0.05, r * 0.15);
    for (final dx in [-0.25, 0.25]) {
      canvas.drawArc(
        Rect.fromCircle(
          center: mid.translate(dx * r, -r * 0.08),
          radius: r * 0.08,
        ),
        0.2,
        2.7,
        false,
        eye,
      );
    }
    canvas
      ..drawArc(
        Rect.fromCircle(center: mid.translate(0, r * 0.06), radius: r * 0.1),
        0.4,
        2.3,
        false,
        eye,
      )
      ..drawCircle(
        mid.translate(-r * 0.42, r * 0.08),
        r * 0.07,
        Paint()..color = cheek.withValues(alpha: 0.6),
      )
      ..drawCircle(
        mid.translate(r * 0.42, r * 0.08),
        r * 0.07,
        Paint()..color = cheek.withValues(alpha: 0.6),
      );
  }

  /// A little Kâbe standing on [base] (bottom center), [k] wide: a soft dark
  /// cube with a golden band and a golden door, in rounded toy shapes.
  @protected
  void drawKaaba(Canvas canvas, Offset base, double k) {
    final box = Rect.fromLTWH(base.dx - k / 2, base.dy - k * 0.92, k, k * 0.92);
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: base.translate(0, k * 0.02),
          width: k * 1.4,
          height: k * 0.16,
        ),
        Paint()
          ..color = LessonGridBackgroundPainter.ink.withValues(alpha: 0.12),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(k * 0.1)),
        Paint()..color = kaaba.withValues(alpha: 0.92),
      )
      // Side face in a lighter tone, for a little depth.
      ..drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(box.right - k * 0.28, box.top, k * 0.28, box.height),
          topRight: Radius.circular(k * 0.1),
          bottomRight: Radius.circular(k * 0.1),
        ),
        Paint()..color = const Color(0xFF55536A).withValues(alpha: 0.9),
      )
      ..drawRect(
        Rect.fromLTWH(box.left, box.top + k * 0.2, box.width, k * 0.1),
        Paint()..color = gold.withValues(alpha: 0.95),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            box.left + k * 0.2,
            box.bottom - k * 0.42,
            k * 0.2,
            k * 0.34,
          ),
          Radius.circular(k * 0.05),
        ),
        Paint()..color = gold.withValues(alpha: 0.95),
      );
  }

  /// The green-domed Mescid-i Nebevî as a toy: cream building with arches,
  /// a round green dome and one slim minaret with a green tip.
  @protected
  void drawNebevi(Canvas canvas, Offset base, double d) {
    final wall = Paint()..color = cream;
    final trim = Paint()..color = creamDark;
    final green = Paint()..color = greenDome;
    final body = Rect.fromLTWH(
      base.dx - d * 0.8,
      base.dy - d * 0.6,
      d * 1.6,
      d * 0.6,
    );
    // Minaret (behind, left).
    _minaret(
      canvas,
      Offset(base.dx - d * 0.62, base.dy),
      d * 1.55,
      d * 0.16,
      wall,
      trim,
      green,
    );
    // Dome first: the building hides its lower half.
    canvas
      ..drawCircle(Offset(base.dx + d * 0.1, body.top), d * 0.42, green)
      ..drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(d * 0.06)),
        wall,
      )
      ..drawRect(
        Rect.fromLTWH(body.left, body.top - d * 0.02, body.width, d * 0.08),
        trim,
      );
    _finial(canvas, Offset(base.dx + d * 0.1, body.top - d * 0.42), d * 0.12);
    for (var i = 0; i < 4; i++) {
      final x = body.left + d * 0.22 + i * d * 0.38;
      _arch(canvas, Offset(x, body.bottom), d * 0.2, d * 0.3, trim);
    }
  }

  /// A mosque with a big blue dome, two small ones and two pencil minarets.
  @protected
  void drawMosque(Canvas canvas, Offset base, double d) {
    final wall = Paint()..color = blueWall;
    final dome = Paint()..color = blueDome;
    final trim =
        Paint()..color = const Color(0xFFB7CBE6).withValues(alpha: 0.95);
    _minaret(
      canvas,
      Offset(base.dx - d * 0.95, base.dy),
      d * 1.7,
      d * 0.14,
      wall,
      trim,
      dome,
    );
    _minaret(
      canvas,
      Offset(base.dx + d * 0.95, base.dy),
      d * 1.7,
      d * 0.14,
      wall,
      trim,
      dome,
    );
    final body = Rect.fromLTWH(
      base.dx - d * 0.75,
      base.dy - d * 0.55,
      d * 1.5,
      d * 0.55,
    );
    canvas
      ..drawCircle(Offset(base.dx - d * 0.48, body.top), d * 0.2, dome)
      ..drawCircle(Offset(base.dx + d * 0.48, body.top), d * 0.2, dome)
      ..drawCircle(Offset(base.dx, body.top), d * 0.45, dome)
      ..drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(d * 0.06)),
        wall,
      );
    _finial(canvas, Offset(base.dx, body.top - d * 0.45), d * 0.12);
    for (final dx in [-0.45, 0.0, 0.45]) {
      _arch(
        canvas,
        Offset(base.dx + dx * d, body.bottom),
        d * 0.22,
        d * 0.32,
        trim,
      );
    }
  }

  void _minaret(
    Canvas canvas,
    Offset base,
    double height,
    double width,
    Paint wall,
    Paint trim,
    Paint tip,
  ) {
    final shaft = Rect.fromLTWH(
      base.dx - width / 2,
      base.dy - height,
      width,
      height,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(shaft, Radius.circular(width * 0.3)),
        wall,
      )
      // Balcony.
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(base.dx, shaft.top + height * 0.28),
            width: width * 1.7,
            height: width * 0.35,
          ),
          Radius.circular(width * 0.15),
        ),
        trim,
      )
      // Pencil tip.
      ..drawPath(
        Path()
          ..moveTo(shaft.left - width * 0.1, shaft.top + width * 0.1)
          ..lineTo(base.dx, shaft.top - width * 1.6)
          ..lineTo(shaft.right + width * 0.1, shaft.top + width * 0.1)
          ..close(),
        tip,
      );
    _finial(canvas, Offset(base.dx, shaft.top - width * 1.6), width * 0.6);
  }

  /// A tiny golden crescent on a pole, on top of a dome or a minaret.
  void _finial(Canvas canvas, Offset top, double r) {
    final paint = Paint()..color = gold.withValues(alpha: 0.95);
    canvas.drawRect(
      Rect.fromCenter(
        center: top.translate(0, -r * 0.5),
        width: r * 0.18,
        height: r,
      ),
      paint,
    );
    final c = top.translate(0, -r * 1.25);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.4)),
        Path()..addOval(
          Rect.fromCircle(
            center: c.translate(r * 0.2, -r * 0.1),
            radius: r * 0.36,
          ),
        ),
      ),
      paint,
    );
  }

  /// A rounded doorway / window standing on [bottom].
  void _arch(
    Canvas canvas,
    Offset bottom,
    double width,
    double height,
    Paint p,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(bottom.dx - width / 2, bottom.dy - height, width, height),
        topLeft: Radius.circular(width / 2),
        topRight: Radius.circular(width / 2),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant HolyPlacesPainter oldDelegate) =>
      oldDelegate.contentWidth != contentWidth;
}
