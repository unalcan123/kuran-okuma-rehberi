import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../data/drag_drop_game_data.dart';
import '../../../models/arabic_letter.dart';
import '../../../models/game_score.dart';
import '../../../services/audio_service.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../widgets/game_colors.dart';
import '../widgets/game_finish_view.dart';
import '../widgets/game_progress.dart';
import '../widgets/game_result_summary.dart';
import '../widgets/game_score_strip.dart';
import 'widgets/draggable_letter.dart';
import '../widgets/fit_grid.dart';
import 'widgets/fly_back.dart';
import 'widgets/sound_slot.dart';

/// "Sürükle & Bırak" — one small game: a few sound cards and the
/// letters that belong to them. The child taps a card to hear its sound,
/// then drags the matching letter onto it. Same teaching idea as the old
/// Elifba app's letter game. Points come from [GameScorer]: right
/// answers earn, misses only lose the first-try bonus.
///
/// The game ends right after the last letter is placed.
class DragDropGameScreen extends StatefulWidget {
  const DragDropGameScreen({super.key, required this.level});

  final DragDropLevel level;

  @override
  State<DragDropGameScreen> createState() => _DragDropGameScreenState();
}

class _Flight {
  _Flight(this.id, this.letter, this.from, this.to, this.size);

  final int id;
  final ArabicLetter letter;
  final Offset from;
  final Offset to;
  final double size;
}

class _DragDropGameScreenState extends State<DragDropGameScreen> {
  /// A beat to see the last letter settle before the result page.
  static const _finishDelay = Duration(milliseconds: 800);

  final _random = math.Random();
  final _stackKey = GlobalKey();
  final _tileKeys = <String, GlobalKey>{};
  final _placed = <String>{};
  final _returning = <String>{};
  final _burst = <String, int>{};
  final _shake = <String, int>{};
  final _missed = <String>{};
  final _flights = <_Flight>[];
  int _flightId = 0;

  late AudioService _audio;
  late GameScoreStore _store;
  late List<ArabicLetter> _letters;
  late List<ArabicLetter> _slotOrder;
  late List<ArabicLetter> _trayOrder;
  late GameScorer _scorer;
  ScoreAward? _award;
  GameResult? _result;
  GameSubmission? _submission;
  Timer? _finishTimer;
  bool _finished = false;

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
    _preloadSounds();
  }

  void _preloadSounds() => _audio.preload([
    kGameCorrectSound,
    for (final letter in _letters) letter.audioAsset,
  ]);

  @override
  void dispose() {
    _finishTimer?.cancel();
    Future.microtask(_audio.stop);
    super.dispose();
  }

  // Deals the letters (new ones each time for the random game).
  void _newGame() {
    _letters = widget.level.draw(_random);
    _scorer = GameScorer(total: _letters.length);
    _placed.clear();
    _returning.clear();
    _burst.clear();
    _shake.clear();
    _missed.clear();
    _flights.clear();
    _award = null;
    _result = null;
    _submission = null;
    _slotOrder = List.of(_letters)..shuffle(_random);
    _trayOrder = List.of(_letters)..shuffle(_random);
  }

  void _replay() {
    _finishTimer?.cancel();
    _audio.stop();
    setState(() {
      _finished = false;
      _newGame();
    });
    _preloadSounds();
  }

  void _finish() {
    if (!mounted) return;
    final result = _scorer.result;
    setState(() {
      _finished = true;
      _result = result;
      _submission = null;
    });
    _store.submit(widget.level.gameKey, result).then((submission) {
          if (mounted && identical(_result, result)) {
            setState(() => _submission = submission);
          }
        });
  }

  void _onLetterDropped(ArabicLetter slot, ArabicLetter dropped) {
    final id = _id(slot);
    if (_id(dropped) != id) {
      _missed.add(_id(dropped));
      _scorer.recordMiss();
      setState(() => _shake[id] = (_shake[id] ?? 0) + 1);
      return;
    }
    final award = _scorer.recordCorrect(firstTry: !_missed.contains(id));
    setState(() {
      _placed.add(id);
      _burst[id] = (_burst[id] ?? 0) + 1;
      _award = award;
    });
    // One player for everything: the cheer first, then the letter's
    // own recording — never two sounds at once.
    final letterSound = slot.audioAsset;
    _audio.playPlaylist([
      kGameCorrectSound,
      if (letterSound != null) letterSound,
    ]);
    if (_placed.length == _letters.length) {
      _finishTimer = Timer(_finishDelay, _finish);
    }
  }

  void _onDragEnd(ArabicLetter letter, DraggableDetails details) {
    final id = _id(letter);
    if (_placed.contains(id) || !mounted) return;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final tile =
        _tileKeys[id]?.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || tile == null || !stack.attached || !tile.attached) {
      return;
    }
    setState(() {
      _returning.add(id);
      _flights.add(
        _Flight(
          ++_flightId,
          letter,
          stack.globalToLocal(details.offset),
          stack.globalToLocal(tile.localToGlobal(Offset.zero)),
          tile.size.width,
        ),
      );
    });
  }

  void _onFlightDone(_Flight flight) {
    if (!mounted) return;
    setState(() {
      _flights.remove(flight);
      _returning.remove(_id(flight.letter));
    });
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
              'Sürükle & Bırak',
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
          if (!_finished)
            GameStepPill(current: _placed.length, total: _letters.length),
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
                      message: 'Harfleri tamamladın.',
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
                    : _buildGame(),
          ),
        ),
      ),
    );
  }

  Widget _buildGame() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      children: [
        GameProgressBar(value: _placed.length / _letters.length),
        const SizedBox(height: 8),
        GameScoreStrip(
          points: _scorer.points,
          award: _award,
          instruction: 'Sesi dinle, harfi doğru yere sürükle.',
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            key: _stackKey,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _playArea()),
              for (final flight in _flights)
                FlyBack(
                  key: ValueKey(flight.id),
                  from: flight.from,
                  to: flight.to,
                  startScale: DraggableLetter.liftScale,
                  onDone: () => _onFlightDone(flight),
                  child: DraggableLetter.lifted(flight.letter, flight.size),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _playArea() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= constraints.maxHeight * 1.2;
      final (maxSlot, maxTile) = switch (Responsive.deviceClassOf(context)) {
        DeviceClass.mobile => (170.0, 130.0),
        DeviceClass.tablet => (250.0, 190.0),
        DeviceClass.desktop => (270.0, 200.0),
      };
      final slots = _panel(
        color: AppColors.surface.withValues(alpha: 0.8),
        border: AppColors.divider,
        child: FitGrid(
          count: _slotOrder.length,
          maxItemSize: maxSlot,
          itemBuilder: (context, index, size) {
            final letter = _slotOrder[index];
            final id = _id(letter);
            final (accent, soft) =
                GameColors.accents[index % GameColors.accents.length];
            return SoundSlot(
              letter: letter,
              size: size,
              accent: accent,
              accentSoft: soft,
              placed: _placed.contains(id),
              burstTrigger: _burst[id] ?? 0,
              shakeTrigger: _shake[id] ?? 0,
              onTap: () => _audio.playLetter(letter),
              onLetterDropped: (dropped) => _onLetterDropped(letter, dropped),
            );
          },
        ),
      );
      final tray = _panel(
        color: AppColors.turquoiseSoft.withValues(alpha: 0.55),
        border: AppColors.turquoise.withValues(alpha: 0.35),
        child: FitGrid(
          count: _trayOrder.length,
          maxItemSize: maxTile,
          itemBuilder: (context, index, size) {
            final letter = _trayOrder[index];
            final id = _id(letter);
            return DraggableLetter(
              key: _tileKeys.putIfAbsent(
                id,
                () => GlobalKey(debugLabel: 'tile-$id'),
              ),
              letter: letter,
              size: size,
              placed: _placed.contains(id),
              returning: _returning.contains(id),
              onDragEnd: (details) => _onDragEnd(letter, details),
            );
          },
        ),
      );
      const gap = 14.0;
      return wide
          ? Row(
            children: [
              Expanded(child: slots),
              const SizedBox(width: gap),
              Expanded(child: tray),
            ],
          )
          : Column(
            children: [
              Expanded(flex: 11, child: slots),
              const SizedBox(height: gap),
              Expanded(flex: 9, child: tray),
            ],
          );
    },
  );

  Widget _panel({
    required Color color,
    required Color border,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: border),
    ),
    child: child,
  );
}
