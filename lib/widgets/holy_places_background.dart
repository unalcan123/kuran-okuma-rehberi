import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'lesson_grid_background.dart';

/// A cute children's-book backdrop for the Namaz Duaları / Namaz Sureleri
/// screens: a smiling crescent moon, twinkling stars, a cloud with a face,
/// two glowing lanterns, and along the bottom a little Kâbe, the green dome
/// of Mescid-i Nebevî and a mosque with pencil minarets on green hills with
/// flowers and a butterfly.
///
/// Our own drawing in shapes (no photos, no picture files, no writing or
/// Arabic letters), soft and rounded, like the home illustrations. The holy
/// places stand at the left and right edges, so the (opaque) cards in the
/// middle stay on a calm sky. Purely ornamental: never takes touches. Use it
/// as the first child of a [Stack].
class HolyPlacesBackground extends StatelessWidget {
  const HolyPlacesBackground({super.key, this.contentWidth});

  /// How wide the page's content (cards) gets: the holy places are sized to
  /// fit the empty margins beside it. Null: they use their normal size.
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

  /// Width of each group of buildings at scale 1 (left: Nebevî + Kâbe).
  static const double groupWidth = 200;

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
            skyTop,
            LessonGridBackgroundPainter.skyMiddle,
            AppColors.background,
          ],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    final unit = (math.min(w, h) / 600).clamp(0.55, 1.2).toDouble();

    // Top: lanterns on the left, a smiling moon on the right, stars.
    drawLantern(canvas, Offset(w * 0.04, 0), 70 * unit, 16 * unit, gold);
    drawLantern(canvas, Offset(w * 0.085, 0), 44 * unit, 13 * unit, teal);
    drawMoon(canvas, Offset(w - 58 * unit, 62 * unit), 30 * unit);
    const stars = <(double, double, double)>[
      (0.16, 0.08, 1.0),
      (0.83, 0.20, 0.8),
      (0.05, 0.30, 0.8),
      (0.95, 0.33, 1.0),
      (0.40, 0.04, 0.6),
      (0.62, 0.07, 0.7),
      (0.10, 0.52, 0.6),
      (0.91, 0.55, 0.7),
    ];
    for (final (x, y, s) in stars) {
      drawStar(canvas, Offset(x * w, y * h), 8 * unit * s);
    }
    drawCloud(canvas, Offset(w * 0.24, 40 * unit), 44 * unit);
    drawCloud(canvas, Offset(w * 0.93, h * 0.44), 40 * unit);
    drawCloudFace(canvas, Offset(w * 0.03, h * 0.42), 42 * unit);

    // Bottom: hills, then the holy places at the edges.
    final hillHeight = math.min(h * 0.13, 120.0);
    drawHill(
      canvas,
      size,
      hillHeight,
      LessonGridBackgroundPainter.hillBack,
      phase: 0.3,
    );
    final ground = h - hillHeight * 0.45;
    // Buildings fit the margin beside the content when there is one
    // (never smaller than 0.5, never bigger than 1.3 of their size).
    final content = contentWidth;
    final margin = content == null ? null : (w - content) / 2;
    final s =
        margin == null
            ? 1.3 * unit
            : (margin / (groupWidth * 1.05)).clamp(0.5, 1.3).toDouble();
    drawNebevi(canvas, Offset(6 + 70 * s, ground), 62 * s);
    drawKaaba(canvas, Offset(6 + 172 * s, ground - 2 * s), 46 * s);
    drawMosque(canvas, Offset(w - 6 - 80 * s, ground), 64 * s);
    drawHill(
      canvas,
      size,
      hillHeight * 0.55,
      LessonGridBackgroundPainter.hillFront,
      phase: 0.7,
    );

    // Flowers, grass and a butterfly in the corners.
    final front = h - hillHeight * 0.16;
    for (final x in [0.03, 0.09, 0.15, 0.85, 0.91, 0.97]) {
      drawGrass(canvas, Offset(x * w, front + 4 * unit), 9 * unit);
    }
    const flowers = <double>[0.06, 0.12, 0.18, 0.82, 0.88, 0.94];
    for (var i = 0; i < flowers.length; i++) {
      drawFlower(
        canvas,
        Offset(flowers[i] * w, front - (i.isEven ? 0 : 6) * unit),
        6.5 * unit,
        LessonGridBackgroundPainter.petals[i %
            LessonGridBackgroundPainter.petals.length],
      );
    }
    drawButterfly(
      canvas,
      Offset(w * 0.90, h * 0.58),
      15 * unit,
      const Color(0xFFF7A8C8),
      tilt: 0.25,
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
