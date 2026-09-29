import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/reading_segment.dart';
import 'audio_service.dart';
import 'reading_settings.dart';

/// One clip in a reading's play order: segment [segment], the [repeat]-th of
/// [of] times in a row.
@immutable
class PlaybackStep {
  const PlaybackStep(this.segment, {this.repeat = 1, this.of = 1});

  final int segment;
  final int repeat;
  final int of;

  @override
  bool operator ==(Object other) =>
      other is PlaybackStep &&
      other.segment == segment &&
      other.repeat == repeat &&
      other.of == of;

  @override
  int get hashCode => Object.hash(segment, repeat, of);

  @override
  String toString() => 'PlaybackStep($segment, $repeat/$of)';
}

/// The order "Dinle" plays [segments] in. Only the play order is made here;
/// the segments (the data) are never changed.
///
/// - [MemorizationMode.listenOnly]: start to end ([repeatCount] times).
/// - [MemorizationMode.stepByStep]: each segment [repeatCount] times, then
///   the next ("Ayet Ayet").
/// - [MemorizationMode.shuffled]: an opening besmele stays first (as the
///   dataset reads it); the other segments come [repeatCount] rounds, each
///   round in a new random order, and never the same segment twice in a
///   row.
List<PlaybackStep> buildPlaybackPlan(
  List<ReadingSegment> segments, {
  required MemorizationMode mode,
  required int repeatCount,
  math.Random? random,
}) {
  final count = repeatCount.clamp(
    ReadingSettings.minRepeat,
    ReadingSettings.maxRepeat,
  );
  switch (mode) {
    case MemorizationMode.listenOnly:
      return [
        for (var round = 0; round < count; round++)
          for (var i = 0; i < segments.length; i++) PlaybackStep(i),
      ];
    case MemorizationMode.stepByStep:
      return [
        for (var i = 0; i < segments.length; i++)
          for (var r = 1; r <= count; r++) PlaybackStep(i, repeat: r, of: count),
      ];
    case MemorizationMode.shuffled:
      final rng = random ?? math.Random();
      final opening = [
        for (var i = 0; i < segments.length; i++)
          if (segments[i].isOpening) i,
      ];
      final rest = [
        for (var i = 0; i < segments.length; i++)
          if (!segments[i].isOpening) i,
      ];
      final order = <int>[...opening];
      for (var round = 0; round < count; round++) {
        final shuffled = [...rest]..shuffle(rng);
        // Never the same segment twice in a row across two rounds.
        if (shuffled.length > 1 &&
            order.isNotEmpty &&
            shuffled.first == order.last) {
          final swap = 1 + rng.nextInt(shuffled.length - 1);
          final first = shuffled.first;
          shuffled[0] = shuffled[swap];
          shuffled[swap] = first;
        }
        order.addAll(shuffled);
      }
      return [for (final i in order) PlaybackStep(i)];
  }
}

enum ReadingPlaybackStatus {
  idle,
  playing,
  paused,

  /// Between two clips (the "Ayetler Arası Bekleme").
  waiting,
}

/// Plays a reading screen's segments on the app's single [AudioService] —
/// "Dinle" in the chosen [MemorizationMode] with repeats, speed and pauses
/// from [ReadingSettings], or one segment on its own play button — and
/// tells the screen which segment is active (to highlight and scroll to).
///
/// It plays one clip at a time ([AudioService.playAsset]) and notices the
/// end of a clip from the service's state, so anything else that starts a
/// sound simply takes over (never two sounds at once).
class ReadingPlaybackController extends ChangeNotifier {
  ReadingPlaybackController({
    required this.segments,
    required this.audio,
    ReadingSettings? settings,
    math.Random? random,
    this.repeatGap = const Duration(milliseconds: 700),
  }) : settings = settings ?? ReadingSettings.instance,
       _random = random {
    audio.addListener(_onAudio);
    this.settings.addListener(_onSettings);
    _appliedSpeed = this.settings.speed;
    unawaited(audio.setPlaybackRate(_appliedSpeed));
  }

  final List<ReadingSegment> segments;
  final AudioService audio;
  final ReadingSettings settings;
  final math.Random? _random;

  /// Short pause between two repeats of the same segment.
  final Duration repeatGap;

  ReadingPlaybackStatus _status = ReadingPlaybackStatus.idle;
  List<PlaybackStep> _plan = const [];
  int _step = 0;
  bool _single = false;
  Timer? _timer;
  bool _pausedWhileWaiting = false;
  bool _revealed = false;
  late double _appliedSpeed;

  /// The asset of the current clip, and whether the service has started
  /// it yet (its end is only counted after it started).
  String? _expected;
  bool _clipStarted = false;

  ReadingPlaybackStatus get status => _status;
  bool get isActive => _status != ReadingPlaybackStatus.idle;
  bool get isPlaying =>
      _status == ReadingPlaybackStatus.playing ||
      _status == ReadingPlaybackStatus.waiting;
  bool get isPaused => _status == ReadingPlaybackStatus.paused;

  /// "Dinle" (the whole reading) rather than one segment's own button.
  bool get isPlayingAll => isActive && !_single;

  /// The play order of the current "Dinle" (for tests / display).
  List<PlaybackStep> get plan => _plan;

  PlaybackStep? get currentStep =>
      isActive && _step < _plan.length ? _plan[_step] : null;

  /// Index in [segments] of the segment being read (or about to be read
  /// again / next after a pause); null when nothing plays.
  int? get activeIndex => currentStep?.segment;

  /// "Metni Gizle": in "Ayet Ayet" with the option on, the active
  /// segment's text is hidden once the student has heard it (from its
  /// second repeat, and in the pause after it) until "Göster".
  bool isTextHidden(int index) {
    final step = currentStep;
    if (step == null || _single || _revealed) return false;
    if (index != step.segment) return false;
    if (settings.mode != MemorizationMode.stepByStep ||
        !settings.hideTextWhileMemorizing) {
      return false;
    }
    return step.repeat > 1 || _status == ReadingPlaybackStatus.waiting;
  }

  /// "Göster": the hidden text comes back until the next segment.
  void reveal() {
    _revealed = true;
    notifyListeners();
  }

  /// "Dinle": from the first segment, in the chosen mode.
  Future<void> start() async {
    _cancelTimer();
    _single = false;
    _plan = buildPlaybackPlan(
      segments,
      mode: settings.mode,
      repeatCount: settings.repeatCount,
      random: _random,
    );
    _step = 0;
    if (_plan.isEmpty) return;
    await _playStep();
  }

  /// A segment's own play button: that segment once; pressed again while it
  /// is the active one, pause / resume.
  Future<void> playSingle(int index) async {
    if (_single && activeIndex == index) {
      if (_status == ReadingPlaybackStatus.playing) return pause();
      if (_status == ReadingPlaybackStatus.paused) return resume();
    }
    _cancelTimer();
    _single = true;
    _plan = [PlaybackStep(index)];
    _step = 0;
    await _playStep();
  }

  Future<void> pause() async {
    switch (_status) {
      case ReadingPlaybackStatus.waiting:
        _cancelTimer();
        _pausedWhileWaiting = true;
        _setStatus(ReadingPlaybackStatus.paused);
      case ReadingPlaybackStatus.playing:
        _pausedWhileWaiting = false;
        _setStatus(ReadingPlaybackStatus.paused);
        await audio.pause();
      case ReadingPlaybackStatus.paused:
      case ReadingPlaybackStatus.idle:
        break;
    }
  }

  Future<void> resume() async {
    if (_status != ReadingPlaybackStatus.paused) return;
    if (_pausedWhileWaiting) {
      _pausedWhileWaiting = false;
      await _advance();
      return;
    }
    _setStatus(ReadingPlaybackStatus.playing);
    await audio.resume();
  }

  Future<void> stop() async {
    _cancelTimer();
    final wasActive = isActive;
    _reset();
    notifyListeners();
    if (wasActive) await audio.stop();
  }

  Future<void> _playStep() async {
    final step = _plan[_step];
    final previous = _expected;
    _expected = segments[step.segment].audioAsset;
    _clipStarted = false;
    if (previous == null ||
        _step == 0 ||
        _plan[_step - 1].segment != step.segment) {
      _revealed = false;
    }
    _pausedWhileWaiting = false;
    _setStatus(ReadingPlaybackStatus.playing);
    await audio.playAsset(_expected!);
  }

  void _onAudio() {
    final expected = _expected;
    if (expected == null || _status == ReadingPlaybackStatus.idle) return;
    final current = audio.currentAsset;
    if (current == expected) {
      _clipStarted = true;
      return;
    }
    if (current != null) {
      // Something else started a sound: it takes over, this reading stops.
      _reset();
      notifyListeners();
      return;
    }
    // Stopped: the clip ended (or failed).
    if (_clipStarted && _status == ReadingPlaybackStatus.playing) {
      _clipStarted = false;
      _afterClip();
    }
  }

  void _afterClip() {
    if (_step + 1 >= _plan.length) {
      _reset();
      notifyListeners();
      return;
    }
    final sameNext = _plan[_step + 1].segment == _plan[_step].segment;
    final gap =
        sameNext ? repeatGap : Duration(seconds: settings.pauseSeconds);
    _setStatus(ReadingPlaybackStatus.waiting);
    _timer = Timer(gap, () => unawaited(_advance()));
  }

  Future<void> _advance() async {
    _cancelTimer();
    if (_step + 1 >= _plan.length) {
      _reset();
      notifyListeners();
      return;
    }
    _step++;
    await _playStep();
  }

  void _onSettings() {
    if (settings.speed != _appliedSpeed) {
      _appliedSpeed = settings.speed;
      unawaited(audio.setPlaybackRate(_appliedSpeed));
    }
    notifyListeners(); // e.g. "Metni Gizle" turned on / off
  }

  void _setStatus(ReadingPlaybackStatus status) {
    _status = status;
    notifyListeners();
  }

  void _reset() {
    _cancelTimer();
    _status = ReadingPlaybackStatus.idle;
    _plan = const [];
    _step = 0;
    _single = false;
    _expected = null;
    _clipStarted = false;
    _pausedWhileWaiting = false;
    _revealed = false;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    audio.removeListener(_onAudio);
    settings.removeListener(_onSettings);
    // Leaving the screen: stop, and the other screens play at normal speed.
    // (After this frame: the widget tree is locked while a screen closes.)
    final wasActive = isActive;
    _reset();
    final service = audio;
    Future.microtask(() async {
      if (wasActive) await service.stop();
      await service.setPlaybackRate(1.0);
    });
    super.dispose();
  }
}
