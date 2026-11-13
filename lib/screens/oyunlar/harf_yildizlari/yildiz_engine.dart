import 'dart:math' as math;

import '../../../models/arabic_letter.dart';
import '../harf_dedektifi/dedektif_data.dart';
import 'yildiz_data.dart';

/// Soru türleri: sesten harf bul, harfin adını eşle, kelimede harfi bul.
enum YildizQuestionType { listen, match, shape }

class YildizOption {
  const YildizOption({required this.id, this.arabic, this.label});

  /// Harf anahtarı (listen/match) ya da kelimenin metni (shape).
  final String id;
  final String? arabic;
  final String? label;
}

class YildizQuestion {
  const YildizQuestion({
    required this.type,
    required this.letterKey,
    required this.options,
    required this.correctIndex,
    this.isRetry = false,
  });

  final YildizQuestionType type;
  final String letterKey;
  final List<YildizOption> options;
  final int correctIndex;
  final bool isRetry;

  ArabicLetter get letter => yildizLetterByKey(letterKey)!;
}

/// Bir sorunun cevaplanış biçimi. "İlk seferde" ile "destekle" ayrı tutulur.
enum YildizOutcome { firstTry, assisted }

enum YildizAnswerKind { correct, wrong, guided }

class YildizAnswer {
  const YildizAnswer(this.kind, {this.completed = false});
  final YildizAnswerKind kind;

  /// Soru bu cevapla bitti mi (doğru ya da yönlendirmeli çözüm).
  final bool completed;
}

/// Soru üretimi (saf Dart, tohumlu).
abstract final class YildizQuestions {
  static bool hasAudio(ArabicLetter letter) =>
      (letter.audioAsset ?? '').isNotEmpty;

  /// Kelimede harfi buldurma yalnızca rehberin (Ders 2) örnek kelimeleri
  /// varsa sorulur; kelime uydurulmaz.
  static bool canAskShape(ArabicLetter letter) {
    final id = detectiveIdOf(letter);
    return id != null && wordsContaining(id).isNotEmpty;
  }

  /// [count] soruluk temel akış: her harf en az bir kez, art arda aynı harf
  /// yok, [priority] (tekrar gereken) harfler başa yakın.
  static List<YildizQuestion> buildBase(
    YildizLesson lesson,
    int count,
    int seed, {
    Set<String> priority = const {},
  }) {
    final rng = math.Random(seed);
    final letters = lesson.letters;
    final total = math.max(count, letters.length);
    final sequence = <ArabicLetter>[];
    while (sequence.length < total) {
      final round = List.of(letters)..shuffle(rng);
      round.sort((a, b) {
        final pa = priority.contains(yildizKey(a)) ? 0 : 1;
        final pb = priority.contains(yildizKey(b)) ? 0 : 1;
        return pa.compareTo(pb);
      });
      if (sequence.isNotEmpty &&
          round.length > 1 &&
          round.first == sequence.last) {
        round.add(round.removeAt(0));
      }
      sequence.addAll(round.take(total - sequence.length));
    }
    final types = [
      YildizQuestionType.listen,
      YildizQuestionType.match,
      YildizQuestionType.shape,
    ];
    return [
      for (var i = 0; i < sequence.length; i++)
        make(lesson, sequence[i], _typeFor(sequence[i], types[i % 3], i), rng),
    ];
  }

  static YildizQuestionType _typeFor(
    ArabicLetter letter,
    YildizQuestionType wanted,
    int i,
  ) {
    var type = wanted;
    if (type == YildizQuestionType.shape && !canAskShape(letter)) {
      type = i.isEven ? YildizQuestionType.listen : YildizQuestionType.match;
    }
    if (type == YildizQuestionType.listen && !hasAudio(letter)) {
      type = YildizQuestionType.match;
    }
    return type;
  }

  /// Hata yapılan harf için, [avoid] dışında bir türde tekrar sorusu.
  static YildizQuestion retry(
    YildizLesson lesson,
    ArabicLetter letter,
    YildizQuestionType avoid,
    math.Random rng,
  ) {
    final candidates = [
      for (final t in YildizQuestionType.values)
        if (t != avoid) _typeFor(letter, t, 0),
    ]..removeWhere((t) => t == avoid);
    final type =
        candidates.isEmpty
            ? _typeFor(letter, avoid, 0)
            : candidates[rng.nextInt(candidates.length)];
    return make(lesson, letter, type, rng, isRetry: true);
  }

  static YildizQuestion make(
    YildizLesson lesson,
    ArabicLetter letter,
    YildizQuestionType type,
    math.Random rng, {
    bool isRetry = false,
  }) {
    final key = yildizKey(letter);
    if (type == YildizQuestionType.shape) {
      final id = detectiveIdOf(letter)!;
      final correct = (List.of(wordsContaining(id))..shuffle(rng)).first;
      final others = [
        for (final w in kDetectiveWords)
          if (w.occurrencesOf(id).isEmpty) w,
      ]..shuffle(rng);
      final words = [correct, ...others.take(2)]..shuffle(rng);
      return YildizQuestion(
        type: type,
        letterKey: key,
        isRetry: isRetry,
        options: [
          for (final w in words) YildizOption(id: w.text, arabic: w.text),
        ],
        correctIndex: words.indexOf(correct),
      );
    }
    // Çeldiriciler dersin kendi harflerinden; yetmezse rehber sırasındaki
    // komşu harflerden.
    final pool = [
      for (final l in lesson.letters)
        if (l != letter) l,
    ]..shuffle(rng);
    if (pool.length < 3) {
      final extra = [
        for (final l in kYildizLetters)
          if (l != letter && !pool.contains(l)) l,
      ]..shuffle(rng);
      pool.addAll(extra);
    }
    final picked = [letter, ...pool.take(3)]..shuffle(rng);
    return YildizQuestion(
      type: type,
      letterKey: key,
      isRetry: isRetry,
      options: [
        for (final l in picked)
          type == YildizQuestionType.listen
              ? YildizOption(id: yildizKey(l), arabic: l.isolatedForm)
              : YildizOption(id: yildizKey(l), label: l.turkishName ?? ''),
      ],
      correctIndex: picked.indexOf(letter),
    );
  }
}

class _PendingRetry {
  _PendingRetry(this.letterKey, this.dueAfter, this.avoid);
  final String letterKey;
  final int dueAfter; // bu kadar temel soru bittikten sonra sorulabilir
  final YildizQuestionType avoid;
}

/// Bir dersin oturumu: soru akışı, yanlışlar, tekrar kuyruğu, XP.
/// Arayüzden bağımsızdır; yarım kalma için [toJson]/[restore].
class YildizSession {
  YildizSession({
    required this.lesson,
    required this.count,
    required this.seed,
    Set<String> priority = const {},
  }) : priority = Set.unmodifiable(priority),
       base = YildizQuestions.buildBase(
         lesson,
         count,
         seed,
         priority: priority,
       ),
       _rng = math.Random(seed ^ 0x5bd1e995) {
    _advance();
  }

  final YildizLesson lesson;
  final int count;
  final int seed;
  final Set<String> priority;
  final List<YildizQuestion> base;
  final math.Random _rng;

  final List<_PendingRetry> _pending = [];
  final Map<String, int> _retryCount = {};

  int _baseIndex = 0;
  int baseDone = 0;
  int xp = 0;
  int _wrongInQuestion = 0;
  final Set<int> _wrongOptions = {};
  YildizQuestion? current;
  bool _currentCompleted = false;
  YildizOutcome? lastOutcome;
  bool finished = false;

  /// Oturumda ilk seferde / destekle tamamlanan harfler (kayıt için).
  final Map<String, int> firstTry = {};
  final Map<String, int> assisted = {};
  final Map<String, int> retryOk = {};
  final Set<String> needsReview = {};

  int get baseTotal => base.length;

  /// Temel sorular bitti, kalan tekrarlar "pekiştirme".
  bool get inReinforcement => baseDone >= baseTotal && current != null;

  bool get currentCompleted => _currentCompleted;
  Set<int> get wrongOptions => Set.unmodifiable(_wrongOptions);
  int get wrongInQuestion => _wrongInQuestion;

  int get total => baseTotal;

  /// Bir tur bitti mi (tur arası gösterilecek).
  bool get atTourBreak {
    final tour = lesson.tourSize;
    return tour != null &&
        _currentCompleted &&
        !current!.isRetry &&
        baseDone < baseTotal &&
        baseDone % tour == 0;
  }

  /// Dokunulan seçeneği işler. Tamamlanmış soruda yok sayılır.
  YildizAnswer answer(int optionIndex) {
    final q = current;
    if (q == null || _currentCompleted || _wrongOptions.contains(optionIndex)) {
      return const YildizAnswer(YildizAnswerKind.wrong);
    }
    if (optionIndex == q.correctIndex) {
      _complete(
        _wrongInQuestion == 0 ? YildizOutcome.firstTry : YildizOutcome.assisted,
      );
      return const YildizAnswer(YildizAnswerKind.correct, completed: true);
    }
    _wrongInQuestion++;
    _wrongOptions.add(optionIndex);
    if (_wrongInQuestion >= YildizRewards.maxWrongBeforeGuide) {
      _complete(YildizOutcome.assisted);
      return const YildizAnswer(YildizAnswerKind.guided, completed: true);
    }
    return const YildizAnswer(YildizAnswerKind.wrong);
  }

  void _complete(YildizOutcome outcome) {
    final q = current!;
    _currentCompleted = true;
    lastOutcome = outcome;
    final key = q.letterKey;
    if (!q.isRetry) {
      baseDone++;
      xp += YildizRewards.practiceXp; // soru başına bir kez
      if (outcome == YildizOutcome.firstTry) {
        firstTry[key] = (firstTry[key] ?? 0) + 1;
      } else {
        assisted[key] = (assisted[key] ?? 0) + 1;
        _scheduleRetry(key, q.type);
      }
      return;
    }
    // Tekrar sorusu: XP yok, başarı ayrı sayılır.
    if (outcome == YildizOutcome.firstTry) {
      retryOk[key] = (retryOk[key] ?? 0) + 1;
      needsReview.remove(key);
    } else {
      needsReview.add(key);
      // Temel sorular sürüyorsa bir kez daha denenebilir.
      if (baseDone < baseTotal) _scheduleRetry(key, q.type);
    }
  }

  void _scheduleRetry(String key, YildizQuestionType avoid) {
    needsReview.add(key);
    final used = _retryCount[key] ?? 0;
    if (used >= YildizRewards.maxRetriesPerLetter) return;
    if (_pending.any((p) => p.letterKey == key)) return;
    _retryCount[key] = used + 1;
    _pending.add(_PendingRetry(key, baseDone + YildizRewards.retryGap, avoid));
  }

  /// Sıradaki soruya geçer; hepsi bittiyse [current] null olur.
  void next() {
    _advance();
  }

  void _advance() {
    _wrongInQuestion = 0;
    _wrongOptions.clear();
    _currentCompleted = false;
    // Zamanı gelen tekrar (temel sorular sürerken).
    final dueIndex = _pending.indexWhere((p) => p.dueAfter <= baseDone);
    if (_baseIndex < base.length && dueIndex >= 0) {
      current = _retryQuestion(_pending.removeAt(dueIndex));
      return;
    }
    if (_baseIndex < base.length) {
      current = base[_baseIndex++];
      return;
    }
    // Temel sorular bitti: kalan tekrarlar kısa pekiştirme turu.
    if (_pending.isNotEmpty) {
      current = _retryQuestion(_pending.removeAt(0));
      return;
    }
    current = null;
  }

  YildizQuestion _retryQuestion(_PendingRetry p) => YildizQuestions.retry(
    lesson,
    yildizLetterByKey(p.letterKey)!,
    p.avoid,
    _rng,
  );

  bool get isDone => current == null;

  Map<String, Object?> toJson() => {
    'seed': seed,
    'priority': priority.toList(),
    'count': count,
    'baseIndex':
        _baseIndex -
        (_currentCompleted
            ? 0
            : (current != null && !current!.isRetry ? 1 : 0)),
    'baseDone': baseDone,
    'xp': xp,
    'pending': [
      if (current != null && current!.isRetry && !_currentCompleted)
        [current!.letterKey, baseDone, current!.type.index],
      for (final p in _pending) [p.letterKey, p.dueAfter, p.avoid.index],
    ],
    'retries': _retryCount,
    'firstTry': firstTry,
    'assisted': assisted,
    'retryOk': retryOk,
    'needsReview': needsReview.toList(),
  };

  /// Kayıttan devam: tamamlanmış sorulardan sonraki noktadan başlar.
  static YildizSession? restore(
    YildizLesson lesson,
    Map<String, Object?> json,
  ) {
    try {
      final session = YildizSession(
        lesson: lesson,
        count: json['count']! as int,
        seed: json['seed']! as int,
        priority:
            ((json['priority'] as List?) ?? const []).cast<String>().toSet(),
      );
      session._baseIndex = (json['baseIndex']! as int).clamp(
        0,
        session.base.length,
      );
      session.baseDone = (json['baseDone']! as int).clamp(
        0,
        session.base.length,
      );
      session.xp = json['xp']! as int;
      session._pending.clear();
      for (final p in (json['pending']! as List).cast<List>()) {
        session._pending.add(
          _PendingRetry(
            p[0] as String,
            p[1] as int,
            YildizQuestionType.values[p[2] as int],
          ),
        );
      }
      void readMap(String name, Map<String, int> into) {
        (json[name] as Map?)?.forEach((k, v) => into[k as String] = v as int);
      }

      readMap('retries', session._retryCount);
      readMap('firstTry', session.firstTry);
      readMap('assisted', session.assisted);
      readMap('retryOk', session.retryOk);
      session.needsReview.addAll(
        ((json['needsReview'] as List?) ?? const []).cast<String>(),
      );
      session._advance();
      return session;
    } catch (_) {
      return null;
    }
  }
}

/// Soru sayısı ayarı: harf sayısının altına inmez (her harf temsil edilir).
int yildizQuestionCount(YildizLesson lesson, int preset) {
  const factors = [0.75, 1.0, 1.5];
  final wanted = (lesson.baseQuestions * factors[preset.clamp(0, 2)]).round();
  return math.max(wanted, lesson.letterCount);
}
