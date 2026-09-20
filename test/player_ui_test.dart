import 'package:kuran_okuma_rehberi/screens/oyunlar/oyunlar_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/skor_tablosu_sayfasi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harf_oyunlari_harness.dart';

PlayerGameResult _r(String id, int score, String game) => PlayerGameResult(
      playerId: id,
      gameId: game,
      score: score,
      correctAnswers: 10,
      wrongAnswers: 1,
      missedTargets: 1,
      totalItems: 20,
      playedAt: DateTime(2026, 1, 1, 12),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(setUpTestEnvironment);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.clear();
  });

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<PlayerRepository> repoWith(
    WidgetTester tester,
    Map<String, int> scores, {
    String? active,
    String game = GameIds.harfArabalari,
  }) async {
    late PlayerRepository repo;
    await tester.runAsync(() async {
      repo = PlayerRepository();
      await repo.load();
      for (final e in scores.entries) {
        final p = (await repo.createProfile(e.key, 'star'))!;
        await repo.recordResult(_r(p.id, e.value, game));
      }
      if (active != null) {
        await repo.selectProfile(
            repo.profiles.firstWhere((p) => p.displayName == active).id);
      }
      repo.promptedThisSession = true;
    });
    return repo;
  }

  group('skor tablosu ekranı', () {
    testWidgets('sıralı liste, aktif oyuncu "Sen" ile vurgulanır; agresif dil yok',
        (tester) async {
      useSize(tester, const Size(390, 844));
      final repo = await repoWith(
        tester,
        {'Elif': 245, 'Yusuf': 220, 'Ahmet': 195, 'MaviKartal': 180},
        active: 'Ahmet',
      );
      await tester.pumpWidget(gameApp(
          const SkorTablosuSayfasi(initialGameId: GameIds.harfArabalari),
          players: repo));
      await tester.pump();

      expect(find.text('Skor Tablosu'), findsWidgets);
      // Sıra: Elif, Yusuf, Ahmet, MaviKartal (yukarıdan aşağı)
      double y(String n) => tester.getTopLeft(find.byKey(Key('row-$n'))).dy;
      expect(y('Elif'), lessThan(y('Yusuf')));
      expect(y('Yusuf'), lessThan(y('Ahmet')));
      expect(y('Ahmet'), lessThan(y('MaviKartal')));
      for (final score in ['245', '220', '195', '180']) {
        expect(find.text(score), findsOneWidget);
      }
      // Yalnızca aktif oyuncu (Ahmet) "Sen" rozeti taşır.
      expect(find.text('Sen'), findsOneWidget);
      expect(
        find.descendant(
            of: find.byKey(const Key('row-Ahmet')), matching: find.text('Sen')),
        findsOneWidget,
      );
      // Çocuğa uygun dil: olumsuz/kaybettiren ifade yok.
      for (final bad in ['Kaybettin', 'Sonuncu', 'kaybettin', 'sonuncusun']) {
        expect(find.textContaining(bad), findsNothing);
      }
    });

    testWidgets('her oyun için ayrı tablo; boş tabloda nazik mesaj', (tester) async {
      useSize(tester, const Size(390, 844));
      final repo = await repoWith(tester, {'Elif': 245, 'Ali': 100}, active: 'Elif');
      await tester.pumpWidget(gameApp(
          const SkorTablosuSayfasi(initialGameId: GameIds.harfArabalari),
          players: repo));
      await tester.pump();
      expect(find.byKey(const Key('row-Elif')), findsOneWidget);

      await tester.tap(find.byKey(const Key('game-bul_patlat')));
      await tester.pump();
      expect(find.byKey(const Key('row-Elif')), findsNothing);
      expect(find.byKey(const Key('leaderboard-empty')), findsOneWidget);
      expect(find.text('Henüz skor yok. İlk oynayan sen ol!'), findsOneWidget);

      // Bul & Patlat'ta skor kaydedilince o tabloda görünür, diğeri değişmez.
      await tester.runAsync(() async {
        await repo.recordResult(
            _r(repo.activePlayer!.id, 77, GameIds.bulPatlat));
      });
      await tester.pump();
      expect(find.text('77'), findsOneWidget);
      await tester.tap(find.byKey(const Key('game-harf_arabalari')));
      await tester.pump();
      expect(find.text('245'), findsOneWidget);
      expect(find.text('77'), findsNothing);
    });

    testWidgets('12 oyuncu: ilk 10 görünür; aktif oyuncu dışarıdaysa kendi sırası ayrıca gösterilir',
        (tester) async {
      useSize(tester, const Size(390, 844));
      final scores = {for (var i = 1; i <= 12; i++) 'Oyuncu$i': i * 10};
      final repo = await repoWith(tester, scores, active: 'Oyuncu1');
      await tester.pumpWidget(gameApp(
          const SkorTablosuSayfasi(initialGameId: GameIds.harfArabalari),
          players: repo));
      await tester.pump();
      // Liste tembel kurulur: sona kaydırarak tüm satırları say.
      final seen = <String>{};
      for (var i = 0; i < 12; i++) {
        for (final e in find.byWidgetPredicate((w) =>
            w.key is Key && '${w.key}'.contains("'row-")).evaluate()) {
          seen.add('${e.widget.key}');
        }
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
      }
      // İlk 10 + aktif oyuncunun (Oyuncu1: 12. sıra) ayrı satırı.
      expect(seen.contains("[<'row-Oyuncu12'>]"), isTrue);
      expect(seen.contains("[<'row-Oyuncu3'>]"), isTrue);
      expect(seen.contains("[<'row-Oyuncu2'>]"), isFalse, reason: '11. sıra tabloda yok');
      expect(seen.contains("[<'row-Oyuncu1'>]"), isTrue, reason: 'kendi sırası gösterilir');
      expect(find.text('Senin sıran:'), findsOneWidget);
    });

    testWidgets('oyun listesindeki Skor Tablosu kartı açılır', (tester) async {
      useSize(tester, const Size(390, 844));
      final repo = await repoWith(tester, {'Elif': 100}, active: 'Elif');
      await tester.pumpWidget(gameApp(const OyunlarScreen(), players: repo));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Skor Tablosu'));
      await tester.pumpAndSettle();
      expect(find.byType(SkorTablosuSayfasi), findsOneWidget);
    });

    group('taşma yok', () {
      final sizes = <String, Size>{
        'küçük telefon 320x568': const Size(320, 568),
        'telefon 390x844': const Size(390, 844),
        'yatay telefon 844x390': const Size(844, 390),
        'tablet dikey 800x1280': const Size(800, 1280),
        'masaüstü 1440x900': const Size(1440, 900),
      };
      for (final s in sizes.entries) {
        testWidgets(s.key, (tester) async {
          final errors = <String>[];
          final old = FlutterError.onError;
          FlutterError.onError = (d) => errors
              .add(d.exceptionAsString().split(String.fromCharCode(10)).first);
          addTearDown(() => FlutterError.onError = old);
          useSize(tester, s.value);
          final scores = {
            'Çok Uzun Oyuncu1': 500, // 16 karakter (sınır)
            for (var i = 1; i <= 11; i++) 'Oyuncu$i': i * 10,
          };
          final repo = await repoWith(tester, scores, active: 'Oyuncu3');
          await tester.pumpWidget(gameApp(
              const SkorTablosuSayfasi(initialGameId: GameIds.harfArabalari),
              players: repo));
          await tester.pump();
          FlutterError.onError = old;
          expect(errors, isEmpty, reason: errors.join(String.fromCharCode(10)));
        });
      }
    });
  });

  group('oyuncu seçici', () {
    testWidgets('oluştur, değiştir, sil; etiket güncellenir; kapat-aç sonrası korunur',
        (tester) async {
      useSize(tester, const Size(390, 844));
      late PlayerRepository repo;
      await tester.runAsync(() async {
        repo = PlayerRepository();
        await repo.load();
        repo.promptedThisSession = true;
      });
      await tester.pumpWidget(gameApp(const OyunlarScreen(), players: repo));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Oyuncu seç'), findsOneWidget);

      // İlk oyuncu: profil yokken doğrudan form açılır.
      await tester.tap(find.byKey(const Key('player-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Kim oynuyor?'), findsOneWidget);
      // Boş ad → hata; gerçek ad sorulmaz, yalnızca takma ad.
      await tester.tap(find.byKey(const Key('create-player')));
      await tester.pump();
      expect(find.text('Bir ad yaz.'), findsOneWidget);
      expect(find.textContaining('e-posta'), findsNothing);
      await tester.enterText(find.byKey(const Key('player-name-field')), 'Elif');
      await tester.tap(find.byKey(const Key('avatar-sun')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('create-player')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(find.text('Oyuncu: Elif'), findsOneWidget);

      // İkinci oyuncu ve aynı ad denemesi.
      await tester.tap(find.byKey(const Key('player-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-player')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('player-name-field')), 'elif');
      await tester.tap(find.byKey(const Key('create-player')));
      await tester.pump();
      expect(find.text('Bu ad zaten kullanılıyor.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('player-name-field')), 'Ahmet');
      await tester.tap(find.byKey(const Key('create-player')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(find.text('Oyuncu: Ahmet'), findsOneWidget);
      expect(repo.profiles.length, 2);

      // Oyuncu değiştir: listeden Elif'i seç.
      await tester.tap(find.byKey(const Key('player-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('player-Elif')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(find.text('Oyuncu: Elif'), findsOneWidget);
      expect(repo.activePlayer!.displayName, 'Elif');

      // "Uygulamayı kapat-aç": yeni repository aynı profili hatırlar.
      late PlayerRepository reopened;
      await tester.runAsync(() async {
        reopened = PlayerRepository();
        await reopened.load();
      });
      expect(reopened.profiles.map((p) => p.displayName).toSet(), {'Elif', 'Ahmet'});
      expect(reopened.activePlayer!.displayName, 'Elif');

      // Silme onay ister; silinince aktif oyuncu kalkar.
      await tester.tap(find.byKey(const Key('player-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete-Elif')));
      await tester.pumpAndSettle();
      expect(find.text('Oyuncu silinsin mi?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(repo.profiles.map((p) => p.displayName), ['Ahmet']);
      expect(repo.activePlayer, isNull);
    });

    testWidgets('küçük ekranda ve klavye açıkken form taşmaz', (tester) async {
      useSize(tester, const Size(320, 568));
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetViewInsets);
      final errors = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (d) => errors
          .add(d.exceptionAsString().split(String.fromCharCode(10)).first);
      addTearDown(() => FlutterError.onError = old);
      late PlayerRepository repo;
      await tester.runAsync(() async {
        repo = PlayerRepository();
        await repo.load();
        repo.promptedThisSession = true;
      });
      await tester.pumpWidget(gameApp(const OyunlarScreen(), players: repo));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('player-chip')));
      await tester.pumpAndSettle();
      FlutterError.onError = old;
      expect(errors, isEmpty, reason: errors.join(String.fromCharCode(10)));
      expect(find.byKey(const Key('create-player')), findsOneWidget);
    });
  });
}
