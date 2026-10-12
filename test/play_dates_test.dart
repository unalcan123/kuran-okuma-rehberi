// Oyuncunun ne zaman oynadığı: Sonuçlarım'da son oynama tarihi, Genel
// Sıralama'da puanın yapıldığı tarih; tarih seçilen dilde kısa yazılır.
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/l10n/date_format.dart';
import 'package:kuran_okuma_rehberi/l10n/l10n.dart';
import 'package:kuran_okuma_rehberi/models/game_score.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_leaderboard_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('kısa tarih her dilde', () {
    final d = DateTime(2026, 10, 12);
    expect(shortDate(d, AppLanguage.tr), '12 Eki 2026');
    expect(shortDate(d, AppLanguage.en), '12 Oct 2026');
    expect(shortDate(d, AppLanguage.fr), '12 oct. 2026');
    expect(shortDate(d, AppLanguage.es), '12 oct 2026');
    expect(shortDate(d, AppLanguage.nl), '12 okt. 2026');
    expect(shortDate(d, AppLanguage.de), '12. Okt. 2026');
    expect(shortDate(d, AppLanguage.bs), '12. okt. 2026');
    for (final language in AppLanguage.values) {
      for (var m = 1; m <= 12; m++) {
        expect(shortDate(DateTime(2026, m, 1), language), isNotEmpty);
      }
    }
  });

  test('oyun bitince son oynama tarihi saklanır', () async {
    final store = GameScoreStore();
    expect((await store.historyOf('memory.easy1')).lastPlayedAt, isNull);
    final before = DateTime.now().subtract(const Duration(seconds: 1));
    await store.submit(
      'memory.easy1',
      const GameResult(points: 40, firstTry: 3, total: 4),
    );
    final last = (await store.historyOf('memory.easy1')).lastPlayedAt;
    expect(last, isNotNull);
    expect(last!.isAfter(before), isTrue);
    await store.clearAll();
    expect((await store.historyOf('memory.easy1')).lastPlayedAt, isNull);
  });

  test('sıralama satırları puanın yapıldığı tarihi taşır', () async {
    final backend = FakeBackend(uid: 'devA');
    final service = serviceFor(backend);
    final outcome = await service.submitAndLoad(
      profileId: 'p1',
      nickname: 'Elif',
      score: scoreOf('bul_patlat', 300),
    );
    final rows = outcome.snapshot!.top;
    expect(rows, isNotEmpty);
    expect(rows.first.bestAt, isNotNull);
  });
}
