import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/audio_service.dart';
import '../services/turkish_audio_catalog.dart';
import '../theme/app_colors.dart';
import 'teacher_head.dart';

/// Makes a Turkish explanation (or heading) listenable: tapping anywhere on
/// it plays its recording [audioId] on the app's one [AudioService] player,
/// so it stops an Arabic word that is playing and the other way round.
/// Tapping it again starts it over, like the Arabic cells.
///
/// Without a recording (or with [audioId] null) [builder] gets
/// `available: false` and nothing can be tapped — the text looks exactly
/// as before.
class TurkishAudioTap extends StatelessWidget {
  const TurkishAudioTap({
    super.key,
    required this.audioId,
    required this.builder,
  });

  final String? audioId;
  final Widget Function(BuildContext context, bool available, bool playing)
  builder;

  @override
  Widget build(BuildContext context) {
    final id = audioId;
    if (id == null) return builder(context, false, false);
    TurkishAudioCatalog.ensureLoaded();
    final asset = 'audio/${context.language.code}/$id.mp3';
    return ValueListenableBuilder<Set<String>>(
      valueListenable: TurkishAudioCatalog.available,
      builder: (context, available, _) {
        if (!available.contains(asset)) return builder(context, false, false);
        // On the web: download it while the page is being read (once).
        context.read<AudioService>().preload([asset]);
        final playing = context.select<AudioService, bool>(
          (audio) => audio.currentAsset == asset && audio.isPlaying,
        );
        return Semantics(
          button: true,
          label: context.t('Açıklamayı dinle'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: ValueKey('tr-audio-$id'),
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<AudioService>().playAsset(asset),
              child: builder(context, true, playing),
            ),
          ),
        );
      },
    );
  }
}

/// The small teacher face shown before a listenable text (the AI teacher's
/// voice); it talks while it plays. Arabic recordings keep the speaker.
class TurkishAudioIcon extends StatelessWidget {
  const TurkishAudioIcon({
    super.key,
    required this.audioId,
    this.playing = false,
    this.size = 18,
  });

  final String audioId;
  final bool playing;
  final double size;

  @override
  Widget build(BuildContext context) => TeacherHead(
    key: ValueKey('tr-audio-icon-$audioId'),
    size: size,
    speaking: playing,
  );
}

/// An explanation paragraph (or several read together) with the speaker
/// in front and a soft highlight while it plays. A block is at least a
/// finger tall, so a one-line rule is easy to hit on a phone.
class TurkishAudioBlock extends StatelessWidget {
  const TurkishAudioBlock({
    super.key,
    required this.audioId,
    required this.child,
  });

  final String? audioId;
  final Widget child;

  @override
  Widget build(BuildContext context) => TurkishAudioTap(
    audioId: audioId,
    builder: (context, available, playing) {
      if (!available) return child;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              playing
                  ? AppColors.turquoise.withValues(alpha: 0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 6),
                child: TurkishAudioIcon(audioId: audioId!, playing: playing),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    },
  );
}
