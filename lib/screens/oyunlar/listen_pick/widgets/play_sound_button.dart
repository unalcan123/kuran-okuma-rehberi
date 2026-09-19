import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// The big round "listen" button. While its sound is playing a soft
/// ring pulses around it so the child can tell something is sounding.
class PlaySoundButton extends StatefulWidget {
  const PlaySoundButton({
    super.key,
    required this.size,
    required this.playing,
    required this.onTap,
  });

  final double size;
  final bool playing;
  final VoidCallback onTap;

  @override
  State<PlaySoundButton> createState() => _PlaySoundButtonState();
}

class _PlaySoundButtonState extends State<PlaySoundButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _pulse.repeat();
  }

  @override
  void didUpdateWidget(PlaySoundButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing == oldWidget.playing) return;
    if (widget.playing) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      button: true,
      label: 'Sesi dinle',
      child: SizedBox(
        width: size * 1.5,
        height: size * 1.5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Opacity(
                  opacity: widget.playing ? (1 - t) * 0.45 : 0,
                  child: Container(
                    width: size * (1 + 0.45 * t),
                    height: size * (1 + 0.45 * t),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.turquoise,
                    ),
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.turquoise,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.turquoise.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onTap,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: size * 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
