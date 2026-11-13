import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/drag_drop_game_data.dart';
import '../../../helpers/colored_arabic_text.dart';
import '../../../models/arabic_letter.dart';
import '../../../l10n/l10n.dart';
import '../../../services/audio_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../../../widgets/game_meadow_background.dart';
import 'yildiz_data.dart';
import 'yildiz_engine.dart';
import 'yildiz_progress.dart';

enum _Phase { intro, quiz, tourBreak, result }

/// Bir Harf Yıldızları dersi: tanışma → sorular → (tur arası) → sonuç.
class HarfYildizlariLessonScreen extends StatefulWidget {
  const HarfYildizlariLessonScreen({
    super.key,
    required this.lesson,
    required this.progress,
    this.restart = false,
    this.seed,
  });

  final YildizLesson lesson;
  final YildizProgress progress;

  /// Yarım kalan oturum varsa yok sayıp baştan başlar ("Tekrar oyna").
  final bool restart;

  /// Testler için sabit tohum.
  final int? seed;

  @override
  State<HarfYildizlariLessonScreen> createState() =>
      _HarfYildizlariLessonScreenState();
}

class _HarfYildizlariLessonScreenState extends State<HarfYildizlariLessonScreen>
    with WidgetsBindingObserver {
  late final AudioService _audio = context.read<AudioService>();
  YildizSession? _session;
  _Phase _phase = _Phase.intro;
  YildizCompletion? _completion;
  String _message = '';
  bool _messageIsGood = false;
  Timer? _advanceTimer;
  bool _foreground = true;

  @visibleForTesting
  YildizSession? get debugSession => _session;

  YildizLesson get _lesson => widget.lesson;
  YildizProgress get _progress => widget.progress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio.preload([
      for (final l in _lesson.letters) l.audioAsset,
      kGameCorrectSound,
    ]);
    if (!widget.restart) {
      final resumed = _progress.resume(_lesson);
      if (resumed != null) {
        _session = resumed;
        _phase = _Phase.quiz;
        _message = 'Kaldığın yerden devam ediyoruz.';
        _messageIsGood = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _autoPlay());
      }
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final session = _session;
    if (session != null && _phase != _Phase.result && !session.finished) {
      _progress.saveSession(session);
    }
    Future.microtask(_audio.stop);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _advanceTimer?.cancel();
      _audio.stop();
    } else if (_phase == _Phase.quiz) {
      if (_session?.currentCompleted ?? false) {
        _scheduleAdvance();
      } else {
        _autoPlay();
      }
    }
  }

  void _scheduleAdvance() {
    _advanceTimer?.cancel();
    final session = _session;
    if (!_foreground || session == null || !session.currentCompleted) return;
    final delay =
        session.wrongInQuestion >= YildizRewards.maxWrongBeforeGuide
            ? const Duration(milliseconds: 2800)
            : const Duration(milliseconds: 900);
    _advanceTimer = Timer(delay, () {
      if (mounted &&
          _foreground &&
          _phase == _Phase.quiz &&
          identical(_session, session) &&
          session.currentCompleted) {
        _continue();
      }
    });
  }

  void _start() {
    _advanceTimer?.cancel();
    final seed = widget.seed ?? math.Random().nextInt(1 << 30);
    _session = YildizSession(
      lesson: _lesson,
      count: yildizQuestionCount(_lesson, _progress.preset),
      seed: seed,
      priority: _progress.reviewKeys(_lesson),
    );
    setState(() {
      _phase = _Phase.quiz;
      _message = '';
    });
    _autoPlay();
  }

  void _play(ArabicLetter letter) {
    _audio.playLetter(letter);
  }

  String? _instructionAsset(YildizQuestionType type) {
    final language = context.language;
    if (language == AppLanguage.tr) {
      final name = switch (type) {
        YildizQuestionType.listen => 'dinle',
        YildizQuestionType.match => 'eslestir',
        YildizQuestionType.shape => 'kelime',
      };
      return 'audio/oyunlar/yildiz_$name.mp3';
    }
    // Mevcut, seçili dildeki ortak oyun yönergesi: dinle ve doğru olanı seç.
    if (AppLanguage.active.contains(language)) {
      return 'audio/${language.code}/game_76383fc2e674b663.mp3';
    }
    return null;
  }

  void _autoPlay() {
    final q = _session?.current;
    if (mounted && _foreground && _phase == _Phase.quiz && q != null) {
      final instruction = _instructionAsset(q.type);
      final letterAudio = q.letter.audioAsset;
      _audio.preload([instruction, letterAudio]);
      _audio.playPlaylist([
        if (instruction != null) instruction,
        if (letterAudio != null) letterAudio,
      ]);
    }
  }

  void _answer(int index) {
    final session = _session!;
    final q = session.current!;
    if (session.currentCompleted) return;
    final result = session.answer(index);
    switch (result.kind) {
      case YildizAnswerKind.correct:
        _audio.playEffect(kGameCorrectSound);
        _message =
            session.lastOutcome == YildizOutcome.firstTry
                ? 'Harika, doğru!'
                : 'Güzel, buldun!';
        _messageIsGood = true;
      case YildizAnswerKind.guided:
        _play(q.letter);
        _message = 'Doğru cevabı işaretledik. Birlikte tekrar dinleyelim.';
        _messageIsGood = true;
      case YildizAnswerKind.wrong:
        if (q.type == YildizQuestionType.listen) {
          _message = 'Bir daha dinleyelim.';
          _play(q.letter);
        } else if (q.type == YildizQuestionType.shape) {
          _message = 'Noktalarına dikkat et.';
        } else {
          _message = 'Bir daha bakalım.';
        }
        _messageIsGood = false;
    }
    setState(() {});
    if (result.completed) {
      _progress.saveSession(session);
      _scheduleAdvance();
    }
  }

  Future<void> _continue() async {
    _advanceTimer?.cancel();
    final session = _session!;
    if (!session.currentCompleted) return;
    if (session.atTourBreak && _phase == _Phase.quiz) {
      await _progress.markStudyDay();
      if (mounted) setState(() => _phase = _Phase.tourBreak);
      return;
    }
    session.next();
    if (session.isDone) {
      final done = await _progress.complete(session);
      if (!mounted) return;
      setState(() {
        _completion = done;
        _phase = _Phase.result;
      });
      return;
    }
    setState(() {
      _message = '';
      _phase = _Phase.quiz;
    });
    _autoPlay();
  }

  void _restart() {
    _progress.discardSession(_lesson.id);
    _session = null;
    _completion = null;
    _start();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      appBar: AppBar(
        title: Text(yt(context, _lesson.title)),
        backgroundColor: Colors.transparent,
        foregroundColor: kYildizNavy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: switch (_phase) {
              _Phase.intro => _buildIntro(),
              _Phase.quiz => _buildQuiz(),
              _Phase.tourBreak => _buildTourBreak(),
              _Phase.result => _buildResult(),
            },
          ),
        ),
      ),
    );
  }

  // --- Tanışma ---------------------------------------------------------

  Widget _buildIntro() {
    final letters = _lesson.letters;
    final big = letters.length <= 5;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                context.t(
                  _lesson.isReview
                      ? 'Hep birlikte tekrar edelim'
                      : 'Yeni harflerimiz',
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: kYildizNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t('Bir harfe dokun, adını dinle.'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final l in letters)
                    _IntroCard(letter: l, big: big, onTap: () => _play(l)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: _BigButton(
            buttonKey: const ValueKey('yildiz-start'),
            icon: Icons.play_arrow_rounded,
            label: 'Başla',
            onPressed: _start,
          ),
        ),
      ],
    );
  }

  // --- Sorular -----------------------------------------------------------

  Widget _buildQuiz() {
    final session = _session!;
    final q = session.current!;
    final reduce = MediaQuery.of(context).disableAnimations;
    final total = session.baseTotal;
    final shown = math.min(
      session.baseDone + (session.currentCompleted ? 0 : 1),
      total,
    );
    final letter = q.letter;
    final prompt = switch (q.type) {
      YildizQuestionType.listen => 'Sesi dinle, doğru harfi bul.',
      YildizQuestionType.match => 'Bu harfin adı hangisi?',
      YildizQuestionType.shape =>
        'Hangi kelimede ${letter.turkishName} harfi var?',
    };
    final content = SingleChildScrollView(
      key: ObjectKey(q),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressHeader(
            done: session.baseDone,
            total: total,
            label:
                session.inReinforcement
                    ? 'Pekiştirme turu'
                    : q.isRetry
                    ? 'Bir daha bakalım'
                    : 'Soru $shown / $total',
            reinforcement: session.inReinforcement || q.isRetry,
            tour: _tourLabel(session),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              yt(context, prompt),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: kYildizNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (q.type == YildizQuestionType.listen)
            Center(child: _ListenButton(onPressed: () => _play(letter)))
          else if (q.type == YildizQuestionType.match)
            Center(
              child: _GlyphPlate(letter: letter, onTap: () => _play(letter)),
            )
          else
            Center(
              child: _GlyphPlate(
                letter: letter,
                small: true,
                onTap: () => _play(letter),
              ),
            ),
          const SizedBox(height: 16),
          _Options(
            question: q,
            wrong: session.wrongOptions,
            completed: session.currentCompleted,
            reduceMotion: reduce,
            onTap: _answer,
          ),
        ],
      ),
    );
    final feedback = SizedBox(
      height: 56,
      child:
          _message.isEmpty
              ? null
              : Semantics(
                liveRegion: true,
                child: _Feedback(text: _message, good: _messageIsGood),
              ),
    );
    return Column(
      children: [
        Expanded(child: content),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: feedback,
        ),
      ],
    );
  }

  String? _tourLabel(YildizSession s) {
    final tour = _lesson.tourSize;
    if (tour == null || s.baseTotal <= tour) return null;
    final tours = (s.baseTotal / tour).ceil();
    final current = math.min(s.baseDone ~/ tour + 1, tours);
    return 'Tur $current / $tours';
  }

  // --- Tur arası ---------------------------------------------------------

  Widget _buildTourBreak() {
    final session = _session!;
    final tour = _lesson.tourSize!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 64),
        const SizedBox(height: 12),
        Text(
          yt(context, '${session.baseDone ~/ tour}. tur tamam!'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: kYildizNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.t(
            'İstersen biraz dinlen, kaldığın yerden devam edebilirsin.',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _BigButton(
          buttonKey: const ValueKey('yildiz-tour-continue'),
          icon: Icons.play_arrow_rounded,
          label: 'Devam et',
          onPressed: () {
            session.next();
            setState(() {
              _phase = _Phase.quiz;
              _message = '';
            });
            _autoPlay();
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('yildiz-tour-later'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          onPressed: () async {
            session.next();
            await _progress.saveSession(session);
            if (mounted) Navigator.of(context).pop();
          },
          child: Text(context.t('Sonra devam ederim')),
        ),
      ],
    );
  }

  // --- Sonuç ---------------------------------------------------------------

  Widget _buildResult() {
    final c = _completion!;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.stars_rounded, color: AppColors.gold, size: 72),
        const SizedBox(height: 8),
        Text(
          context.t('Ders tamam!'),
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            color: kYildizNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          yt(context, '+${c.totalXp} XP'),
          key: const ValueKey('yildiz-xp-gained'),
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: kYildizNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (c.bonusXp > 0)
          Text(
            yt(context, 'Ders bitirme bonusu dahil: +${c.bonusXp}'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: 16),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _EffortStar(label: 'Dinledim', icon: Icons.hearing_rounded),
            _EffortStar(label: 'Denedim', icon: Icons.touch_app_rounded),
            _EffortStar(label: 'Tamamladım', icon: Icons.check_circle_rounded),
          ],
        ),
        if (c.newBadge != null) ...[
          const SizedBox(height: 16),
          Container(
            key: const ValueKey('yildiz-badge'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.gold,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    yt(context, 'Yeni rozet: ${c.newBadge}'),
                    style: textTheme.titleMedium?.copyWith(
                      color: kYildizNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (c.needsReview.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            context.t(
              'Bazı harfleri bir sonraki derste yine birlikte tekrar edeceğiz.',
            ),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          yt(context, _progress.weekMessage),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _BigButton(
          buttonKey: const ValueKey('yildiz-continue'),
          icon: Icons.arrow_forward_rounded,
          label: 'Devam et',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('yildiz-replay'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          onPressed: _restart,
          icon: const Icon(Icons.replay_rounded),
          label: Text(context.t('Tekrar oyna')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Parçalar

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.buttonKey,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: buttonKey,
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(yt(context, label)),
    style: FilledButton.styleFrom(
      backgroundColor: kYildizNavy,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(56),
      textStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.letter,
    required this.big,
    required this.onTap,
  });
  final ArabicLetter letter;
  final bool big;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = big ? 104.0 : 80.0;
    final h = big ? 132.0 : 100.0;
    return Semantics(
      button: true,
      label: yt(context, '${letter.turkishName} harfi, dinlemek için dokun'),
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: w,
            height: h,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: kYildizNavy.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: FittedBox(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: ColoredArabicText(
                        letter.isolatedForm,
                        style: AppTextTheme.arabicSmall(
                          fontSize: big ? 60 : 44,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  yt(context, letter.turkishName ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: kYildizNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(
                  Icons.volume_up_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.done,
    required this.total,
    required this.label,
    required this.reinforcement,
    this.tour,
  });

  final int done;
  final int total;
  final String label;
  final bool reinforcement;
  final String? tour;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                yt(context, label),
                key: const ValueKey('yildiz-progress-label'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: reinforcement ? AppColors.gold : kYildizNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (tour != null)
              Text(
                yt(context, tour!),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 12,
            color: kYildizNavy,
            backgroundColor: kYildizNavy.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.t('Sesi tekrar dinle'),
    excludeSemantics: true,
    child: Material(
      color: kYildizNavy,
      shape: const CircleBorder(),
      child: InkWell(
        key: const ValueKey('yildiz-listen'),
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 88,
          height: 88,
          child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 44),
        ),
      ),
    ),
  );
}

class _GlyphPlate extends StatelessWidget {
  const _GlyphPlate({
    required this.letter,
    required this.onTap,
    this.small = false,
  });
  final ArabicLetter letter;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 88.0 : 128.0;
    return Semantics(
      button: true,
      label: yt(context, '${letter.turkishName} harfi, sesini dinle'),
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: const ValueKey('yildiz-glyph'),
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: kYildizNavy.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: ColoredArabicText(
                    letter.isolatedForm,
                    style: AppTextTheme.arabicSmall(fontSize: small ? 52 : 80),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.question,
    required this.wrong,
    required this.completed,
    required this.reduceMotion,
    required this.onTap,
  });

  final YildizQuestion question;
  final Set<int> wrong;
  final bool completed;
  final bool reduceMotion;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isWord = question.type == YildizQuestionType.shape;
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 12.0;
        final columns = isWord ? 1 : 2;
        final w = (box.maxWidth - gap * (columns - 1)) / columns;
        final h =
            isWord
                ? 84.0
                : (question.type == YildizQuestionType.listen ? 104.0 : 72.0);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < question.options.length; i++)
              SizedBox(
                width: w,
                height: h,
                child: _OptionCard(
                  key: ValueKey('yildiz-option-$i'),
                  option: question.options[i],
                  isWord: isWord,
                  state:
                      completed && i == question.correctIndex
                          ? _OptionState.correct
                          : wrong.contains(i)
                          ? _OptionState.wrong
                          : _OptionState.idle,
                  enabled: !completed && !wrong.contains(i),
                  reduceMotion: reduceMotion,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _OptionState { idle, wrong, correct }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.option,
    required this.isWord,
    required this.state,
    required this.enabled,
    required this.reduceMotion,
    required this.onTap,
  });

  final YildizOption option;
  final bool isWord;
  final _OptionState state;
  final bool enabled;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OptionState.correct => AppColors.sageSoft,
      _OptionState.wrong => AppColors.divider.withValues(alpha: 0.4),
      _OptionState.idle => AppColors.surface,
    };
    final border = switch (state) {
      _OptionState.correct => const Color(0xFF2E7D32),
      _OptionState.wrong => AppColors.divider,
      _OptionState.idle => kYildizNavy.withValues(alpha: 0.3),
    };
    final suffix = switch (state) {
      _OptionState.correct => ', doğru cevap',
      _OptionState.wrong => ', yanlış, başka seçeneği dene',
      _OptionState.idle => '',
    };
    final text =
        option.arabic != null
            ? Directionality(
              textDirection: TextDirection.rtl,
              child: ColoredArabicText(
                option.arabic!,
                style: AppTextTheme.arabicSmall(fontSize: isWord ? 48 : 56),
              ),
            )
            : Text(
              yt(context, option.label ?? ''),
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: kYildizNavy,
                fontWeight: FontWeight.w800,
              ),
            );
    final semanticLabel =
        yt(context, option.label ?? option.arabic ?? '') + yt(context, suffix);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: border,
            width: state == _OptionState.correct ? 3 : 2,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? onTap : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: state == _OptionState.wrong ? 0.45 : 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: text,
                    ),
                  ),
                ),
                if (state == _OptionState.correct)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 24,
                    ),
                  ),
                if (state == _OptionState.wrong)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.replay_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
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

class _Feedback extends StatelessWidget {
  const _Feedback({required this.text, required this.good});
  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('yildiz-feedback'),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: good ? AppColors.sageSoft : AppColors.goldSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(
          good ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
          color: good ? const Color(0xFF2E7D32) : AppColors.gold,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            yt(context, text),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EffortStar extends StatelessWidget {
  const _EffortStar({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: yt(context, '$label yıldızı kazanıldı'),
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 48),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
          Text(
            yt(context, label),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: kYildizNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
