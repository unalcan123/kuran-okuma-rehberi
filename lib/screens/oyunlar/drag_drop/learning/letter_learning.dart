import 'dart:math' as math;

import '../../../../data/drag_drop_game_data.dart';
import '../../../../models/arabic_letter.dart';

/// Sürükle & Bırak'ın kademeli öğrenme yolu (saf Dart; kayıt ve arayüz ayrı).
///
/// * 29 harf ([kDragDropAllLetters], Elifba sırası, Lâm Elif dahil) 3'erli
///   gruplara bölünür: önce grubun yeni harfleri öğretilir ([LearnPhase.learn]),
///   sonra eski harflerle karışık test ([LearnPhase.review], en az %80 ilk
///   denemede doğru), zorlanılan harf varsa kısa pekiştirme
///   ([LearnPhase.reinforce]). Test geçilemezse yalnızca zorlanılan harfler
///   çalışılır ve test tekrarlanır; oyun baştan başlamaz.
/// * Her harfin kendi durumu var ([LetterProgress]); seviye tek doğruyla
///   yükselmez (art arda 2 ilk-deneme doğru), 2. seviyeden sonra yalnızca
///   tekrar zamanı gelmişse yükselir (aralıklar 1, 3, 7, 14 gün).
/// * Tekrar soruları %45 zorlanılan, %35 öğrenilmekte olan, %20 iyi bilinen
///   harflerden seçilir; bir sınıfta yeterli harf yoksa pay diğerlerine geçer.
/// * 29 harf bitince oyun bitmez: [LearnPhase.mastery] bütün harflerle sürer.

/// Harf kimliği = tek başına yazılış (oyun kartları da bunu kullanır).
String letterIdOf(ArabicLetter letter) => letter.isolatedForm;

const int kLearnGroupSize = 3;

/// Bir yeni harfin öğrenme turlarında kaç kez ilk denemede doğru
/// eşleştirilmesi gerekir.
const int kLearnCorrectNeeded = 2;

/// Karışık testin en az kaç sorudan oluşacağı.
const int kReviewTestItems = 6;

/// Testi geçme oranı (ilk denemede doğru / soru).
const double kReviewPassRate = 0.8;

/// Seviyeye göre tekrar aralığı (gün). Seviye 0-1 aynı oturumda tekrarlanır.
const List<int> kReviewIntervalDays = [0, 0, 1, 3, 7, 14];

const int kMaxLevel = 5;

/// Birbirine benzeyen harf aileleri (yalnızca noktalar/çizgi farklı).
const List<List<String>> kSimilarLetterGroups = [
  ['ب', 'ت', 'ث'],
  ['ج', 'ح', 'خ'],
  ['د', 'ذ'],
  ['ر', 'ز'],
  ['س', 'ش'],
  ['ص', 'ض'],
  ['ط', 'ظ'],
  ['ع', 'غ'],
  ['ف', 'ق'],
];

int? similarGroupOf(String id) {
  for (var i = 0; i < kSimilarLetterGroups.length; i++) {
    if (kSimilarLetterGroups[i].contains(id)) return i;
  }
  return null;
}

/// Öğrenme yolu: 3'erli gruplar (son grup 2 harf).
List<List<ArabicLetter>> learningGroups([List<ArabicLetter>? letters]) {
  final all = letters ?? kDragDropAllLetters;
  return [
    for (var i = 0; i < all.length; i += kLearnGroupSize)
      all.sublist(i, math.min(i + kLearnGroupSize, all.length)),
  ];
}

enum DragDropDifficulty {
  /// 3 kart, büyük, süre yok, yanlıştan sonra doğru harf parlar.
  easy('Kolay', 3),

  /// 6 kart, eski + yeni karışık; ipucu ancak 2 yanlıştan sonra.
  medium('Orta', 6),

  /// 6 kart, bütün öğrenilmiş harflerden; benzer harfler yan yana,
  /// ipucu yok, renkli kart vurgusu yok.
  hard('Zor', 6);

  const DragDropDifficulty(this.label, this.cards);
  final String label;
  final int cards;

  /// Kaç yanlıştan sonra doğru harf parlar (null = hiç).
  int? get hintAfterMisses => switch (this) {
    easy => 1,
    medium => 2,
    hard => null,
  };

  static DragDropDifficulty fromName(String? name) => values.firstWhere(
    (d) => d.name == name,
    orElse: () => DragDropDifficulty.easy,
  );
}

enum LearnPhase { learn, review, reinforce, mastery }

/// Bir turun türü (ekrandaki başlık ve sonrası buna göre).
enum RoundKind { learn, review, reinforce, mastery, daily }

class LetterProgress {
  LetterProgress({
    required this.id,
    this.seen = 0,
    this.correct = 0,
    this.wrong = 0,
    this.streak = 0,
    this.lastStudied,
    this.level = 0,
    this.dueAt,
    this.difficulty = 0,
  });

  final String id;
  int seen;
  int correct;
  int wrong;

  /// Art arda ilk denemede doğru sayısı.
  int streak;
  DateTime? lastStudied;

  /// 0 yeni … 5 ustalaştı.
  int level;

  /// Bir sonraki tekrar zamanı (null = henüz yok).
  DateTime? dueAt;

  /// Zorlanma puanı: yanlışta artar, ilk denemede doğruda azalır (0-5).
  double difficulty;

  bool isDue(DateTime now) => dueAt != null && !dueAt!.isAfter(now);

  Map<String, Object?> toJson() => {
    'id': id,
    'seen': seen,
    'correct': correct,
    'wrong': wrong,
    'streak': streak,
    'lastStudied': lastStudied?.millisecondsSinceEpoch,
    'level': level,
    'dueAt': dueAt?.millisecondsSinceEpoch,
    'difficulty': difficulty,
  };

  static LetterProgress? tryFromJson(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    int i(String k) => (raw[k] is num) ? (raw[k] as num).toInt() : 0;
    DateTime? t(String k) => raw[k] is num
        ? DateTime.fromMillisecondsSinceEpoch((raw[k] as num).toInt())
        : null;
    return LetterProgress(
      id: raw['id'] as String,
      seen: i('seen'),
      correct: i('correct'),
      wrong: i('wrong'),
      streak: i('streak'),
      lastStudied: t('lastStudied'),
      level: i('level').clamp(0, kMaxLevel),
      dueAt: t('dueAt'),
      difficulty: (raw['difficulty'] is num)
          ? (raw['difficulty'] as num).toDouble().clamp(0.0, 5.0)
          : 0,
    );
  }
}

/// Oyuncunun öğrenme durumu (kayıt: [LearningRepository]).
class LearningState {
  LearningState({
    this.group = 0,
    this.phase = LearnPhase.learn,
    Map<String, int>? stageCorrect,
    Set<String>? testedNew,
    this.testItems = 0,
    this.testFirstTry = 0,
    this.testPassed = false,
    Set<String>? struggled,
    Map<String, LetterProgress>? letters,
    Map<int, int>? confusions,
    this.lastDailyReview,
    this.stars = 0,
    this.rounds = 0,
    this.difficulty = DragDropDifficulty.easy,
    List<String>? lastRound,
    this.updatedAt = 0,
  }) : stageCorrect = stageCorrect ?? {},
       testedNew = testedNew ?? {},
       struggled = struggled ?? {},
       letters = letters ?? {},
       confusions = confusions ?? {},
       lastRound = lastRound ?? [];

  /// Şu an öğretilen grubun sırası; grup sayısına eşitse bütün harfler
  /// öğrenilmiştir.
  int group;
  LearnPhase phase;

  /// Bu aşamada yeni harflerin ilk denemede doğru sayısı.
  final Map<String, int> stageCorrect;

  /// Karışık testte sorulmuş yeni harfler.
  final Set<String> testedNew;
  int testItems;
  int testFirstTry;
  bool testPassed;

  /// Bu aşamada zorlanılan (yanlış yapılan) harfler — pekiştirilecek.
  final Set<String> struggled;
  final Map<String, LetterProgress> letters;

  /// Benzer harf ailesi → karıştırma sayısı.
  final Map<int, int> confusions;

  /// Son günlük tekrarın günü (yyyy-mm-dd).
  String? lastDailyReview;
  int stars;
  int rounds;
  DragDropDifficulty difficulty;

  /// Son turun harfleri (art arda aynı harfleri sormamak için).
  final List<String> lastRound;

  /// Son değişiklik (ms) — cihaz/bulut kopyası arasında yenisi seçilir.
  int updatedAt;

  LetterProgress progressOf(String id) =>
      letters.putIfAbsent(id, () => LetterProgress(id: id));

  Map<String, Object?> toJson() => {
    'v': 1,
    'group': group,
    'phase': phase.name,
    'stageCorrect': stageCorrect,
    'testedNew': testedNew.toList(),
    'testItems': testItems,
    'testFirstTry': testFirstTry,
    'testPassed': testPassed,
    'struggled': struggled.toList(),
    'letters': [for (final p in letters.values) p.toJson()],
    'confusions': {for (final e in confusions.entries) '${e.key}': e.value},
    'lastDailyReview': lastDailyReview,
    'stars': stars,
    'rounds': rounds,
    'difficulty': difficulty.name,
    'lastRound': lastRound,
    'updatedAt': updatedAt,
  };

  static LearningState fromJson(Object? raw, {int? groupCount}) {
    if (raw is! Map) return LearningState();
    final groups = groupCount ?? learningGroups().length;
    int i(String k) => (raw[k] is num) ? (raw[k] as num).toInt() : 0;
    List<String> strings(String k) =>
        raw[k] is List ? [for (final x in raw[k] as List) if (x is String) x] : [];
    final letters = <String, LetterProgress>{};
    if (raw['letters'] is List) {
      for (final item in raw['letters'] as List) {
        final p = LetterProgress.tryFromJson(item);
        if (p != null) letters[p.id] = p;
      }
    }
    return LearningState(
      group: i('group').clamp(0, groups),
      phase: LearnPhase.values.firstWhere(
        (p) => p.name == raw['phase'],
        orElse: () => LearnPhase.learn,
      ),
      stageCorrect: raw['stageCorrect'] is Map
          ? {
              for (final e in (raw['stageCorrect'] as Map).entries)
                if (e.value is num) '${e.key}': (e.value as num).toInt(),
            }
          : null,
      testedNew: strings('testedNew').toSet(),
      testItems: i('testItems'),
      testFirstTry: i('testFirstTry'),
      testPassed: raw['testPassed'] == true,
      struggled: strings('struggled').toSet(),
      letters: letters,
      confusions: raw['confusions'] is Map
          ? {
              for (final e in (raw['confusions'] as Map).entries)
                if (int.tryParse('${e.key}') != null && e.value is num)
                  int.parse('${e.key}'): (e.value as num).toInt(),
            }
          : null,
      lastDailyReview: raw['lastDailyReview'] is String
          ? raw['lastDailyReview'] as String
          : null,
      stars: i('stars'),
      rounds: i('rounds'),
      difficulty: DragDropDifficulty.fromName(raw['difficulty'] as String?),
      lastRound: strings('lastRound'),
      updatedAt: i('updatedAt'),
    );
  }
}

/// Bir tur: ekrana gelecek harfler (birbirinden farklı) ve türü.
class DragDropRound {
  const DragDropRound({
    required this.kind,
    required this.letters,
    required this.difficulty,
    this.newLetters = const [],
  });

  final RoundKind kind;
  final List<ArabicLetter> letters;
  final DragDropDifficulty difficulty;

  /// Bu aşamanın yeni harfleri (başlıkta gösterilir).
  final List<ArabicLetter> newLetters;
}

/// Bir harfin turdaki sonucu.
class LetterAnswer {
  const LetterAnswer({required this.firstTry, this.wrongDrops = 0});
  final bool firstTry;
  final int wrongDrops;
}

/// Bir turun sonucu: harf → cevap, ve karıştırılan çiftler
/// (hedef, bırakılan).
class RoundOutcome {
  const RoundOutcome({required this.answers, this.mixUps = const [], this.stars = 0});
  final Map<String, LetterAnswer> answers;
  final List<(String target, String dropped)> mixUps;
  final int stars;

  double get firstTryRate => answers.isEmpty
      ? 0
      : answers.values.where((a) => a.firstTry).length / answers.length;
}

/// Tur sonrasında olan dikkat çekici olay (sonuç ekranında söylenir).
enum StageEvent {
  none,

  /// Yeni harfler öğrenildi, karışık test başlıyor.
  learned,

  /// Test geçildi, yeni harf grubu açıldı.
  groupUnlocked,

  /// Test geçildi ama önce kısa pekiştirme.
  reinforceAfterPass,

  /// Test %80'in altında: zorlanılan harfler çalışılacak, sonra test.
  reinforceAfterFail,

  /// Pekiştirme bitti, test yeniden.
  retest,

  /// Bütün harfler öğrenildi; ustalık modu açıldı.
  allLearned,

  /// Günlük tekrar tamamlandı.
  dailyDone,
}

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

class LetterLearningEngine {
  LetterLearningEngine({List<ArabicLetter>? letters})
    : groups = learningGroups(letters),
      _letters = letters ?? kDragDropAllLetters;

  final List<List<ArabicLetter>> groups;
  final List<ArabicLetter> _letters;

  late final Map<String, ArabicLetter> _byId = {
    for (final l in _letters) letterIdOf(l): l,
  };

  ArabicLetter? letterById(String id) => _byId[id];

  int get letterCount => _letters.length;

  bool isComplete(LearningState s) => s.group >= groups.length;

  /// Şu an öğretilen grubun harfleri (bitince boş).
  List<ArabicLetter> currentGroup(LearningState s) =>
      isComplete(s) ? const [] : groups[s.group];

  /// Açılmış (şimdiye kadar tanıtılmış) harfler, yeni grup dahil.
  List<ArabicLetter> unlocked(LearningState s) => [
    for (var g = 0; g <= math.min(s.group, groups.length - 1); g++)
      ...groups[g],
  ];

  /// Testi geçilmiş gruplardaki harfler = öğrenilmiş harf sayısı.
  int learnedCount(LearningState s) => [
    for (var g = 0; g < math.min(s.group, groups.length); g++) ...groups[g],
  ].length;

  /// Günlük tekrar bekleyen harfler (öğrenilmiş, zamanı gelmiş).
  List<ArabicLetter> dueLetters(LearningState s, DateTime now) => [
    for (final l in unlocked(s))
      if ((s.letters[letterIdOf(l)]?.level ?? 0) >= 2 &&
          s.letters[letterIdOf(l)]!.isDue(now))
        l,
  ];

  /// Bugün henüz günlük tekrar yapılmadı ve tekrar zamanı gelen harf var.
  bool dailyReviewDue(LearningState s, DateTime now) =>
      s.lastDailyReview != dayKey(now) && dueLetters(s, now).isNotEmpty;

  // ---- sınıflandırma ------------------------------------------------------

  bool isStruggling(LetterProgress p, DateTime now) =>
      p.difficulty >= 1.0 || (p.seen > 0 && p.wrong > p.correct);

  bool isKnown(LetterProgress p) => p.level >= 4 && p.difficulty < 1.0;

  double _weight(LetterProgress p, DateTime now) =>
      1 + 2 * p.difficulty + (p.isDue(now) ? 2 : 0) + (p.seen == 0 ? 1 : 0);

  /// [count] harf seçer: %45 zorlanılan, %35 öğrenilmekte, %20 iyi bilinen
  /// (yetmeyen pay sıradaki sınıfa geçer). [exclude] seçilmez; [recent]
  /// (son tur) başka seçenek varsa geri plana atılır.
  List<String> pickReview(
    LearningState s,
    Iterable<String> pool,
    int count,
    DateTime now,
    math.Random rng, {
    Set<String> exclude = const {},
    Iterable<String> recent = const [],
  }) {
    final candidates = [
      for (final id in pool)
        if (!exclude.contains(id)) id,
    ];
    if (count <= 0 || candidates.isEmpty) return [];
    final recentSet = recent.toSet();
    final struggling = <String>[], learning = <String>[], known = <String>[];
    for (final id in candidates) {
      final p = s.progressOf(id);
      if (isStruggling(p, now)) {
        struggling.add(id);
      } else if (isKnown(p)) {
        known.add(id);
      } else {
        learning.add(id);
      }
    }
    final targets = [
      (count * 0.45).round(),
      (count * 0.35).round(),
    ];
    targets.add(math.max(0, count - targets[0] - targets[1]));
    final classes = [struggling, learning, known];
    final picked = <String>[];

    String? draw(List<String> from) {
      final options = from.where((id) => !picked.contains(id)).toList();
      if (options.isEmpty) return null;
      final fresh = options.where((id) => !recentSet.contains(id)).toList();
      final use = fresh.isNotEmpty ? fresh : options;
      final weights = [for (final id in use) _weight(s.progressOf(id), now)];
      var r = rng.nextDouble() * weights.fold<double>(0, (a, b) => a + b);
      for (var i = 0; i < use.length; i++) {
        r -= weights[i];
        if (r <= 0) return use[i];
      }
      return use.last;
    }

    var carry = 0;
    for (var c = 0; c < classes.length; c++) {
      var want = targets[c] + carry;
      while (want > 0) {
        final id = draw(classes[c]);
        if (id == null) break;
        picked.add(id);
        want--;
      }
      carry = want;
    }
    // Hâlâ eksikse kalanların hepsinden.
    while (picked.length < math.min(count, candidates.length)) {
      final id = draw(candidates);
      if (id == null) break;
      picked.add(id);
    }
    return picked;
  }

  /// Benzer harfleri birlikte göstermek: karıştırılan (ya da zor modda
  /// öğrenme ilerlemişse her) aileden açılmış kardeşleri ekler; yer yoksa
  /// iyi bilinen/sonradan seçilmiş harflerin yerine koyar. [keep] çıkarılmaz.
  List<String> withSimilar(
    LearningState s,
    List<String> picked,
    Set<String> unlockedIds,
    int count, {
    required bool includeUnconfused,
    Set<String> keep = const {},
  }) {
    final out = List.of(picked);
    for (final id in picked) {
      final g = similarGroupOf(id);
      if (g == null) continue;
      if ((s.confusions[g] ?? 0) <= 0 && !includeUnconfused) continue;
      for (final sibling in kSimilarLetterGroups[g]) {
        if (out.contains(sibling) || !unlockedIds.contains(sibling)) continue;
        if (out.length < count) {
          out.add(sibling);
          continue;
        }
        // Yer aç: sondan, korunmayan ve aynı aileden olmayan birini çıkar.
        final victim = out.lastIndexWhere(
          (x) => !keep.contains(x) && similarGroupOf(x) != g && x != id,
        );
        if (victim < 0) break;
        out[victim] = sibling;
      }
    }
    return out;
  }

  /// Sıradaki tur. [daily] günlük tekrar turunu ister.
  DragDropRound nextRound(
    LearningState s,
    DateTime now,
    math.Random rng, {
    bool daily = false,
  }) {
    final difficulty = s.difficulty;
    final unlockedIds = [for (final l in unlocked(s)) letterIdOf(l)];
    final k = math.min(difficulty.cards, unlockedIds.length);
    final newIds = [for (final l in currentGroup(s)) letterIdOf(l)];
    final recent = s.lastRound;
    List<String> ids;
    RoundKind kind;

    if (daily) {
      kind = RoundKind.daily;
      final due = [for (final l in dueLetters(s, now)) letterIdOf(l)];
      ids = pickReview(s, due, k, now, rng, recent: recent);
      if (ids.length < math.min(3, unlockedIds.length)) {
        ids += pickReview(
          s,
          unlockedIds,
          math.min(3, unlockedIds.length) - ids.length,
          now,
          rng,
          exclude: ids.toSet(),
          recent: recent,
        );
      }
    } else if (isComplete(s) || s.phase == LearnPhase.mastery) {
      kind = RoundKind.mastery;
      ids = pickReview(s, unlockedIds, k, now, rng, recent: recent);
      ids = withSimilar(
        s,
        ids,
        unlockedIds.toSet(),
        k,
        includeUnconfused: difficulty == DragDropDifficulty.hard,
      );
    } else {
      switch (s.phase) {
        case LearnPhase.learn:
          kind = RoundKind.learn;
          // Önce yeni harfler (henüz yeterince doğru olmayanlar önde).
          final ordered = List.of(newIds)
            ..sort(
              (a, b) =>
                  (s.stageCorrect[a] ?? 0).compareTo(s.stageCorrect[b] ?? 0),
            );
          ids = ordered.take(k).toList();
          if (ids.length < k) {
            ids += pickReview(
              s,
              unlockedIds,
              k - ids.length,
              now,
              rng,
              exclude: {...newIds},
              recent: recent,
            );
          }
        case LearnPhase.review:
          kind = RoundKind.review;
          // Testte henüz sorulmamış yeni harfler önce (turun yarısına kadar).
          final untested = newIds.where((id) => !s.testedNew.contains(id));
          final share = math.max(1, (k / 2).ceil());
          ids = untested.take(share).toList();
          final older = unlockedIds.where((id) => !newIds.contains(id));
          ids += pickReview(
            s,
            older.isEmpty ? unlockedIds : older,
            k - ids.length,
            now,
            rng,
            exclude: ids.toSet(),
            recent: recent,
          );
          if (ids.length < k) {
            ids += pickReview(
              s,
              unlockedIds,
              k - ids.length,
              now,
              rng,
              exclude: ids.toSet(),
            );
          }
          // Öğrenme ilerleyince benzer harfleri karşılaştır (erken değil).
          if (unlockedIds.length >= 6 && difficulty != DragDropDifficulty.easy) {
            ids = withSimilar(
              s,
              ids,
              unlockedIds.toSet(),
              k,
              includeUnconfused:
                  difficulty == DragDropDifficulty.hard &&
                  unlockedIds.length >= 9,
              keep: untested.take(share).toSet(),
            );
          }
        case LearnPhase.reinforce:
        case LearnPhase.mastery:
          kind = RoundKind.reinforce;
          final hard = s.struggled.where(unlockedIds.contains).toList();
          final size = math.max(math.min(3, unlockedIds.length), math.min(hard.length, k));
          ids = hard.take(size).toList();
          // Karşılaştırma: zorlanılan harfin karıştığı kardeşler.
          ids = withSimilar(
            s,
            ids,
            unlockedIds.toSet(),
            size,
            includeUnconfused: false,
            keep: ids.toSet(),
          );
          if (ids.length < size) {
            ids += pickReview(
              s,
              unlockedIds,
              size - ids.length,
              now,
              rng,
              exclude: ids.toSet(),
              recent: recent,
            );
          }
      }
    }
    final letters = [for (final id in ids.toSet()) _byId[id]!];
    return DragDropRound(
      kind: kind,
      letters: letters,
      difficulty: difficulty,
      newLetters: currentGroup(s),
    );
  }

  /// Turun sonucunu duruma işler; dikkat çekici olayı döndürür.
  StageEvent apply(
    LearningState s,
    DragDropRound round,
    RoundOutcome outcome,
    DateTime now,
  ) {
    s.rounds++;
    s.stars += outcome.stars;
    s.updatedAt = now.millisecondsSinceEpoch;
    s.lastRound
      ..clear()
      ..addAll(outcome.answers.keys);
    for (final MapEntry(key: id, value: answer) in outcome.answers.entries) {
      _updateLetter(s.progressOf(id), answer, now);
    }
    for (final (target, dropped) in outcome.mixUps) {
      final g = similarGroupOf(target);
      if (g != null && g == similarGroupOf(dropped)) {
        s.confusions[g] = (s.confusions[g] ?? 0) + 1;
      }
    }
    // Karşılaştırmada ailenin harfleri hatasız eşleşince karışıklık azalır.
    for (final g
        in outcome.answers.keys.map(similarGroupOf).whereType<int>().toSet()) {
      final members = outcome.answers.entries.where(
        (e) => similarGroupOf(e.key) == g,
      );
      if (members.length >= 2 && members.every((e) => e.value.firstTry)) {
        s.confusions[g] = math.max(0, (s.confusions[g] ?? 0) - 1);
      }
    }

    if (round.kind == RoundKind.daily) {
      s.lastDailyReview = dayKey(now);
      for (final MapEntry(key: id, value: a) in outcome.answers.entries) {
        if (!a.firstTry) s.struggled.add(id);
      }
      return StageEvent.dailyDone;
    }
    if (round.kind == RoundKind.mastery) return StageEvent.none;

    final newIds = {for (final l in currentGroup(s)) letterIdOf(l)};
    switch (s.phase) {
      case LearnPhase.learn:
        for (final MapEntry(key: id, value: a) in outcome.answers.entries) {
          if (!newIds.contains(id)) continue;
          if (a.firstTry) s.stageCorrect[id] = (s.stageCorrect[id] ?? 0) + 1;
        }
        if (newIds.every((id) => (s.stageCorrect[id] ?? 0) >= kLearnCorrectNeeded)) {
          _startTest(s);
          return StageEvent.learned;
        }
        return StageEvent.none;
      case LearnPhase.review:
        for (final MapEntry(key: id, value: a) in outcome.answers.entries) {
          s.testItems++;
          if (a.firstTry) {
            s.testFirstTry++;
          } else {
            s.struggled.add(id);
          }
          if (newIds.contains(id)) s.testedNew.add(id);
        }
        final done =
            s.testItems >= kReviewTestItems && newIds.every(s.testedNew.contains);
        if (!done) return StageEvent.none;
        final passed = s.testFirstTry >= kReviewPassRate * s.testItems;
        s.testPassed = passed;
        if (s.struggled.isEmpty) return _advance(s, now);
        s.phase = LearnPhase.reinforce;
        return passed
            ? StageEvent.reinforceAfterPass
            : StageEvent.reinforceAfterFail;
      case LearnPhase.reinforce:
        for (final MapEntry(key: id, value: a) in outcome.answers.entries) {
          if (a.firstTry) s.struggled.remove(id);
        }
        if (s.struggled.isNotEmpty) return StageEvent.none;
        if (s.testPassed) return _advance(s, now);
        _startTest(s);
        return StageEvent.retest;
      case LearnPhase.mastery:
        return StageEvent.none;
    }
  }

  void _startTest(LearningState s) {
    s.phase = LearnPhase.review;
    s.testedNew.clear();
    s.testItems = 0;
    s.testFirstTry = 0;
    s.testPassed = false;
  }

  StageEvent _advance(LearningState s, DateTime now) {
    // Grubun harfleri artık "öğrenildi": en az 2. seviye, yarın tekrar.
    for (final l in currentGroup(s)) {
      final p = s.progressOf(letterIdOf(l));
      if (p.level < 2) {
        p.level = 2;
        p.streak = 0;
        p.dueAt = now.add(Duration(days: kReviewIntervalDays[2]));
      }
    }
    s.group++;
    s.stageCorrect.clear();
    s.struggled.clear();
    s.testedNew.clear();
    s.testItems = 0;
    s.testFirstTry = 0;
    s.testPassed = false;
    if (isComplete(s)) {
      s.phase = LearnPhase.mastery;
      return StageEvent.allLearned;
    }
    s.phase = LearnPhase.learn;
    return StageEvent.groupUnlocked;
  }

  void _updateLetter(LetterProgress p, LetterAnswer a, DateTime now) {
    p.seen++;
    p.lastStudied = now;
    if (a.firstTry) {
      p.correct++;
      p.streak++;
      p.difficulty = p.difficulty * 0.6;
      if (p.difficulty < 0.05) p.difficulty = 0;
      // Seviye tek doğruyla yükselmez; 2'den sonra yalnızca zamanı gelince.
      final canRise = p.level < 2 || p.dueAt == null || p.isDue(now);
      if (p.streak >= 2 && p.level < kMaxLevel && canRise) {
        p.level++;
        p.streak = 0;
        p.dueAt = now.add(Duration(days: kReviewIntervalDays[p.level]));
      }
    } else {
      p.wrong += math.max(1, a.wrongDrops);
      p.streak = 0;
      p.difficulty = math.min(5, p.difficulty + 1);
      if (p.level > 2) p.level--;
      // Yanlış yapılan harf hemen tekrar sırasına girer.
      p.dueAt = now;
    }
  }

  /// Eski "Oyun 1-7" kayıtlarından güvenli başlangıç: baştan itibaren art
  /// arda en az [minStars] yıldızla bitirilmiş oyunların harfleri öğrenilmiş
  /// sayılır (tam 3'lü gruplar açılır, harfler yarın tekrar edilir).
  LearningState migrateFromOldLevels(
    List<int?> oldBestStars,
    DateTime now, {
    int minStars = 2,
  }) {
    final s = LearningState(updatedAt: now.millisecondsSinceEpoch);
    final known = <String>{};
    for (var i = 0; i < oldBestStars.length && i < kDragDropGroups.length; i++) {
      final stars = oldBestStars[i];
      if (stars == null || stars < minStars) break;
      known.addAll(kDragDropGroups[i].map(letterIdOf));
    }
    var g = 0;
    while (g < groups.length &&
        groups[g].every((l) => known.contains(letterIdOf(l)))) {
      g++;
    }
    for (var i = 0; i < g; i++) {
      for (final l in groups[i]) {
        s.letters[letterIdOf(l)] = LetterProgress(
          id: letterIdOf(l),
          seen: 1,
          correct: 1,
          level: 2,
          lastStudied: now,
          dueAt: now,
        );
      }
    }
    s.group = g;
    s.phase = g >= groups.length ? LearnPhase.mastery : LearnPhase.learn;
    return s;
  }
}
