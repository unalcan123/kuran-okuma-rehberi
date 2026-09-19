import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../data/drag_drop_game_data.dart';
import '../../../models/arabic_letter.dart';
import '../../../models/game_score.dart';
import '../../../models/lesson.dart';
import '../../../services/audio_service.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../widgets/game_finish_view.dart';
import '../widgets/game_progress.dart';
import '../widgets/game_result_summary.dart';
import '../widgets/game_score_strip.dart';
import 'listen_pick_questions.dart';
import 'widgets/option_card.dart';
import 'widgets/options_grid.dart';
import 'widgets/play_sound_button.dart';

/// "Dinle ve Seç": a recording plays (again whenever the big button is
/// tapped) and the child picks the written form that matches it, from
/// the lesson they chose. Same idea as the old Elifba game, without the
/// score race: a wrong pick just dims that card and the child tries
/// again. Points come from [GameScorer]; the finish screen shows them
/// with stars and the best score for this lesson.
class ListenPickScreen extends StatefulWidget {
  const ListenPickScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<ListenPickScreen> createState() => _ListenPickScreenState();
}

class _ListenPickScreenState extends State<ListenPickScreen> {
  late final List<ArabicLetter> _pool = listenPickPool(widget.lesson.letters);
  late List<ListenPickQuestion> _questions;
  late AudioService _audio;
  late GameScoreStore _store;
  late GameScorer _scorer = GameScorer(total: _questions.length);
  ScoreAward? _award;
  GameResult? _result;
  GameSubmission? _submission;
  Timer? _autoPlay;
  Timer? _advance;

  /// How long the right answer stays on screen before the next question.
  static const _advanceDelay = Duration(seconds: 2);

  int _index = 0;
  bool _solved = false;
  bool _missed = false;
  bool _finished = false;
  int _burst = 0;
  final _wrong = <String>{};
  final _shake = <String, int>{};

  ListenPickQuestion get _current => _questions[_index];

  // Lessons that teach written positions ask for a position each question.
  List<ListenPickQuestion> _draw() => buildListenPickQuestions(
    _pool,
    positions: listenPickUsesPositions(_pool),
  );

  @override
  void initState() {
    super.initState();
    _questions = _draw();
    _scheduleAutoPlay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<AudioService>();
    _store = context.read<GameScoreStore>();
    _audio.preload([
      kGameCorrectSound,
      for (final item in _pool) item.audioAsset,
    ]);
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _advance?.cancel();
    Future.microtask(_audio.stop);
    super.dispose();
  }

  // The question's recording starts by itself, a beat after it appears.
  void _scheduleAutoPlay() {
    _autoPlay?.cancel();
    _autoPlay = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_finished && !_solved) _audio.playLetter(_current.answer);
    });
  }

  void _pick(ArabicLetter option) {
    if (_solved || _finished) return;
    final id = listenPickId(option);
    if (_wrong.contains(id)) return;
    if (id == listenPickId(_current.answer)) {
      _autoPlay?.cancel();
      final award = _scorer.recordCorrect(firstTry: !_missed);
      final last = _index + 1 >= _questions.length;
      setState(() {
        _solved = true;
        _burst++;
        _award = award;
        // The last answer goes straight to the result page.
        if (last) {
          _finished = true;
          _finish();
        }
      });
      // The question's sound was just heard; only the cheer plays now.
      _audio.playPlaylist([kGameCorrectSound]);
      if (!last) _advance = Timer(_advanceDelay, _next);
    } else {
      _scorer.recordMiss();
      setState(() {
        _wrong.add(id);
        _missed = true;
        _shake[id] = (_shake[id] ?? 0) + 1;
      });
    }
  }

  void _next() {
    if (!mounted) return;
    _audio.stop();
    setState(() {
      _index++;
      _resetQuestion();
    });
    _scheduleAutoPlay();
  }

  void _finish() {
    final result = _scorer.result;
    _result = result;
    _submission = null;
    _store.submit(listenPickGameKey(widget.lesson), result).then((submission) {
      if (mounted && identical(_result, result)) {
        setState(() => _submission = submission);
      }
    });
  }

  void _resetQuestion() {
    _solved = false;
    _missed = false;
    _burst = 0;
    _wrong.clear();
    _shake.clear();
  }

  void _replay() {
    _advance?.cancel();
    _audio.stop();
    setState(() {
      _questions = _draw();
      _index = 0;
      _finished = false;
      _scorer = GameScorer(total: _questions.length);
      _award = null;
      _result = null;
      _submission = null;
      _resetQuestion();
    });
    _scheduleAutoPlay();
  }

  double get _progress =>
      (_index + (_solved ? 1 : 0)) / _questions.length;

  OptionState _stateOf(ArabicLetter option) {
    final id = listenPickId(option);
    if (_solved) {
      return id == listenPickId(_current.answer)
          ? OptionState.correct
          : OptionState.faded;
    }
    return _wrong.contains(id) ? OptionState.wrong : OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = switch (Responsive.deviceClassOf(context)) {
      DeviceClass.mobile => 900.0,
      DeviceClass.tablet => 1100.0,
      DeviceClass.desktop => 1200.0,
    };
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dinle ve Seç',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.lesson.label} · ${widget.lesson.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (!_finished)
            GameStepPill(current: _index + 1, total: _questions.length),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child:
                _finished
                    ? GameFinishView(
                      title: 'Tebrikler!',
                      message: 'Soruları tamamladın.',
                      summary:
                          _result == null
                              ? null
                              : GameResultSummary(
                                result: _result!,
                                submission: _submission,
                              ),
                      onReplay: _replay,
                      exitLabel: 'Derslere Dön',
                      onExit: () => Navigator.of(context).pop(),
                    )
                    : _buildGame(context),
          ),
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      children: [
        GameProgressBar(value: _progress),
        const SizedBox(height: 8),
        GameScoreStrip(
          points: _scorer.points,
          award: _award,
          instruction:
              _current.position == null
                  ? 'Sesi dinle, doğru olanı seç.'
                  : 'Sesi dinle, harfin ${_current.position!.label.toLowerCase()} yazılışını seç.',
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(key: ValueKey(_index), child: _playArea()),
          ),
        ),
      ],
    ),
  );

  Widget _playArea() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= constraints.maxHeight * 1.15;
      // (largest letter, tallest card, biggest listen button)
      final (maxFont, maxCell, maxPlay) = switch (Responsive.deviceClassOf(
        context,
      )) {
        DeviceClass.mobile => (84.0, 220.0, 140.0),
        DeviceClass.tablet => (120.0, 320.0, 190.0),
        DeviceClass.desktop => (130.0, 300.0, 200.0),
      };
      final playSize = (constraints.maxHeight * (wide ? 0.36 : 0.16)).clamp(
        64.0,
        maxPlay,
      );

      final playButton = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Selector<AudioService, bool>(
            selector:
                (_, audio) =>
                    audio.isPlaying &&
                    audio.currentAsset == _current.answer.audioAsset,
            builder:
                (context, playing, _) => PlaySoundButton(
                  size: playSize,
                  playing: playing,
                  onTap: () => _audio.playLetter(_current.answer),
                ),
          ),
          Text(
            'Dinle',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.turquoise,
            ),
          ),
          if (_current.position case final position?) ...[
            const SizedBox(height: 8),
            Container(
              key: const ValueKey('position-chip'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                position.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ],
      );

      final options = OptionsGrid(
        options: _current.options,
        textOf: _current.textOf,
        maxFontSize: maxFont,
        maxCellHeight: maxCell,
        itemBuilder:
            (context, item, fontSize) => OptionCard(
              key: ValueKey('option-${listenPickId(item)}'),
              item: item,
              text: _current.textOf(item),
              fontSize: fontSize,
              state: _stateOf(item),
              burstTrigger:
                  listenPickId(item) == listenPickId(_current.answer)
                      ? _burst
                      : 0,
              shakeTrigger: _shake[listenPickId(item)] ?? 0,
              onTap: () => _pick(item),
            ),
      );

      if (wide) {
        return Row(
          children: [
            SizedBox(
              width: constraints.maxWidth * 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [playButton],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: options),
          ],
        );
      }
      return Column(
        children: [
          playButton,
          const SizedBox(height: 12),
          Expanded(child: options),
        ],
      );
    },
  );
}
