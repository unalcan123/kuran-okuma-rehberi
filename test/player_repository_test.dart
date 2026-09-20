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

    test('birden fazla profil; değiştirme kalıcıdır', () async {
      final repo = await _fresh();
      final a = (await repo.createProfile('Ali', 'star'))!;
      final b = (await repo.createProfile('Elif', 'note'))!;
      expect(repo.activePlayer!.id, b.id); // son oluşturulan aktif
      await repo.selectProfile(a.id);
      expect((await _fresh()).activePlayer!.id, a.id);
      expect(repo.profiles.length, 2);
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
      expect(repo.leaderboard(GameIds.harfArabalari), isEmpty);
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
      expect(repo.leaderboard(GameIds.harfArabalari), isEmpty);
    });

    test('PlayerGameResult doğruluğu hesaplanır', () {
      expect(_result('x', 1, correct: 14, wrong: 0, missed: 3).accuracyPercent, 82);
      expect(_result('x', 1, correct: 0, wrong: 0, missed: 0).accuracyPercent, 0);
    });
  });

  group('skor tablosu (yerel Top 10)', () {
    test('en iyi skora göre sıralı; sadece o oyunu oynayanlar', () async {
      final repo = await _fresh();
      final names = {'Elif': 245, 'Yusuf': 220, 'Ahmet': 195, 'MaviKartal': 180};
      for (final e in names.entries) {
        final p = (await repo.createProfile(e.key, 'star'))!;
        await repo.recordResult(_result(p.id, e.value));
      }
      await repo.createProfile('Hiç Oynamadı', 'star');

      final board = repo.leaderboard(GameIds.harfArabalari);
      expect(board.map((e) => '${e.rank}.${e.profile.displayName}.${e.stats.bestScore}'),
          ['1.Elif.245', '2.Yusuf.220', '3.Ahmet.195', '4.MaviKartal.180']);
      // Başka oyunda kimse yok: ayrı tablo.
      expect(repo.leaderboard(GameIds.bulPatlat), isEmpty);
    });

    test('12 oyuncu varsa yalnızca ilk 10; limit ileride 20 olabilir', () async {
      final repo = await _fresh();
      for (var i = 1; i <= 12; i++) {
        final p = (await repo.createProfile('Oyuncu$i', 'star'))!;
        await repo.recordResult(_result(p.id, i * 10));
      }
      final top10 = repo.leaderboard(GameIds.harfArabalari);
      expect(top10.length, 10);
      expect(top10.first.stats.bestScore, 120);
      expect(top10.last.stats.bestScore, 30);
      expect(repo.leaderboard(GameIds.harfArabalari, limit: 20).length, 12);
      // Tablonun dışında kalan oyuncu kendi sırasını yine bulur.
      final last = repo.profiles.first; // Oyuncu1: 10 puan → 12. sıra
      expect(repo.entryOf(last.id, GameIds.harfArabalari)!.rank, 12);
    });

    test('beraberlikte önce o skora ulaşan; sonra ada göre', () async {
      final repo = await _fresh();
      final b = (await repo.createProfile('Bora', 'star'))!;
      final a = (await repo.createProfile('Ada', 'star'))!;
      await repo.recordResult(_result(b.id, 100, at: DateTime(2026, 1, 1, 10)));
      await repo.recordResult(_result(a.id, 100, at: DateTime(2026, 1, 1, 11)));
      var board = repo.leaderboard(GameIds.harfArabalari);
      expect(board.map((e) => e.profile.displayName), ['Bora', 'Ada']);

      // Aynı skoru sonra tekrarlamak eski tarihi (öndeki sırayı) bozmaz.
      await repo.recordResult(_result(a.id, 100, at: DateTime(2026, 1, 2)));
      board = repo.leaderboard(GameIds.harfArabalari);
      expect(board.first.profile.displayName, 'Bora');
    });

    test('her oyun için ayrı sıralama', () async {
      final repo = await _fresh();
      final elif = (await repo.createProfile('Elif', 'star'))!;
      final ali = (await repo.createProfile('Ali', 'star'))!;
      await repo.recordResult(_result(elif.id, 300, gameId: GameIds.bulPatlat));
      await repo.recordResult(_result(ali.id, 100, gameId: GameIds.bulPatlat));
      await repo.recordResult(_result(elif.id, 50, gameId: GameIds.harfArabalari));
      await repo.recordResult(_result(ali.id, 250, gameId: GameIds.harfArabalari));
      expect(repo.leaderboard(GameIds.bulPatlat).first.profile.displayName, 'Elif');
      expect(repo.leaderboard(GameIds.harfArabalari).first.profile.displayName, 'Ali');
    });
  });
}
