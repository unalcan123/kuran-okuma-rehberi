import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/audio_service.dart';
import '../../../theme/app_colors.dart';
import '../harf_dedektifi/dedektif_data.dart';
import '../harf_oyunlari/game_letters.dart';
import '../harf_oyunlari/profil/player_repository.dart';
import 'ciz_evaluator.dart';
import 'ciz_models.dart';
import 'ciz_progress_store.dart';
import 'ciz_session.dart';
import 'widgets/trace_pad.dart';

/// Bir harfin aşamaları.
enum DrawStep {
  /// A — İzle: harf büyük, sesi çalar; "Nasıl çizilir?" animasyonu.
  watch,

  /// B — Üzerinden çiz (belirgin kılavuz, başlangıç noktası, oklar).
  trace,

  /// Noktaları koy (belirgin hedefler).
  dots,

  /// Kılavuzla tamamlandı (1. yıldız).
  guidedDone,

  /// C — Daha az yardımla: silik kılavuz, ok yok.
  lessTrace,

  /// Daha az yardımla noktalar (silik hedefler).
  lessDots,

  /// Daha az yardımla tamamlandı (2. yıldız).
  lessDone,

  /// Kılavuzsuz serbest deneme — değerlendirilmez.
  free,

  /// Serbest çizim ile örnek yan yana: "Birlikte bakalım".
  freeReview,
}

/// Harf Çiziyorum oturumu: [letterIds] sırayla çalışılır (genelde 5 harf).
/// Pop edilirken `true` dönerse başlangıç ekranı da kapanır ("Oyunlara Dön").
class HarfCiziyorumGameScreen extends StatefulWidget {
  const HarfCiziyorumGameScreen({super.key, required this.letterIds});

  final List<int> letterIds;

  @override
  State<HarfCiziyorumGameScreen> createState() =>
      _HarfCiziyorumGameScreenState();
}

class _HarfCiziyorumGameScreenState extends State<HarfCiziyorumGameScreen>
    with SingleTickerProviderStateMixin {
  late AudioService _audio;
  final _store = DrawProgressStore();
  late final AnimationController _anim = AnimationController(vsync: this)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _animating = false);
      }
    });

  late List<int> _letters = widget.letterIds;
  int _index = 0;
  DrawStep _step = DrawStep.watch;
  final List<List<Offset>> _strokes = [];
  final List<Offset> _dots = [];
  List<List<Offset>> _missing = const [];
  _Message? _message;
  bool _animating = false;
  bool _showStaticHints = false;
  bool _muted = false;
  bool _finished = false;
  bool _locked = false;
  Timer? _unlock;
  Timer? _autoSound;

  // Bu harfte zorlanma işaretleri (harften çıkarken kaydedilir).
  bool _helped = false;
  int _clears = 0;
  int _dotMisses = 0;
  bool _guidedThisVisit = false;
  bool _lessThisVisit = false;

  Map<int, LetterDrawProgress> _progress = {};
  final Map<int, int> _starsGained = {};
  final List<int> _studied = [];

  DetectiveLetter get _letter => letterById(_letters[_index]);
  LetterTraceModel get _model => traceModelFor(_letters[_index])!;

  @override
  void initState() {
    super.initState();
    _store.isMuted().then((m) {
      if (mounted) setState(() => _muted = m);
    });
    _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterLetter());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<AudioService>();
  }

  @override
  void dispose() {
    _anim.dispose();
    _unlock?.cancel();
    _autoSound?.cancel();
    Future.microtask(_audio.stop);
    super.dispose();
  }

  String? _profileId() {
    try {
      return context.read<PlayerRepository>().activePlayer?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProgress() async {
    final p = await _store.load(_profileId());
    if (mounted) setState(() => _progress = p);
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  // Aşama değişince kısa süre düğmelere basılmaz: aynı yerde beliren bir
  // sonraki düğmeye çift dokunmayla basılmasın.
  void _lock() {
    _locked = true;
    _unlock?.cancel();
    _unlock = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _locked = false);
    });
  }

  // ---- ses ----------------------------------------------------------------

  void _playLetter() {
    if (_muted) return;
    final audio = _letter.audio;
    // Dosya yoksa ya da çalınamazsa AudioService hatayı yutar; oyun sürer.
    if (audio != null) _audio.playAsset(audio);
  }

  Future<void> _toggleMute() async {
    final muted = !_muted;
    setState(() => _muted = muted);
    if (muted) {
      _autoSound?.cancel();
      await _audio.stop();
    }
    await _store.setMuted(muted);
  }

  // ---- akış ---------------------------------------------------------------

  void _enterLetter() {
    if (!mounted) return;
    _anim.stop();
    setState(() {
      _step = DrawStep.watch;
      _strokes.clear();
      _dots.clear();
      _missing = const [];
      _animating = false;
      _showStaticHints = false;
      _helped = false;
      _clears = 0;
      _dotMisses = 0;
      _guidedThisVisit = false;
      _lessThisVisit = false;
      _message = const _Message(
        _Tone.info,
        'Harfi dinle ve izle. Nasıl çizildiğini görmek için düğmeye bas.',
      );
      if (!_studied.contains(_letters[_index])) _studied.add(_letters[_index]);
      _lock();
    });
    _autoSound?.cancel();
    _autoSound = Timer(const Duration(milliseconds: 350), _playLetter);
  }

  void _playHowTo() {
    if (_reduceMotion) {
      // Azaltılmış hareket: animasyon yerine başlangıç ve oklar sabit.
      setState(() {
        _showStaticHints = true;
        _message = const _Message(
          _Tone.info,
          'Yeşil noktadan başla, okları izle. Bu bir yazış yolu.',
        );
      });
      return;
    }
    final model = _model;
    final ms = 900 + model.length * 1500 + (model.hasDots ? 700 : 0);
    _anim.duration = Duration(milliseconds: ms.round());
    setState(() {
      _animating = true;
      _message = _Message(
        _Tone.info,
        model.hasDots
            ? 'Önce gövde, sonra noktalar. Bu bir yazış yolu.'
            : 'Yeşil noktadan başlar, oklar yönü gösterir.',
      );
    });
    _anim.forward(from: 0);
  }

  void _skipAnimation() {
    _anim.stop();
    setState(() => _animating = false);
  }

  double get _animValue => _anim.value * (_model.hasDots ? 2 : 1);

  void _startTracing({bool lessHelp = false}) {
    _anim.stop();
    setState(() {
      _animating = false;
      _step = lessHelp ? DrawStep.lessTrace : DrawStep.trace;
      _strokes.clear();
      _dots.clear();
      _missing = const [];
      _message = _Message(
        _Tone.info,
        lessHelp
            ? 'Şimdi daha az yardımla çiz.'
            : 'Buradan başla: yeşil noktadan, çizginin üstünden git.',
      );
      _lock();
    });
  }

  void _onStroke(List<Offset> stroke) {
    if (_step != DrawStep.trace &&
        _step != DrawStep.lessTrace &&
        _step != DrawStep.free) {
      return;
    }
    setState(() => _strokes.add(stroke));
    if (_step == DrawStep.free) return; // serbest çizim değerlendirilmez
    _evaluate();
  }

  void _evaluate() {
    final a = assessTrace(_model, _strokes);
    setState(() {
      switch (a.verdict) {
        case TraceVerdict.complete:
          _missing = const [];
          _bodyDone();
        case TraceVerdict.keepGoing:
          _missing = a.missing;
          _message = const _Message(
            _Tone.keepGoing,
            'Biraz daha devam et! Sarı yerleri de çiz.',
          );
        case TraceVerdict.offPath:
          _missing = const [];
          _message = const _Message(
            _Tone.keepGoing,
            'Çizginin üstünden gitmeye çalış. İstersen Temizle.',
          );
        case TraceVerdict.empty:
          _missing = const [];
      }
    });
  }

  // setState içinde çağrılır.
  void _bodyDone() {
    final less = _step == DrawStep.lessTrace;
    if (_model.hasDots) {
      _step = less ? DrawStep.lessDots : DrawStep.dots;
      _message = _Message(
        _Tone.success,
        less ? 'Güzel! Şimdi noktaları ekle!' : _dotsInstruction(),
      );
      _lock();
    } else {
      _letterStageDone(less: less);
    }
  }

  String _dotsInstruction() {
    final n = _model.dots.length;
    final side = _model.dotSide == DotSide.above ? 'üstüne' : 'altına';
    return 'Şimdi noktaları ekle! Harfin $side $n nokta koy: sarı yerlere dokun.';
  }

  void _onDotTap(Offset p) {
    if (_step != DrawStep.dots && _step != DrawStep.lessDots) return;
    final need = _model.dots.length;
    setState(() {
      // Var olan noktaya dokunmak onu kaldırır (yanlış nokta geri alınır).
      final i = _dots.indexWhere((d) => (d - p).distance < 0.06);
      if (i >= 0) {
        _dots.removeAt(i);
      } else if (_dots.length < 6) {
        _dots.add(p);
      }
      if (_dots.length < need) {
        final left = need - _dots.length;
        _message = _Message(
          _Tone.info,
          left == 1 ? 'Bir nokta daha koy.' : '$left nokta daha koy.',
        );
      }
    });
    if (_dots.length >= need) _checkDots();
  }

  void _checkDots() {
    final a = assessDots(_model, _dots);
    final less = _step == DrawStep.lessDots;
    setState(() {
      switch (a.verdict) {
        case DotVerdict.correct:
          _letterStageDone(less: less);
        case DotVerdict.tooFew:
          _message = _Message(
            _Tone.keepGoing,
            a.missingCount == 1
                ? 'Bir nokta daha koy.'
                : '${a.missingCount} nokta daha koy.',
          );
        case DotVerdict.tooMany:
          _dotMisses++;
          _message = const _Message(
            _Tone.keepGoing,
            'Fazla nokta var. Birine dokunarak kaldır.',
          );
        case DotVerdict.wrongSide:
          _dotMisses++;
          _message = _Message(
            _Tone.keepGoing,
            _model.dotSide == DotSide.above
                ? 'Bu harfin noktaları üstte olur. Birlikte bakalım.'
                : 'Bu harfin noktaları altta olur. Birlikte bakalım.',
          );
        case DotVerdict.misplaced:
          _dotMisses++;
          _message = const _Message(
            _Tone.keepGoing,
            'Noktaları sarı yerlere biraz daha yaklaştır.',
          );
      }
    });
  }

  // setState içinde çağrılır.
  void _letterStageDone({required bool less}) {
    final id = _letters[_index];
    _step = less ? DrawStep.lessDone : DrawStep.guidedDone;
    _message = _Message(
      _Tone.success,
      less
          ? 'Çok güzel! Daha az yardımla da çizdin.'
          : 'Harika! Harfi tamamladın.',
    );
    _lock();
    _playLetter();
    // Kayıt yalnızca uygun tamamlamada ve bu ziyarette bir kez.
    if (less ? _lessThisVisit : _guidedThisVisit) return;
    if (less) {
      _lessThisVisit = true;
    } else {
      _guidedThisVisit = true;
    }
    final before = _progress[id] ?? const LetterDrawProgress();
    final gained = less ? !before.lessHelp : !before.guided;
    final after =
        less
            ? before.copyWith(lessHelp: true, struggle: before.struggle - 1)
            : before.copyWith(guided: true);
    _progress = {..._progress, id: after};
    if (gained) _starsGained[id] = (_starsGained[id] ?? 0) + 1;
    _store.update(
      _profileId(),
      id,
      (old) =>
          less
              ? old.copyWith(lessHelp: true, struggle: old.struggle - 1)
              : old.copyWith(guided: true),
    );
  }

  void _undo() {
    setState(() {
      if (_step == DrawStep.dots || _step == DrawStep.lessDots) {
        if (_dots.isNotEmpty) _dots.removeLast();
      } else if (_strokes.isNotEmpty) {
        _strokes.removeLast();
        _missing = const [];
      }
    });
  }

  void _clear() {
    setState(() {
      if (_step == DrawStep.dots || _step == DrawStep.lessDots) {
        _dots.clear();
      } else {
        if (_strokes.isNotEmpty) _clears++;
        _strokes.clear();
        _missing = const [];
      }
    });
  }

  void _help() {
    _helped = true;
    if (_step == DrawStep.dots || _step == DrawStep.lessDots) {
      setState(() {
        _message = _Message(_Tone.info, _dotsInstruction());
        // İpucu: hedefler bu aşamada belirgin görünür.
        _dotHelp = true;
      });
      return;
    }
    final a = assessTrace(_model, _strokes);
    setState(() {
      _missing = _strokes.isEmpty ? const [] : a.missing;
      _message = const _Message(
        _Tone.info,
        'Birlikte bakalım: harf nasıl çiziliyor, izle.',
      );
    });
    if (_reduceMotion) {
      setState(() => _showStaticHints = true);
    } else {
      _playHowTo();
    }
  }

  bool _dotHelp = false;

  void _startFree() {
    setState(() {
      _step = DrawStep.free;
      _strokes.clear();
      _dots.clear();
      _missing = const [];
      _message = const _Message(
        _Tone.info,
        'Kılavuzsuz dene. Bitince "Bitti"ye bas.',
      );
      _lock();
    });
  }

  void _finishFree() {
    setState(() {
      _step = DrawStep.freeReview;
      _message = const _Message(
        _Tone.info,
        'Birlikte bakalım: senin çizimin ve örnek harf yan yana.',
      );
      _lock();
    });
  }

  Future<void> _nextLetter() async {
    await _recordStruggle();
    if (!mounted) return;
    if (_index + 1 >= _letters.length) {
      _audio.stop();
      setState(() {
        _finished = true;
        _lock();
      });
      return;
    }
    setState(() {
      _index++;
      _dotHelp = false;
    });
    _enterLetter();
  }

  /// Zorlanılan harf, harften çıkarken bir kez işaretlenir.
  Future<void> _recordStruggle() async {
    final struggled = _helped || _clears >= 2 || _dotMisses >= 2;
    if (!struggled || _lessThisVisit) return;
    final id = _letters[_index];
    final next = await _store.update(
      _profileId(),
      id,
      (old) => old.copyWith(struggle: old.struggle + 1),
    );
    if (mounted) setState(() => _progress = {..._progress, id: next});
  }

  void _continueWith(List<int> letters) {
    if (letters.isEmpty) return;
    setState(() {
      _letters = letters;
      _index = 0;
      _finished = false;
      _studied.clear();
      _starsGained.clear();
      _dotHelp = false;
    });
    _enterLetter();
  }

  // ---- arayüz -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Harf Çiziyorum',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (!_finished)
              Text(
                '${_index + 1}. harf / ${_letters.length}',
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
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _finished ? _summary(context) : _game(context)),
    );
  }

  Widget _game(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > constraints.maxHeight * 1.1;
        final compact = constraints.maxHeight < 420;
        final header = _LetterHeader(
          letter: _letter,
          stars: _progress[_letters[_index]]?.stars ?? 0,
          step: _step,
          hasDots: _model.hasDots,
          muted: _muted,
          compact: compact,
          onListen: _playLetter,
        );
        final message = _MessageBar(message: _message, compact: compact);
        final compare =
            (_step == DrawStep.dots || _step == DrawStep.lessDots)
                ? _DotCompare(letterId: _letters[_index])
                : null;
        final buttons = AbsorbPointer(
          absorbing: _locked,
          child: _buttons(context),
        );
        final pad = KeyedSubtree(
          key: ValueKey('pad-$_index-${_step.name}'),
          child: _pad(),
        );
        if (wide) {
          return Row(
            children: [
              SizedBox(
                width: math.min(360, constraints.maxWidth * 0.4),
                child: Column(
                  children: [
                    // Alçak yatay ekranda bilgi kısmı kayar, düğmeler sabit.
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            header,
                            const SizedBox(height: 8),
                            message,
                            if (compare != null) ...[
                              const SizedBox(height: 8),
                              compare,
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    buttons,
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: pad),
            ],
          );
        }
        return Column(
          children: [
            header,
            const SizedBox(height: 6),
            message,
            if (compare != null) ...[const SizedBox(height: 6), compare],
            const SizedBox(height: 8),
            Expanded(child: pad),
            // Düğmeler çizim alanından yeterince uzakta.
            const SizedBox(height: 16),
            buttons,
          ],
        );
      },
    ),
  );

  Widget _pad() {
    final model = _model;
    switch (_step) {
      case DrawStep.watch:
        return AnimatedBuilder(
          animation: _anim,
          builder:
              (context, _) => TracePad(
                key: const ValueKey('pad-watch'),
                model: model,
                strokes: const [],
                dots: const [],
                guideOpacity: _animating ? 0.18 : 1,
                showModelDots: !_animating,
                showPathHints: _showStaticHints,
                animationProgress: _animating ? _animValue : null,
              ),
        );
      case DrawStep.trace:
      case DrawStep.lessTrace:
        final less = _step == DrawStep.lessTrace;
        return AnimatedBuilder(
          animation: _anim,
          builder:
              (context, _) => TracePad(
                key: const ValueKey('pad-trace'),
                model: model,
                strokes: _strokes,
                dots: const [],
                input: PadInput.draw,
                guideOpacity: less ? 0.1 : 0.28,
                showPathHints: !less || _showStaticHints,
                missing: _missing,
                animationProgress: _animating ? math.min(1, _animValue) : null,
                onStrokeEnd: _onStroke,
              ),
        );
      case DrawStep.dots:
      case DrawStep.lessDots:
        final less = _step == DrawStep.lessDots;
        return TracePad(
          key: const ValueKey('pad-dots'),
          model: model,
          strokes: _strokes,
          dots: _dots,
          input: PadInput.dots,
          guideOpacity: less ? 0.1 : 0.28,
          dotTargetOpacity: less && !_dotHelp ? 0.3 : 0.9,
          onDotTap: _onDotTap,
        );
      case DrawStep.guidedDone:
      case DrawStep.lessDone:
        return TracePad(
          key: const ValueKey('pad-done'),
          model: model,
          strokes: _strokes,
          dots: _dots,
          guideOpacity: 0.15,
        );
      case DrawStep.free:
        return TracePad(
          key: const ValueKey('pad-free'),
          model: model,
          strokes: _strokes,
          dots: _dots,
          input: PadInput.draw,
          guideOpacity: 0,
          onStrokeEnd: _onStroke,
        );
      case DrawStep.freeReview:
        return LayoutBuilder(
          builder: (context, c) {
            final side = c.maxWidth > c.maxHeight;
            final mine = _Captioned(
              caption: 'Senin çizimin',
              child: TracePad(
                key: const ValueKey('pad-review-mine'),
                model: model,
                strokes: _strokes,
                dots: const [],
                guideOpacity: 0,
              ),
            );
            final example = _Captioned(
              caption: 'Örnek harf',
              child: TracePad(
                key: const ValueKey('pad-review-model'),
                model: model,
                strokes: const [],
                dots: const [],
                guideOpacity: 1,
                showModelDots: true,
              ),
            );
            return side
                ? Row(
                  children: [
                    Expanded(child: mine),
                    const SizedBox(width: 12),
                    Expanded(child: example),
                  ],
                )
                : Column(
                  children: [
                    Expanded(child: mine),
                    const SizedBox(height: 12),
                    Expanded(child: example),
                  ],
                );
          },
        );
    }
  }

  Widget _buttons(BuildContext context) {
    final List<Widget> row;
    switch (_step) {
      case DrawStep.watch:
        row = [
          _Btn(
            key: const ValueKey('howto-button'),
            icon:
                _animating
                    ? Icons.skip_next_rounded
                    : Icons.play_circle_rounded,
            label: _animating ? 'Atla' : 'Nasıl çizilir?',
            onTap: _animating ? _skipAnimation : _playHowTo,
          ),
          _Btn(
            key: const ValueKey('start-trace-button'),
            icon: Icons.gesture_rounded,
            label: 'Çizmeye başla',
            primary: true,
            onTap: () => _startTracing(),
          ),
        ];
      case DrawStep.trace:
      case DrawStep.lessTrace:
      case DrawStep.dots:
      case DrawStep.lessDots:
        row = [
          _Btn(
            key: const ValueKey('undo-button'),
            icon: Icons.undo_rounded,
            label: 'Geri Al',
            onTap: _undo,
          ),
          _Btn(
            key: const ValueKey('clear-button'),
            icon: Icons.cleaning_services_rounded,
            label: 'Temizle',
            onTap: _clear,
          ),
          _Btn(
            key: const ValueKey('help-button'),
            icon: Icons.lightbulb_outline_rounded,
            label: 'Yardım',
            onTap: _help,
          ),
        ];
      case DrawStep.guidedDone:
        row = [
          _Btn(
            key: const ValueKey('next-letter-button'),
            icon: Icons.arrow_forward_rounded,
            label: _index + 1 >= _letters.length ? 'Bitir' : 'Sonraki harf',
            onTap: _nextLetter,
          ),
          _Btn(
            key: const ValueKey('less-help-button'),
            icon: Icons.star_half_rounded,
            label: 'Daha az yardımla',
            primary: true,
            onTap: () => _startTracing(lessHelp: true),
          ),
        ];
      case DrawStep.lessDone:
        row = [
          _Btn(
            key: const ValueKey('free-button'),
            icon: Icons.brush_rounded,
            label: 'Kılavuzsuz dene',
            onTap: _startFree,
          ),
          _Btn(
            key: const ValueKey('next-letter-button'),
            icon: Icons.arrow_forward_rounded,
            label: _index + 1 >= _letters.length ? 'Bitir' : 'Sonraki harf',
            primary: true,
            onTap: _nextLetter,
          ),
        ];
      case DrawStep.free:
        row = [
          _Btn(
            key: const ValueKey('undo-button'),
            icon: Icons.undo_rounded,
            label: 'Geri Al',
            onTap: _undo,
          ),
          _Btn(
            key: const ValueKey('clear-button'),
            icon: Icons.cleaning_services_rounded,
            label: 'Temizle',
            onTap: _clear,
          ),
          _Btn(
            key: const ValueKey('free-done-button'),
            icon: Icons.check_rounded,
            label: 'Bitti',
            primary: true,
            onTap: _strokes.isEmpty ? null : _finishFree,
          ),
        ];
      case DrawStep.freeReview:
        row = [
          _Btn(
            key: const ValueKey('free-again-button'),
            icon: Icons.replay_rounded,
            label: 'Tekrar dene',
            onTap: _startFree,
          ),
          _Btn(
            key: const ValueKey('next-letter-button'),
            icon: Icons.arrow_forward_rounded,
            label: _index + 1 >= _letters.length ? 'Bitir' : 'Sonraki harf',
            primary: true,
            onTap: _nextLetter,
          ),
        ];
    }
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          for (var i = 0; i < row.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: row[i]),
          ],
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gained = _starsGained.values.fold(0, (a, b) => a + b);
    final nextLetters = nextLettersInOrder(_letters.last, _progress);
    final practice = practiceLetters(_progress);
    return Center(
      child: AbsorbPointer(
        absorbing: _locked,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.brush_rounded,
                  size: 52,
                  color: AppColors.turquoise,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tebrikler!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gained == 0
                      ? '${_studied.length} harf çalıştın.'
                      : '${_studied.length} harf çalıştın, $gained yeni yıldız kazandın.',
                  key: const ValueKey('summary-text'),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final id in _studied)
                      _StudiedChip(
                        letter: letterById(id),
                        stars: _progress[id]?.stars ?? 0,
                        gained: _starsGained[id] ?? 0,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('more-button'),
                  onPressed: () => _continueWith(nextLetters),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('5 harf daha'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
                if (practice.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    key: const ValueKey('practice-button'),
                    onPressed: () => _continueWith(practice),
                    icon: const Icon(Icons.refresh_rounded),
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

// ---------------------------------------------------------------------------

enum _Tone { info, success, keepGoing }

class _Message {
  const _Message(this.tone, this.text);
  final _Tone tone;
  final String text;
}

class _MessageBar extends StatelessWidget {
  const _MessageBar({required this.message, required this.compact});

  final _Message? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final (icon, color, bg) = switch (m?.tone) {
      _Tone.success => (
        Icons.check_circle_rounded,
        AppColors.turquoise,
        AppColors.turquoiseSoft,
      ),
      _Tone.keepGoing => (
        Icons.gesture_rounded,
        AppColors.gold,
        AppColors.goldSoft,
      ),
      _ => (
        Icons.info_outline_rounded,
        AppColors.navySoft,
        AppColors.skyBlueSoft,
      ),
    };
    return SizedBox(
      height: compact ? 48 : 58,
      child:
          m == null
              ? null
              : Semantics(
                liveRegion: true,
                child: Container(
                  key: const ValueKey('message'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                            height: 1.2,
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

class _LetterHeader extends StatelessWidget {
  const _LetterHeader({
    required this.letter,
    required this.stars,
    required this.step,
    required this.hasDots,
    required this.muted,
    required this.compact,
    required this.onListen,
  });

  final DetectiveLetter letter;
  final int stars;
  final DrawStep step;
  final bool hasDots;
  final bool muted;
  final bool compact;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final glyph = compact ? 52.0 : 64.0;
    final stages = [
      ('İzle', {DrawStep.watch}),
      ('Çiz', {DrawStep.trace, DrawStep.guidedDone}),
      if (hasDots) ('Noktalar', {DrawStep.dots}),
      ('Az yardım', {DrawStep.lessTrace, DrawStep.lessDots, DrawStep.lessDone}),
      ('Serbest', {DrawStep.free, DrawStep.freeReview}),
    ];
    return Row(
      children: [
        IconButton.filled(
          key: const ValueKey('listen-button'),
          tooltip: muted ? 'Ses kapalı' : 'Harfin sesini dinle',
          onPressed: muted ? null : onListen,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.turquoise,
            foregroundColor: Colors.white,
            minimumSize: Size.square(compact ? 44 : 52),
          ),
          icon: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: glyph,
          height: glyph,
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                letter.char,
                textScaler: TextScaler.noScaling,
                style: singleGlyphStyle(glyph * 0.95),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      letter.name,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _Stars(stars: stars, size: 20),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  for (final (label, steps) in stages)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            steps.contains(step)
                                ? AppColors.turquoise
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        label,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              steps.contains(step)
                                  ? Colors.white
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars, this.size = 18});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars yıldız',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 2; i++)
            Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < stars ? AppColors.gold : AppColors.divider,
            ),
        ],
      ),
    ),
  );
}

/// Aynı gövdeyi paylaşan harflerde nokta farkı: ب ت ث gibi.
class _DotCompare extends StatelessWidget {
  const _DotCompare({required this.letterId});

  final int letterId;

  @override
  Widget build(BuildContext context) {
    final group = similarGroupOf(letterId);
    if (group == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      key: const ValueKey('dot-compare'),
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final id in group) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      id == letterId ? AppColors.goldSoft : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: id == letterId ? AppColors.gold : AppColors.divider,
                    width: id == letterId ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      letterById(id).char,
                      textScaler: TextScaler.noScaling,
                      style: singleGlyphStyle(30),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${letterById(id).name}: ${dotPhrase(id) ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Captioned extends StatelessWidget {
  const _Captioned({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        caption,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      Expanded(child: child),
    ],
  );
}

class _Btn extends StatelessWidget {
  const _Btn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800);
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(width: 6), Text(label)],
      ),
    );
    return primary
        ? FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.turquoise,
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: style,
          ),
          child: child,
        )
        : OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.divider, width: 1.5),
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: style,
          ),
          child: child,
        );
  }
}

class _StudiedChip extends StatelessWidget {
  const _StudiedChip({
    required this.letter,
    required this.stars,
    required this.gained,
  });

  final DetectiveLetter letter;
  final int stars;
  final int gained;

  @override
  Widget build(BuildContext context) => Container(
    width: 96,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: gained > 0 ? AppColors.gold : AppColors.divider,
        width: gained > 0 ? 2 : 1,
      ),
    ),
    child: Column(
      children: [
        Text(
          letter.char,
          textScaler: TextScaler.noScaling,
          style: singleGlyphStyle(40),
        ),
        Text(
          letter.name,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        _Stars(stars: stars),
        if (gained > 0)
          Text(
            '+$gained',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
      ],
    ),
  );
}
