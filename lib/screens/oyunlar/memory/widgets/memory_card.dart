import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../helpers/colored_arabic_text.dart';
import '../../../../models/arabic_letter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_theme.dart';
import '../../widgets/music_note_burst.dart';
import '../../widgets/shake_on_trigger.dart';

/// One card of the memory game. Face down it shows a music-note back;
/// turned over (or found) it shows the letter, and a found card also
/// says the letter's name. It turns like a real card.
class MemoryCard extends StatelessWidget {
  const MemoryCard({
    super.key,
    required this.letter,
    required this.size,
    required this.faceUp,
    required this.matched,
    required this.burstTrigger,
    required this.shakeTrigger,
    required this.onTap,
  });

  final ArabicLetter letter;
  final double size;
  final bool faceUp;

  /// Its pair has been found: stays open, drawn calm and green.
  final bool matched;
  final int burstTrigger;
  final int shakeTrigger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = faceUp || matched;
    return Semantics(
      button: true,
      label: open ? 'Açık kart' : 'Kapalı kart',
      child: ShakeOnTrigger(
        trigger: shakeTrigger,
        amplitude: size * 0.06,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: open ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  builder: (context, turn, _) {
                    final showFront = turn > 0.5;
                    return Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(turn * math.pi),
                      // The front is drawn mirrored by the turn; flip it back.
                      child:
                          showFront
                              ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: _front(context),
                              )
                              : _back(),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: MusicNoteBurst(trigger: burstTrigger, size: size),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _back() => Material(
    color: AppColors.turquoise,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(size * 0.18),
      side: BorderSide(color: AppColors.navy.withValues(alpha: 0.18), width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.46,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    ),
  );

  Widget _front(BuildContext context) {
    final showName = matched && size >= 72 && letter.turkishName != null;
    return Material(
      color: matched ? AppColors.sageSoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size * 0.18),
        side: BorderSide(
          color: matched ? AppColors.sage : AppColors.gold.withValues(alpha: 0.7),
          width: matched ? 2.5 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (matched)
              Positioned(
                top: size * 0.06,
                right: size * 0.06,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: size * 0.18,
                  color: AppColors.sage,
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                size * 0.08,
                size * 0.08,
                size * 0.08,
                showName ? size * 0.26 : size * 0.08,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ColoredArabicText(
                  letter.isolatedForm,
                  textDirection: TextDirection.rtl,
                  style: AppTextTheme.arabicLetter(fontSize: size * 0.5),
                ),
              ),
            ),
            if (showName)
              Positioned(
                bottom: size * 0.07,
                left: 0,
                right: 0,
                child: Text(
                  letter.turkishName!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
