import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A play order (see `buildPlaybackPlan`). On screen there are only two
/// buttons: "Dinle" = [listenOnly]; "Ezberle" = [stepByStep], or [shuffled]
/// with the "Karışık sıra" option ([ReadingSettings.memorizeShuffled]).
enum MemorizationMode {
  /// Each part [ReadingSettings.repeatCount] times, then the next.
  stepByStep,

  /// The parts in a random order (never the same one twice in a row).
  shuffled,

  /// Start to end, in order.
  listenOnly,
}

/// The reading screens' settings (Sureler and Dualar share them), kept on the
/// device so a student sets them once: Arabic size, reading speed, what is
/// shown, and repeating / memorizing. One app-wide instance
/// ([ReadingSettings.instance]); it loads itself the first time a reading
/// screen opens ([ensureLoaded]) and saves every change.
class ReadingSettings extends ChangeNotifier {
  ReadingSettings._();

  static final ReadingSettings instance = ReadingSettings._();

  /// Arabic size, as a share of the base size of the reading screens'
  /// Arabic ([arabicBaseFontSize]): 100 % … 160 %. Default 130 %.
  static const List<double> arabicScales = [1.0, 1.15, 1.3, 1.45, 1.6];
  static const double defaultArabicScale = 1.3;

  static const List<double> speeds = [0.75, 0.85, 1.0, 1.15, 1.25];
  static const double defaultSpeed = 1.0;

  static const int minRepeat = 1;
  static const int maxRepeat = 10;

  /// "Ezberle": each part this many times unless the student picks another.
  static const int defaultRepeat = 3;

  /// Seconds between two parts.
  static const List<int> pauses = [1, 2, 3, 5];
  static const int defaultPause = 2;

  static const String _prefix = 'reading.';

  double _arabicScale = defaultArabicScale;
  double _speed = defaultSpeed;
  bool _showArabic = true;
  bool _showMeaning = false;
  int _repeatCount = defaultRepeat;
  int _pauseSeconds = defaultPause;
  bool _memorizeShuffled = false;
  bool _hideTextWhileMemorizing = false;

  double get arabicScale => _arabicScale;
  double get speed => _speed;
  bool get showArabic => _showArabic;
  bool get showMeaning => _showMeaning;
  int get repeatCount => _repeatCount;
  int get pauseSeconds => _pauseSeconds;
  /// "Karışık sıra": "Ezberle" takes the parts in a random order.
  bool get memorizeShuffled => _memorizeShuffled;

  /// The order "Ezberle" uses.
  MemorizationMode get memorizeMode =>
      _memorizeShuffled
          ? MemorizationMode.shuffled
          : MemorizationMode.stepByStep;
  bool get hideTextWhileMemorizing => _hideTextWhileMemorizing;

  /// The Arabic font size of a reading screen's text at 100 %, by screen
  /// class — the sizes the screens used before (the besmele a little
  /// smaller). Multiplied by [arabicScale].
  static double arabicBaseFontSize({required bool wide, required bool large}) =>
      large ? 46 : (wide ? 42 : 30);

  Future<void>? _loading;

  /// Reads the saved settings once (later calls wait for the same load).
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _arabicScale = _pick(
        prefs.getDouble('${_prefix}arabicScale'),
        arabicScales,
        defaultArabicScale,
      );
      _speed = _pick(prefs.getDouble('${_prefix}speed'), speeds, defaultSpeed);
      _showArabic = prefs.getBool('${_prefix}showArabic') ?? true;
      _showMeaning = prefs.getBool('${_prefix}showMeaning') ?? false;
      _repeatCount = (prefs.getInt('${_prefix}repeatCount') ??
              defaultRepeat)
          .clamp(
        minRepeat,
        maxRepeat,
      );
      final pause = prefs.getInt('${_prefix}pauseSeconds');
      _pauseSeconds = pauses.contains(pause) ? pause! : defaultPause;
      _memorizeShuffled =
          prefs.getBool('${_prefix}memorizeShuffled') ??
          // The first version kept a mode; "shuffled" means the same.
          prefs.getString('${_prefix}mode') == MemorizationMode.shuffled.name;
      _hideTextWhileMemorizing =
          prefs.getBool('${_prefix}hideTextWhileMemorizing') ?? false;
      notifyListeners();
    } catch (error) {
      // No storage (tests, private mode): the defaults stay.
      debugPrint('ReadingSettings: ayarlar okunamadı — $error');
    }
  }

  static double _pick(double? saved, List<double> allowed, double fallback) {
    if (saved == null) return fallback;
    for (final value in allowed) {
      if ((value - saved).abs() < 0.001) return value;
    }
    return fallback;
  }

  Future<void> _save(void Function(SharedPreferences prefs) write) async {
    try {
      write(await SharedPreferences.getInstance());
    } catch (error) {
      debugPrint('ReadingSettings: ayar kaydedilemedi — $error');
    }
  }

  set arabicScale(double value) {
    final scale = _pick(value, arabicScales, _arabicScale);
    if (scale == _arabicScale) return;
    _arabicScale = scale;
    notifyListeners();
    _save((p) => p.setDouble('${_prefix}arabicScale', scale));
  }

  /// One step smaller / larger Arabic ([arabicScales]).
  void stepArabicScale(int direction) {
    final i = arabicScales.indexOf(_arabicScale);
    final next = (i + direction).clamp(0, arabicScales.length - 1);
    arabicScale = arabicScales[next];
  }

  set speed(double value) {
    final speed = _pick(value, speeds, _speed);
    if (speed == _speed) return;
    _speed = speed;
    notifyListeners();
    _save((p) => p.setDouble('${_prefix}speed', speed));
  }

  set showArabic(bool value) {
    if (value == _showArabic) return;
    _showArabic = value;
    notifyListeners();
    _save((p) => p.setBool('${_prefix}showArabic', value));
  }

  set showMeaning(bool value) {
    if (value == _showMeaning) return;
    _showMeaning = value;
    notifyListeners();
    _save((p) => p.setBool('${_prefix}showMeaning', value));
  }

  set repeatCount(int value) {
    final count = value.clamp(minRepeat, maxRepeat);
    if (count == _repeatCount) return;
    _repeatCount = count;
    notifyListeners();
    _save((p) => p.setInt('${_prefix}repeatCount', count));
  }

  set pauseSeconds(int value) {
    if (!pauses.contains(value) || value == _pauseSeconds) return;
    _pauseSeconds = value;
    notifyListeners();
    _save((p) => p.setInt('${_prefix}pauseSeconds', value));
  }

  set memorizeShuffled(bool value) {
    if (value == _memorizeShuffled) return;
    _memorizeShuffled = value;
    notifyListeners();
    _save((p) => p.setBool('${_prefix}memorizeShuffled', value));
  }

  set hideTextWhileMemorizing(bool value) {
    if (value == _hideTextWhileMemorizing) return;
    _hideTextWhileMemorizing = value;
    notifyListeners();
    _save((p) => p.setBool('${_prefix}hideTextWhileMemorizing', value));
  }

  /// Back to the defaults and "not loaded" (tests).
  @visibleForTesting
  void resetForTest() {
    _arabicScale = defaultArabicScale;
    _speed = defaultSpeed;
    _showArabic = true;
    _showMeaning = false;
    _repeatCount = defaultRepeat;
    _pauseSeconds = defaultPause;
    _memorizeShuffled = false;
    _hideTextWhileMemorizing = false;
    _loading = null;
    notifyListeners();
  }
}
