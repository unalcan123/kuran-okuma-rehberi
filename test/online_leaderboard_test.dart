import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/bul_patlat/bul_patlat_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/bul_patlat/bul_patlat_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/game_letters.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/harf_arabalari/harf_arabalari_engine.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/harf_arabalari/harf_arabalari_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/widgets/online_leaderboard_section.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_backend.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_models.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_service.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/nickname_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harf_oyunlari_harness.dart';

/// Bellek içi arka uç: Firestore kurallarının ve sorgularının anlamını taklit
/// eder (en iyi düşmez, puan azalan + önce ulaşan önde, sahiplik öneki).
class FakeBackend implements LeaderboardBackend {
  FakeBackend({this.uid = 'deviceA', Map<String, FakeDoc>? shared})
    : docs = shared ?? {};

  String uid;
  final Map<String, FakeDoc> docs; // "<gameId>__<playerId>"
  final Map<String, String> players = {};
  bool online = true;
  int writes = 0;
  static int _clock = 0;

  void _net() {
    if (!online) throw const SocketException('çevrimdışı');
  }

  @override
  Future<String> signIn() async {
    _net();
    return uid;
  }

  @override
  Future<void> savePlayer({
    required String playerId,
    required String ownerUid,
    required String nickname,
  }) async {
    _net();
    if (!playerId.startsWith('${ownerUid}_')) {
      throw const LeaderboardRejected('sahip değil');
    }
    players[playerId] = nickname;
  }

  @override
  Future<void> submitBest({
    required String playerId,
    required String ownerUid,
    required String nickname,
    required OnlineScore score,
  }) async {
    _net();
    final id = '${score.gameId}__$playerId';
    final old = docs[id];
    if (old != null && score.score <= old.best) return;
    writes++;
    docs[id] = FakeDoc(playerId, nickname, score.gameId, score.score, ++_clock);
  }

  List<FakeDoc> _sorted(String gameId) =>
      docs.values.where((d) => d.gameId == gameId).toList()..sort(
        (a, b) =>
            b.best != a.best ? b.best.compareTo(a.best) : a.at.compareTo(b.at),
      );

  @override
  Future<StoredBest?> fetchBest(String gameId, String playerId) async {
    _net();
    final d = docs['${gameId}__$playerId'];
    return d == null
        ? null
        : StoredBest(
          bestScore: d.best,
          bestAt: DateTime(2026).add(Duration(seconds: d.at)),
          nickname: d.nickname,
        );
  }

  @override
  Future<List<LeaderboardRow>> top(String gameId, int limit) async {
    _net();
    final rows = _sorted(gameId).take(limit).toList();
    return [
      for (var i = 0; i < rows.length; i++)
        LeaderboardRow(
          rank: i + 1,
          playerId: rows[i].playerId,
          nickname: rows[i].nickname,
          bestScore: rows[i].best,
        ),
    ];
  }

  @override
  Future<int> countAhead(String gameId, StoredBest mine) async {
    _net();
    final at = mine.bestAt.difference(DateTime(2026)).inSeconds;
    return docs.values
        .where(
          (d) =>
              d.gameId == gameId &&
              (d.best > mine.bestScore ||
                  (d.best == mine.bestScore && d.at < at)),
        )
        .length;
  }

  @override
  Future<int> countPlayers(String gameId) async {
    _net();
    return docs.values.where((d) => d.gameId == gameId).length;
  }

  @override
  Future<void> deletePlayer(String playerId, Iterable<String> gameIds) async {
    _net();
    for (final g in gameIds) {
      docs.remove('${g}__$playerId');
    }
    players.remove(playerId);
  }
}

class FakeDoc {
  FakeDoc(this.playerId, this.nickname, this.gameId, this.best, this.at);
  final String playerId;
  final String nickname;
  final String gameId;
  final int best;
  final int at;
}

/// [correct] doğru, hepsi ilk denemede: puan kuralına uygun en yüksek puan.
OnlineScore scoreOf(String gameId, int points, {int? correct}) {
  final c = correct ?? (points * 3 / 50).ceil();
  return OnlineScore(
    gameId: gameId,
    score: points,
    correctAnswers: c,
    wrongAnswers: 1,
    missedTargets: 1,
    totalItems: c + 10,
  );
}

LeaderboardService serviceFor(FakeBackend b) => LeaderboardService(
  backend: b,
  games: kOnlineLeaderboardGames,
  timeout: const Duration(seconds: 2),
);

List<String> rowsOf(OnlineOutcome o) => [
  for (final r in o.snapshot!.top) '${r.nickname} ${r.bestScore}',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.clear();
  });

  group('takma ad kuralları', () {
    test('geçerli / geçersiz', () {
      for (final ok in [
        'Ahmed',
        'Şükrü Öz',
        'أحمد',
        'Elif_2',
        'Ay',
        'a' * 16,
      ]) {
        expect(NicknamePolicy.validate(ok), isNull, reason: ok);
      }
      expect(NicknamePolicy.validate('   '), NicknameError.empty);
      expect(NicknamePolicy.validate('A'), NicknameError.tooShort);
      expect(NicknamePolicy.validate('a' * 17), NicknameError.tooLong);
      for (final bad in [
        '<script>',
        'Ali;',
        'x"y',
        'a{b}',
        'Ali/Veli',
        'a=b',
      ]) {
        expect(
          NicknamePolicy.validate(bad),
          NicknameError.invalidChars,
          reason: bad,
        );
      }
      expect(NicknamePolicy.validate('Aq'), NicknameError.notAllowed);
      expect(NicknamePolicy.validate('SİKK'), NicknameError.notAllowed);
      // Kısa kökler kelimenin içinde aranmaz: masum adlar engellenmez.
      for (final ok in ['Işık', 'Aqil', 'Gotham', 'Picasso', 'Sıkı Can']) {
        expect(NicknamePolicy.validate(ok), isNull, reason: ok);
      }
    });

    test('boşluk ve kontrol karakterleri sadeleşir', () {
      expect(NicknamePolicy.normalize('  Ah   med \n'), 'Ah med');
      expect(NicknamePolicy.normalize('Ali\u0000\u202E'), 'Ali');
    });

    test('yerel profil de aynı kuralları kullanır', () async {
      final repo = PlayerRepository();
      await repo.load();
      expect(repo.validateName('A'), PlayerNameError.tooShort);
      expect(repo.validateName('<b>'), PlayerNameError.invalidChars);
      expect(repo.validateName('Elif'), isNull);
    });
  });

  test('istemci sınırları firestore.rules ile aynı', () {
    final rules = File('firestore.rules').readAsStringSync();
    for (final e in kOnlineLeaderboardGames.entries) {
      final l = e.value;
      final expected =
          "'${e.key}': {'maxScore': ${l.maxScore}, 'maxCorrect': ${l.maxCorrect}, "
          "'maxWrong': ${l.maxWrong}, 'maxMissed': ${l.maxMissed}, "
          "'maxTotalItems': ${l.maxTotalItems}}";
      expect(rules, contains(expected), reason: e.key);
    }
    expect(rules, isNot(contains('if true')));
  });

  group('puan tutarlılığı (oyun kodundan)', () {
    final letters = [
      for (final c in 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي'.split(''))
        GameLetter(c, 'a/$c.mp3'),
    ];

    // Çok hızlı bir insan: hedef sesi duyduktan en az 0,5 sn sonra, hedef
    // görünürken dokunur. (Her kareye dokunan bir bot kodda tavan olmadığı için
    // Bul & Patlat'ta ~28 000 puan yapabilir; sınırlar insan hızına göredir.)
    void playHuman({
      required void Function(double dt) tick,
      required bool Function() running,
      required String? Function() target,
      required void Function() tapVisibleTarget,
    }) {
      var since = 0.0;
      String? last;
      while (running()) {
        tick(1 / 60);
        since += 1 / 60;
        if (target() != last) {
          last = target();
          since = 0;
        }
        if (since >= 0.5) tapVisibleTarget();
      }
    }

    test(
      'Bul & Patlat: çok hızlı bir oyuncu (en hızlı seviye) kabul edilir',
      () {
        for (final seed in [1, 2, 3]) {
          final e = BulPatlatEngine(
            letters: letters,
            random: math.Random(seed),
          );
          e.resize(1920, 1080);
          e.start(level: 3);
          playHuman(
            tick: e.tick,
            running: () => e.status == BpStatus.running,
            target: () => e.target?.char,
            tapVisibleTarget: () {
              for (final b in e.balloons.toList()) {
                if (b.letter.char == e.target?.char &&
                    b.y + b.bodyHeight / 2 < e.height) {
                  e.tap(b.id);
                  return;
                }
              }
            },
          );
          // ignore: avoid_print
          print(
            'Bul & Patlat (tohum $seed): ${e.score} puan, ${e.correct} doğru',
          );
          final s = OnlineScore(
            gameId: GameIds.bulPatlat,
            score: e.score,
            correctAnswers: e.correct,
            wrongAnswers: e.wrongTaps,
            missedTargets: e.missedTargets,
            totalItems: e.spawned,
          );
          expect(
            s.isPlausible(kOnlineLeaderboardGames[GameIds.bulPatlat]!),
            isTrue,
            reason: 'puan ${e.score}, doğru ${e.correct}',
          );
        }
      },
    );

    test(
      'Harf Arabaları: çok hızlı bir oyuncu (en hızlı seviye) kabul edilir',
      () {
        for (final seed in [1, 2, 3]) {
          final e = HarfArabalariEngine(
            letters: letters,
            random: math.Random(seed),
          );
          e.resize(1920, 1080);
          e.start(level: 3);
          playHuman(
            tick: e.tick,
            running: () => e.status == HaStatus.running,
            target: () => e.target?.char,
            tapVisibleTarget: () {
              for (final c in e.cars.toList()) {
                if (c.catchable && c.letter.char == e.target?.char && c.x > 0) {
                  e.tap(c.id);
                  return;
                }
              }
            },
          );
          // ignore: avoid_print
          print(
            'Harf Arabaları (tohum $seed): ${e.score} puan, ${e.correct} doğru',
          );
          final s = OnlineScore(
            gameId: GameIds.harfArabalari,
            score: e.score,
            correctAnswers: e.correct,
            wrongAnswers: e.wrongTaps,
            missedTargets: e.missedTargets,
            totalItems: e.spawned,
          );
          expect(
            s.isPlausible(kOnlineLeaderboardGames[GameIds.harfArabalari]!),
            isTrue,
            reason: 'puan ${e.score}, doğru ${e.correct}',
          );
        }
      },
    );

    test('tutarsız sonuçlar reddedilir', () {
      final l = kOnlineLeaderboardGames[GameIds.bulPatlat]!;
      OnlineScore s(int p, int c, {int m = 0, int t = 100}) => OnlineScore(
        gameId: GameIds.bulPatlat,
        score: p,
        correctAnswers: c,
        wrongAnswers: 0,
        missedTargets: m,
        totalItems: t,
      );
      expect(s(330, 20).isPlausible(l), isTrue);
      expect(s(335, 20).isPlausible(l), isFalse); // 20 doğruyla en çok 330
      expect(s(195, 20).isPlausible(l), isFalse);
      expect(s(332, 20).isPlausible(l), isFalse);
      expect(s(330, 20, t: 19).isPlausible(l), isFalse);
      expect(s(330, 20, m: 6).isPlausible(l), isFalse);
      expect(s(-5, 0).isPlausible(l), isFalse);
      expect(s(4005, 241, t: 300).isPlausible(l), isFalse);
    });
  });

  group('servis', () {
    for (final game in [GameIds.bulPatlat, GameIds.harfArabalari]) {
      test('$game: görevdeki senaryo (en iyi korunur, sıra, toplam)', () async {
        final shared = <String, FakeDoc>{};
        final a = serviceFor(FakeBackend(uid: 'uidA', shared: shared));
        final b = serviceFor(FakeBackend(uid: 'uidB', shared: shared));
        final c = serviceFor(FakeBackend(uid: 'uidC', shared: shared));

        await a.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(game, 300),
        );
        await b.submitAndLoad(
          profileId: 'p1',
          nickname: 'Elif',
          score: scoreOf(game, 450),
        );
        var o = await c.submitAndLoad(
          profileId: 'p1',
          nickname: 'Yusuf',
          score: scoreOf(game, 400),
        );
        expect(o.status, OnlineStatus.ranked);
        expect(rowsOf(o), ['Elif 450', 'Yusuf 400', 'Ahmed 300']);
        expect(o.snapshot!.me!.rank, 2);
        expect(o.snapshot!.totalPlayers, 3);

        o = await a.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(game, 500),
        );
        expect(rowsOf(o), ['Ahmed 500', 'Elif 450', 'Yusuf 400']);
        expect(o.snapshot!.me!.rank, 1);
        expect(o.snapshot!.meInTop, isTrue);

        o = await a.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(game, 200),
        );
        expect(rowsOf(o), [
          'Ahmed 500',
          'Elif 450',
          'Yusuf 400',
        ], reason: 'düşük skor en iyiyi düşürmez');
        expect(o.snapshot!.me!.bestScore, 500);
      });
    }

    test(
      'aynı takma adla iki farklı UID ayrı oyuncudur; aynı cihazda iki çocuk da',
      () async {
        final shared = <String, FakeDoc>{};
        final d1 = serviceFor(FakeBackend(uid: 'uid1', shared: shared));
        final d2 = serviceFor(FakeBackend(uid: 'uid2', shared: shared));
        await d1.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(GameIds.bulPatlat, 300),
        );
        await d1.submitAndLoad(
          profileId: 'p2',
          nickname: 'Zeynep',
          score: scoreOf(GameIds.bulPatlat, 250),
        );
        final o = await d2.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(GameIds.bulPatlat, 350),
        );
        expect(rowsOf(o), ['Ahmed 350', 'Ahmed 300', 'Zeynep 250']);
        expect(o.snapshot!.totalPlayers, 3);
        expect(o.snapshot!.me!.playerId, 'uid2_p1');
      },
    );

    test(
      'ilk 10 dışındaki oyuncu kendi sırasını görür; eşitlikte önce ulaşan önde',
      () async {
        final shared = <String, FakeDoc>{};
        for (var i = 0; i < 30; i++) {
          await serviceFor(
            FakeBackend(uid: 'u$i', shared: shared),
          ).submitAndLoad(
            profileId: 'p1',
            nickname: 'Oyuncu $i',
            score: scoreOf(GameIds.bulPatlat, 900 - i * 20),
          );
        }
        // 900 … 320. Geç gelen 480'e ulaşır: 480 yapan u21'in arkasına düşer.
        final late = serviceFor(FakeBackend(uid: 'late', shared: shared));
        final o = await late.submitAndLoad(
          profileId: 'p1',
          nickname: 'Geç',
          score: scoreOf(GameIds.bulPatlat, 480),
        );
        expect(o.snapshot!.top, hasLength(10));
        expect(o.snapshot!.meInTop, isFalse);
        expect(o.snapshot!.me!.rank, 23);
        expect(o.snapshot!.me!.nickname, 'Geç');
        expect(o.snapshot!.totalPlayers, 31);
      },
    );

    test(
      'internet yok → cihazda bekler; bağlantı gelince (ya da yeniden açılışta) gönderilir',
      () async {
        final backend = FakeBackend()..online = false;
        final s = serviceFor(backend);
        var o = await s.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(GameIds.bulPatlat, 300),
        );
        expect(o.status, OnlineStatus.savedOffline);
        expect(await s.hasPending('p1', GameIds.bulPatlat), isTrue);
        // Daha düşük bir sonuç kuyruktaki en iyinin yerine geçmez.
        await s.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(GameIds.bulPatlat, 100),
        );

        // "Uygulama yeniden açıldı": yeni servis, kuyruk cihazdan okunur.
        backend.online = true;
        final restarted = serviceFor(backend);
        await restarted.init();
        expect(await restarted.hasPending('p1', GameIds.bulPatlat), isFalse);
        o = await restarted.retry(profileId: 'p1', gameId: GameIds.bulPatlat);
        expect(o.status, OnlineStatus.ranked);
        expect(rowsOf(o), ['Ahmed 300']);
        expect(backend.players['deviceA_p1'], 'Ahmed');
      },
    );

    test(
      'Firebase yüklenemedi (hata) → bekler; yapılandırılmamış (null) → bölüm yok',
      () async {
        final broken = LeaderboardService(
          backend: Future<LeaderboardBackend?>.error(
            StateError('firebase yok'),
          ),
          games: kOnlineLeaderboardGames,
        );
        final o = await broken.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(GameIds.bulPatlat, 300),
        );
        expect(o.status, OnlineStatus.savedOffline);

        final none = LeaderboardService(
          backend: null,
          games: kOnlineLeaderboardGames,
        );
        expect(
          (await none.submitAndLoad(
            profileId: 'p1',
            nickname: 'Ahmed',
            score: scoreOf(GameIds.bulPatlat, 300),
          )).status,
          OnlineStatus.unavailable,
        );
      },
    );

    test('oyuncu yok / geçersiz ad / tutarsız skor gönderilmez', () async {
      final backend = FakeBackend();
      final s = serviceFor(backend);
      expect(
        (await s.submitAndLoad(
          profileId: null,
          nickname: null,
          score: scoreOf(GameIds.bulPatlat, 300),
        )).status,
        OnlineStatus.noPlayer,
      );
      expect(
        (await s.submitAndLoad(
          profileId: 'p1',
          nickname: 'A',
          score: scoreOf(GameIds.bulPatlat, 300),
        )).status,
        OnlineStatus.invalidName,
      );
      expect(
        (await s.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(GameIds.bulPatlat, 300, correct: 5),
        )).status,
        OnlineStatus.rejected,
      );
      expect(
        (await s.submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf('baska_oyun', 300),
        )).status,
        OnlineStatus.rejected,
      );
      expect(backend.writes, 0);
    });

    test(
      'sıralama yüklenemezse loadFailed (skor yine gönderilmiş olur)',
      () async {
        final backend = _FailingTop();
        final o = await serviceFor(backend).submitAndLoad(
          profileId: 'p1',
          nickname: 'Ahmed',
          score: scoreOf(GameIds.bulPatlat, 300),
        );
        expect(o.status, OnlineStatus.loadFailed);
        expect(backend.writes, 1);
      },
    );

    test('profil silinince çevrimiçi kaydı da silinir', () async {
      final backend = FakeBackend();
      final s = serviceFor(backend);
      await s.submitAndLoad(
        profileId: 'p1',
        nickname: 'Ahmed',
        score: scoreOf(GameIds.bulPatlat, 300),
      );
      await s.forgetPlayer('p1');
      expect(backend.docs, isEmpty);
      expect(backend.players, isEmpty);
    });
  });

  group('sonuç ekranı bölümü', () {
    Future<void> pumpSection(
      WidgetTester tester,
      Future<OnlineOutcome> request, {
      Future<OnlineOutcome> Function()? retry,
      Size size = const Size(360, 800),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 372),
                  child: OnlineLeaderboardSection(
                    request: request,
                    onRetry: retry ?? () => request,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    LeaderboardSnapshot snap({int meRank = 27, int total = 127}) {
      const names = [
        'Yusuf',
        'Zeynep',
        'Emir',
        'Ayşe',
        'Ömer',
        'Elif',
        'Hamza',
        'Meryem',
        'Ali',
        'Kerem',
      ];
      return LeaderboardSnapshot(
        gameId: GameIds.bulPatlat,
        top: [
          for (var i = 0; i < 10; i++)
            LeaderboardRow(
              rank: i + 1,
              playerId: 'x$i',
              nickname: names[i],
              bestScore: 580 - i * 20,
            ),
        ],
        me:
            meRank <= 10
                ? LeaderboardRow(
                  rank: meRank,
                  playerId: 'x${meRank - 1}',
                  nickname: names[meRank - 1],
                  bestScore: 580 - (meRank - 1) * 20,
                )
                : LeaderboardRow(
                  rank: meRank,
                  playerId: 'me',
                  nickname: 'Ahmed',
                  bestScore: 315,
                ),
        totalPlayers: total,
      );
    }

    testWidgets('ilk 10 + SEN satırı + "127 oyuncu arasında 27. sıradasın"', (
      tester,
    ) async {
      await pumpSection(
        tester,
        Future.value(OnlineOutcome(OnlineStatus.ranked, snapshot: snap())),
      );
      expect(find.byKey(const Key('online-loading')), findsOneWidget);
      await tester.pump();
      expect(find.text('Genel Sıralama'), findsOneWidget);
      expect(find.text('Yusuf'), findsOneWidget);
      expect(find.text('Kerem'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('SEN'), findsOneWidget);
      expect(find.text('127 oyuncu arasında 27. sıradasın'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ilk 10 içindeyse satırı vurgulanır, ayrıca tekrarlanmaz', (
      tester,
    ) async {
      await pumpSection(
        tester,
        Future.value(
          OnlineOutcome(OnlineStatus.ranked, snapshot: snap(meRank: 8)),
        ),
      );
      await tester.pump();
      expect(find.text('Meryem'), findsOneWidget);
      expect(find.byKey(const Key('online-me-row')), findsOneWidget);
      expect(find.text('127 oyuncu arasında 8. sıradasın'), findsOneWidget);
    });

    testWidgets('çevrimdışı mesajı + tekrar dene', (tester) async {
      var calls = 0;
      await pumpSection(
        tester,
        Future.value(const OnlineOutcome(OnlineStatus.savedOffline)),
        retry: () async {
          calls++;
          return OnlineOutcome(OnlineStatus.ranked, snapshot: snap());
        },
      );
      await tester.pump();
      expect(
        find.textContaining('Skorun bu cihaza kaydedildi'),
        findsOneWidget,
      );
      expect(find.textContaining('kaydedildi.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('online-retry')));
      await tester.pump();
      await tester.pump();
      expect(calls, 1);
      expect(find.text('127 oyuncu arasında 27. sıradasın'), findsOneWidget);
    });

    testWidgets('yüklenemedi / hata → sakin mesaj, çökme yok', (tester) async {
      await pumpSection(
        tester,
        Future<OnlineOutcome>.delayed(
          Duration.zero,
          () => throw Exception('x'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(find.text('Genel sıralama şu anda yüklenemiyor.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uzun adlar ve büyük puanlar dar ekranda taşmaz', (
      tester,
    ) async {
      final s = LeaderboardSnapshot(
        gameId: GameIds.bulPatlat,
        top: [
          for (var i = 0; i < 10; i++)
            LeaderboardRow(
              rank: i + 1,
              playerId: 'x$i',
              nickname: 'WWWWWWWWWWWWWWWW',
              bestScore: 3995,
            ),
        ],
        me: const LeaderboardRow(
          rank: 1234,
          playerId: 'me',
          nickname: 'ŞŞŞŞŞŞŞŞŞŞŞŞŞŞŞŞ',
          bestScore: 3990,
        ),
        totalPlayers: 12345,
      );
      for (final size in const [
        Size(320, 640),
        Size(360, 800),
        Size(800, 360),
      ]) {
        await pumpSection(
          tester,
          Future.value(OnlineOutcome(OnlineStatus.ranked, snapshot: s)),
          size: size,
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });
  });

  group('oyun sonu entegrasyonu', () {
    setUpAll(setUpTestEnvironment);

    Future<(PlayerRepository, FakeBackend, LeaderboardService)> setup(
      WidgetTester tester,
    ) async {
      late PlayerRepository repo;
      final backend = FakeBackend();
      final shared = backend.docs;
      await tester.runAsync(() async {
        repo = PlayerRepository();
        await repo.load();
        // Diğer cihazlardan 12 oyuncu.
        for (var i = 0; i < 12; i++) {
          await serviceFor(
            FakeBackend(uid: 'o$i', shared: shared),
          ).submitAndLoad(
            profileId: 'p1',
            nickname: 'Oyuncu $i',
            score: scoreOf(GameIds.bulPatlat, 900 - i * 10),
          );
          await serviceFor(
            FakeBackend(uid: 'o$i', shared: shared),
          ).submitAndLoad(
            profileId: 'p1',
            nickname: 'Oyuncu $i',
            score: scoreOf(GameIds.harfArabalari, 900 - i * 10),
          );
        }
        await repo.createProfile('Ahmed', 'star');
        repo.promptedThisSession = true;
      });
      return (repo, backend, serviceFor(backend));
    }

    for (final size in const [
      Size(360, 800),
      Size(800, 1280),
      Size(1280, 800),
      Size(800, 360),
      Size(1920, 1080),
    ]) {
      testWidgets('Bul & Patlat: bitince genel sıralama görünür ($size)', (
        tester,
      ) async {
        final (repo, backend, service) = await setup(tester);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          gameApp(
            BulPatlatOyunu(random: math.Random(3)),
            players: repo,
            leaderboard: service,
          ),
        );
        for (var i = 0; i < 40 && find.text('BAŞLA').evaluate().isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.ensureVisible(find.text('BAŞLA'));
        await tester.tap(find.text('BAŞLA'));
        await tester.pump();
        final state = tester.state<BulPatlatOyunuState>(
          find.byType(BulPatlatOyunu),
        );
        final engine = state.engineForTest!;
        while (engine.status == BpStatus.running) {
          engine.tick(0.1);
          final t =
              engine.balloons
                  .where(
                    (b) =>
                        b.letter.char == engine.target?.char &&
                        b.y < engine.height - 10,
                  )
                  .toList();
          if (t.isNotEmpty && engine.elapsed < 20) engine.tap(t.first.id);
        }
        await tester.pump();
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('Bul & Patlat Tamamlandı'), findsOneWidget);
        expect(find.text('Genel Sıralama'), findsOneWidget);
        expect(find.text('Oyuncu 0'), findsOneWidget);
        expect(find.text('SEN'), findsOneWidget);
        expect(find.textContaining('oyuncu arasında'), findsOneWidget);
        expect(
          backend.docs.keys,
          contains('bul_patlat__deviceA_${repo.activePlayer!.id}'),
        );
        expect(
          backend.docs['bul_patlat__deviceA_${repo.activePlayer!.id}']!.best,
          engine.score,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'Harf Arabaları: bitince genel sıralama görünür; internet yoksa sakin mesaj',
      (tester) async {
        final (repo, backend, service) = await setup(tester);
        backend.online = false;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          gameApp(
            HarfArabalariOyunu(random: math.Random(3)),
            players: repo,
            leaderboard: service,
          ),
        );
        for (var i = 0; i < 40 && find.text('BAŞLA').evaluate().isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.ensureVisible(find.text('BAŞLA'));
        await tester.tap(find.text('BAŞLA'));
        await tester.pump();
        final engine =
            tester
                .state<HarfArabalariOyunuState>(find.byType(HarfArabalariOyunu))
                .engineForTest!;
        while (engine.status == HaStatus.running) {
          engine.tick(0.1);
          for (final c in engine.cars.toList()) {
            if (c.catchable &&
                c.letter.char == engine.target?.char &&
                c.x > 0) {
              engine.tap(c.id);
            }
          }
        }
        await tester.pump();
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('Harf Arabaları Tamamlandı'), findsOneWidget);
        expect(
          find.textContaining('Skorun bu cihaza kaydedildi'),
          findsOneWidget,
        );

        backend.online = true;
        await tester.ensureVisible(find.byKey(const Key('online-retry')));
        await tester.tap(find.byKey(const Key('online-retry')));
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('SEN'), findsOneWidget);
        expect(
          backend
              .docs['harf_arabalari__deviceA_${repo.activePlayer!.id}']!
              .best,
          engine.score,
        );
      },
    );
  });
}

class _FailingTop extends FakeBackend {
  @override
  Future<List<LeaderboardRow>> top(String gameId, int limit) async =>
      throw const SocketException('x');
}
