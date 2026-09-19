import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Three small music notes that drift up and fade out — the game's
/// "well done" sparkle. Place it in a `Stack(clipBehavior: Clip.none)`
/// over the thing that was answered; bump [trigger] to play it once.
class MusicNoteBurst extends StatefulWidget {
  const MusicNoteBurst({super.key, required this.trigger, required this.size});

  final int trigger;
  final double size;

  @override
  State<MusicNoteBurst> createState() => _MusicNoteBurstState();
}

class _MusicNoteBurstState extends State<MusicNoteBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  static const _notes = [
    (Icons.music_note_rounded, AppColors.gold, -0.30, 0.0),
    (Icons.audiotrack_rounded, AppColors.turquoise, 0.0, 0.14),
    (Icons.music_note_rounded, AppColors.sage, 0.30, 0.28),
  ];
  static const _noteSpan = 0.62;

  @override
  void didUpdateWidget(MusicNoteBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final iconSize = (size * 0.24).clamp(20.0, 36.0);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating) return const SizedBox.shrink();
          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              for (final (icon, color, dx, delay) in _notes)
                _note(icon, color, dx, delay, size, iconSize),
            ],
          );
        },
      ),
    );
  }

  Widget _note(
    IconData icon,
    Color color,
    double dx,
    double delay,
    double size,
    double iconSize,
  ) {
    final t = ((_controller.value - delay) / _noteSpan).clamp(0.0, 1.0);
    final rise = Curves.easeOutCubic.transform(t);
    final opacity = t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8;
    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(
          dx * size + math.sin(t * math.pi * 1.5) * size * 0.04,
          -(size * 0.1 + size * 0.7 * rise),
        ),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.75 + 0.35 * rise,
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}
