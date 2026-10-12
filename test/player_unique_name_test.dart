// Tekil oyuncu adı: ad bütün oyuncular arasında tek; alınmışsa alınmamış
// öneriler; çevrimdışı verilen ad sonra denetlenir, başkasındaysa yeni ad
// istenir. Kurallar: firestore.rules "nicknames" (tool/firestore_rules_test).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_picker.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_service.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/nickname_policy.dart';
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

  group('NicknamePolicy', () {
    test('büyük/küçük harf, boşluk ve . - _ aynı ad sayılır', () {
      expect(NicknamePolicy.claimKey('Ali 123'), 'ali123');
      expect(NicknamePolicy.claimKey('ALİ_123'), 'ali123');
      expect(NicknamePolicy.claimKey('  ali.1-23 '), 'ali123');
      expect(NicknamePolicy.claimKey('Ayşe'), isNot(NicknamePolicy.claimKey('Ayse')));
    });

    test('öneriler geçerli, farklı ve "Ali 123" → "Ali 123x"', () {
      final list = NicknamePolicy.suggestions(
        'Ali 123',
        random: math.Random(1),
      );
      expect(list.length, 8);
      expect(list.where((s) => RegExp(r'^Ali 123\d$').hasMatch(s)), isNotEmpty);
      final keys = list.map(NicknamePolicy.claimKey).toSet();
      expect(keys.length, list.length);
      expect(keys, isNot(contains('ali123')));
      for (final s in list) {
        expect(NicknamePolicy.isValid(s), isTrue, reason: s);
      }
      // Uzun adlar 16 harfe sığdırılır.
      for (final s in NicknamePolicy.suggestions('Abdurrahmanoglu1')) {
        expect(s.runes.length, lessThanOrEqualTo(16), reason: s);
        expect(NicknamePolicy.isValid(s), isTrue, reason: s);
      }
    });
  });

  group('LeaderboardService.claimName', () {
    test('ilk alan korur; ikinci oyuncuya alınmamış öneriler', () async {
      final a = FakeBackend(uid: 'devA');
      final b = FakeBackend(uid: 'devB', sharedNames: a.names);
      expect(
        (await serviceFor(a).claimName('p1', 'Ali 123')).status,
        NameClaimStatus.ok,
      );
      // Bir öneriyi de başkası almış olsun: önerilerde çıkmamalı.
      final taken = await serviceFor(b).claimName('p2', 'ali123');
      expect(taken.status, NameClaimStatus.taken);
      expect(taken.suggestions, isNotEmpty);
      for (final s in taken.suggestions) {
        expect(a.names.containsKey(NicknamePolicy.claimKey(s)), isFalse);
      }
      // Önerilerden biri alınabilir.
      expect(
        (await serviceFor(b).claimName('p2', taken.suggestions.first)).status,
        NameClaimStatus.ok,
      );
      // Aynı oyuncu kendi adını yeniden isteyince sorun yok.
      expect(
        (await serviceFor(a).claimName('p1', 'ALI 123')).status,
        NameClaimStatus.ok,
      );
    });

    test('ad değişince eskisi bırakılır, başkası alabilir', () async {
      final a = FakeBackend(uid: 'devA');
      final service = serviceFor(a);
      await service.claimName('p1', 'Elif');
      await service.claimName('p1', 'Elif Nur', previous: 'Elif');
      await Future<void>.delayed(Duration.zero);
      expect(a.names.containsKey('elif'), isFalse);
      final b = FakeBackend(uid: 'devB', sharedNames: a.names);
      expect(
        (await serviceFor(b).claimName('p2', 'Elif')).status,
        NameClaimStatus.ok,
      );
    });

    test('çevrimdışı: ad kuyruğa; sonra başkasında çıkarsa çakışma', () async {
      final a = FakeBackend(uid: 'devA')..online = false;
      final service = serviceFor(a);
      expect(
        (await service.claimName('p1', 'Yusuf')).status,
        NameClaimStatus.offline,
      );
      // Bu arada başka biri "Yusuf"u aldı.
      a.names['yusuf'] = 'devB_p9';
      a.online = true;
      await service.init();
      expect(await service.nameConflictFor('p1'), 'Yusuf');
      expect(await service.isClaimed('p1', 'Yusuf'), isFalse);
      // Yeni ad alınınca çakışma kalkar.
      expect(
        (await service.claimName('p1', 'Yusuf 7')).status,
        NameClaimStatus.ok,
      );
      expect(await service.nameConflictFor('p1'), isNull);
      expect(await service.isClaimed('p1', 'yusuf 7'), isTrue);
    });
  });

  group('ad sayfası', () {
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
      await tester.pumpAndSettle();
    }

    testWidgets('alınmış ad: uyarı ve öneri; öneriye dokununca kaydedilir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final other = FakeBackend(uid: 'devB');
      other.names['ali123'] = 'devB_p1';
      final service = serviceFor(
        FakeBackend(uid: 'devA', sharedNames: other.names),
      );
      final repo = await emptyRepo(tester);
      await tester.pumpWidget(
        gameApp(
          Builder(
            builder:
                (context) => TextButton(
                  onPressed: () => showPlayerNameSheet(context),
                  child: const Text('aç'),
                ),
          ),
          players: repo,
          leaderboard: service,
        ),
      );
      await tester.tap(find.text('aç'));
      await settle(tester);
      await tester.enterText(
        find.byKey(const Key('player-name-field')),
        'Ali 123',
      );
      await tester.tap(find.byKey(const Key('save-player-name')));
      await settle(tester);
      expect(
        find.textContaining('Bu ad başka bir oyuncuda'),
        findsOneWidget,
      );
      expect(repo.activePlayer, isNull, reason: 'alınmış ad kaydedilmez');
      final chips = find.byType(ActionChip);
      expect(chips, findsWidgets);
      final chip = tester.widget<ActionChip>(chips.first);
      final suggestion = (chip.label as Text).data!;
      await tester.tap(chips.first);
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-player-name')));
      await settle(tester);
      expect(repo.activePlayer?.displayName, suggestion);
      expect(
        other.names[NicknamePolicy.claimKey(suggestion)],
        endsWith('_${repo.activePlayer!.id}'),
      );
    });

    testWidgets('çakışan ad: not ve hazır öneriler gösterilir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = await emptyRepo(tester);
      await tester.runAsync(() => repo.setName('Zeynep'));
      final service = serviceFor(FakeBackend(uid: 'devA'));
      await tester.pumpWidget(
        gameApp(
          Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showPlayerNameSheet(context, conflictName: 'Zeynep'),
                  child: const Text('aç'),
                ),
          ),
          players: repo,
          leaderboard: service,
        ),
      );
      await tester.tap(find.text('aç'));
      await settle(tester);
      expect(find.byKey(const Key('player-name-conflict')), findsOneWidget);
      expect(find.byType(ActionChip), findsWidgets);
    });
  });
}
