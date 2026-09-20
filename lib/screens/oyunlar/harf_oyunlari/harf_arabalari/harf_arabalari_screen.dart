import 'dart:math' as math;

import '../game_texts.dart';
import '../game_letters.dart';
import '../game_panels.dart';
import '../letter_game_runner.dart';
import '../profil/player_models.dart';
import '../profil/player_picker.dart';
import '../profil/player_repository.dart';
import '../profil/record_result.dart';
import '../profil/skor_tablosu_sayfasi.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/game_score.dart';

import 'harf_arabalari_engine.dart';
import 'harf_arabalari_painters.dart';

/// Oyun 6 — Harf Arabaları.
///
/// Çocuk duyduğu harfi, soldan sağa geçen arabaların üzerindeki harflerden bulup
/// doğru arabaya dokunarak yakalar. Kurallar ortak [LetterGameCore]'da, ticker/
/// yaşam döngüsü/hedef sesi [LetterGameRunner]'dadır (Bul & Patlat ile ortak).
class HarfArabalariOyunu extends StatefulWidget {
  static String route = 'HarfArabalariOyunu';

  const HarfArabalariOyunu({super.key, this.random});

  /// Yalnızca test: deterministik rastgelelik.
  final math.Random? random;

  @override
  State<HarfArabalariOyunu> createState() => HarfArabalariOyunuState();
}

class HarfArabalariOyunuState extends State<HarfArabalariOyunu>
    with
        WidgetsBindingObserver,
        SingleTickerProviderStateMixin,
        LetterGameRunner<HarfArabalariOyunu> {
  /// Kısa, yumuşak başarı sesi (mevcut 2 sn'lik kutlama sesi sık doğru cevapta
  /// harf sesiyle çakışırdı).
  static const String _catchEffect = 'audio/oyunlar/car_catch.wav';

  static const Color _bgTop = Color(0xFFEAF3E8);
  static const Color _bgBottom = Color(0xFFD6E6EC);
  static const Color _ink = kGameInk;

  HarfArabalariEngine? _engine;
  bool _loading = true;
  bool _loadFailed = false;
  Size _area = Size.zero;
  int _bestBefore = 0;
  String? _resultPlayer;

  @visibleForTesting
  HarfArabalariEngine? get engineForTest => _engine;

  @override
  bool get gameRunning => _engine?.status == HaStatus.running;

  @override
  GameLetter? get currentTarget => _engine?.target;

  @override
  void initState() {
    super.initState();
    audio.preload([_catchEffect]);
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    var letters = <GameLetter>[];
    try {
      letters = await loadGameLetters();
    } catch (e) {
      debugPrint('HarfArabalari: harfler yüklenemedi — $e');
    }
    if (!mounted) return;
    if (letters.length < 6) {
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    audio.preload(letters.map((l) => l.audio));
    setState(() {
      _engine = HarfArabalariEngine(letters: letters, random: widget.random);
      _loading = false;
    });
  }

  // ---- oyun akışı -----------------------------------------------------------

  Future<void> _onStartPressed() async {
    await ensureActivePlayer(context);
    if (mounted) _startGame();
  }

  void _startGame() {
    final engine = _engine;
    if (engine == null || _area.isEmpty) return;
    engine.resize(_area.width, _area.height);
    engine.start();
    _resultPlayer = null;
    _handleEvents(); // ilk hedef + ses
    startRunner();
    setState(() {});
  }

  @override
  void onRunnerFrame(double dt) {
    final engine = _engine;
    if (engine == null) return;
    if (dt > 0) engine.tick(dt);
    _handleEvents();
  }

  void _handleEvents() {
    final engine = _engine;
    if (engine == null) return;
    for (final event in engine.takeEvents()) {
      switch (event) {
        case HaTargetChanged():
          speakLater(event.letter, event.afterCatch ? 420 : 250);
        case HaCaught():
          // Efekt kanalı ayrı: konuşma sesini kesmez.
          audio.playEffect(_catchEffect);
        case HaWrongTap():
        case HaTargetMissed():
          break;
        case HaGameOver():
          _onGameOver();
      }
    }
  }

  void _onCarTap(int id) {
    final engine = _engine;
    if (engine == null || !gameRunning) return;
    engine.tap(id);
    _handleEvents();
    frame.value++;
  }

  void _onGameOver() {
    stopRunner();
    final engine = _engine!;
    recordFinishedGame(
      context,
      gameId: GameIds.harfArabalari,
      storeKey: GameIds.harfArabalari,
      firstTry: engine.core.firstTryCorrect,
      score: engine.score,
      correct: engine.correct,
      wrong: engine.wrongTaps,
      missed: engine.missedTargets,
      totalItems: engine.spawned,
    ).then((best) {
      if (mounted) setState(() => _bestBefore = best);
    });
    _resultPlayer = context.read<PlayerRepository>().activePlayer?.displayName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  // ---- arayüz ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = const GameTexts();
    final compact = MediaQuery.sizeOf(context).height < 480;

    return Scaffold(
      backgroundColor: _bgBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              // Geniş ekranda arabaların geçiş süresi uzamasın.
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  _buildHeader(l, compact),
                  Expanded(child: _buildPlayArea(l)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GameTexts l, bool compact) {
    final engine = _engine;

    Widget stats() => ListenableBuilder(
      listenable: frame,
      builder: (context, _) {
        final remaining = engine?.remainingSeconds ?? 120;
        final mm = remaining ~/ 60;
        final ss = (remaining % 60).toString().padLeft(2, '0');
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l.score} ${engine?.score ?? 0}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 20),
              // Süre yalnızca bilgi: sakin renk, büyük/kırmızı geri sayım yok.
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: _ink.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 3),
              Text(
                '$mm:$ss',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink.withValues(alpha: 0.8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );

    final listen = TextButton.icon(
      onPressed: gameRunning ? replayTarget : null,
      icon: const Icon(Icons.volume_up_rounded, size: 20),
      label: Text(l.bpListenAgain),
      style: TextButton.styleFrom(
        foregroundColor: _ink,
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );

    final back = IconButton(
      tooltip: l.back,
      icon: const Icon(Icons.arrow_back_rounded, color: _ink),
      onPressed: () => Navigator.of(context).maybePop(),
    );
    final title = Text(
      l.haGame,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: _ink,
      ),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
        child: Row(
          children: [
            back,
            Flexible(flex: 2, child: title),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: Center(child: stats())),
            listen,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 4),
      child: Column(
        children: [
          Row(children: [back, Expanded(child: title)]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: stats()),
                ),
              ],
            ),
          ),
          Row(
            children: [
              listen,
              Flexible(
                child: Text(
                  l.bpListenAndFind,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: _ink.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayArea(GameTexts l) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final engine = _engine;
    if (_loadFailed || engine == null) {
      return const Center(child: Icon(Icons.error_outline, size: 48));
    }

    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        if (size != _area) {
          _area = size;
          engine.resize(size.width, size.height);
        }
        return ClipRect(
          child: Stack(
            children: [
              // Sade yol (şerit sayısı değişmedikçe yeniden çizilmez).
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: RoadPainter(engine.lanes)),
                ),
              ),
              // Arabalar: yalnızca bu katman her karede yeniden kurulur.
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: frame,
                  builder:
                      (context, _) => Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          for (final c in engine.cars) _buildCar(c, engine),
                        ],
                      ),
                ),
              ),
              // "+puan" ve ♪: dokunuşları engellemez.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CatchFxPainter(engine.floats, repaint: frame),
                  ),
                ),
              ),
              if (engine.status == HaStatus.ready)
                GameIntroPanel(
                  title: l.haGame,
                  description: l.haDesc,
                  onStart: _onStartPressed,
                ),
              if (engine.status == HaStatus.over) _buildResult(l, engine),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCar(HaCar c, HarfArabalariEngine engine) {
    final shakeDx = c.shake > 0 ? math.sin(c.shake * 34) * 8 * c.shake : 0.0;
    final color = kCarColors[c.colorIndex % kCarColors.length];
    final top = c.lane * engine.laneHeight + (engine.laneHeight - c.height) / 2;

    Widget car = SizedBox(
      width: c.width,
      height: c.height,
      child: RepaintBoundary(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: CarPainter(color))),
            // Büyük, net harf plakası (kapı üstünde yuvarlak etiket).
            Positioned(
              left: c.width * 0.5 - c.height * 0.36,
              top: c.height * 0.5 - c.height * 0.36,
              width: c.height * 0.72,
              height: c.height * 0.72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFFDF7),
                  border: Border.all(
                    color: kCarLetterColor.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: c.height * 0.5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      // Harf tek Text: birleşim ve harekeler bozulmaz.
                      child: Text(
                        c.letter.char,
                        textDirection: TextDirection.rtl,
                        style: lessonArabicStyle(
                          c.height * 0.62,
                          color: kCarLetterColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (c.caught) {
      car = Opacity(
        opacity: (1 - c.caughtAge / HaCar.caughtLifetime).clamp(0.0, 1.0),
        child: car,
      );
    }
    return Positioned(
      key: ValueKey(c.id),
      left: 0,
      top: 0,
      child: Transform.translate(
        offset: Offset(c.x + shakeDx, top),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // onTapDown: araba hareket ettiği için parmak değdiği anda tepki.
            onTapDown: (_) => _onCarTap(c.id),
            child: car,
          ),
        ),
      ),
    );
  }

  Widget _buildResult(GameTexts l, HarfArabalariEngine e) {
    final best = math.max(_bestBefore, e.score);
    return GameResultPanel(
      title: l.haCompleted,
      playerName: _resultPlayer,
      stars:
          GameResult(
            points: e.score,
            firstTry: e.core.firstTryCorrect,
            total: math.max(1, e.correct),
          ).stars,
      stats: [
        (l.score, '${e.score}'),
        (l.bpCorrect, '${e.correct}'),
        (l.haCars, '${e.spawned}'),
        (l.haMissedTarget, '${e.missedTargets}'),
        (l.haWrong, '${e.wrongTaps}'),
        (l.bpAccuracy, '%${e.accuracyPercent}'),
        (l.bpBest, '$best'),
      ],
      footer: '',
      onReplay: _startGame,
      onBack: () => Navigator.of(context).maybePop(),
      onLeaderboard:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => const SkorTablosuSayfasi(
                    initialGameId: GameIds.harfArabalari,
                  ),
            ),
          ),
    );
  }
}
