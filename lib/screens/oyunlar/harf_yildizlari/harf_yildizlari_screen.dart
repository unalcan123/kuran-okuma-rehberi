import 'package:flutter/material.dart';

import '../../../helpers/colored_arabic_text.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../../../widgets/game_meadow_background.dart';
import 'harf_yildizlari_lesson_screen.dart';
import 'yildiz_data.dart';
import 'yildiz_progress.dart';

const String kYildizTagline = 'Dinle, keşfet, harfleri öğren!';

/// Harf Yıldızları'nın giriş ekranı: XP, hafta mesajı, soru sayısı ayarı ve
/// ders haritası (6 ana ders + 5 tekrar durağı).
class HarfYildizlariScreen extends StatefulWidget {
  const HarfYildizlariScreen({super.key, this.progress});

  /// Testler için hazır ilerleme.
  final YildizProgress? progress;

  @override
  State<HarfYildizlariScreen> createState() => _HarfYildizlariScreenState();
}

class _HarfYildizlariScreenState extends State<HarfYildizlariScreen> {
  late final YildizProgress _progress = widget.progress ?? YildizProgress();
  late final Future<void> _loaded =
      widget.progress == null ? _progress.load() : Future.value();

  Future<void> _open(YildizLesson lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/harf-yildizlari/${lesson.id}'),
        builder:
            (_) =>
                HarfYildizlariLessonScreen(lesson: lesson, progress: _progress),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      appBar: AppBar(
        title: Text(context.t('Harf Yıldızları')),
        backgroundColor: Colors.transparent,
        foregroundColor: kYildizNavy,
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _loaded,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListenableBuilder(
              listenable: _progress,
              builder:
                  (context, _) => Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        children: [
                          _Header(progress: _progress),
                          const SizedBox(height: 12),
                          _CountSetting(progress: _progress),
                          const SizedBox(height: 16),
                          for (final lesson in kYildizLessons) ...[
                            _LessonTile(
                              lesson: lesson,
                              progress: _progress,
                              onTap: () => _open(lesson),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.progress});
  final YildizProgress progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kYildizNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD667),
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('Harf Yıldızları'),
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      yt(context, kYildizTagline),
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(
                yt(context, '${progress.xp} XP'),
                key: const ValueKey('yildiz-total-xp'),
                style: textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFFFD667),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                yt(context, '${progress.badges.length} rozet'),
                style: textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              Text(
                yt(
                  context,
                  '${progress.solidLetterCount} / ${kYildizLetters.length} harf pekişti',
                ),
                style: textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            yt(context, progress.weekMessage),
            key: const ValueKey('yildiz-week'),
            style: textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CountSetting extends StatelessWidget {
  const _CountSetting({required this.progress});
  final YildizProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('Soru sayısı'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: kYildizNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            key: const ValueKey('yildiz-count'),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(minimumSize: const Size(48, 48)),
            segments: [
              ButtonSegment(value: 0, label: Text(context.t('Az'))),
              ButtonSegment(value: 1, label: Text(context.t('Normal'))),
              ButtonSegment(value: 2, label: Text(context.t('Çok'))),
            ],
            selected: {progress.preset},
            onSelectionChanged: (s) => progress.setPreset(s.first),
          ),
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.progress,
    required this.onTap,
  });

  final YildizLesson lesson;
  final YildizProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unlocked = progress.isUnlocked(lesson);
    final done = progress.isCompleted(lesson.id);
    final partial = progress.partial(lesson.id);
    final isNext = progress.nextLesson?.id == lesson.id;
    final missing = [
      for (final id in lesson.requires)
        if (!progress.isCompleted(id)) yt(context, yildizLessonById(id).title),
    ];
    final reason =
        missing.isEmpty
            ? null
            : yt(context, 'Önce bitir: ${missing.join(', ')}');
    final status =
        !unlocked
            ? reason ?? ''
            : partial != null
            ? 'Yarım kaldı: ${partial.$1} / ${partial.$2} · devam et'
            : done
            ? 'Tamamlandı · tekrar oynayabilirsin'
            : lesson.rangeLabel;
    final icon =
        !unlocked
            ? Icons.lock_rounded
            : done
            ? Icons.star_rounded
            : Icons.star_outline_rounded;
    final iconColor =
        !unlocked
            ? AppColors.textSecondary
            : done
            ? AppColors.gold
            : kYildizNavy;
    return Semantics(
      button: true,
      enabled: unlocked,
      label:
          '${yt(context, lesson.title)}. ${yt(context, lesson.rangeLabel)}. ${yt(context, status)}',
      excludeSemantics: true,
      child: Material(
        color:
            unlocked
                ? AppColors.surface
                : AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: ValueKey('yildiz-lesson-${lesson.id}'),
          borderRadius: BorderRadius.circular(20),
          onTap: unlocked ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNext ? kYildizNavy : AppColors.divider,
                width: isNext ? 3 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              yt(context, lesson.title),
                              style: textTheme.titleMedium?.copyWith(
                                color: kYildizNavy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (lesson.isReview) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.turquoiseSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                context.t('Tekrar'),
                                style: textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        yt(context, status),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: ColoredArabicText(
                        lesson.letters
                            .take(6)
                            .map((l) => l.isolatedForm)
                            .join(' '),
                        style: AppTextTheme.arabicSmall(fontSize: 26),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
