import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A soft side-to-side wobble that plays whenever [trigger] changes —
/// the games' calm way of saying "not that one" without any red or alarm.
class ShakeOnTrigger extends StatefulWidget {
  const ShakeOnTrigger({
    super.key,
    required this.trigger,
    required this.amplitude,
    required this.child,
  });

  final int trigger;

  /// Largest sideways offset in logical pixels.
  final double amplitude;
  final Widget child;

  @override
  State<ShakeOnTrigger> createState() => _ShakeOnTriggerState();
}

class _ShakeOnTriggerState extends State<ShakeOnTrigger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(ShakeOnTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder:
        (context, child) => Transform.translate(
          offset: Offset(
            math.sin(_controller.value * math.pi * 4) *
                (1 - _controller.value) *
                widget.amplitude,
            0,
          ),
          child: child,
        ),
    child: widget.child,
  );
}
