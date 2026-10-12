import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../helpers/colored_arabic_text.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../../../widgets/game_meadow_background.dart';
import 'drag_drop_game_screen.dart';
import 'learning/learning_session.dart';
import 'learning/letter_learning.dart';

/// Sürükle & Bırak'ın giriş ekranı: harf yolculuğunun durumu (öğrenilen
/// harf / 29, aşama, günlük tekrar, yıldızlar, harf haritası), zorluk ve
/// "Devam Et". Sabit "Oyun 1-7" listesinin yerini alır.
class DragDropHomeScreen extends StatefulWidget {
  const DragDropHomeScreen({super.key, this.clock});

  /// For tests.
  final DateTime Function()? clock;

  @override
  State<DragDropHomeScreen> createState() => _DragDropHomeScreenState();
}

class _DragDropHomeScreenState extends State<DragDropHomeScreen> {
  late final Future<LearningSession> _session = LearningSession.open(
    context,
    clock: widget.clock,
  );

  Future<void> _play(LearningSession session, {bool daily = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DragDropGameScreen(session: session, daily: daily),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.isDesktop(context) ? 760.0 : 640.0;
    return GameScaffold(
      appBar: AppBar(title: Text(context.t('Sürükle & Bırak'))),
      body: FutureBuilder<LearningSession>(
        future: _session,
        builder: (context, snapshot) {
          final session = snapshot.data;
          if (session == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListenableBuilder(
            listenable: session,
            builder: (context, _) => Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _StatusCard(session: session),
                    const SizedBox(height: 16),
                    _LetterMap(session: session),
                    const SizedBox(height: 16),
                    _DifficultyPicker(session: session),
                    const SizedBox(height: 20),
                    if (session.dailyReviewDue) ...[
                      FilledButton.icon(
                        key: const ValueKey('daily-review'),
                        onPressed: () => _play(session, daily: true),
                        icon: const Icon(Icons.wb_sunny_rounded),
                        label: Text(context.t('Günlük Tekrara Başla')),
                        style: _bigButton(context, AppColors.gold),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const ValueKey('continue-learning'),
                        onPressed: () => _play(session),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(context.t('Devam Et')),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ] else
                      FilledButton.icon(
                        key: const ValueKey('continue-learning'),
                        onPressed: () => _play(session),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(context.t('Devam Et')),
                        style: _bigButton(context, AppColors.turquoise),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  ButtonStyle _bigButton(BuildContext context, Color color) =>
      FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(60),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.divider),
    ),
    child: child,
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.session});
  final LearningSession session;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final s = session.state;
    final engine = session.engine;
    final learned = session.learnedCount;
    final total = session.letterCount;
    final complete = engine.isComplete(s);
    final stage = math.min(s.group + 1, session.stageCount);
    final newLetters = engine.currentGroup(s);
    final phase = switch (s.phase) {
      LearnPhase.learn => 'Yeni harfler',
      LearnPhase.review => 'Karışık tekrar',
      LearnPhase.reinforce => 'Pekiştirme',
      LearnPhase.mastery => 'Ustalık turu',
    };
    final due = engine.dueLetters(s, session.now).length;
    final daily =
        s.lastDailyReview == dayKey(session.now)
            ? context.t('Bugünkü tekrar tamam!')
            : due > 0
            ? context.t('Günlük tekrar: {n} harf seni bekliyor', {'n': due})
            : context.t('Bugün tekrar edilecek harf yok');
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t('Harf Yolculuğu'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 28),
              const SizedBox(width: 4),
              Text(
                '${s.stars}',
                key: const ValueKey('total-stars'),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.t('{n} / {total} harf öğrenildi', {
              'n': learned,
              'total': total,
            }),
            key: const ValueKey('learned-count'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: learned / total,
              minHeight: 12,
              color: AppColors.sage,
              backgroundColor: AppColors.sage.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.flag_rounded,
            color: AppColors.turquoise,
            text:
                complete
                    ? context.t('Bütün harfler öğrenildi · Ustalık')
                    : context.t('Aşama {n} / {total} · {title}', {
                      'n': stage,
                      'total': session.stageCount,
                      'title': phase,
                    }),
            trailing:
                newLetters.isEmpty
                    ? null
                    : Directionality(
                      textDirection: TextDirection.rtl,
                      child: ColoredArabicText(
                        newLetters.map(letterIdOf).join('  '),
                        style: AppTextTheme.arabicSmall(
                          fontSize: 26,
                        ).copyWith(color: AppColors.textPrimary),
                      ),
                    ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.wb_sunny_rounded,
            color: AppColors.gold,
            text: daily,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 8), trailing!],
    ],
  );
}

/// The 29 letters as small round badges: faint while locked, a golden ring
/// for the new ones, greener as they are mastered, warm orange when the
/// child is struggling with them (never red).
class _LetterMap extends StatelessWidget {
  const _LetterMap({required this.session});
  final LearningSession session;

  @override
  Widget build(BuildContext context) {
    final s = session.state;
    final engine = session.engine;
    final unlocked = engine.unlocked(s).map(letterIdOf).toSet();
    final current = engine.currentGroup(s).map(letterIdOf).toSet();
    final now = session.now;
    return _Panel(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final group in engine.groups)
              for (final letter in group)
                () {
                  final id = letterIdOf(letter);
                  final p = s.letters[id];
                  final open = unlocked.contains(id);
                  final struggling = p != null && engine.isStruggling(p, now);
                  final level = p?.level ?? 0;
                  final fill =
                      !open
                          ? AppColors.divider.withValues(alpha: 0.35)
                          : struggling
                          ? const Color(0xFFFFE0B2)
                          : Color.lerp(
                            AppColors.surface,
                            AppColors.sage.withValues(alpha: 0.55),
                            level / kMaxLevel,
                          )!;
                  return Container(
                    key: ValueKey('map-$id'),
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fill,
                      border: Border.all(
                        color:
                            current.contains(id)
                                ? AppColors.gold
                                : AppColors.divider,
                        width: current.contains(id) ? 3 : 1,
                      ),
                    ),
                    child: Opacity(
                      opacity: open ? 1 : 0.35,
                      child: ColoredArabicText(
                        id,
                        style: AppTextTheme.arabicSmall(fontSize: 22),
                      ),
                    ),
                  );
                }(),
          ],
        ),
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.session});
  final LearningSession session;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('Zorluk'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<DragDropDifficulty>(
              showSelectedIcon: false,
              segments: [
                for (final d in DragDropDifficulty.values)
                  ButtonSegment(
                    value: d,
                    label: Text(context.t(d.label)),
                  ),
              ],
              selected: {session.state.difficulty},
              onSelectionChanged: (s) => session.setDifficulty(s.first),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(switch (session.state.difficulty) {
              DragDropDifficulty.easy =>
                '3 büyük kart, süre yok; zorlanınca doğru harf parlar.',
              DragDropDifficulty.medium =>
                '6 kart, eski ve yeni harfler karışık; daha az yardım.',
              DragDropDifficulty.hard =>
                '6 kart, bütün öğrendiğin harflerden; benzer harfler yan yana.',
            }),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
