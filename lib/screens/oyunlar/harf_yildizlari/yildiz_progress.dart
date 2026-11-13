import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'yildiz_data.dart';
import 'yildiz_engine.dart';

/// Bir dersin tamamlanma sonucu (sonuç ekranı için).
class YildizCompletion {
  const YildizCompletion({
    required this.practiceXp,
    required this.bonusXp,
    required this.newBadge,
    required this.firstCompletion,
    required this.needsReview,
  });

  final int practiceXp;
  final int bonusXp;
  final String? newBadge;
  final bool firstCompletion;

  /// Henüz pekişmemiş harfler (yumuşak "tekrar edelim" mesajı için).
  final List<String> needsReview;

  int get totalXp => practiceXp + bonusXp;
}

/// Harf başına kayıt: ilk seferde doğru, destekle doğru, sonraki tekrarda
/// doğru ayrı sayılır; tek doğru cevap "tam öğrendi" demek değildir.
class YildizLetterRecord {
  YildizLetterRecord({
    this.firstTry = 0,
    this.assisted = 0,
    this.retryOk = 0,
    this.needsReview = false,
  });

  int firstTry;
  int assisted;
  int retryOk;
  bool needsReview;

  /// Yeterince pekişti: tekrarda doğru ya da en az iki kez ilk seferde doğru.
  bool get solid => !needsReview && (retryOk > 0 || firstTry >= 2);

  Map<String, Object?> toJson() => {
    'f': firstTry,
    'a': assisted,
    'r': retryOk,
    'n': needsReview,
  };

  static YildizLetterRecord fromJson(Map json) => YildizLetterRecord(
    firstTry: json['f'] as int? ?? 0,
    assisted: json['a'] as int? ?? 0,
    retryOk: json['r'] as int? ?? 0,
    needsReview: json['n'] as bool? ?? false,
  );
}

String yildizDayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Harf Yıldızları ilerlemesi (yalnızca cihazda, `SharedPreferences`).
/// XP, tamamlanan dersler, rozetler, tekrar ihtiyacı, çalışma günleri,
/// yarım kalan oturum ve soru sayısı ayarı.
class YildizProgress extends ChangeNotifier {
  YildizProgress({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const String prefsKey = 'harf_yildizlari.v1';

  final DateTime Function() _clock;

  int xp = 0;
  int preset = 1; // 0 kısa, 1 normal, 2 uzun
  final Map<String, int> completions = {};
  final Set<String> badges = {};
  final Map<String, YildizLetterRecord> letters = {};
  final Set<String> studyDays = {};
  final Map<String, Map<String, Object?>> sessions = {};

  DateTime get now => _clock();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map;
      xp = json['xp'] as int? ?? 0;
      preset = (json['preset'] as int? ?? 1).clamp(0, 2);
      completions
        ..clear()
        ..addAll(
          ((json['completions'] as Map?) ?? {}).map(
            (k, v) => MapEntry(k as String, v as int),
          ),
        );
      badges
        ..clear()
        ..addAll(((json['badges'] as List?) ?? []).cast<String>());
      studyDays
        ..clear()
        ..addAll(((json['days'] as List?) ?? []).cast<String>());
      letters
        ..clear()
        ..addAll(
          ((json['letters'] as Map?) ?? {}).map(
            (k, v) =>
                MapEntry(k as String, YildizLetterRecord.fromJson(v as Map)),
          ),
        );
      sessions
        ..clear()
        ..addAll(
          ((json['sessions'] as Map?) ?? {}).map(
            (k, v) =>
                MapEntry(k as String, Map<String, Object?>.from(v as Map)),
          ),
        );
    } catch (error) {
      debugPrint('YildizProgress: kayıt okunamadı, boş başlıyor — $error');
      xp = 0;
      completions.clear();
      badges.clear();
      studyDays.clear();
      letters.clear();
      sessions.clear();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefsKey,
        jsonEncode({
          'xp': xp,
          'preset': preset,
          'completions': completions,
          'badges': badges.toList(),
          'days': studyDays.toList()..sort(),
          'letters': {for (final e in letters.entries) e.key: e.value.toJson()},
          'sessions': sessions,
        }),
      );
    } catch (error) {
      debugPrint('YildizProgress: kayıt yazılamadı — $error');
    }
  }

  // --- Dersler -------------------------------------------------------

  bool isCompleted(String lessonId) => (completions[lessonId] ?? 0) > 0;

  bool isUnlocked(YildizLesson lesson) => lesson.requires.every(isCompleted);

  /// Açılmayan dersin sebebi (çocuğa gösterilen kısa metin).
  String? lockedReason(YildizLesson lesson) {
    final missing = [
      for (final id in lesson.requires)
        if (!isCompleted(id)) yildizLessonById(id).title,
    ];
    if (missing.isEmpty) return null;
    return 'Önce bitir: ${missing.join(', ')}';
  }

  /// Sıradaki ana ders (haritada vurgulanır): tamamlanmamış ilk açık ders.
  YildizLesson? get nextLesson {
    for (final lesson in kYildizLessons) {
      if (!isCompleted(lesson.id) && isUnlocked(lesson)) return lesson;
    }
    return null;
  }

  Set<String> reviewKeys(YildizLesson lesson) => {
    for (final letter in lesson.letters)
      if (letters[yildizKey(letter)]?.needsReview ?? false) yildizKey(letter),
  };

  int get solidLetterCount =>
      letters.values.where((record) => record.solid).length;

  // --- Ayar ------------------------------------------------------------

  Future<void> setPreset(int value) async {
    preset = value.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  // --- Yarım kalan oturum ----------------------------------------------

  YildizSession? resume(YildizLesson lesson) {
    final json = sessions[lesson.id];
    if (json == null) return null;
    final session = YildizSession.restore(lesson, json);
    if (session == null || session.isDone) {
      sessions.remove(lesson.id);
      return null;
    }
    return session;
  }

  /// Bir dersin yarım kalan oturumunun (tamamlanan/temel) ilerlemesi.
  (int, int)? partial(String lessonId) {
    final json = sessions[lessonId];
    if (json == null) return null;
    final done = json['baseDone'] as int?;
    final count = json['count'] as int?;
    if (done == null || count == null) return null;
    return (done, count);
  }

  Future<void> saveSession(YildizSession session) async {
    if (session.finished) return;
    sessions[session.lesson.id] = session.toJson();
    if (session.baseDone >= YildizRewards.meaningfulQuestions) {
      studyDays.add(yildizDayKey(now));
    }
    notifyListeners();
    await _save();
  }

  Future<void> discardSession(String lessonId) async {
    if (sessions.remove(lessonId) != null) {
      notifyListeners();
      await _save();
    }
  }

  // --- Tamamlama (tek yerde ödül kuralları) ------------------------------

  /// Dersi bitirir. Bir oturum için yalnızca bir kez çalışır (çift yazım yok).
  Future<YildizCompletion> complete(YildizSession session) async {
    final lesson = session.lesson;
    if (session.finished) {
      return const YildizCompletion(
        practiceXp: 0,
        bonusXp: 0,
        newBadge: null,
        firstCompletion: false,
        needsReview: [],
      );
    }
    session.finished = true;
    final first = !isCompleted(lesson.id);
    final bonus = first ? YildizRewards.firstCompletionBonus : 0;
    xp += session.xp + bonus;
    completions[lesson.id] = (completions[lesson.id] ?? 0) + 1;
    String? newBadge;
    if (lesson.badge != null && badges.add(lesson.badge!)) {
      newBadge = lesson.badge;
    }
    void merge(
      Map<String, int> from,
      void Function(YildizLetterRecord, int) f,
    ) {
      from.forEach(
        (key, n) => f(letters.putIfAbsent(key, YildizLetterRecord.new), n),
      );
    }

    merge(session.firstTry, (r, n) => r.firstTry += n);
    merge(session.assisted, (r, n) => r.assisted += n);
    merge(session.retryOk, (r, n) => r.retryOk += n);
    for (final key in session.needsReview) {
      letters.putIfAbsent(key, YildizLetterRecord.new).needsReview = true;
    }
    // Bu oturumda tekrarda ya da yeniden ilk seferde doğru bilinenler temizlenir.
    for (final key in {...session.retryOk.keys, ...session.firstTry.keys}) {
      if (!session.needsReview.contains(key)) {
        letters[key]?.needsReview = false;
      }
    }
    sessions.remove(lesson.id);
    studyDays.add(yildizDayKey(now));
    notifyListeners();
    await _save();
    return YildizCompletion(
      practiceXp: session.xp,
      bonusXp: bonus,
      newBadge: newBadge,
      firstCompletion: first,
      needsReview: [...session.needsReview],
    );
  }

  /// Bir turun sonunda da gün kaydedilir (anlamlı çalışma).
  Future<void> markStudyDay() async {
    if (studyDays.add(yildizDayKey(now))) {
      notifyListeners();
      await _save();
    }
  }

  // --- Günlük ilerleme --------------------------------------------------

  /// Bu haftada (pazartesi başlangıçlı) çalışılan gün sayısı.
  int get daysThisWeek {
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    var n = 0;
    for (var i = 0; i < 7; i++) {
      if (studyDays.contains(yildizDayKey(monday.add(Duration(days: i))))) n++;
    }
    return n;
  }

  /// Üst üste çalışılan gün sayısı; bugün henüz çalışılmadıysa dünden sayılır.
  int get streak {
    var day = DateTime(now.year, now.month, now.day);
    if (!studyDays.contains(yildizDayKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var n = 0;
    while (studyDays.contains(yildizDayKey(day))) {
      n++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return n;
  }

  /// Hiç suçlamayan, olumlu hafta mesajı.
  String get weekMessage {
    final n = daysThisWeek;
    if (n == 0) return 'Hazır olduğunda yıldızlar seni bekliyor.';
    return 'Bu hafta $n gün çalıştın!';
  }
}
