import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../data/drag_drop_game_data.dart';
import '../../../models/game_score.dart';
import '../../../services/audio_service.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../harf_oyunlari/game_letters.dart';
import '../harf_oyunlari/profil/player_repository.dart';
import '../widgets/fit_grid.dart';
import '../widgets/game_progress.dart';
import '../widgets/game_result_summary.dart';
import '../widgets/game_score_strip.dart';
import 'dedektif_data.dart';
import 'dedektif_engine.dart';
import 'dedektif_progress_store.dart';
import 'widgets/detective_card.dart';
import 'widgets/tappable_word.dart';

/// Harf Dedektifi'nin oyun ekranı: 5 kısa tur, süre yok.
///
/// Her turda hedef harfin bütün doğru örnekleri bulunur ("Bulunan: 2 / 4");
/// bulunan her YENİ örnek 10 puan. Aynı doğruya tekrar basmak puan vermez,
/// yanlış seçim turu bitirmez ve puan silmez. İki farklı yanlıştan sonra
/// "İpucu" düğmesi belirginleşir. Tur bitince kısa kutlama + "Sonraki".
///
/// Pop edilirken `true` dönerse çağıran (başlangıç ekranı) da kapanır:
/// "Oyunlara Dön".
class HarfDedektifiGameScreen extends StatefulWidget {
  const HarfDedektifiGameScreen({
    super.key,
    required this.mode,
    required this.choice,
    this.random,
  });

  final DetectiveMode mode;
  final LetterChoice choice;

  /// Testlerde sabit sıra için.
  final math.Random? random;

  @override
  State<HarfDedektifiGameScreen> createState() =>
      _HarfDedektifiGameScreenState();
}

enum _FeedbackKind { found, info, wrong, hint, complete }

class _Feedback {
  const _Feedback(this.kind, this.text, {this.compare});

  final _FeedbackKind kind;
  final String text;

  /// Benzer Harfler: hedef ile seçilen harf yan yana (aynı biçimde).
  final (String, String, String, String)? compare;
}

class _HarfDedektifiGameScreenState extends State<HarfDedektifiGameScreen> {
  late final math.Random _random = widget.random ?? math.Random();
  late AudioService _audio;
  late GameScoreStore _store;
  final _progress = DetectiveProgressStore();
  bool _preloaded = false;

  DetectiveSession? _session;
  int _serial = 0;
  bool _intro = false;
  bool _muted = false;
  _Feedback? _feedback;
  ScoreAward? _award;
  final Map<String, int> _shake = {};
  bool _finished = false;
  bool _saved = false;
  GameResult? _result;
  GameSubmission? _submission;
  Timer? _autoPlay;

  /// Tur/ekran değişince kısa süre dokunma alınmaz: "Sonraki"ye çift
  /// dokunan çocuk, aynı yerde beliren İpucu / Aramaya Başla / sonuç
  /// düğmesine yanlışlıkla basmasın.
  bool _inputLocked = false;
  Timer? _unlock;
  static const _inputLockTime = Duration(milliseconds: 600);

  /// Önceki oturumun zorluk kaydı; yeni oturum onu bekleyip okur.
  Future<void>? _pendingSave;

  DetectiveMode get _mode => widget.mode;

  @override
  void initState() {
    super.initState();
    _progress.isMuted().then((muted) {
      if (mounted) setState(() => _muted = muted);
    });
    _startSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<AudioService>();
    _store = context.read<GameScoreStore>();
    if (!_preloaded) {
      _preloaded = true;
      _audio.preload([
        kGameCorrectSound,
        for (final letter in kDetectiveLetters) letter.audio,
      ]);
    }
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _unlock?.cancel();
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

  // ---- oturum ---------------------------------------------------------------

  void _lockInput() {
    _inputLocked = true;
    _unlock?.cancel();
    _unlock = Timer(_inputLockTime, () {
      if (mounted) setState(() => _inputLocked = false);
    });
  }

  Future<void> _startSession({List<int> focus = const []}) async {
    final serial = ++_serial;
    _autoPlay?.cancel();
    setState(() {
      _session = null;
      _finished = false;
      _saved = false;
      _result = null;
      _submission = null;
      _feedback = null;
      _award = null;
      _shake.clear();
      _intro = false;
    });
    await _pendingSave;
    if (!mounted || serial != _serial) return;
    final weights = await _progress.weightsFor(_mode, profileId: _profileId());
    if (!mounted || serial != _serial) return;
    final factory = DetectiveRoundFactory(_random);
    final targets = factory.pickTargets(
      DetectiveRoundFactory.candidatesFor(_mode, widget.choice.ids),
      weights: weights,
      focus: focus,
    );
    setState(() {
      _session = DetectiveSession(
        mode: _mode,
        targets: targets,
        factory: factory,
      );
      _enterRound();
    });
  }

  // setState içinde çağrılır.
  void _enterRound() {
    final session = _session!;
    _intro =
        _mode == DetectiveMode.shapes &&
        session.isFirstAppearance(session.roundIndex);
    _feedback = null;
    _shake.clear();
    _lockInput();
    _scheduleTargetSound();
  }

  DetectiveLetter get _target => letterById(_session!.current.round.targetId);

  void _scheduleTargetSound() {
    _autoPlay?.cancel();
    _autoPlay = Timer(const Duration(milliseconds: 450), () {
      if (mounted && !_finished && _session != null) _playTarget();
    });
  }

  void _playTarget() {
    if (_muted) return;
    final audio = _target.audio;
    // Ses dosyası yoksa sessiz geçilir; AudioService hatayı kendisi yakalar.
    if (audio != null) {
      _audio.stopEffect();
      _audio.playAsset(audio);
    }
  }

  Future<void> _toggleMute() async {
    final muted = !_muted;
    setState(() => _muted = muted);
    if (muted) {
      _autoPlay?.cancel();
      await _audio.stop();
      await _audio.stopEffect();
    }
    await _progress.setMuted(muted);
  }

  void _tap(String itemId) {
    final session = _session;
    if (session == null || _intro || _finished || _inputLocked) return;
    final state = session.current;
    final result = session.tap(itemId);
    if (result == TapResult.ignored) return;
    setState(() {
      switch (result) {
        case TapResult.found:
          _autoPlay?.cancel();
          // Her bulguda YENİ nesne: şerit "+10"u her seferinde gösterir.
          _award = ScoreAward(
            base: kDetectivePointsPerFind,
            firstTryBonus: 0,
            streakBonus: 0,
          );
          _feedback =
              state.complete
                  ? const _Feedback(_FeedbackKind.complete, 'Hepsini buldun!')
                  : _Feedback(
                    _FeedbackKind.found,
                    'Buldun! Kalan: ${state.total - state.found.length}',
                  );
          if (!_muted) {
            // Aynı anda tek ses: harf sesi susar, kısa "doğru" sesi çalar.
            _audio.stop();
            _audio.playEffect(kGameCorrectSound);
          }
        case TapResult.alreadyFound:
          _feedback = const _Feedback(
            _FeedbackKind.info,
            'Bunu zaten buldun. Başka bir tane ara!',
          );
        case TapResult.wrong:
        case TapResult.repeatWrong:
          _shake[itemId] = (_shake[itemId] ?? 0) + 1;
          _feedback = _wrongFeedback(state, itemId);
        case TapResult.ignored:
          break;
      }
    });
  }

  _Feedback _wrongFeedback(RoundState state, String itemId) {
    final pickedId = state.round.letterIdOf(itemId);
    final picked = pickedId == null ? null : letterById(pickedId);
    final target = letterById(state.round.targetId);
    if (picked == null) {
      return const _Feedback(_FeedbackKind.wrong, 'Bir daha bakalım!');
    }
    switch (_mode) {
      case DetectiveMode.similar:
        final form = state.round.formOf(itemId) ?? LetterForm.isolated;
        return _Feedback(
          _FeedbackKind.wrong,
          _dotHint(picked, target) ??
              'Bu ${picked.name} harfi. Bir daha bakalım!',
          compare: (
            target.display(form),
            target.name,
            picked.display(form),
            picked.name,
          ),
        );
      case DetectiveMode.shapes:
        // Yalnızca noktası farklı bir harf seçildiyse farkı söyle.
        final dots =
            looksAlike(picked.id, target.id) ? _dotHint(picked, target) : null;
        return _Feedback(
          _FeedbackKind.wrong,
          dots ?? 'Bu ${picked.name} harfi. Bir daha bakalım!',
        );
      case DetectiveMode.words:
        return _Feedback(
          _FeedbackKind.wrong,
          'Bu harf ${picked.name}. Bir daha bakalım!',
        );
    }
  }

  /// "Seçtiğin Te: üstünde 2 nokta var. Aradığımız Be: altında 1 nokta var."
  String? _dotHint(DetectiveLetter picked, DetectiveLetter target) {
    final p = dotPhrase(picked.id);
    final t = dotPhrase(target.id);
    if (p == null || t == null) return null;
    return 'Seçtiğin ${picked.name}: $p. Aradığımız ${target.name}: $t.';
  }

  void _hint() {
    final session = _session;
    if (session == null || _intro || _inputLocked) return;
    final id = session.hint(_random);
    if (id == null) return;
    setState(() {
      _feedback = _Feedback(
        _FeedbackKind.hint,
        _mode == DetectiveMode.words
            ? 'İpucu: Parlayan harfe dokun.'
            : 'İpucu: Büyüteçli karta bak.',
      );
    });
  }

  void _next() {
    final session = _session;
    if (session == null || !session.current.complete || _finished) return;
    if (session.isLastRound) {
      _finish();
      return;
    }
    _audio.stop();
    setState(() {
      session.next();
      _enterRound();
    });
  }

  void _finish() {
    final session = _session!;
    session.finish();
    _autoPlay?.cancel();
    final result = GameResult(
      points: session.points,
      firstTry: session.countOf(FindKind.firstTry),
      total: session.foundCount,
    );
    setState(() {
      _finished = true;
      _result = result;
      _lockInput();
    });
    // Tamamlanan oturum yalnızca bir kez kaydedilir.
    if (_saved) return;
    _saved = true;
    final serial = _serial;
    _store.submit(_mode.gameKey, result).then((submission) {
      if (mounted && serial == _serial) {
        setState(() => _submission = submission);
      }
    });
    _pendingSave = _progress.applySession(
      _mode,
      profileId: _profileId(),
      struggled: session.struggledTargets,
      clean: session.cleanTargets,
    );
  }

  // ---- arayüz ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = _session;
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
              'Harf Dedektifi',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _mode.title,
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
          if (session != null && !_finished)
            GameStepPill(
              current: session.roundIndex + 1,
              total: session.roundCount,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child:
                _finished && session != null
                    ? _DetectiveFinishView(
                      session: session,
                      result: _result!,
                      submission: _submission,
                      onReplay: () => _startSession(),
                      onPractice:
                          () => _startSession(focus: session.weakLetterIds()),
                      onExit: () => Navigator.of(context).pop(true),
                      locked: _inputLocked,
                    )
                    : session == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildGame(context, session),
          ),
        ),
      ),
    );
  }

  String get _stripInstruction => switch (_mode) {
    DetectiveMode.shapes => 'Aynı harfin bütün yazılışlarını bul.',
    DetectiveMode.similar => 'Aynı harfi benzerlerinin arasından bul.',
    DetectiveMode.words => 'Kelimelerin içinde harfe dokun.',
  };

  Widget _buildGame(BuildContext context, DetectiveSession session) {
    final state = session.current;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final progress =
        (session.roundIndex + (state.complete ? 1 : 0)) / session.roundCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          GameProgressBar(value: progress),
          const SizedBox(height: 8),
          GameScoreStrip(
            points: session.points,
            award: _award,
            instruction: _stripInstruction,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= constraints.maxHeight * 1.15;
                final compact = constraints.maxHeight < 420;
                final header = _TargetHeader(
                  key: ValueKey('header-$_serial-${session.roundIndex}'),
                  letter: _target,
                  mode: _mode,
                  found: state.found.length,
                  total: state.total,
                  compact: compact,
                  onListen: _playTarget,
                  muted: _muted,
                  reduceMotion: reduceMotion,
                );
                // Dikeyde sabit yükseklik; yanda kalan alan (tur boyunca
                // değişmez, oyun alanı kaymaz).
                final feedbackHeight =
                    _mode == DetectiveMode.similar ? 100.0 : 56.0;
                _FeedbackArea feedback([double? height]) => _FeedbackArea(
                  feedback: _feedback,
                  height: height,
                  reduceMotion: reduceMotion,
                );
                final actions = _RoundActions(
                  intro: _intro,
                  complete: state.complete,
                  hintSuggested: state.hintSuggested,
                  hintActive: state.hintedId != null,
                  last: session.isLastRound,
                  onHint: _hint,
                  onNext: _next,
                  onStart: () {
                    if (_inputLocked) return;
                    setState(() {
                      _intro = false;
                      _lockInput();
                    });
                  },
                );
                final play = KeyedSubtree(
                  key: ValueKey('$_serial-${session.roundIndex}-$_intro'),
                  child: _playArea(context, state, reduceMotion),
                );
                if (wide) {
                  return Row(
                    children: [
                      SizedBox(
                        width: math.min(360, constraints.maxWidth * 0.36),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            header,
                            const SizedBox(height: 8),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: feedbackHeight + 20,
                                ),
                                child: feedback(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            actions,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: play),
                    ],
                  );
                }
                return Column(
                  children: [
                    header,
                    const SizedBox(height: 6),
                    feedback(feedbackHeight),
                    const SizedBox(height: 6),
                    Expanded(child: play),
                    const SizedBox(height: 8),
                    actions,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  (double, double) _cardSizes(BuildContext context) =>
      switch (Responsive.deviceClassOf(context)) {
        DeviceClass.mobile => (150.0, 140.0),
        DeviceClass.tablet => (210.0, 200.0),
        DeviceClass.desktop => (230.0, 200.0),
      };

  Widget _playArea(BuildContext context, RoundState state, bool reduceMotion) {
    final round = state.round;
    if (_intro) return _introArea(context, reduceMotion);
    switch (round) {
      case CardRound():
        final (maxCard, _) = _cardSizes(context);
        return FitGrid(
          count: round.cards.length,
          maxItemSize: maxCard,
          gap: 12,
          itemBuilder: (context, i, size) {
            final id = CardRound.idOf(i);
            return DetectiveCard(
              key: ValueKey('card-$i'),
              text: round.cards[i].text,
              size: size,
              reduceMotion: reduceMotion,
              semanticLabel:
                  'Kart ${i + 1}'
                  '${state.found.contains(id) ? ', bulundu' : ''}',
              state:
                  state.found.contains(id)
                      ? DetectiveCardState.found
                      : state.hintedId == id
                      ? DetectiveCardState.hinted
                      : state.wrong.contains(id)
                      ? DetectiveCardState.wrong
                      : DetectiveCardState.idle,
              shakeTrigger: _shake[id] ?? 0,
              onTap: () => _tap(id),
            );
          },
        );
      case WordRound():
        final maxFont = switch (Responsive.deviceClassOf(context)) {
          DeviceClass.mobile => 130.0,
          DeviceClass.tablet => 190.0,
          DeviceClass.desktop => 180.0,
        };
        return _WordsArea(
          round: round,
          maxFontSize: maxFont,
          markOf: (w, l) {
            final id = WordRound.idOf(w, l);
            if (state.found.contains(id)) return WordLetterMark.found;
            if (state.hintedId == id) return WordLetterMark.hinted;
            if (state.wrong.contains(id)) return WordLetterMark.wrong;
            return WordLetterMark.none;
          },
          onTap: (w, l) => _tap(WordRound.idOf(w, l)),
        );
    }
  }

  /// Şekilleri Tanı: harf ilk kez gelince önce biçimleri adlarıyla tanıtılır.
  /// Arama başlayınca kartlarda ad yoktur.
  Widget _introArea(BuildContext context, bool reduceMotion) {
    final letter = _target;
    final forms = letter.forms;
    final (_, maxCard) = _cardSizes(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          'Tanıyalım: ${letter.name} harfinin yazılışları',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        if (!letter.joinsNext)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Bu harf kendinden sonraki harfe bağlanmaz.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: FitGrid(
            count: forms.length,
            maxItemSize: maxCard,
            gap: 12,
            itemBuilder:
                (context, i, size) => SizedBox.square(
                  key: ValueKey('intro-$i'),
                  dimension: size,
                  child: Column(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(size * 0.14),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5),
                              ),
                            ),
                            padding: EdgeInsets.all(size * 0.08),
                            alignment: Alignment.center,
                            child: FittedBox(
                              child: Text(
                                letter.display(forms[i]),
                                textDirection: TextDirection.rtl,
                                textScaler: TextScaler.noScaling,
                                style: singleGlyphStyle(size * 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          letter.formLabel(forms[i]),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _TargetHeader extends StatelessWidget {
  const _TargetHeader({
    super.key,
    required this.letter,
    required this.mode,
    required this.found,
    required this.total,
    required this.compact,
    required this.onListen,
    required this.muted,
    required this.reduceMotion,
  });

  final bool reduceMotion;
  final DetectiveLetter letter;
  final DetectiveMode mode;
  final int found;
  final int total;
  final bool compact;
  final VoidCallback onListen;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final glyph = compact ? 60.0 : 84.0;
    final instruction = switch (mode) {
      DetectiveMode.shapes => 'harfinin bütün şekillerini bul!',
      DetectiveMode.similar => 'harfini bul!',
      DetectiveMode.words => 'harfini kelimelerde bul!',
    };
    return Semantics(
      container: true,
      label: '${letter.name} harfini bul. Bulunan: $found / $total',
      child: Row(
        children: [
          IconButton.filled(
            key: const ValueKey('listen-button'),
            tooltip: muted ? 'Ses kapalı' : 'Harfin sesini dinle',
            onPressed: muted ? null : onListen,
            iconSize: compact ? 26 : 32,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              foregroundColor: Colors.white,
              minimumSize: Size.square(compact ? 48 : 58),
            ),
            icon: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
          ),
          const SizedBox(width: 10),
          // Tur başında aranan harf bir kez büyüyüp küçülür: okuyamayan
          // çocuk da neyi araması gerektiğini görür.
          ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
              duration: Duration(milliseconds: reduceMotion ? 0 : 900),
              builder:
                  (context, t, child) => Transform.scale(
                    scale: 1 + 0.18 * math.sin(t * math.pi),
                    child: child,
                  ),
              child: Container(
                key: const ValueKey('target-glyph'),
                width: glyph,
                height: glyph,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      letter.char,
                      textScaler: TextScaler.noScaling,
                      style: singleGlyphStyle(glyph * 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    instruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (compact
                            ? textTheme.titleMedium
                            : textTheme.titleLarge)
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        letter.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        key: const ValueKey('found-counter'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.turquoiseSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Bulunan: $found / $total',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackArea extends StatelessWidget {
  const _FeedbackArea({
    required this.feedback,
    required this.height,
    required this.reduceMotion,
  });

  final _Feedback? feedback;

  /// `null`: verilen alanın tamamı.
  final double? height;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final feedback = this.feedback;
    // Sabit yükseklik: mesaj değişince oyun alanı kaymaz.
    return SizedBox(
      height: height ?? double.infinity,
      child: AnimatedSwitcher(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        child:
            feedback == null
                ? const SizedBox.expand(key: ValueKey('empty'))
                : Semantics(
                  key: ObjectKey(feedback),
                  liveRegion: true,
                  child: _content(context, feedback),
                ),
      ),
    );
  }

  Widget _content(BuildContext context, _Feedback feedback) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color, background) = switch (feedback.kind) {
      _FeedbackKind.found => (
        Icons.check_circle_rounded,
        AppColors.turquoise,
        AppColors.turquoiseSoft,
      ),
      _FeedbackKind.complete => (
        Icons.star_rounded,
        AppColors.gold,
        AppColors.goldSoft,
      ),
      _FeedbackKind.hint => (
        Icons.search_rounded,
        AppColors.gold,
        AppColors.goldSoft,
      ),
      _FeedbackKind.wrong => (
        Icons.search_rounded,
        AppColors.navySoft,
        AppColors.skyBlueSoft,
      ),
      _FeedbackKind.info => (
        Icons.info_outline_rounded,
        AppColors.navySoft,
        AppColors.skyBlueSoft,
      ),
    };
    final message = Text(
      feedback.text,
      maxLines: feedback.compare == null ? 3 : 4,
      overflow: TextOverflow.ellipsis,
      style: textTheme.titleSmall?.copyWith(
        fontSize: feedback.compare == null ? null : 13,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        height: 1.2,
      ),
    );
    final compare = feedback.compare;
    return Container(
      key: const ValueKey('feedback'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (compare != null) ...[
            // Hedef ve seçilen harf yan yana, aynı biçimde büyütülmüş.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CompareGlyph(
                    text: compare.$1,
                    caption: 'Aranan',
                    name: compare.$2,
                    highlight: true,
                  ),
                  const SizedBox(width: 6),
                  _CompareGlyph(
                    text: compare.$3,
                    caption: 'Seçtiğin',
                    name: compare.$4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ] else ...[
            if (feedback.kind == _FeedbackKind.complete)
              _Stars(reduceMotion: reduceMotion)
            else
              Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
          ],
          Expanded(child: message),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
          duration: Duration(milliseconds: reduceMotion ? 0 : 350 + i * 150),
          curve: Curves.easeOutBack,
          builder:
              (context, t, child) => Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(scale: t, child: child),
              ),
          child: Icon(
            Icons.star_rounded,
            color: AppColors.gold,
            size: i == 1 ? 30 : 22,
          ),
        ),
    ],
  );
}

class _CompareGlyph extends StatelessWidget {
  const _CompareGlyph({
    required this.text,
    required this.caption,
    required this.name,
    this.highlight = false,
  });

  final String text;
  final String caption;
  final String name;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      height: 1.1,
    );
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(caption, maxLines: 1, style: style),
          Container(
            width: 56,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlight ? AppColors.gold : AppColors.divider,
                width: highlight ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  text,
                  textDirection: TextDirection.rtl,
                  textScaler: TextScaler.noScaling,
                  style: singleGlyphStyle(36),
                ),
              ),
            ),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}

class _RoundActions extends StatelessWidget {
  const _RoundActions({
    required this.intro,
    required this.complete,
    required this.hintSuggested,
    required this.hintActive,
    required this.last,
    required this.onHint,
    required this.onNext,
    required this.onStart,
  });

  final bool intro;
  final bool complete;
  final bool hintSuggested;
  final bool hintActive;
  final bool last;
  final VoidCallback onHint;
  final VoidCallback onNext;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    Widget child;
    if (intro) {
      child = FilledButton.icon(
        key: const ValueKey('start-search'),
        autofocus: true,
        onPressed: onStart,
        icon: const Icon(Icons.search_rounded),
        label: const Text('Aramaya Başla'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          minimumSize: const Size(200, 50),
          textStyle: textStyle,
        ),
      );
    } else if (complete) {
      child = FilledButton.icon(
        key: const ValueKey('next-button'),
        autofocus: true,
        onPressed: onNext,
        icon: Icon(last ? Icons.flag_rounded : Icons.arrow_forward_rounded),
        label: Text(last ? 'Sonuçları Gör' : 'Sonraki'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          minimumSize: const Size(200, 50),
          textStyle: textStyle,
        ),
      );
    } else if (hintSuggested) {
      child = FilledButton.icon(
        key: const ValueKey('hint-button'),
        onPressed: hintActive ? null : onHint,
        icon: const Icon(Icons.lightbulb_rounded),
        label: const Text('İpucu'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          minimumSize: const Size(160, 50),
          textStyle: textStyle,
        ),
      );
    } else {
      child = OutlinedButton.icon(
        key: const ValueKey('hint-button'),
        onPressed: hintActive ? null : onHint,
        icon: const Icon(Icons.lightbulb_outline_rounded),
        label: const Text('İpucu'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.divider, width: 1.5),
          minimumSize: const Size(140, 46),
          textStyle: textStyle?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
    }
    return SizedBox(height: 52, child: Center(child: child));
  }
}

/// 2–3 kelimeyi alana sığacak en büyük (ortak) yazı boyutunda dizer:
/// dar ekranda alt alta, geniş ekranda yan yana (sağdan sola).
class _WordsArea extends StatelessWidget {
  const _WordsArea({
    required this.round,
    required this.maxFontSize,
    required this.markOf,
    required this.onTap,
  });

  final WordRound round;
  final double maxFontSize;
  final WordLetterMark Function(int word, int letter) markOf;
  final void Function(int word, int letter) onTap;

  static const double _gap = 16;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const probe = 100.0;
      final sizes = [
        for (final w in round.words) TappableWord.measure(w, probe),
      ];
      final n = sizes.length;
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      double column = double.infinity;
      for (final s in sizes) {
        column = math.min(column, probe * w / s.width);
        column = math.min(
          column,
          probe * ((h - _gap * (n - 1)) / n) / s.height,
        );
      }
      final totalWidth = sizes.fold(0.0, (a, s) => a + s.width);
      final tallest = sizes.fold(0.0, (a, s) => math.max(a, s.height));
      final row = math.min(
        probe * (w - _gap * 2 * (n - 1)) / totalWidth,
        probe * h / tallest,
      );
      final horizontal = row > column;
      final fontSize = math
          .min(maxFontSize, (horizontal ? row : column) * 0.96)
          .clamp(24.0, maxFontSize);
      final words = [
        for (var i = 0; i < n; i++)
          TappableWord(
            key: ValueKey('word-$i'),
            word: round.words[i],
            wordIndex: i,
            fontSize: fontSize,
            markOf: (l) => markOf(i, l),
            onTapLetter: (l) => onTap(i, l),
          ),
      ];
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child:
              horizontal
                  ? Row(
                    textDirection: TextDirection.rtl,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0) const SizedBox(width: _gap * 2),
                        words[i],
                      ],
                    ],
                  )
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0) const SizedBox(height: _gap),
                        words[i],
                      ],
                    ],
                  ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------

class _DetectiveFinishView extends StatelessWidget {
  const _DetectiveFinishView({
    required this.session,
    required this.result,
    required this.submission,
    required this.onReplay,
    required this.onPractice,
    required this.onExit,
    required this.locked,
  });

  final bool locked;
  final DetectiveSession session;
  final GameResult result;
  final GameSubmission? submission;
  final VoidCallback onReplay;
  final VoidCallback onPractice;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final weak = session.weakSpots();
    final lineStyle = textTheme.titleMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return Center(
      child: AbsorbPointer(
        absorbing: locked,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 56,
                  color: AppColors.turquoise,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tebrikler, dedektif!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.roundCount} turu tamamladın.',
                  textAlign: TextAlign.center,
                  style: lineStyle,
                ),
                const SizedBox(height: 16),
                GameResultSummary(result: result, submission: submission),
                const SizedBox(height: 12),
                Text(
                  'Bulunan örnek: ${session.foundCount}',
                  key: const ValueKey('found-total'),
                  textAlign: TextAlign.center,
                  style: lineStyle?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  'Tekrar deneyerek: ${session.countOf(FindKind.afterRetry)}'
                  ' · İpucuyla: ${session.countOf(FindKind.withHint)}',
                  key: const ValueKey('find-kinds'),
                  textAlign: TextAlign.center,
                  style: lineStyle,
                ),
                if (weak.isNotEmpty) ...[
                  const SizedBox(height: 18),
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
                    children: [for (final spot in weak) _WeakChip(spot: spot)],
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('replay-button'),
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Tekrar Oyna'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                    minimumSize: const Size.fromHeight(54),
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (weak.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    key: const ValueKey('practice-button'),
                    onPressed: onPractice,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Zorlandıklarımı Çalış'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldSoft,
                      foregroundColor: AppColors.navy,
                      minimumSize: const Size.fromHeight(54),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const ValueKey('exit-button'),
                  onPressed: onExit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(
                      color: AppColors.divider,
                      width: 1.5,
                    ),
                    minimumSize: const Size.fromHeight(54),
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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

class _WeakChip extends StatelessWidget {
  const _WeakChip({required this.spot});

  final WeakSpot spot;

  @override
  Widget build(BuildContext context) {
    final letter = letterById(spot.letterId);
    final form = spot.form;
    final label =
        form == null
            ? letter.name
            : '${letter.name} · ${letter.formLabel(form)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            form == null ? letter.char : letter.display(form),
            textDirection: TextDirection.rtl,
            textScaler: TextScaler.noScaling,
            style: singleGlyphStyle(34),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
