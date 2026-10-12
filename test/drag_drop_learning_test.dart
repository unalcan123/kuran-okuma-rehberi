// Sürükle & Bırak öğrenme yolu (saf motor): harflerin sırayla açılması,
// eski harflerin tekrar havuzuna girmesi, zorlanılan harfin sık sorulması,
// 29 harfe kadar ilerleme, test/pekiştirme, seviye kuralı, günlük tekrar,
// kayıt (JSON) ve eski "Oyun 1-7" kayıtlarından başlangıç.
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/learning/learning_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuran_okuma_rehberi/data/drag_drop_game_data.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/drag_drop/learning/letter_learning.dart';

final _engine = LetterLearningEngine();
final _t0 = DateTime(2026, 10, 12, 10);

/// Oynar: [wrongFor] dışındaki her harf ilk denemede doğru.
RoundOutcome _play(DragDropRound round, {Set<String> wrongFor = const {}}) =>
    RoundOutcome(
      answers: {
        for (final l in round.letters)
          letterIdOf(l): LetterAnswer(
            firstTry: !wrongFor.contains(letterIdOf(l)),
            wrongDrops: wrongFor.contains(letterIdOf(l)) ? 1 : 0,
          ),
      },
    );

class _FakeCloud implements LearningCloud {
  final docs = <String, Map<String, Object?>>{};
  bool fail = false;
  int pushes = 0;

  @override
  Future<Map<String, Object?>?> fetch(String profileId) async {
    if (fail) throw StateError('çevrimdışı');
    return docs[profileId];
  }

  @override
  Future<void> push(String profileId, Map<String, Object?> state) async {
    if (fail) throw StateError('çevrimdışı');
    pushes++;
    docs[profileId] = Map.of(state);
  }
}

void main() {
  test('29 harf, Elifba sırasıyla 3\'erli gruplar (son grup 2)', () {
    final groups = _engine.groups;
    expect(groups.length, 10);
    expect([for (final g in groups) g.length], [3, 3, 3, 3, 3, 3, 3, 3, 3, 2]);
    expect(groups.expand((g) => g).toList(), kDragDropAllLetters);
    expect(kDragDropAllLetters.length, 29);
    expect(kDragDropAllLetters.map(letterIdOf).toSet().length, 29);
  });

  for (final difficulty in DragDropDifficulty.values) {
    test('hatasız çocuk 29 harfin hepsini sırayla öğrenir ($difficulty)', () {
      final s = LearningState(difficulty: difficulty);
      final rng = math.Random(1);
      var now = _t0;
      final unlockOrder = <String>[];
      var rounds = 0;
      var sawOldInReview = 0;
      while (!_engine.isComplete(s)) {
        final group = _engine.currentGroup(s);
        for (final l in group) {
          if (!unlockOrder.contains(letterIdOf(l))) {
            unlockOrder.add(letterIdOf(l));
          }
        }
        final round = _engine.nextRound(s, now, rng);
        // Ekrandaki harfler birbirinden farklı ve hep açılmış harflerden.
        expect(round.letters.toSet().length, round.letters.length);
        final unlocked = _engine.unlocked(s).toSet();
        expect(unlocked.containsAll(round.letters), isTrue);
        expect(round.letters.length, lessThanOrEqualTo(difficulty.cards));
        if (round.kind == RoundKind.review && s.group > 0) {
          final old = round.letters.where((l) => !group.contains(l));
          if (old.isNotEmpty) sawOldInReview++;
        }
        _engine.apply(s, round, _play(round), now);
        now = now.add(const Duration(minutes: 1));
        expect(++rounds, lessThan(200), reason: 'ilerleme takıldı');
      }
      expect(unlockOrder, kDragDropAllLetters.map(letterIdOf).toList());
      expect(_engine.learnedCount(s), 29);
      expect(s.phase, LearnPhase.mastery);
      // Her yeni gruptan sonra karışık testte eski harfler de soruldu.
      expect(sawOldInReview, greaterThanOrEqualTo(9));
      // Son aşamada eksik harf yok: hepsi en az 2. seviyede.
      for (final l in kDragDropAllLetters) {
        expect(s.letters[letterIdOf(l)]!.level, greaterThanOrEqualTo(2));
      }
      // Bitince oyun bitmez: ustalık turları bütün harflerden gelir.
      final mastery = _engine.nextRound(s, now, rng);
      expect(mastery.kind, RoundKind.mastery);
      expect(mastery.letters, isNotEmpty);
    });
  }

  test('öğrenme turu yalnızca yeni 3 harfi gösterir (kolay)', () {
    final s = LearningState();
    final round = _engine.nextRound(s, _t0, math.Random(2));
    expect(round.kind, RoundKind.learn);
    expect(round.letters, _engine.groups[0]);
  });

  test('her yeni harf 2 kez ilk denemede doğru olmadan teste geçilmez', () {
    final s = LearningState();
    final rng = math.Random(3);
    final round = _engine.nextRound(s, _t0, rng);
    expect(_engine.apply(s, round, _play(round), _t0), StageEvent.none);
    expect(s.phase, LearnPhase.learn);
    final again = _engine.nextRound(s, _t0, rng);
    expect(_engine.apply(s, again, _play(again), _t0), StageEvent.learned);
    expect(s.phase, LearnPhase.review);
  });

  test('test %80 altında: oyun baştan başlamaz, zorlanılan harf çalışılır', () {
    final s = LearningState(group: 1);
    final rng = math.Random(4);
    // Öğrenme turlarını hatasız geç.
    while (s.phase == LearnPhase.learn) {
      final r = _engine.nextRound(s, _t0, rng);
      _engine.apply(s, r, _play(r), _t0);
    }
    final hard = letterIdOf(_engine.groups[1][0]);
    final second = letterIdOf(_engine.groups[1][1]);
    StageEvent event = StageEvent.none;
    while (s.phase == LearnPhase.review) {
      final r = _engine.nextRound(s, _t0, rng);
      event = _engine.apply(s, r, _play(r, wrongFor: {hard, second}), _t0);
    }
    expect(event, StageEvent.reinforceAfterFail);
    expect(s.group, 1, reason: 'aşama korunur');
    expect(s.struggled, containsAll([hard, second]));
    final reinforce = _engine.nextRound(s, _t0, rng);
    expect(reinforce.kind, RoundKind.reinforce);
    expect(
      reinforce.letters.map(letterIdOf),
      containsAll([hard, second]),
    );
    expect(
      _engine.apply(s, reinforce, _play(reinforce), _t0),
      StageEvent.retest,
    );
    expect(s.phase, LearnPhase.review);
    expect(s.group, 1);
  });

  test('yanlış yapılan harf daha sık sorulur, bilinenler kaybolmaz', () {
    final s = LearningState(
      group: _engine.groups.length,
      phase: LearnPhase.mastery,
    );
    for (final l in kDragDropAllLetters) {
      s.letters[letterIdOf(l)] = LetterProgress(
        id: letterIdOf(l),
        seen: 10,
        correct: 10,
        level: 4,
        dueAt: _t0.add(const Duration(days: 5)),
      );
    }
    final weak = letterIdOf(kDragDropAllLetters[10]);
    final rng = math.Random(5);
    final counts = <String, int>{};
    for (var i = 0; i < 300; i++) {
      final r = _engine.nextRound(s, _t0, rng);
      for (final l in r.letters) {
        counts[letterIdOf(l)] = (counts[letterIdOf(l)] ?? 0) + 1;
      }
      _engine.apply(s, r, _play(r, wrongFor: {weak}), _t0);
    }
    final others = counts.entries.where((e) => e.key != weak).map((e) => e.value);
    final avg = others.reduce((a, b) => a + b) / others.length;
    expect(counts[weak]!, greaterThan(avg * 2));
    // İyi bilinenler de soruldu (tamamen kaybolmadı).
    expect(counts.length, 29);
  });

  test('45/35/20 dağılımı; sınıf yetmezse dinamik', () {
    final s = LearningState();
    final ids = kDragDropAllLetters.map(letterIdOf).toList();
    for (var i = 0; i < ids.length; i++) {
      s.letters[ids[i]] = LetterProgress(
        id: ids[i],
        seen: 5,
        correct: i < 10 ? 1 : 5,
        wrong: i < 10 ? 4 : 0,
        difficulty: i < 10 ? 2 : 0,
        level: i >= 20 ? 5 : 2,
      );
    }
    final picked = _engine.pickReview(s, ids, 20, _t0, math.Random(6));
    final struggling = picked.where((id) => ids.indexOf(id) < 10).length;
    final known = picked.where((id) => ids.indexOf(id) >= 20).length;
    expect(struggling, 9); // 20 × %45
    expect(known, 4); // 20 × %20
    // Zorlanılan harf yoksa pay diğer sınıflara geçer.
    final onlyKnown = ids.sublist(20);
    expect(
      _engine.pickReview(s, onlyKnown, 6, _t0, math.Random(7)).length,
      6,
    );
  });

  test('aynı harfler art arda gereksiz yere sorulmaz', () {
    final s = LearningState(
      group: _engine.groups.length,
      phase: LearnPhase.mastery,
    );
    final rng = math.Random(8);
    var previous = <String>{};
    for (var i = 0; i < 40; i++) {
      final r = _engine.nextRound(s, _t0, rng);
      final ids = r.letters.map(letterIdOf).toSet();
      expect(ids.intersection(previous), isEmpty);
      _engine.apply(s, r, _play(r), _t0);
      previous = ids;
    }
  });

  test('seviye tek doğru cevapla yükselmez; tekrar aralıkları 1-3-7-14 gün', () {
    final s = LearningState();
    final p = s.progressOf('ب');
    final round = DragDropRound(
      kind: RoundKind.mastery,
      letters: [kDragDropAllLetters[1]],
      difficulty: DragDropDifficulty.easy,
    );
    RoundOutcome ok() => const RoundOutcome(
      answers: {'ب': LetterAnswer(firstTry: true)},
    );
    _engine.apply(s, round, ok(), _t0);
    expect(p.level, 0);
    _engine.apply(s, round, ok(), _t0);
    expect(p.level, 1);
    _engine.apply(s, round, ok(), _t0);
    _engine.apply(s, round, ok(), _t0);
    expect(p.level, 2);
    expect(p.dueAt, _t0.add(const Duration(days: 1)));
    // Zamanı gelmeden yükselmez.
    _engine.apply(s, round, ok(), _t0);
    _engine.apply(s, round, ok(), _t0);
    expect(p.level, 2);
    final days = <int>[];
    var now = _t0;
    for (var level = 2; level < kMaxLevel; level++) {
      now = p.dueAt!;
      _engine.apply(s, round, ok(), now);
      _engine.apply(s, round, ok(), now);
      days.add(p.dueAt!.difference(now).inDays);
    }
    expect(days, [3, 7, 14]);
    // Yanlış: hemen tekrar sırasına, seviye bir düşer.
    _engine.apply(
      s,
      round,
      const RoundOutcome(answers: {'ب': LetterAnswer(firstTry: false)}),
      now,
    );
    expect(p.level, 4);
    expect(p.isDue(now), isTrue);
    expect(p.difficulty, greaterThan(0));
  });

  test('ertesi gün önce günlük tekrar önerilir, günde bir kez', () {
    final s = LearningState();
    final rng = math.Random(9);
    var now = _t0;
    while (s.group < 2) {
      final r = _engine.nextRound(s, now, rng);
      _engine.apply(s, r, _play(r), now);
    }
    expect(_engine.dailyReviewDue(s, now), isFalse);
    final tomorrow = now.add(const Duration(days: 1, hours: 1));
    expect(_engine.dailyReviewDue(s, tomorrow), isTrue);
    final daily = _engine.nextRound(s, tomorrow, rng, daily: true);
    expect(daily.kind, RoundKind.daily);
    final due = _engine.dueLetters(s, tomorrow).toSet();
    expect(daily.letters.where(due.contains), isNotEmpty);
    final group = s.group;
    expect(
      _engine.apply(s, daily, _play(daily), tomorrow),
      StageEvent.dailyDone,
    );
    expect(s.group, group, reason: 'günlük tekrar aşamayı değiştirmez');
    expect(_engine.dailyReviewDue(s, tomorrow), isFalse);
  });

  test('benzer harfler karıştırılınca karşılaştırma sorusu gelir', () {
    final s = LearningState(group: 3, difficulty: DragDropDifficulty.medium);
    s.phase = LearnPhase.reinforce;
    // ب yerine ت bırakıldı.
    _engine.apply(
      s,
      const DragDropRound(
        kind: RoundKind.mastery,
        letters: [],
        difficulty: DragDropDifficulty.medium,
      ),
      const RoundOutcome(
        answers: {'ب': LetterAnswer(firstTry: false, wrongDrops: 1)},
        mixUps: [('ب', 'ت')],
      ),
      _t0,
    );
    s.struggled.add('ب');
    final r = _engine.nextRound(s, _t0, math.Random(10));
    final ids = r.letters.map(letterIdOf).toSet();
    expect(ids, containsAll(['ب', 'ت', 'ث']));
  });

  test('kolayda erken aşamada benzer harfler zorlanmaz', () {
    final s = LearningState(group: 1);
    s.phase = LearnPhase.review;
    final r = _engine.nextRound(s, _t0, math.Random(11));
    expect(r.letters.length, 3);
  });

  test('durum JSON\'a yazılıp aynen geri okunur', () {
    final s = LearningState(difficulty: DragDropDifficulty.hard);
    final rng = math.Random(12);
    for (var i = 0; i < 6; i++) {
      final r = _engine.nextRound(s, _t0, rng);
      _engine.apply(
        s,
        r,
        _play(r, wrongFor: {letterIdOf(r.letters.first)}),
        _t0,
      );
    }
    final copy = LearningState.fromJson(s.toJson());
    expect(copy.toJson(), s.toJson());
    expect(LearningState.fromJson(null).group, 0);
    expect(LearningState.fromJson({'group': 99}).group, 10);
  });

  test('eski Oyun 1-7 kayıtlarından güvenli başlangıç', () {
    // Oyun 1 (4 harf) ve 2 (3 harf) iyi oynanmış, 3 zayıf → 7 harf bilinir.
    final s = _engine.migrateFromOldLevels([3, 2, 1, null, 3, 3, 3], _t0);
    expect(s.group, 2); // 6 harf = iki tam grup
    expect(_engine.learnedCount(s), 6);
    expect(s.letters.length, 6);
    expect(s.phase, LearnPhase.learn);
    final fresh = _engine.migrateFromOldLevels([null, 3], _t0);
    expect(fresh.group, 0);
    expect(fresh.letters, isEmpty);
  });

  group('kayıt ve geri yükleme (cihaz + bulut)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('kaydedilen durum buluta gider; yeni cihazda buluttan gelir', () async {
      final cloud = _FakeCloud();
      final repo = LearningRepository(engine: _engine, cloud: cloud);
      final s = await repo.load(profileId: 'p1');
      final rng = math.Random(20);
      for (var i = 0; i < 5; i++) {
        final r = _engine.nextRound(s, _t0, rng);
        _engine.apply(s, r, _play(r), _t0.add(Duration(minutes: i)));
        await repo.save(s, profileId: 'p1');
      }
      await Future<void>.delayed(Duration.zero);
      expect(cloud.docs['p1'], isNotNull);
      // Yeni cihaz: boş cihaz deposu, aynı oyuncu.
      SharedPreferences.setMockInitialValues({});
      final restored = await LearningRepository(
        engine: _engine,
        cloud: cloud,
      ).load(profileId: 'p1');
      expect(restored.toJson(), s.toJson());
    });

    test('iki kopyadan yenisi seçilir, eskisi güncellenir', () async {
      final cloud = _FakeCloud();
      final newer = LearningState(group: 4, updatedAt: 2000);
      final older = LearningState(group: 2, updatedAt: 1000);
      cloud.docs['p1'] = newer.toJson();
      SharedPreferences.setMockInitialValues({
        LearningRepository.keyFor('p1'): jsonEncode(older.toJson()),
      });
      final repo = LearningRepository(engine: _engine, cloud: cloud);
      expect((await repo.load(profileId: 'p1')).group, 4);
      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString(LearningRepository.keyFor('p1'))!)['group'],
        4,
      );
      // Cihazdaki daha yeniyse bulut güncellenir.
      cloud.docs['p1'] = older.toJson();
      await prefs.setString(
        LearningRepository.keyFor('p1'),
        jsonEncode(newer.toJson()),
      );
      expect((await repo.load(profileId: 'p1')).group, 4);
      await Future<void>.delayed(Duration.zero);
      expect(cloud.docs['p1']!['group'], 4);
    });

    test('bulut çalışmazsa cihazdaki kayıtla devam edilir', () async {
      final cloud = _FakeCloud()..fail = true;
      final repo = LearningRepository(engine: _engine, cloud: cloud);
      final s = await repo.load(profileId: 'p1');
      s.group = 3;
      s.updatedAt = 5;
      await repo.save(s, profileId: 'p1');
      await Future<void>.delayed(Duration.zero);
      expect((await repo.load(profileId: 'p1')).group, 3);
    });

    test('ad verilmeden yapılan ilerleme oyuncunun profiline geçer', () async {
      final repo = LearningRepository(engine: _engine);
      final s = await repo.load();
      s
        ..group = 2
        ..updatedAt = 7;
      await repo.save(s);
      expect((await repo.load(profileId: 'p9')).group, 2);
    });

    test('bozuk kayıt güvenli başlangıca döner', () async {
      SharedPreferences.setMockInitialValues({
        LearningRepository.keyFor(null): '{bozuk',
      });
      final s = await LearningRepository(engine: _engine).load();
      expect(s.group, 0);
      expect(s.phase, LearnPhase.learn);
    });
  });
}
