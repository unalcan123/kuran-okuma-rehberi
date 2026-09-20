import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/arabic_letter.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

/// One example word of a book table. Tapping it plays its recording; the
/// part the book prints in red is drawn red ([before] + [red] + [after] is
/// the whole word).
class WordCell extends StatelessWidget {
  final ArabicLetter letter;
  final String before;
  final String red;
  final String after;
  final double fontSize;

  const WordCell({
    super.key,
    required this.letter,
    required this.before,
    required this.red,
    this.after = '',
    this.fontSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final playing = audio.isPlaying && audio.currentAsset == letter.audioAsset;
    final style = AppTextTheme.arabicSmall(fontSize: fontSize).copyWith(
      color: AppColors.textPrimary,
      height: 1.7,
    );
    return Semantics(
      button: true,
      label: 'Dinle',
      child: Material(
        color: playing ? AppColors.turquoiseSoft : Colors.transparent,
        child: InkWell(
          onTap: () => audio.playLetter(letter),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Center(
              // Long phrases shrink to fit the cell instead of overflowing.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: before),
                      TextSpan(text: red, style: const TextStyle(color: AppColors.red)),
                      TextSpan(text: after),
                    ],
                    style: style,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
