import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../l10n/game_narration_ids.g.dart';
import 'teacher_head.dart';
import 'turkish_audio_block.dart';

/// Instructions play only when tapped, keeping target letter sounds intact.
class GameNarratedText extends StatelessWidget {
  const GameNarratedText(this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) => TurkishAudioTap(
    audioId: kGameNarrationIds[text],
    builder:
        (context, available, playing) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (available) ...[
              TeacherHead(size: 18, speaking: playing),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                context.t(text),
                style: style,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: overflow,
              ),
            ),
          ],
        ),
  );
}
