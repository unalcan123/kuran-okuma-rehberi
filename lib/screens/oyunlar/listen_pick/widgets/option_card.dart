import 'package:flutter/material.dart';

import '../../../../models/arabic_letter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_theme.dart';
import '../../widgets/music_note_burst.dart';
import '../../widgets/shake_on_trigger.dart';

enum OptionState {
  idle,

  /// Tried and not it: dims and stays out of the way.
  wrong,

  /// The right answer.
  correct,

  /// Not chosen, question already answered.
  faded,
}

/// Style shared by the measuring pass and the card itself, so what is
/// measured is exactly what is drawn.
TextStyle optionTextStyle(double fontSize) =>
    AppTextTheme.arabicLetter(fontSize: fontSize).copyWith(height: 1.5);

/// One written choice. Nothing here is red or loud: a wrong pick wobbles
/// and dims, the right one turns sage green with a check and notes.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.item,
    required this.text,
    required this.fontSize,
    required this.state,
    required this.burstTrigger,
    required this.shakeTrigger,
    required this.onTap,
  });

  final ArabicLetter item;

  /// What the card shows (the letter's isolated or positional form).
  final String text;
  final double fontSize;
  final OptionState state;
  final int burstTrigger;
  final int shakeTrigger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final correct = state == OptionState.correct;
    final dimmed = state == OptionState.wrong || state == OptionState.faded;
    return ShakeOnTrigger(
      trigger: shakeTrigger,
      amplitude: 9,
      child: LayoutBuilder(
        builder:
            (context, constraints) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: dimmed ? 0.45 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: Material(
                      color: correct ? AppColors.sageSoft : AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: correct ? AppColors.sage : AppColors.divider,
                          width: correct ? 3 : 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: state == OptionState.idle ? onTap : null,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (correct)
                              const Positioned(
                                top: 10,
                                right: 12,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.sage,
                                  size: 26,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  text,
                                  textDirection: TextDirection.rtl,
                                  style: optionTextStyle(fontSize),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: MusicNoteBurst(
                    trigger: burstTrigger,
                    size: constraints.biggest.shortestSide,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
