import '../../../l10n/l10n.dart';
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
import '../../../widgets/game_meadow_background.dart';
import '../widgets/fit_grid.dart';
import '../widgets/game_colors.dart';
import '../widgets/game_progress.dart';
import '../widgets/game_result_summary.dart';
import '../widgets/game_score_strip.dart';
import 'learning/learning_session.dart';
import 'learning/letter_learning.dart';
import 'widgets/draggable_letter.dart';
import 'widgets/fly_back.dart';
import 'widgets/sound_slot.dart';

/// Where the learning path's rounds keep their scores ("Sonuçlarım").
const String kDragDropLearnKey = '$kDragDropGameKey.learn';

/// "Sürükle & Bırak" — the learning path, one small round at a time: a few
/// sound cards and the letters that belong to them. The child taps a card
/// to hear its sound, then drags the matching letter onto it — or taps the
/// letter and then the card. [LearningSession] picks each round's letters
/// and records how every letter went; after a round the child sees what
/// comes next and continues.
class DragDropGameScreen extends StatefulWidget {
  const DragDropGameScreen({
    super.key,
    required this.session,
    this.daily = false,
  });

  final LearningSession session;

  /// Start with the short daily review of older letters.
  final bool daily;

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

  /// Letters involved in a wrong drop, dropped or aimed at (for learning).
  final _missed = <String>{};

  /// Letters dropped somewhere wrong (they lose the first-try points).
  final _missedTiles = <String>{};

  /// Wrong drops on each card (for the hint).
  final _slotMisses = <String, int>{};
  final _mixUps = <(String, String)>[];
  final _flights = <_Flight>[];
  int _flightId = 0;

  late AudioService _audio;
  late GameScoreStore _store;
  late DragDropRound _round;
  late List<ArabicLetter> _slotOrder;
  late List<ArabicLetter> _trayOrder;
  late GameScorer _scorer;
  String? _selected;
  ScoreAward? _award;
  GameResult? _result;
  GameSubmission? _submission;
  StageEvent _event = StageEvent.none;
  Timer? _finishTimer;
  bool _finished = false;
  bool _saving = false;

  static String _id(ArabicLetter letter) => letterIdOf(letter);

  LearningSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _newRound(daily: widget.daily);
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
    for (final letter in _round.letters) letter.audioAsset,
  ]);

  @override
  void dispose() {
    _finishTimer?.cancel();
    Future.microtask(_audio.stop);
    super.dispose();
  }

  void _newRound({bool daily = false}) {
    _round = _session.nextRound(daily: daily);
    _scorer = GameScorer(total: _round.letters.length);
    _placed.clear();
    _returning.clear();
    _burst.clear();
    _shake.clear();
    _missed.clear();
    _missedTiles.clear();
    _slotMisses.clear();
    _mixUps.clear();
    _flights.clear();
    _selected = null;
    _award = null;
    _result = null;
    _submission = null;
    _event = StageEvent.none;
    _slotOrder = List.of(_round.letters)..shuffle(_random);
    _trayOrder = List.of(_round.letters)..shuffle(_random);
  }

  void _continue() {
    _finishTimer?.cancel();
    _audio.stop();
    setState(() {
      _finished = false;
      _newRound();
    });
    _preloadSounds();
  }

  Future<void> _finish() async {
    if (!mounted) return;
    final result = _scorer.result;
    setState(() {
      _finished = true;
      _result = result;
      _saving = true;
    });
    final outcome = RoundOutcome(
      answers: {
        for (final letter in _round.letters)
          _id(letter): LetterAnswer(
            firstTry: !_missed.contains(_id(letter)),
            wrongDrops: _slotMisses[_id(letter)] ?? 0,
          ),
      },
      mixUps: List.of(_mixUps),
      stars: result.stars,
    );
    final event = await _session.complete(_round, outcome);
    final submission = await _store.submit(kDragDropLearnKey, result);
    if (!mounted || !identical(_result, result)) return;
    setState(() {
      _event = event;
      _submission = submission;
      _saving = false;
    });
  }

  bool _hinted(ArabicLetter letter) {
    final after = _round.difficulty.hintAfterMisses;
    if (after == null) return false;
    return (_slotMisses[_id(letter)] ?? 0) >= after;
  }

  void _onLetterDropped(ArabicLetter slot, ArabicLetter dropped) {
    final id = _id(slot);
    _selected = null;
    if (_id(dropped) != id) {
      _missed
        ..add(_id(dropped))
        ..add(id);
      _missedTiles.add(_id(dropped));
      _slotMisses[id] = (_slotMisses[id] ?? 0) + 1;
      _mixUps.add((id, _id(dropped)));
      _scorer.recordMiss();
      setState(() => _shake[id] = (_shake[id] ?? 0) + 1);
      return;
    }
    final award = _scorer.recordCorrect(firstTry: !_missedTiles.contains(id));
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
    if (_placed.length == _round.letters.length) {
      _finishTimer = Timer(_finishDelay, _finish);
    }
  }

  /// Tap a letter, then a card: the same as dragging it there.
  void _onTileTap(ArabicLetter letter) {
    final id = _id(letter);
    setState(() => _selected = _selected == id ? null : id);
  }

  void _onSlotTap(ArabicLetter slot) {
    final selected = _selected;
    if (selected == null || _placed.contains(_id(slot))) {
      _audio.playLetter(slot);
      return;
    }
    final letter = _round.letters.firstWhere((l) => _id(l) == selected);
    _onLetterDropped(slot, letter);
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

  String get _roundTitle => switch (_round.kind) {
    RoundKind.learn => 'Yeni harfler',
    RoundKind.review => 'Karışık tekrar',
    RoundKind.reinforce => 'Pekiştirme',
    RoundKind.mastery => 'Ustalık turu',
    RoundKind.daily => 'Günlük tekrar',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = switch (Responsive.deviceClassOf(context)) {
      DeviceClass.mobile => 900.0,
      DeviceClass.tablet => 1100.0,
      DeviceClass.desktop => 1200.0,
    };
    final stage = math.min(_session.state.group + 1, _session.stageCount);
    return GameScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.t('Sürükle & Bırak'),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              context.t('Aşama {n} / {total} · {title}', {
                'n': stage,
                'total': _session.stageCount,
                'title': _roundTitle,
              }),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (!_finished)
            GameStepPill(current: _placed.length, total: _round.letters.length),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _finished ? _roundDone(context) : _buildGame(),
          ),
        ),
      ),
    );
  }

  String _eventMessage() => switch (_event) {
    StageEvent.learned =>
      'Yeni harfleri öğrendin! Şimdi eskilerle karışık tekrar.',
    StageEvent.groupUnlocked => 'Harika! Yeni harfler açıldı.',
    StageEvent.reinforceAfterPass =>
      'Testi geçtin! Önce zorlandığın harflere kısa bir bakış.',
    StageEvent.reinforceAfterFail =>
      'Biraz daha çalışalım: zorlandığın harfleri birlikte tekrar edelim.',
    StageEvent.retest => 'Şimdi karışık tekrarı bir daha deneyelim.',
    StageEvent.allLearned =>
      'Bütün harfleri öğrendin! Ustalık turları seni bekliyor.',
    StageEvent.dailyDone => 'Günlük tekrarı bitirdin!',
    StageEvent.none => 'Güzel gidiyorsun!',
  };

  Widget _roundDone(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final celebrate =
        _event == StageEvent.groupUnlocked ||
        _event == StageEvent.allLearned ||
        _event == StageEvent.learned;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CelebrationStars(
                    key: ValueKey('stars-${_session.state.rounds}'),
                    count: _result?.stars ?? 0,
                    big: celebrate,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.t('Tur tamamlandı'),
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_saving)
                    Text(
                      context.t(_eventMessage()),
                      key: const ValueKey('stage-message'),
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (_result != null) ...[
                    const SizedBox(height: 12),
                    GameResultSummary(
                      result: _result!,
                      submission: _submission,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('continue-round'),
                    onPressed: _saving ? null : _continue,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(context.t('Devam Et')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(context.t('Ara ver')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      children: [
        GameProgressBar(value: _placed.length / _round.letters.length),
        const SizedBox(height: 8),
        GameScoreStrip(
          points: _scorer.points,
          award: _award,
          instruction: 'Sesi dinle, harfi doğru yere sürükle.',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 6),
          child: Text(
            context.t('Ya da önce harfe, sonra karta dokun.'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
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
      var (maxSlot, maxTile) = switch (Responsive.deviceClassOf(context)) {
        DeviceClass.mobile => (170.0, 130.0),
        DeviceClass.tablet => (250.0, 190.0),
        DeviceClass.desktop => (270.0, 200.0),
      };
      // Kolay: büyük kartlar, geniş bırakma alanları.
      if (_round.difficulty == DragDropDifficulty.easy) {
        maxSlot *= 1.15;
        maxTile *= 1.15;
      }
      final plain = _round.difficulty == DragDropDifficulty.hard;
      final slots = _panel(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: AppColors.divider,
        child: FitGrid(
          count: _slotOrder.length,
          maxItemSize: maxSlot,
          itemBuilder: (context, index, size) {
            final letter = _slotOrder[index];
            final id = _id(letter);
            // Zor: daha az görsel ipucu (bütün kartlar aynı renk).
            final (accent, soft) =
                plain
                    ? GameColors.accents[0]
                    : GameColors.accents[index % GameColors.accents.length];
            return SoundSlot(
              letter: letter,
              size: size,
              accent: accent,
              accentSoft: soft,
              placed: _placed.contains(id),
              burstTrigger: _burst[id] ?? 0,
              shakeTrigger: _shake[id] ?? 0,
              onTap: () => _onSlotTap(letter),
              onLetterDropped: (dropped) => _onLetterDropped(letter, dropped),
            );
          },
        ),
      );
      final tray = _panel(
        color: AppColors.turquoiseSoft.withValues(alpha: 0.7),
        border: AppColors.turquoise.withValues(alpha: 0.35),
        child: FitGrid(
          count: _trayOrder.length,
          maxItemSize: maxTile,
          itemBuilder: (context, index, size) {
            final letter = _trayOrder[index];
            final id = _id(letter);
            final placed = _placed.contains(id);
            final selected = _selected == id;
            final glow = !placed && (selected || _hinted(letter));
            return GestureDetector(
              key: ValueKey('tile-tap-$id'),
              behavior: HitTestBehavior.translucent,
              onTap: placed ? null : () => _onTileTap(letter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow:
                      glow
                          ? [
                            BoxShadow(
                              color: (selected
                                      ? AppColors.turquoise
                                      : AppColors.gold)
                                  .withValues(alpha: 0.6),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ]
                          : const [],
                ),
                child: DraggableLetter(
                  key: _tileKeys.putIfAbsent(
                    id,
                    () => GlobalKey(debugLabel: 'tile-$id'),
                  ),
                  letter: letter,
                  size: size,
                  placed: placed,
                  returning: _returning.contains(id),
                  onDragEnd: (details) => _onDragEnd(letter, details),
                ),
              ),
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

/// Up to three stars that pop in one after another (bigger when a new
/// stage opened).
class _CelebrationStars extends StatelessWidget {
  const _CelebrationStars({super.key, required this.count, required this.big});

  final int count;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 56.0 : 44.0;
    return Semantics(
      label: context.t('{n} yıldız', {'n': count}),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 450 + i * 180),
                curve: Curves.easeOutBack,
                builder:
                    (context, t, child) =>
                        Transform.scale(scale: t.clamp(0.0, 1.2), child: child),
                child: Icon(
                  i < count ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: i == 1 ? size * 1.2 : size,
                  color: i < count ? AppColors.gold : AppColors.divider,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
