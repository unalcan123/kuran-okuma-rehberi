import 'package:flutter/material.dart';

import '../../../../helpers/colored_arabic_text.dart';
import '../../../../models/arabic_letter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_theme.dart';

/// A big round letter token the child picks up and carries to a sound.
/// The whole circle is the drag handle, and the piece being carried
/// grows slightly and casts a shadow so it stays readable under a
/// finger.
class DraggableLetter extends StatelessWidget {
  const DraggableLetter({
    super.key,
    required this.letter,
    required this.size,
    required this.placed,
    required this.returning,
    required this.onDragEnd,
  });

  final ArabicLetter letter;
  final double size;

  /// Already matched — only an empty outline stays behind.
  final bool placed;

  /// Currently gliding back to its spot after a wrong drop.
  final bool returning;
  final ValueChanged<DraggableDetails> onDragEnd;

  static const double liftScale = 1.12;

  /// The token as carried, also reused for the glide back.
  static Widget lifted(ArabicLetter letter, double size) => Material(
    type: MaterialType.transparency,
    child: Transform.scale(
      scale: liftScale,
      child: LetterFace(letter: letter, size: size, lifted: true),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (placed || returning) return LetterFace.empty(size: size);
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<ArabicLetter>(
        data: letter,
        maxSimultaneousDrags: 1,
        hitTestBehavior: HitTestBehavior.opaque,
        onDragEnd: onDragEnd,
        feedback: lifted(letter, size),
        childWhenDragging: LetterFace.empty(size: size),
        child: LetterFace(letter: letter, size: size),
      ),
    );
  }
}

/// The token drawn inside a [size] × [size] cell. The circle takes 84%
/// of the cell: the full cell stays the touch target, and a carried
/// piece leaves a rim of the sound card visible beneath it.
class LetterFace extends StatelessWidget {
  const LetterFace({
    super.key,
    required this.letter,
    required this.size,
    this.lifted = false,
  }) : empty = false;

  const LetterFace.empty({super.key, required this.size})
    : letter = null,
      lifted = false,
      empty = true;

  final ArabicLetter? letter;
  final double size;
  final bool lifted;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final diameter = size * 0.84;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child:
            empty
                ? Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.navy.withValues(alpha: 0.04),
                    border: Border.all(color: AppColors.divider, width: 2),
                  ),
                )
                : Container(
                  width: diameter,
                  height: diameter,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.65),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(
                          alpha: lifted ? 0.22 : 0.08,
                        ),
                        blurRadius: lifted ? 22 : 10,
                        offset: Offset(0, lifted ? 10 : 4),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.all(diameter * 0.14),
                      child: ColoredArabicText(
                        letter!.isolatedForm,
                        textDirection: TextDirection.rtl,
                        style: AppTextTheme.arabicLetter(
                          fontSize: diameter * 0.56,
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
