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
import 'package:shared_preferences/shared_preferences.dart';

import 'bul_patlat_engine.dart';
import 'bul_patlat_painters.dart';

/// Oyun 5 — Bul & Patlat.
///
/// Çocuk duyduğu harfi, aşağıdan yükselen balonların arasından bulup patlatır.
/// Oyun mantığı [BulPatlatEngine]'dedir (kurallar ortak [LetterGameCore]'da);
/// ticker/yaşam döngüsü/hedef sesi [LetterGameRunner]'dan gelir.
class BulPatlatOyunu extends StatefulWidget {
  static String route = 'BulPatlatOyunu';

  const BulPatlatOyunu({super.key, this.random});

  /// Yalnızca test: deterministik rastgelelik.
  final math.Random? random;

  @override
  State<BulPatlatOyunu> createState() => BulPatlatOyunuState();
}

class BulPatlatOyunuState extends State<BulPatlatOyunu>
    with
        WidgetsBindingObserver,
        SingleTickerProviderStateMixin,
        LetterGameRunner<BulPatlatOyunu> {
  static const String _popEffect = 'audio/oyunlar/balloon_pop.wav';
  static const String _levelKey = 'bul_patlat_level_v1';

  static const Color _bgTop = Color(0xFFE8F4F1);
  static const Color _bgBottom = Color(0xFFCFE6EC);
  static const Color _ink = kGameInk;

  BulPatlatEngine? _engine;
  bool _loading = true;
  bool _loadFailed = false;
  Size _area = Size.zero;
  int _bestBefore = 0;
  String? _resultPlayer;

  /// Seçili seviye (1 yavaş, 2 biraz hızlı, 3 hızlı); cihazda hatırlanır.
  int _level = 2;

  @visibleForTesting
  BulPatlatEngine? get engineForTest => _engine;

  @override
  bool get gameRunning => _engine?.status == BpStatus.running;

  @override
  GameLetter? get currentTarget => _engine?.target;

  @override
  void initState() {
    super.initState();
    audio.preload([_popEffect]);
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    var letters = <BpLetter>[];
    try {
      letters = await loadGameLetters();
    } catch (e) {
      debugPrint('BulPatlat: harfler yüklenemedi — $e');
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
    try {
      final prefs = await SharedPreferences.getInstance();
      _level = (prefs.getInt(_levelKey) ?? 2).clamp(
        BulPatlatEngine.minLevel,
        BulPatlatEngine.maxLevel,
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _engine = BulPatlatEngine(letters: letters, random: widget.random);
      _loading = false;
    });
  }

  // ---- oyun akışı -----------------------------------------------------------

  /// BAŞLA: aktif oyuncu yoksa bir kez "Kim oynuyor?" sorulur, sonra oyun başlar.
  Future<void> _onStartPressed() async {
    await ensureActivePlayer(context);
    if (mounted) _startGame();
  }

  Future<void> _setLevel(int level) async {
    setState(() => _level = level);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_levelKey, level);
    } catch (_) {}
  }

  Widget _levelPicker(GameTexts l) => GameLevelPicker(
    level: _level,
    onChanged: _setLevel,
    levelWord: l.bpLevel,
    labels: [l.bpLevel1, l.bpLevel2, l.bpLevel3],
  );

  void _startGame() {
    final engine = _engine;
    if (engine == null || _area.isEmpty) return;
    engine.resize(_area.width, _area.height);
    engine.start(level: _level);
    _resultPlayer = null;
    _handleEvents(); // ilk hedef + ses
    startRunner();
    setState(() {}); // başlangıç/sonuç panelini kapat
  }

  @override
  void onRunnerFrame(double dt) {
    final engine = _engine;
    if (engine == null) return;
    if (dt > 0) engine.tick(dt);
    _handleEvents(); // bitiş olayı dahil: ticker'ı durdurup sonucu gösterir
  }

  void _handleEvents() {
    final engine = _engine;
    if (engine == null) return;
    for (final event in engine.takeEvents()) {
      switch (event) {
        case BpTargetChanged():
          // Doğru balon az önce patladıysa pop sesi bitsin diye ses biraz gecikir.
          speakLater(event.letter, event.afterPop ? 420 : 200);
        case BpPopped():
          // Efekt kanalı ayrı: konuşma sesini kesmez.
          audio.playEffect(_popEffect);
        case BpWrongTap():
        case BpTargetMissed():
          break;
        case BpGameOver():
          _onGameOver();
      }
    }
  }

  void _onBalloonTap(int id) {
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
      gameId: GameIds.bulPatlat,
      storeKey: '${GameIds.bulPatlat}.l${engine.level}',
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
    // Sonuç panelini göster.
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
              // Geniş ekranda (web/masaüstü/tablet yatay) balonlar dağılmasın.
              constraints: const BoxConstraints(maxWidth: 900),
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
        final missed = engine?.missedTargets ?? 0;
        final maxMissed = engine?.maxMissed ?? 5;
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
              const SizedBox(width: 18),
              Text(
                '${l.bpMissed} ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink.withValues(alpha: 0.75),
                ),
              ),
              for (var i = 0; i < maxMissed; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < missed ? Icons.circle : Icons.circle_outlined,
                    size: 12,
                    color:
                        i < missed
                            ? const Color(0xFFD08A70)
                            : _ink.withValues(alpha: 0.4),
                  ),
                ),
              const SizedBox(width: 18),
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
      l.bpGame,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: _ink,
      ),
    );

    if (compact) {
      // Yatay telefon: tek satır, alan balonlara kalsın.
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
        child: Row(
          children: [
            back,
            Flexible(flex: 2, child: title),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: Center(child: stats())),
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
              // Balonlar: yalnızca bu katman her karede yeniden kurulur.
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: frame,
                  builder:
                      (context, _) => Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          for (final b in engine.balloons)
                            _buildBalloon(b, engine.time),
                        ],
                      ),
                ),
              ),
              // Patlama parçacıkları ve nota: dokunuşları engellemez.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: PopPainter(engine.pops, repaint: frame),
                  ),
                ),
              ),
              if (engine.status == BpStatus.ready)
                GameIntroPanel(
                  title: l.bpGame,
                  description: l.bpDesc,
                  onStart: _onStartPressed,
                  extra: _levelPicker(l),
                ),
              if (engine.status == BpStatus.over) _buildResult(l, engine),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalloon(BpBalloon b, double time) {
    final shakeDx = b.shake > 0 ? math.sin(b.shake * 34) * 9 * b.shake : 0.0;
    final pulse = 1 + 0.07 * b.shake;
    final color = kBalloonColors[b.colorIndex % kBalloonColors.length];
    return Positioned(
      key: ValueKey(b.id),
      left: 0,
      top: 0,
      child: Transform.translate(
        offset: Offset(b.x + b.swayOffset(time) + shakeDx, b.y),
        child: Transform.scale(
          scale: pulse,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // onTapDown: parmak değdiği anda tepki (balon yükseldiği için).
              onTapDown: (_) => _onBalloonTap(b.id),
              child: SizedBox(
                width: b.size,
                height: b.boxHeight,
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: BalloonPainter(color)),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        width: b.size,
                        height: b.bodyHeight,
                        child: Center(
                          // Dar harfler (ا د ر) büyük kalır; geniş harfler (ص ش ض)
                          // gövdeye sığacak kadar küçülür. Harf tek Text: birleşim
                          // ve harekeler bozulmaz.
                          child: SizedBox(
                            width: b.size * 0.72,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                b.letter.char,
                                textDirection: TextDirection.rtl,
                                style: lessonArabicStyle(
                                  b.size * 0.95,
                                  color: kBalloonLetterColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult(GameTexts l, BulPatlatEngine e) {
    final best = math.max(_bestBefore, e.score);
    return GameResultPanel(
      title: l.bpCompleted,
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
        (l.bpMissed, '${e.missedTargets}'),
        (l.bpAccuracy, '%${e.accuracyPercent}'),
        (l.bpBest, '$best'),
      ],
      footer:
          '${l.bpTotalBalloons} ${e.spawned} · ${l.bpWrongTaps} ${e.wrongTaps}',
      extra: _levelPicker(l),
      onReplay: _startGame,
      onBack: () => Navigator.of(context).maybePop(),
      onLeaderboard:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => const SkorTablosuSayfasi(
                    initialGameId: GameIds.bulPatlat,
                  ),
            ),
          ),
    );
  }
}
