import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/genel_siralama_sayfasi.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/oyunlar_screen.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harf_oyunlari_harness.dart';
import 'support/fake_leaderboard_backend.dart';

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

  Future<PlayerRepository> emptyRepo(WidgetTester tester) async {
    late PlayerRepository repo;
    await tester.runAsync(() async {
      repo = PlayerRepository();
      await repo.load();
    });
    return repo;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  /// Diğer cihazlardan 12 oyuncu (her iki oyunda) + bu cihaz ("deviceA").
  Future<(FakeBackend, LeaderboardService)> onlineWith12(
    WidgetTester tester,
  ) async {
    final backend = FakeBackend();
    await tester.runAsync(() async {
      for (var i = 0; i < 12; i++) {
        final other = serviceFor(FakeBackend(uid: 'o$i', shared: backend.docs));
        for (final g in GameIds.leaderboardGames) {
          await other.submitAndLoad(
            profileId: 'p1',
            nickname: 'Oyuncu $i',
            score: scoreOf(g, 900 - i * 10),
          );
        }
      }
    });
    return (backend, serviceFor(backend));
  }

  group('oyuncu adı (cihaz başına tek oyuncu)', () {
    testWidgets(
      'Oyunlar ilk açılınca ad sorulur; kaydedilir, sonra bir daha sorulmaz',
      (tester) async {
        useSize(tester, const Size(390, 844));
        final repo = await emptyRepo(tester);
        await tester.pumpWidget(gameApp(const OyunlarScreen(), players: repo));
        await settle(tester);
        expect(find.byKey(const Key('player-name-field')), findsOneWidget);
        expect(find.textContaining('Genel sıralamada bu adla'), findsOneWidget);
        // Birden çok oyuncu / avatar / e-posta yok.
        expect(find.textContaining('Yeni Oyuncu'), findsNothing);
        expect(find.textContaining('e-posta'), findsNothing);

        await tester.enterText(find.byKey(const Key('player-name-field')), 'A');
        await tester.tap(find.byKey(const Key('save-player-name')));
        await tester.pump();
        expect(find.text('En az 2 harf.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('player-name-field')),
          'Elif',
        );
        await tester.tap(find.byKey(const Key('save-player-name')));
        await settle(tester);
        expect(find.text('Oyuncu: Elif'), findsOneWidget);

        // Menü yeniden açılınca (ve uygulama yeniden açılınca) sorulmaz.
        late PlayerRepository reopened;
        await tester.runAsync(() async {
          reopened = PlayerRepository();
          await reopened.load();
        });
        expect(reopened.activePlayer!.displayName, 'Elif');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          gameApp(const OyunlarScreen(), players: reopened),
        );
        await settle(tester);
        expect(find.byKey(const Key('player-name-field')), findsNothing);
      },
    );

    testWidgets(
      'ad düzeltilir: tek oyuncu kalır, çevrimiçi ad da güncellenir',
      (tester) async {
        useSize(tester, const Size(390, 844));
        final repo = await emptyRepo(tester);
        final (backend, service) = await onlineWith12(tester);
        await tester.runAsync(() async {
          await repo.setName('Elif');
          await service.submitAndLoad(
            profileId: repo.activePlayer!.id,
            nickname: 'Elif',
            score: scoreOf(GameIds.bulPatlat, 300),
          );
        });
        await tester.pumpWidget(
          gameApp(const OyunlarScreen(), players: repo, leaderboard: service),
        );
        await settle(tester);
        await tester.tap(find.byKey(const Key('player-chip')));
        await settle(tester);
        final field = tester.widget<TextField>(
          find.byKey(const Key('player-name-field')),
        );
        expect(field.controller!.text, 'Elif');
        await tester.enterText(
          find.byKey(const Key('player-name-field')),
          'Elif Nur',
        );
        await tester.tap(find.byKey(const Key('save-player-name')));
        await settle(tester);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        expect(find.text('Oyuncu: Elif Nur'), findsOneWidget);
        expect(repo.profiles, hasLength(1));
        final id = 'deviceA_${repo.activePlayer!.id}';
        expect(backend.renames[id], 'Elif Nur');
        expect(backend.docs['bul_patlat__$id']!.nickname, 'Elif Nur');
        expect(backend.docs['bul_patlat__$id']!.best, 300);
      },
    );

    testWidgets('küçük ekranda ve klavye açıkken ad penceresi taşmaz', (
      tester,
    ) async {
      useSize(tester, const Size(320, 568));
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetViewInsets);
      final repo = await emptyRepo(tester);
      await tester.pumpWidget(gameApp(const OyunlarScreen(), players: repo));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('save-player-name')), findsOneWidget);
    });
  });

  group('Genel Sıralama sayfası', () {
    testWidgets('menüden açılır; ilk 10, SEN ve sıra; oyun sekmesi değişir', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      final repo = await emptyRepo(tester);
      final (_, service) = await onlineWith12(tester);
      await tester.runAsync(() async {
        await repo.setName('Ahmet');
        await service.submitAndLoad(
          profileId: repo.activePlayer!.id,
          nickname: 'Ahmet',
          score: scoreOf(GameIds.bulPatlat, 500),
        );
      });
      await tester.pumpWidget(
        gameApp(const OyunlarScreen(), players: repo, leaderboard: service),
      );
      await settle(tester);
      // Menü uzun: kart tembel listede aşağıda, önce kaydır.
      await tester.scrollUntilVisible(find.text('Genel Sıralama'), 200);
      await settle(tester);
      await tester.tap(find.text('Genel Sıralama'));
      await settle(tester);
      expect(find.byType(GenelSiralamaSayfasi), findsOneWidget);
      expect(find.text('Oyuncu 0'), findsOneWidget);
      expect(find.text('Oyuncu 9'), findsOneWidget);
      expect(find.text('Oyuncu 10'), findsNothing);
      expect(find.text('SEN'), findsOneWidget);
      expect(find.text('13 oyuncu arasında 13. sıradasın'), findsOneWidget);

      // Harf Arabaları'nda henüz skoru yok: yalnızca oyuncu sayısı.
      await tester.tap(find.byKey(Key('game-${GameIds.harfArabalari}')));
      await settle(tester);
      expect(find.text('SEN'), findsNothing);
      expect(find.text('12 oyuncu'), findsOneWidget);
    });

    testWidgets('çevrimiçi sıralama yoksa sakin mesaj', (tester) async {
      useSize(tester, const Size(390, 844));
      final repo = await emptyRepo(tester);
      await tester.pumpWidget(
        gameApp(const GenelSiralamaSayfasi(), players: repo),
      );
      await settle(tester);
      expect(find.text('Genel sıralama şu anda yüklenemiyor.'), findsOneWidget);
    });

    group('taşma yok', () {
      const sizes = {
        '360x800': Size(360, 800),
        '800x1280': Size(800, 1280),
        '1280x800': Size(1280, 800),
        '800x360': Size(800, 360),
        '1920x1080': Size(1920, 1080),
      };
      for (final s in sizes.entries) {
        testWidgets(s.key, (tester) async {
          useSize(tester, s.value);
          final repo = await emptyRepo(tester);
          final (_, service) = await onlineWith12(tester);
          await tester.runAsync(() => repo.setName('ŞŞŞŞŞŞŞŞŞŞŞŞŞŞŞŞ'));
          await tester.pumpWidget(
            gameApp(
              const GenelSiralamaSayfasi(),
              players: repo,
              leaderboard: service,
            ),
          );
          await settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('Oyuncu 0'), findsOneWidget);
        });
      }
    });
  });
}
