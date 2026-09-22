import 'package:flutter/material.dart';

import '../../../../helpers/colored_arabic_text.dart';
import '../../../../models/arabic_letter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_theme.dart';
import '../../widgets/music_note_burst.dart';
import '../../widgets/shake_on_trigger.dart';

/// A drop target that stands for one letter's sound. Tapping it plays
/// the sound; dropping the matching letter on it fills it in. A wrong
/// letter just makes the card wobble — nothing is punished.
class SoundSlot extends StatelessWidget {
  const SoundSlot({
    super.key,
    required this.letter,
    required this.size,
    required this.accent,
    required this.accentSoft,
    required this.placed,
    required this.burstTrigger,
    required this.shakeTrigger,
    required this.onTap,
    required this.onLetterDropped,
  });

  final ArabicLetter letter;
  final double size;
  final Color accent;
  final Color accentSoft;
  final bool placed;
  final int burstTrigger;
  final int shakeTrigger;
  final VoidCallback onTap;
  final ValueChanged<ArabicLetter> onLetterDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ArabicLetter>(
      onWillAcceptWithDetails: (_) => !placed,
      onAcceptWithDetails: (details) => onLetterDropped(details.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return ShakeOnTrigger(
          trigger: shakeTrigger,
          amplitude: size * 0.06,
          child: AnimatedScale(
            scale: hovering ? 1.06 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: _card(context, hovering)),
                  Positioned.fill(
                    child: MusicNoteBurst(trigger: burstTrigger, size: size),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, bool hovering) {
    return Semantics(
      button: true,
      label: 'Sesi dinle',
      child: Material(
        color: placed || hovering ? AppColors.surface : accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.18),
          side: BorderSide(
            color: accent.withValues(alpha: hovering ? 1 : 0.75),
            width: hovering ? 3.5 : 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder:
                (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.6, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
            child:
                placed
                    ? _filled(const ValueKey('filled'))
                    : _empty(context, const ValueKey('empty')),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, Key key) => Stack(
    key: key,
    alignment: Alignment.center,
    children: [
      Positioned(
        top: size * 0.08,
        right: size * 0.1,
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.17,
          color: accent.withValues(alpha: 0.5),
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volume_up_rounded, size: size * 0.36, color: accent),
          if (size >= 96)
            Text(
              'Dinle',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
        ],
      ),
    ],
  );

  Widget _filled(Key key) => Stack(
    key: key,
    alignment: Alignment.center,
    children: [
      Positioned(
        top: size * 0.07,
        right: size * 0.07,
        child: Icon(
          Icons.check_circle_rounded,
          size: size * 0.18,
          color: AppColors.sage,
        ),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: ColoredArabicText(
            letter.isolatedForm,
            textDirection: TextDirection.rtl,
            style: AppTextTheme.arabicLetter(fontSize: size * 0.56),
          ),
        ),
      ),
    ],
  );
}
