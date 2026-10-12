import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/audio_service.dart';
import '../services/teacher_voice.dart';
import '../theme/app_colors.dart';

/// Sesli öğretmenin küçük yüzü (hoparlör simgesinin yerine): yuvarlak yüz,
/// saç, gözler, gülümseme, pembe yanaklar. [speaking] iken yanında ses
/// dalgaları; [muted] iken soluk ve ağzı düz. Kendi çizimimiz (resim yok).
class TeacherHead extends StatelessWidget {
  const TeacherHead({
    super.key,
    this.size = 22,
    this.speaking = false,
    this.muted = false,
  });

  final double size;
  final bool speaking;
  final bool muted;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.3,
    height: size,
    child: CustomPaint(
      painter: _TeacherHeadPainter(speaking: speaking, muted: muted),
    ),
  );
}

class _TeacherHeadPainter extends CustomPainter {
  _TeacherHeadPainter({required this.speaking, required this.muted});

  final bool speaking;
  final bool muted;

  static const _skin = Color(0xFFFFD9B8);
  static const _hair = Color(0xFF8D6E63);
  static const _ink = Color(0xFF5D4E46);
  static const _cheek = Color(0xFFF8A5B8);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final c = Offset(r, r);
    final fade = muted ? 0.45 : 1.0;
    Paint fill(Color color) =>
        Paint()..color = color.withValues(alpha: color.a * fade);

    // Saç (arkada), yüz, perçem.
    canvas.drawCircle(c.translate(0, -r * 0.06), r * 0.96, fill(_hair));
    canvas.drawCircle(c.translate(0, r * 0.08), r * 0.82, fill(_skin));
    canvas.drawArc(
      Rect.fromCircle(center: c.translate(0, -r * 0.1), radius: r * 0.84),
      math.pi * 1.05,
      math.pi * 0.9,
      true,
      fill(_hair),
    );
    // Gözler.
    final eye = fill(_ink);
    canvas
      ..drawCircle(c.translate(-r * 0.3, r * 0.08), r * 0.09, eye)
      ..drawCircle(c.translate(r * 0.3, r * 0.08), r * 0.09, eye)
      // Yanaklar.
      ..drawCircle(c.translate(-r * 0.48, r * 0.3), r * 0.12, fill(_cheek))
      ..drawCircle(c.translate(r * 0.48, r * 0.3), r * 0.12, fill(_cheek));
    // Ağız: konuşurken açık, kapalıyken düz, yoksa gülümseme.
    final mouth = Paint()
      ..color = _ink.withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1
      ..strokeCap = StrokeCap.round;
    if (muted) {
      canvas.drawLine(
        c.translate(-r * 0.16, r * 0.42),
        c.translate(r * 0.16, r * 0.42),
        mouth,
      );
    } else if (speaking) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c.translate(0, r * 0.42),
          width: r * 0.32,
          height: r * 0.24,
        ),
        fill(_ink),
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: c.translate(0, r * 0.26), radius: r * 0.22),
        0.35,
        math.pi - 0.7,
        false,
        mouth,
      );
    }
    // Ses dalgaları (konuşurken) ya da sessiz çizgisi.
    final wave = Paint()
      ..color = (muted ? AppColors.textSecondary : AppColors.turquoise)
          .withValues(alpha: muted ? 0.6 : 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;
    final right = Offset(r * 2.05, r);
    if (muted) {
      canvas.drawLine(
        right.translate(-r * 0.12, -r * 0.3),
        right.translate(r * 0.38, r * 0.3),
        wave,
      );
    } else {
      final waves = speaking ? 2 : 1;
      for (var i = 0; i < waves; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: right.translate(-r * 0.3, 0), radius: r * (0.3 + 0.28 * i)),
          -0.7,
          1.4,
          false,
          wave,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TeacherHeadPainter old) =>
      old.speaking != speaking || old.muted != muted;
}

/// "Nasıl oynanır?" düğmesi (öğretmen yüzü + ?): oyunun açıklamasını yazılı
/// gösterir ve (kaydı varsa) okur. Ses kapalı olsa da çalar: çocuk istedi.
class HowToPlayButton extends StatelessWidget {
  const HowToPlayButton({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    final line = TeacherLine.howToFor(gameId);
    if (line == null) return const SizedBox.shrink();
    return IconButton(
      key: ValueKey('how-to-$gameId'),
      tooltip: context.t('Nasıl oynanır?'),
      onPressed: () => showHowToPlay(context, gameId),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const TeacherHead(size: 24),
          Positioned(
            right: -4,
            top: -6,
            child: Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '?', // l10n-ignore
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Açıklamayı pencerede gösterir ve okur.
Future<void> showHowToPlay(BuildContext context, String gameId) async {
  final line = TeacherLine.howToFor(gameId);
  if (line == null) return;
  final audio = context.read<AudioService>();
  final voice = TeacherVoice.maybeOf(context);
  final language = context.language;
  void read() => voice?.play(audio, language, line);
  read();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('how-to-dialog'),
      title: Row(
        children: [
          const TeacherHead(size: 30, speaking: true),
          const SizedBox(width: 10),
          Expanded(child: Text(dialogContext.t('Nasıl oynanır?'))),
        ],
      ),
      content: Text(
        dialogContext.t(line.turkish),
        style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
          height: 1.4,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: read,
          icon: const TeacherHead(size: 18),
          label: Text(dialogContext.t('Tekrar dinle')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.t('Anladım')),
        ),
      ],
    ),
  );
}
