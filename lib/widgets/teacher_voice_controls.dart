import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/audio_service.dart';
import '../services/teacher_voice.dart';
import '../theme/app_colors.dart';
import 'teacher_head.dart';

/// Sesli öğretmenin iki küçük düğmesi: son konuşmayı tekrar dinle ve
/// öğretmen sesini aç/kapa. Servis yoksa hiçbir şey çizmez.
class TeacherVoiceControls extends StatelessWidget {
  const TeacherVoiceControls({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    final voice = TeacherVoice.maybeOf(context);
    if (voice == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) {
        final audio = context.read<AudioService>();
        Widget button({
          required Key key,
          required Widget icon,
          required String tooltip,
          required VoidCallback? onPressed,
        }) => IconButton(
          key: key,
          tooltip: tooltip,
          onPressed: onPressed,
          icon: icon,
          color: AppColors.turquoise,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(
            width: size * 1.3 + 20,
            height: size + 20,
          ),
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (voice.enabled && voice.hasLast)
              button(
                key: const ValueKey('teacher-repeat'),
                icon: Icon(Icons.replay_rounded, size: size),
                tooltip: context.t('Öğretmeni tekrar dinle'),
                onPressed: () => voice.repeatLast(audio),
              ),
            button(
              key: const ValueKey('teacher-toggle'),
              icon: TeacherHead(size: size, muted: !voice.enabled),
              tooltip: context.t(
                voice.enabled ? 'Öğretmen sesini kapat' : 'Öğretmen sesini aç',
              ),
              onPressed: () => voice.setEnabled(!voice.enabled, audio: audio),
            ),
          ],
        );
      },
    );
  }
}
