import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

PlayerGameResult _result(String playerId, int score,
        {String gameId = GameIds.harfArabalari,
        int correct = 5,
        int wrong = 1,
        int missed = 1,
        int items = 20,
        DateTime? at}) =>
    PlayerGameResult(
      playerId: playerId,
      gameId: gameId,
      score: score,
      correctAnswers: correct,
      wrongAnswers: wrong,
      missedTargets: missed,
      totalItems: items,
      playedAt: at ?? DateTime(2026, 1, 1, 12),
    );

Future<PlayerRepository> _fresh() async {
  final repo = PlayerRepository();
  await repo.load();
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('profiller', () {
    test('oluşturma: aktif olur; uygulama kapanıp açılınca korunur', () async {
      final repo = await _fresh();
      expect(repo.profiles, isEmpty);
      expect(repo.activePlayer, isNull);

      final elif = await repo.createProfile('Elif', 'moon');
      expect(elif, isNotNull);
      expect(repo.activePlayer!.displayName, 'Elif');
      expect(repo.activePlayer!.avatarId, 'moon');

      // "Uygulamayı kapat-aç": yeni repository aynı depodan okur.
      final reopened = await _fresh();
      expect(reopened.profiles.map((p) => p.displayName), ['Elif']);
      expect(reopened.activePlayer!.id, elif!.id);
    });

    test('tek oyuncu: ad verilir, düzeltilir; kimlik ve skorlar korunur', () async {
      final repo = await _fresh();
      expect(await repo.setName('A'), PlayerNameError.tooShort);
      expect(repo.activePlayer, isNull);
      expect(await repo.setName('  Ahmet  '), isNull);
      final p = repo.activePlayer!;
      expect(p.displayName, 'Ahmet');
      await repo.recordResult(_result(p.id, 120));

      expect(await repo.setName('<b>'), PlayerNameError.invalidChars);
      expect(await repo.setName('Ahmed'), isNull);
      expect(repo.profiles, hasLength(1), reason: 'yeni oyuncu açılmaz');
      final reopened = await _fresh();
      expect(reopened.activePlayer!.id, p.id);
      expect(reopened.activePlayer!.displayName, 'Ahmed');
      expect(reopened.bestScore(p.id, GameIds.harfArabalari), 120);
    });

    test('eski sürümde birden çok profil: aktif olan (yoksa ilk) oyuncu olur', () async {
      final repo = await _fresh();
      final a = (await repo.createProfile('Ali', 'star'))!;
      final b = (await repo.createProfile('Elif', 'note'))!;
      expect(repo.activePlayer!.id, b.id);
      SharedPreferences.setMockInitialValues({
        PlayerRepository.profilesKey:
            '[${[a, b].map((p) => '{"id":"${p.id}","displayName":"${p.displayName}","avatarId":"star","createdAt":"2026-01-01"}').join(',')}]',
      });
      expect((await _fresh()).activePlayer!.id, a.id);
    });

    test('ad doğrulama: boş, çok uzun, aynı ad (büyük/küçük harf fark etmez)', () async {
      final repo = await _fresh();
      expect(repo.validateName('   '), PlayerNameError.empty);
      expect(repo.validateName('a' * 17), PlayerNameError.tooLong);
      expect(repo.validateName('a' * 16), isNull);
      await repo.createProfile('Elif', 'star');
      expect(repo.validateName('elif'), PlayerNameError.taken);
      expect(repo.validateName('  ELİF  '), PlayerNameError.taken); // Türkçe büyük harf de aynı ad
      expect(repo.validateName('Elif2'), isNull);
      expect(await repo.createProfile('  ', 'star'), isNull);
      expect(repo.profiles.length, 1);
    });

    test('ad sadeleştirilir; geçersiz avatar varsayılana düşer', () async {
      final repo = await _fresh();
      final p = (await repo.createProfile('  Mavi   Kartal \n', 'yok'))!;
      expect(p.displayName, 'Mavi Kartal');
      expect(p.avatarId, kPlayerAvatars.first.id);
    });

    test('yalnızca takma ad + avatar saklanır (kişisel veri alanı yok)', () async {
      final repo = await _fresh();
      final p = (await repo.createProfile('Yusuf', 'sun'))!;
      expect(p.toJson().keys.toSet(), {'id', 'displayName', 'avatarId', 'createdAt'});
    });

    test('silme: profil, skorları ve aktiflik kalkar', () async {
      final repo = await _fresh();
      final p = (await repo.createProfile('Ali', 'star'))!;
      await repo.recordResult(_result(p.id, 100));
      await repo.deleteProfile(p.id);
      expect(repo.profiles, isEmpty);
      expect(repo.activePlayer, isNull);
      expect((await _fresh()).profiles, isEmpty);
    });

    test('bozuk kayıt uygulamayı çökertmez', () async {
      SharedPreferences.setMockInitialValues({
        PlayerRepository.profilesKey: '{bozuk json',
        PlayerRepository.statsKey: '[1,2',
      });
      final repo = await _fresh();
      expect(repo.profiles, isEmpty);
      expect(repo.loaded, isTrue);
    });
  });

  group('skorlar: oyuncular birbirinin üzerine yazmaz', () {
    test('aynı oyunda iki oyuncu ayrı en iyi/son/toplam tutar', () async {
      final repo = await _fresh();
      final elif = (await repo.createProfile('Elif', 'star'))!;
      final ahmet = (await repo.createProfile('Ahmet', 'note'))!;

      await repo.recordResult(_result(elif.id, 245, correct: 16, wrong: 2, missed: 3));
      await repo.recordResult(_result(ahmet.id, 195, correct: 12, wrong: 4, missed: 1));
      await repo.recordResult(_result(elif.id, 100, correct: 8, wrong: 0, missed: 1));

      final e = repo.statsFor(elif.id, GameIds.harfArabalari);
      expect(e.bestScore, 245); // düşük skor en iyiyi bozmaz
      expect(e.lastScore, 100);
      expect(e.gamesPlayed, 2);
      expect(e.totalCorrect, 24);
      expect(e.totalWrong, 2);
      expect(e.totalMissed, 4);
      expect(e.totalItems, 40);
      expect(e.accuracyPercent, 80); // 24 / (24+2+4) — saklanmaz, hesaplanır

      final a = repo.statsFor(ahmet.id, GameIds.harfArabalari);
      expect(a.bestScore, 195);
      expect(a.gamesPlayed, 1);
    });

    test('oyunlar ayrı tutulur: Bul & Patlat ile Harf Arabaları karışmaz', () async {
      final repo = await _fresh();
      final p = (await repo.createProfile('Elif', 'star'))!;
      await repo.recordResult(_result(p.id, 90, gameId: GameIds.bulPatlat));
      await repo.recordResult(_result(p.id, 200, gameId: GameIds.harfArabalari));
      expect(repo.bestScore(p.id, GameIds.bulPatlat), 90);
      expect(repo.bestScore(p.id, GameIds.harfArabalari), 200);
    });

    test('kayıtlar uygulama yeniden açılınca korunur', () async {
      final repo = await _fresh();
      final p = (await repo.createProfile('Elif', 'star'))!;
      await repo.recordResult(_result(p.id, 210));
      final reopened = await _fresh();
      expect(reopened.bestScore(p.id, GameIds.harfArabalari), 210);
      expect(reopened.statsFor(p.id, GameIds.harfArabalari).lastScore, 210);
    });

    test('silinmiş profile sonuç yazılmaz', () async {
      final repo = await _fresh();
      await repo.recordResult(_result('yok', 50));
      expect(repo.statsFor('yok', GameIds.harfArabalari).gamesPlayed, 0);
    });

    test('PlayerGameResult doğruluğu hesaplanır', () {
      expect(_result('x', 1, correct: 14, wrong: 0, missed: 3).accuracyPercent, 82);
      expect(_result('x', 1, correct: 0, wrong: 0, missed: 0).accuracyPercent, 0);
    });
  });
}
