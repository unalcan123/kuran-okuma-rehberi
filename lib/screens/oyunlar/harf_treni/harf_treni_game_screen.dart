import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../models/game_score.dart';
import '../../../services/audio_service.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../harf_dedektifi/dedektif_data.dart';
import '../harf_dedektifi/widgets/detective_card.dart';
import '../harf_oyunlari/game_letters.dart';
import '../harf_oyunlari/profil/player_repository.dart';
import '../widgets/fit_grid.dart';
import '../widgets/game_progress.dart';
import '../widgets/game_result_summary.dart';
import '../widgets/game_score_strip.dart';
import 'tren_engine.dart';
import 'tren_progress_store.dart';
import 'widgets/train_view.dart';

/// Harf Treni oyun ekranı: 5 tren. Doğru karta dokununca kart sıradaki boş
/// vagona uçar (dokunarak oynanır; sürükle-bırak yok). Vagonlar dolunca tren
/// istasyona gider, "Sonraki Tren". Pop edilirken `true` → "Oyunlara Dön".
class HarfTreniGameScreen extends StatefulWidget {
  const HarfTreniGameScreen({
    super.key,
    required this.level,
    required this.fonts,
    this.focus = const [],
    this.random,
  });

  final TrainLevel level;

  /// Seviye 4 için yüklendiği doğrulanmış yazı tipleri.
  final List<String> fonts;

  /// "Zorlandıklarımı Çalış": turların çoğu bu harfler.
  final List<int> focus;
  final math.Random? random;

  @override
  State<HarfTreniGameScreen> createState() => _HarfTreniGameScreenState();
}

class _Flight {
  _Flight(this.controller, this.entry);
  final AnimationController controller;
  final OverlayEntry entry;
}

class _HarfTreniGameScreenState extends State<HarfTreniGameScreen>
    with TickerProviderStateMixin {
  late final math.Random _random = widget.random ?? math.Random();
  late AudioService _audio;
  late GameScoreStore _store;
  final _progress = TrainProgressStore();
  bool _preloaded = false;

  TrainSession? _session;
  int _serial = 0;
  late List<int> _focus = widget.focus;

  // Tur görünümü
  final Set<int> _landed = {};
  final Map<int, GlobalKey> _cardKeys = {};
  List<GlobalKey> _wagonKeys = [];
  final List<_Flight> _flights = [];
  final Map<int, int> _shake = {};
  String? _message;
  bool _messageWrong = false;
  ScoreAward? _award;

  late final AnimationController _depart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..addStatusListener((s) {
    if (s == AnimationStatus.completed) _arrived();
  });
  bool _departing = false;
  bool _departed = false;

  bool _muted = false;
  bool _showDemo = false;
  bool _finished = false;
  bool _saved = false;
  bool _locked = false;
  GameResult? _result;
  GameSubmission? _submission;
  Future<void>? _pendingSave;

  Timer? _autoPlay;
  Timer? _unlock;
  Timer? _departDelay;

  TrainLevel get _level => widget.level;

  @override
  void initState() {
    super.initState();
    _progress.isMuted().then((m) {
      if (mounted) setState(() => _muted = m);
    });
    _progress.demoSeen().then((seen) {
      if (mounted && !seen) setState(() => _showDemo = true);
    });
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<AudioService>();
    _store = context.read<GameScoreStore>();
    if (!_preloaded) {
      _preloaded = true;
      _audio.preload([for (final l in kDetectiveLetters) l.audio]);
    }
  }

  @override
  void dispose() {
    // Animasyon sırasında çıkılsa da hiçbir şey arkada kalmaz.
    _autoPlay?.cancel();
    _unlock?.cancel();
    _departDelay?.cancel();
    _clearFlights();
    _depart.dispose();
    Future.microtask(_audio.stop);
    super.dispose();
  }

  void _clearFlights() {
    for (final f in _flights) {
      f.entry.remove();
      f.controller.dispose();
    }
    _flights.clear();
  }

  String? _profileId() {
    try {
      return context.read<PlayerRepository>().activePlayer?.id;
    } catch (_) {
      return null;
    }
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _lock([Duration d = const Duration(milliseconds: 450)]) {
    _locked = true;
    _unlock?.cancel();
    _unlock = Timer(d, () {
      if (mounted) setState(() => _locked = false);
    });
  }

  // ---- oturum --------------------------------------------------------------

  Future<void> _start({List<int>? focus}) async {
    final serial = ++_serial;
    if (focus != null) _focus = focus;
    _autoPlay?.cancel();
    _departDelay?.cancel();
    _clearFlights();
    _depart.reset();
    setState(() {
      _session = null;
      _finished = false;
      _saved = false;
      _result = null;
      _submission = null;
      _award = null;
    });
    await _pendingSave;
    if (!mounted || serial != _serial) return;
    final weights = await _progress.weightsFor(_level, profileId: _profileId());
    if (!mounted || serial != _serial) return;
    final factory = TrainRoundFactory(
      _random,
      fonts: widget.fonts,
      baseFont: AppTextTheme.arabicFontFamily,
    );
    final targets = factory.pickTargets(
      _level,
      weights: weights,
      focus: _focus,
    );
    setState(() {
      _session = TrainSession(
        level: _level,
        targets: targets,
        factory: factory,
      );
      _enterRound();
    });
  }

  // setState içinde.
  void _enterRound() {
    final s = _session!;
    _landed.clear();
    _cardKeys
      ..clear()
      ..addAll({for (final c in s.current.round.cards) c.id: GlobalKey()});
    _wagonKeys = [for (var i = 0; i < s.current.wagons; i++) GlobalKey()];
    _shake.clear();
    _message = null;
    _messageWrong = false;
    _departing = false;
    _departed = false;
    _depart.reset();
    _lock();
    _autoPlay?.cancel();
    _autoPlay = Timer(const Duration(milliseconds: 450), _playTarget);
  }

  DetectiveLetter get _target => letterById(_session!.current.round.targetId);

  void _playTarget() {
    if (_muted || !mounted || _session == null) return;
    final audio = _target.audio;
    // Ses yoksa/çalınamazsa AudioService hatayı yutar, oyun sürer.
    if (audio != null) _audio.playAsset(audio);
  }

  Future<void> _toggleMute() async {
    final muted = !_muted;
    setState(() => _muted = muted);
    if (muted) {
      _autoPlay?.cancel();
      await _audio.stop();
    }
    await _progress.setMuted(muted);
  }

  void _tap(int cardId) {
    final s = _session;
    if (s == null || _locked || _showDemo || _finished) return;
    final state = s.current;
    final result = s.tap(cardId);
    switch (result) {
      case TrainTap.placed:
        final wagonIndex = state.placed.length - 1;
        _autoPlay?.cancel();
        _playTarget(); // tek oynatıcı: önceki ses kesilir, üst üste binmez
        setState(() {
          _award = ScoreAward(
            base: kTrainPointsPerCard,
            firstTryBonus: 0,
            streakBonus: 0,
          );
          _message =
              state.complete
                  ? 'Bütün vagonlar doldu!'
                  : 'Harika! Vagona yerleşti.';
          _messageWrong = false;
        });
        _fly(state.round.card(cardId), wagonIndex);
      case TrainTap.alreadyPlaced:
        setState(() {
          _message = 'Bu kart zaten vagonda.';
          _messageWrong = false;
        });
      case TrainTap.wrong:
      case TrainTap.repeatWrong:
        setState(() {
          _shake[cardId] = (_shake[cardId] ?? 0) + 1;
          _message = _wrongMessage(state.round.card(cardId));
          _messageWrong = true;
        });
      case TrainTap.ignored:
        break;
    }
  }

  String _wrongMessage(TrainCard picked) {
    final p = letterById(picked.letterId);
    final t = _target;
    if (_level == TrainLevel.l3) {
      final pp = dotPhrase(p.id);
      final tp = dotPhrase(t.id);
      if (pp != null && tp != null) {
        return 'Bir daha bakalım! Seçtiğin ${p.name}: $pp. '
            'Aradığımız ${t.name}: $tp.';
      }
    }
    if (_level == TrainLevel.l4) {
      return 'Bir daha bakalım! Bu ${p.name} harfi. Yazı değişse de harfin şekline bak.';
    }
    return 'Bir daha bakalım! Bu ${p.name} harfi.';
  }

  /// Kart sıradaki vagona uçar; varınca vagonda görünür. Azaltılmış harekette
  /// hemen yerleşir.
  void _fly(TrainCard card, int wagonIndex) {
    void land() {
      if (!mounted) return;
      setState(() => _landed.add(card.id));
      if (_session!.current.complete &&
          _landed.length >= _session!.current.wagons) {
        _startDeparture();
      }
    }

    final from = _rectOf(_cardKeys[card.id]);
    final to =
        wagonIndex < _wagonKeys.length ? _rectOf(_wagonKeys[wagonIndex]) : null;
    final overlay = Overlay.maybeOf(context);
    if (_reduceMotion || from == null || to == null || overlay == null) {
      land();
      return;
    }
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    final size = math.min(from.width, from.height);
    final entry = OverlayEntry(
      builder:
          (context) => AnimatedBuilder(
            animation: curve,
            builder: (context, _) {
              final r =
                  Rect.lerp(
                    Rect.fromCenter(
                      center: from.center,
                      width: size,
                      height: size,
                    ),
                    Rect.fromCenter(
                      center: to.center,
                      width: to.width * 0.8,
                      height: to.width * 0.8,
                    ),
                    curve.value,
                  )!;
              return Positioned.fromRect(
                rect: r,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.turquoiseSoft,
                      borderRadius: BorderRadius.circular(r.width * 0.16),
                      border: Border.all(color: AppColors.turquoise, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          card.text,
                          textDirection: TextDirection.rtl,
                          textScaler: TextScaler.noScaling,
                          style: singleGlyphStyle(
                            40,
                            color: AppColors.turquoise,
                          ).copyWith(fontFamily: card.font),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
    final flight = _Flight(controller, entry);
    _flights.add(flight);
    controller.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      entry.remove();
      _flights.remove(flight);
      controller.dispose();
      land();
    });
    overlay.insert(entry);
    controller.forward();
  }

  Rect? _rectOf(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _startDeparture() {
    if (_departing) return;
    _departing = true;
    if (_reduceMotion) {
      _arrived();
      return;
    }
    _departDelay = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _depart.forward(from: 0);
    });
  }

  void _arrived() {
    if (!mounted) return;
    setState(() {
      _departed = true;
      _message = 'Tren istasyona vardı!';
      _messageWrong = false;
      _lock();
    });
  }

  void _hint() {
    final s = _session;
    if (s == null || _locked) return;
    final id = s.hint(_random);
    if (id == null) return;
    setState(() {
      _message = 'İpucu: Büyüteçli karta bak.';
      _messageWrong = false;
    });
  }

  void _next() {
    final s = _session;
    if (s == null || !_departed || _locked) return;
    if (s.isLast) {
      _finish();
      return;
    }
    _audio.stop();
    setState(() {
      s.next();
      _enterRound();
    });
  }

  void _finish() {
    final s = _session!;
    s.finish();
    final result = GameResult(
      points: s.points,
      firstTry: s.countOf(TrainFind.firstTry),
      total: s.placedCount,
    );
    setState(() {
      _finished = true;
      _result = result;
      _lock();
    });
    // Tamamlanan oturum bir kez kaydedilir.
    if (_saved) return;
    _saved = true;
    final serial = _serial;
    _store.submit(_level.gameKey, result).then((sub) {
      if (mounted && serial == _serial) setState(() => _submission = sub);
    });
    _pendingSave = _progress.applySession(
      _level,
      profileId: _profileId(),
      struggled: s.struggledTargets,
      clean: s.cleanTargets,
    );
  }

  void _closeDemo() {
    setState(() => _showDemo = false);
    _progress.setDemoSeen();
  }

  // ---- arayüz ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final s = _session;
    final maxWidth = switch (Responsive.deviceClassOf(context)) {
      DeviceClass.mobile => 900.0,
      DeviceClass.tablet => 1000.0,
      DeviceClass.desktop => 1100.0,
    };
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Harf Treni',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Seviye ${_level.number} · ${_level.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('mute-button'),
            tooltip: _muted ? 'Sesi aç' : 'Sesi kapat',
            onPressed: _toggleMute,
            icon: Icon(
              _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: AppColors.navy,
            ),
          ),
          if (s != null && !_finished)
            GameStepPill(current: s.index + 1, total: s.count),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child:
                s == null
                    ? const Center(child: CircularProgressIndicator())
                    : _finished
                    ? _summary(context, s)
                    : Stack(
                      children: [
                        Positioned.fill(child: _game(context, s)),
                        if (_showDemo)
                          Positioned.fill(
                            child: _Demo(
                              reduceMotion: _reduceMotion,
                              onClose: _closeDemo,
                            ),
                          ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Widget _game(BuildContext context, TrainSession s) {
    final state = s.current;
    final textTheme = Theme.of(context).textTheme;
    final visiblePlaced = [
      for (final id in state.placed)
        if (_landed.contains(id)) state.round.card(id),
    ];
    final train = AnimatedBuilder(
      animation: _depart,
      builder:
          (context, _) => TrainView(
            key: ValueKey('train-$_serial-${s.index}'),
            targetChar: _target.char,
            targetName: _target.name,
            wagons: state.wagons,
            placed: visiblePlaced,
            wagonKeys: _wagonKeys,
            onListen: _playTarget,
            muted: _muted,
            departure: Curves.easeInCubic.transform(_depart.value),
          ),
    );
    final progress = Row(
      children: [
        Container(
          key: const ValueKey('wagon-progress'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.turquoiseSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${state.placed.length} / ${state.wagons} vagon hazır',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_target.name} harfini bul',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
    final message = _MessageLine(text: _message, wrong: _messageWrong);
    final grid = FitGrid(
      count: state.round.cards.length,
      maxItemSize: switch (Responsive.deviceClassOf(context)) {
        DeviceClass.mobile => 140.0,
        _ => 190.0,
      },
      gap: 10,
      itemBuilder: (context, i, size) {
        final card = state.round.cards[i];
        final placed = state.placed.contains(card.id);
        return KeyedSubtree(
          key: _cardKeys[card.id],
          child: Opacity(
            opacity: placed ? 0.35 : 1,
            child: DetectiveCard(
              key: ValueKey('card-${card.id}'),
              text: card.text,
              fontFamily: card.font,
              size: size,
              reduceMotion: _reduceMotion,
              semanticLabel: 'Kart ${i + 1}${placed ? ', vagonda' : ''}',
              state:
                  placed
                      ? DetectiveCardState.found
                      : state.hintedId == card.id
                      ? DetectiveCardState.hinted
                      : state.wrong.contains(card.id)
                      ? DetectiveCardState.wrong
                      : DetectiveCardState.idle,
              shakeTrigger: _shake[card.id] ?? 0,
              onTap: () => _tap(card.id),
            ),
          ),
        );
      },
    );
    final action = SizedBox(
      height: 52,
      child: Center(child: _action(context, s)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          GameProgressBar(value: (s.index + (_departed ? 1 : 0)) / s.count),
          const SizedBox(height: 6),
          GameScoreStrip(
            points: s.points,
            award: _award,
            instruction: 'Aynı harfleri bul, vagonları doldur!',
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                // Alçak/geniş ekranda tren solda, kartlar sağda.
                if (c.maxWidth > c.maxHeight * 1.3) {
                  final left = c.maxWidth * 11 / 21 - 8;
                  return Row(
                    children: [
                      SizedBox(
                        width: left,
                        // Çok alçak ekranda sol sütun orantılı küçülür
                        // (harfler kesilmez, taşma olmaz).
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: left,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                train,
                                const SizedBox(height: 4),
                                progress,
                                const SizedBox(height: 6),
                                message,
                                const SizedBox(height: 8),
                                action,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: grid),
                    ],
                  );
                }
                return Column(
                  children: [
                    train,
                    const SizedBox(height: 4),
                    progress,
                    const SizedBox(height: 6),
                    message,
                    const SizedBox(height: 6),
                    Expanded(child: grid),
                    const SizedBox(height: 10),
                    action,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, TrainSession s) {
    final state = s.current;
    final style = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    if (_departed) {
      return FilledButton.icon(
        key: const ValueKey('next-train-button'),
        autofocus: true,
        onPressed: _locked ? null : _next,
        icon: Icon(s.isLast ? Icons.flag_rounded : Icons.train_rounded),
        label: Text(s.isLast ? 'Sonuçları Gör' : 'Sonraki Tren'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          minimumSize: const Size(220, 50),
          textStyle: style,
        ),
      );
    }
    if (state.complete) return const SizedBox.shrink();
    return state.hintSuggested
        ? FilledButton.icon(
          key: const ValueKey('hint-button'),
          onPressed: state.hintedId != null ? null : _hint,
          icon: const Icon(Icons.lightbulb_rounded),
          label: const Text('İpucu'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            minimumSize: const Size(160, 50),
            textStyle: style,
          ),
        )
        : OutlinedButton.icon(
          key: const ValueKey('hint-button'),
          onPressed: state.hintedId != null ? null : _hint,
          icon: const Icon(Icons.lightbulb_outline_rounded),
          label: const Text('İpucu'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(140, 46),
            textStyle: style?.copyWith(fontWeight: FontWeight.w700),
          ),
        );
  }

  Widget _summary(BuildContext context, TrainSession s) {
    final textTheme = Theme.of(context).textTheme;
    final weak = s.weakLetters();
    final line = textTheme.titleMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return Center(
      child: AbsorbPointer(
        absorbing: _locked,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.train_rounded,
                  size: 56,
                  color: AppColors.turquoise,
                ),
                const SizedBox(height: 6),
                Text(
                  'Bütün trenler istasyonda!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.trainsDone} tren dolduruldu.',
                  key: const ValueKey('trains-done'),
                  textAlign: TextAlign.center,
                  style: line,
                ),
                const SizedBox(height: 14),
                GameResultSummary(result: _result!, submission: _submission),
                const SizedBox(height: 8),
                Text(
                  'Tekrar deneyerek: ${s.countOf(TrainFind.afterRetry)} · '
                  'İpucuyla: ${s.countOf(TrainFind.withHint)}',
                  key: const ValueKey('find-kinds'),
                  textAlign: TextAlign.center,
                  style: line,
                ),
                if (weak.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tekrar çalışalım',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in weak)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                letterById(id).char,
                                textScaler: TextScaler.noScaling,
                                style: singleGlyphStyle(30),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                letterById(id).name,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton.icon(
                  key: const ValueKey('replay-button'),
                  onPressed: () => _start(focus: const []),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Tekrar Oyna'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
                if (weak.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    key: const ValueKey('practice-button'),
                    onPressed: () => _start(focus: weak),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Zorlandıklarımı Çalış'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldSoft,
                      foregroundColor: AppColors.navy,
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const ValueKey('exit-button'),
                  onPressed: () => Navigator.of(context).pop(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: const Text('Oyunlara Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageLine extends StatelessWidget {
  const _MessageLine({required this.text, required this.wrong});

  final String? text;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final t = text;
    return SizedBox(
      height: 44,
      child:
          t == null
              ? null
              : Semantics(
                liveRegion: true,
                child: Container(
                  key: const ValueKey('message'),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color:
                        wrong ? AppColors.skyBlueSoft : AppColors.turquoiseSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        wrong
                            ? Icons.search_rounded
                            : Icons.check_circle_rounded,
                        color: wrong ? AppColors.navySoft : AppColors.turquoise,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

/// İlk kullanımda kısa, atlanabilir örnek: bir kart vagona uçar.
class _Demo extends StatefulWidget {
  const _Demo({required this.reduceMotion, required this.onClose});

  final bool reduceMotion;
  final VoidCallback onClose;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('demo'),
      color: AppColors.navy.withValues(alpha: 0.55),
      child: LayoutBuilder(
        builder: (context, c) {
          final from = Offset(c.maxWidth * 0.5, c.maxHeight * 0.72);
          final to = Offset(c.maxWidth * 0.62, c.maxHeight * 0.2);
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t =
                  widget.reduceMotion
                      ? 1.0
                      : Curves.easeInOut.transform(
                        (_c.value * 1.4).clamp(0.0, 1.0),
                      );
              final p = Offset.lerp(from, to, t)!;
              return Stack(
                children: [
                  // Hedef vagon
                  Positioned(
                    left: to.dx - 34,
                    top: to.dy - 34,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                    ),
                  ),
                  // Uçan kart + el
                  Positioned(
                    left: p.dx - 30,
                    top: p.dy - 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.turquoise,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ب',
                        textScaler: TextScaler.noScaling,
                        style: singleGlyphStyle(34),
                      ),
                    ),
                  ),
                  if (!widget.reduceMotion && t < 0.1)
                    Positioned(
                      left: from.dx + 6,
                      top: from.dy + 10,
                      child: const Icon(
                        Icons.touch_app_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Doğru karta dokun, vagona gitsin!',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const ValueKey('demo-close'),
                          autofocus: true,
                          onPressed: widget.onClose,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.turquoise,
                            minimumSize: const Size(180, 50),
                          ),
                          child: const Text('Anladım'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
