import 'package:flutter/material.dart';

/// Glides a dropped-wrong letter from where it was let go back to its
/// spot. Must sit directly inside a [Stack] (it positions itself in
/// that stack's coordinates) and reports [onDone] once it has landed.
class FlyBack extends StatefulWidget {
  const FlyBack({
    super.key,
    required this.from,
    required this.to,
    required this.child,
    required this.onDone,
    required this.startScale,
  });

  final Offset from;
  final Offset to;
  final double startScale;
  final Widget child;
  final VoidCallback onDone;

  @override
  State<FlyBack> createState() => _FlyBackState();
}

class _FlyBackState extends State<FlyBack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 340),
        )
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final t = Curves.easeOutCubic.transform(_controller.value);
      final position = Offset.lerp(widget.from, widget.to, t)!;
      final scale = 1 + (widget.startScale - 1) * (1 - t);
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: IgnorePointer(
          child: Transform.scale(scale: scale, child: child),
        ),
      );
    },
    child: widget.child,
  );
}
