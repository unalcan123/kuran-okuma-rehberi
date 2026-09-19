import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../data/drag_drop_game_data.dart';
import '../../../data/memory_game_data.dart';
import '../../../models/arabic_letter.dart';
import '../../../models/game_score.dart';
import '../../../services/audio_service.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../widgets/fit_grid.dart';
import '../widgets/game_finish_view.dart';
import '../widgets/game_progress.dart';
import '../widgets/game_result_summary.dart';
import '../widgets/game_score_strip.dart';
import 'widgets/memory_card.dart';

enum _Phase { preview, playing, finished }

/// "Hafıza": every letter of the level is hidden twice among the cards.
/// First all cards are shown for a few seconds (tap one to hear it), then
/// they turn over and the child finds the matching pairs. Each card that
/// turns over says its letter aloud, so the game teaches the letters as
/// well as testing the memory.
///
/// Points come from [GameScorer], one item per pair: finding a pair earns
/// points, and a pair found without ever having been part of a wrong
/// guess earns the first-try bonus. Nothing is taken away for a wrong
/// guess and nothing restarts by itself.
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key, required this.level});

  final MemoryLevel level;

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  /// Two wrong cards stay open this long (a tap elsewhere ends it sooner).
  static const _mismatchDelay = Duration(milliseconds: 1100);

  /// A beat to see the last pair settle before the result page.
  static const _finishDelay = Duration(milliseconds: 800);

  final _random = math.Random();
  final _matched = <String>{};
  final _faceUp = <int>{};
  final _missed = <String>{};
  final _burst = <int, int>{};
  final _shake = <int, int>{};

  late AudioService _audio;
  late GameScoreStore _store;
  late List<ArabicLetter> _cards;
  late GameScorer _scorer;
  ScoreAward? _award;
  GameResult? _result;
  GameSubmission? _submission;
  _Phase _phase = _Phase.preview;
  int? _first;
  (int, int)? _mismatch;
  int _tries = 0;
  Timer? _previewTimer;
  Timer? _mismatchTimer;
  Timer? _finishTimer;

  int get _pairs => widget.level.pairCount;

  /// Longer to look at when there is more to remember.
  Duration get _previewTime => Duration(seconds: 2 + _pairs);

  static String _id(ArabicLetter letter) => letter.isolatedForm;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<AudioService>();
    _store = context.read<GameScoreStore>();
    _audio.preload([
      kGameCorrectSound,
      for (final letter in widget.level.letters) letter.audioAsset,
    ]);
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _mismatchTimer?.cancel();
    _finishTimer?.cancel();
    Future.microtask(_audio.stop);
    super.dispose();
  }

  void _newGame() {
    _cards = [...widget.level.letters, ...widget.level.letters]
      ..shuffle(_random);
    _scorer = GameScorer(total: _pairs);
    _matched.clear();
    _faceUp.clear();
    _missed.clear();
    _burst.clear();
    _shake.clear();
    _award = null;
    _result = null;
    _submission = null;
    _first = null;
    _mismatch = null;
    _tries = 0;
    _phase = _Phase.preview;
    _previewTimer?.cancel();
    _previewTimer = Timer(_previewTime, _startPlaying);
  }

  void _replay() {
    _mismatchTimer?.cancel();
    _finishTimer?.cancel();
    _audio.stop();
    setState(_newGame);
  }

  void _startPlaying() {
    if (!mounted || _phase != _Phase.preview) return;
    _previewTimer?.cancel();
    _audio.stop();
    setState(() => _phase = _Phase.playing);
  }

  void _finish() {
    if (!mounted) return;
    final result = _scorer.result;
    setState(() {
      _phase = _Phase.finished;
      _result = result;
      _submission = null;
    });
    _store.submit(widget.level.gameKey, result).then((submission) {
      if (mounted && identical(_result, result)) {
        setState(() => _submission = submission);
      }
    });
  }

  void _resolveMismatch() {
    final pending = _mismatch;
    if (pending == null) return;
    _mismatchTimer?.cancel();
    setState(() {
      _faceUp
        ..remove(pending.$1)
        ..remove(pending.$2);
      _mismatch = null;
    });
  }

  void _tap(int index) {
    final letter = _cards[index];
    if (_phase == _Phase.preview) {
      _audio.playLetter(letter);
      return;
    }
    if (_phase != _Phase.playing) return;
    // A tap while two wrong cards are showing turns them back at once.
    if (_mismatch != null) _resolveMismatch();
    if (_matched.contains(_id(letter)) || _faceUp.contains(index)) return;

    final first = _first;
    if (first == null) {
      setState(() {
        _faceUp.add(index);
        _first = index;
      });
      _audio.playLetter(letter);
      return;
    }

    _tries++;
    if (_id(_cards[first]) == _id(letter)) {
      final id = _id(letter);
      final award = _scorer.recordCorrect(firstTry: !_missed.contains(id));
      setState(() {
        _matched.add(id);
        _faceUp.remove(first);
        _first = null;
        _burst[first] = (_burst[first] ?? 0) + 1;
        _burst[index] = (_burst[index] ?? 0) + 1;
        _award = award;
      });
      // One player: the cheer, then the letter's name — never together.
      final sound = letter.audioAsset;
      _audio.playPlaylist([kGameCorrectSound, if (sound != null) sound]);
      if (_matched.length == _pairs) {
        _finishTimer = Timer(_finishDelay, _finish);
      }
    } else {
      _missed
        ..add(_id(_cards[first]))
        ..add(_id(letter));
      _scorer.recordMiss();
      setState(() {
        _faceUp.add(index);
        _first = null;
        _mismatch = (first, index);
        _shake[first] = (_shake[first] ?? 0) + 1;
        _shake[index] = (_shake[index] ?? 0) + 1;
      });
      // Hear what this one was, so the next try is better informed.
      _audio.playLetter(letter);
      _mismatchTimer = Timer(_mismatchDelay, _resolveMismatch);
    }
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
              'Hafıza',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.level.title,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (_phase != _Phase.finished)
            GameStepPill(current: _matched.length, total: _pairs),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child:
                _phase == _Phase.finished
                    ? GameFinishView(
                      title: 'Tebrikler!',
                      message: 'Bütün çiftleri buldun.',
                      summary:
                          _result == null
                              ? null
                              : GameResultSummary(
                                result: _result!,
                                submission: _submission,
                              ),
                      onReplay: _replay,
                      exitLabel: 'Oyun Seç',
                      onExit: () => Navigator.of(context).pop(),
                    )
                    : _buildGame(context),
          ),
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final previewing = _phase == _Phase.preview;
    final maxCard = switch (Responsive.deviceClassOf(context)) {
      DeviceClass.mobile => 120.0,
      DeviceClass.tablet => 170.0,
      DeviceClass.desktop => 190.0,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          GameProgressBar(value: _matched.length / _pairs),
          const SizedBox(height: 8),
          GameScoreStrip(
            points: _scorer.points,
            award: _award,
            instruction:
                previewing
                    ? 'Harfleri ve yerlerini aklında tut. Dokununca sesini dinlersin.'
                    : 'Aynı harfleri bul.',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FitGrid(
              count: _cards.length,
              maxItemSize: maxCard,
              gap: 10,
              itemBuilder: (context, index, size) {
                final letter = _cards[index];
                return MemoryCard(
                  key: ValueKey('card-$index'),
                  letter: letter,
                  size: size,
                  faceUp: previewing || _faceUp.contains(index),
                  matched: _matched.contains(_id(letter)),
                  burstTrigger: _burst[index] ?? 0,
                  shakeTrigger: _shake[index] ?? 0,
                  onTap: () => _tap(index),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Same height in both phases so the cards never change size.
          SizedBox(
            height: 52,
            child: Center(
              child:
                  previewing
                      ? FilledButton.icon(
                        key: const ValueKey('ready'),
                        onPressed: _startPlaying,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Hazırım'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                          minimumSize: const Size(160, 48),
                          textStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      )
                      : Text(
                        'Deneme: $_tries',
                        key: const ValueKey('tries'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
