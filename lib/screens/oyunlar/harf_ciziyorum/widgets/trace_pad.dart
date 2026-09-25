import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../ciz_models.dart';

enum PadInput { none, draw, dots }

/// Harf çizim alanı. Harf kutusu, alanın içine sığan en büyük kare; bütün
/// koordinatlar bu kutuya göre 0–1 (model ile aynı). Ekran dönse, boyut
/// değişse ya da piksel yoğunluğu farklı olsa da çizim ve hedef aynı yerde
/// kalır.
///
/// Giriş: dokunma, fare ve kalem (hepsi işaretçi olayı). Yalnızca ilk parmak
/// çizer; ikinci parmak yok sayılır. Alanın içinde başlayan hareket sayfayı
/// kaydırmaz (EagerGestureRecognizer); sayfanın geri kalanı etkilenmez.
/// Parmak alandan çıkarsa çizgi devam eder, bırakınca/iptal olunca biter.
class TracePad extends StatefulWidget {
  const TracePad({
    super.key,
    required this.model,
    required this.strokes,
    required this.dots,
    this.input = PadInput.none,
    this.guideOpacity = 0.25,
    this.showPathHints = false,
    this.dotTargetOpacity = 0,
    this.showModelDots = false,
    this.missing = const [],
    this.animationProgress,
    this.onStrokeEnd,
    this.onDotTap,
  });

  final LetterTraceModel model;

  /// Tamamlanmış çizgiler (normalleştirilmiş).
  final List<List<Offset>> strokes;

  /// Konulmuş noktalar.
  final List<Offset> dots;
  final PadInput input;

  /// Kılavuz harfin görünürlüğü (0 = kılavuzsuz, 1 = tam harf).
  final double guideOpacity;

  /// Başlangıç noktası, sıra numarası ve yön okları ("bir yol").
  final bool showPathHints;

  /// Nokta hedeflerinin görünürlüğü (0 = gizli).
  final double dotTargetOpacity;

  /// Modelin noktalarını dolu çiz (izle aşaması, karşılaştırma).
  final bool showModelDots;

  /// "Buraya da devam et" diye vurgulanan eksik parçalar.
  final List<List<Offset>> missing;

  /// Nasıl çizilir animasyonu: 0–1 gövde, 1–2 noktalar. `null` = yok.
  final double? animationProgress;

  final ValueChanged<List<Offset>>? onStrokeEnd;
  final ValueChanged<Offset>? onDotTap;

  @override
  State<TracePad> createState() => _TracePadState();
}

class _TracePadState extends State<TracePad> {
  final _repaint = ValueNotifier<int>(0);
  List<Offset>? _current;
  int? _pointer;
  Offset? _downAt;
  Rect _box = Rect.zero;

  /// Parmak bırakıldığında noktanın "dokunma" sayılması için en çok kayma.
  static const double _tapSlop = 0.04;

  @override
  void dispose() {
    _repaint.dispose();
    super.dispose();
  }

  Offset _norm(Offset local) =>
      _box.width == 0 ? Offset.zero : (local - _box.topLeft) / _box.width;

  void _down(PointerDownEvent e) {
    if (_pointer != null || widget.input == PadInput.none) return;
    if (e.kind == PointerDeviceKind.mouse && e.buttons != kPrimaryButton) {
      return; // farenin sağ/orta tuşu çizmez
    }
    _pointer = e.pointer;
    final p = _norm(e.localPosition);
    _downAt = p;
    if (widget.input == PadInput.draw) {
      _current = [p];
      _repaint.value++;
    }
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer || _current == null) return;
    final p = _norm(e.localPosition);
    // Titreme kırıntılarını at (kutunun %0,3'ünden kısa adımlar).
    if ((p - _current!.last).distance < 0.003) return;
    _current!.add(p);
    _repaint.value++;
  }

  void _up(PointerEvent e, {required bool cancelled}) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    final p = _norm(e.localPosition);
    if (widget.input == PadInput.draw) {
      final stroke = _current;
      _current = null;
      _repaint.value++;
      if (stroke != null && stroke.isNotEmpty) widget.onStrokeEnd?.call(stroke);
    } else if (widget.input == PadInput.dots && !cancelled) {
      final start = _downAt ?? p;
      if ((p - start).distance <= _tapSlop) widget.onDotTap?.call(p);
    }
    _downAt = null;
  }

  @override
  void didUpdateWidget(TracePad old) {
    super.didUpdateWidget(old);
    if (old.input != widget.input) {
      _pointer = null;
      _current = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = math.min(constraints.maxWidth, constraints.maxHeight);
      _box = Rect.fromLTWH(
        (constraints.maxWidth - side) / 2,
        (constraints.maxHeight - side) / 2,
        side,
        side,
      );
      final pad = CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _PadPainter(
          box: _box,
          widget: widget,
          current: () => _current,
          repaint: _repaint,
        ),
      );
      if (widget.input == PadInput.none) return pad;
      return RawGestureDetector(
        gestures: {
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (_) {},
              ),
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: (e) => _up(e, cancelled: false),
          onPointerCancel: (e) => _up(e, cancelled: true),
          child: pad,
        ),
      );
    },
  );
}

class _PadPainter extends CustomPainter {
  _PadPainter({
    required this.box,
    required this.widget,
    required this.current,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Rect box;
  final TracePad widget;
  final List<Offset>? Function() current;

  double get side => box.width;
  Offset _px(Offset n) => box.topLeft + n * side;

  Path _smooth(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    final p = [for (final q in pts) _px(q)];
    path.moveTo(p.first.dx, p.first.dy);
    if (p.length == 1) {
      path.lineTo(p.first.dx + 0.01, p.first.dy);
      return path;
    }
    for (var i = 1; i < p.length - 1; i++) {
      final mid = Offset.lerp(p[i], p[i + 1], 0.5)!;
      path.quadraticBezierTo(p[i].dx, p[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(p.last.dx, p.last.dy);
    return path;
  }

  Paint _pen(Color color, double width) =>
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final model = widget.model;
    // Kağıt
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(side * 0.06)),
      Paint()..color = AppColors.surface,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(side * 0.06)),
      _pen(AppColors.divider, 2),
    );

    final guideWidth = math.max(10.0, model.penWidth * side * 1.35);

    // Kılavuz (modelin merkez çizgisi, glif kalınlığında)
    if (widget.guideOpacity > 0) {
      final pen = _pen(
        AppColors.navy.withValues(alpha: widget.guideOpacity),
        guideWidth,
      );
      for (final s in model.strokes) {
        canvas.drawPath(_smooth(s.points), pen);
      }
    }

    // Eksik parçalar
    for (final m in widget.missing) {
      canvas.drawPath(
        _smooth(m),
        _pen(AppColors.gold.withValues(alpha: 0.55), guideWidth * 1.15),
      );
    }

    // Nokta hedefleri: birbirine yakın noktalarda (ث ش) daireler üst üste
    // binmesin diye yarıçap en yakın komşunun yarısını geçmez.
    if (widget.dotTargetOpacity > 0) {
      for (final d in model.dots) {
        var r = math.max(d.size * side * 0.6, side * 0.03);
        for (final o in model.dots) {
          if (identical(o, d)) continue;
          r = math.min(r, (o.center - d.center).distance * side * 0.48);
        }
        canvas.drawCircle(
          _px(d.center),
          r,
          Paint()
            ..color = AppColors.gold.withValues(
              alpha: widget.dotTargetOpacity * 0.35,
            ),
        );
        canvas.drawCircle(
          _px(d.center),
          r,
          _pen(AppColors.gold.withValues(alpha: widget.dotTargetOpacity), 2.5),
        );
      }
    }
    if (widget.showModelDots) {
      for (final d in model.dots) {
        canvas.drawCircle(
          _px(d.center),
          math.max(d.size * side * 0.5, 5),
          Paint()
            ..color = AppColors.navy.withValues(
              alpha: math.max(0.35, widget.guideOpacity),
            ),
        );
      }
    }

    // Çocuğun izi
    final inkPen = _pen(AppColors.turquoise, math.max(8.0, side * 0.045));
    for (final s in widget.strokes) {
      canvas.drawPath(_smooth(s), inkPen);
    }
    final cur = current();
    if (cur != null) canvas.drawPath(_smooth(cur), inkPen);

    // Konulmuş noktalar
    for (final d in widget.dots) {
      canvas.drawCircle(
        _px(d),
        math.max(7.0, side * 0.032),
        Paint()..color = AppColors.navy,
      );
    }

    if (widget.showPathHints) _paintHints(canvas);
    final anim = widget.animationProgress;
    if (anim != null) _paintAnimation(canvas, anim, guideWidth);
  }

  void _paintHints(Canvas canvas) {
    final model = widget.model;
    final multi = model.strokes.length > 1;
    for (var k = 0; k < model.strokes.length; k++) {
      final pts = model.strokes[k].points;
      _chevrons(canvas, pts, AppColors.navySoft.withValues(alpha: 0.8));
      _startMarker(canvas, pts.first, multi ? '${k + 1}' : null);
    }
  }

  void _startMarker(Canvas canvas, Offset n, String? label) {
    final c = _px(n);
    final r = math.max(11.0, side * 0.035);
    canvas.drawCircle(c, r, Paint()..color = AppColors.sage);
    canvas.drawCircle(c, r, _pen(Colors.white, 2));
    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: r * 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
  }

  /// Yol boyunca küçük yön okları (önerilen yön).
  void _chevrons(Canvas canvas, List<Offset> pts, Color color) {
    final samples = resamplePolyline(pts, 0.005);
    if (samples.length < 3) return;
    final every = math.max(1, (0.13 / 0.005).round());
    final pen = _pen(color, math.max(2.5, side * 0.009));
    final len = math.max(7.0, side * 0.025);
    for (var i = every ~/ 2; i < samples.length - 1; i += every) {
      final a = _px(samples[i]);
      final b = _px(samples[math.min(samples.length - 1, i + 2)]);
      final ang = math.atan2(b.dy - a.dy, b.dx - a.dx);
      for (final da in const [2.5, -2.5]) {
        canvas.drawLine(
          a,
          a + Offset(math.cos(ang + da), math.sin(ang + da)) * len,
          pen,
        );
      }
    }
  }

  void _paintAnimation(Canvas canvas, double t, double width) {
    final model = widget.model;
    final pen = _pen(AppColors.turquoise.withValues(alpha: 0.85), width);
    final total = model.length;
    var budget = t.clamp(0.0, 1.0) * total;
    Offset? tip;
    var tipAngle = 0.0;
    for (var k = 0; k < model.strokes.length; k++) {
      final pts = model.strokes[k].points;
      _startMarker(
        canvas,
        pts.first,
        model.strokes.length > 1 ? '${k + 1}' : null,
      );
      if (budget <= 0) continue;
      final samples = resamplePolyline(pts, 0.004);
      final take = math.min(samples.length, (budget / 0.004).floor() + 1);
      budget -= model.strokes[k].length;
      if (take < 2) continue;
      final part = samples.sublist(0, take);
      canvas.drawPath(_smooth(part), pen);
      if (budget < 0) {
        tip = part.last;
        final prev = part[math.max(0, part.length - 3)];
        tipAngle = math.atan2(tip.dy - prev.dy, tip.dx - prev.dx);
      }
    }
    if (tip != null) {
      final c = _px(tip);
      final len = math.max(14.0, side * 0.05);
      final head = _pen(AppColors.gold, math.max(4.0, side * 0.014));
      for (final da in const [2.6, -2.6]) {
        canvas.drawLine(
          c,
          c + Offset(math.cos(tipAngle + da), math.sin(tipAngle + da)) * len,
          head,
        );
      }
    }
    // Noktalar gövdeden sonra, ayrı aşamada tek tek belirir.
    if (t > 1 && model.hasDots) {
      final shown = ((t - 1).clamp(0.0, 1.0) * model.dots.length).ceil();
      for (var i = 0; i < shown && i < model.dots.length; i++) {
        final d = model.dots[i];
        canvas.drawCircle(
          _px(d.center),
          math.max(d.size * side * 0.55, 6),
          Paint()..color = AppColors.turquoise,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PadPainter old) => true;
}
