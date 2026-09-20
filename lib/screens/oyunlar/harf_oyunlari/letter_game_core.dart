import 'dart:math' as math;

import 'game_letters.dart';

/// "Sesi dinle, doğru harfi bul" oyunlarının ortak çekirdeği: dengeli hedef
/// torbası, puan/seri, istatistikler ve benzer harfli çeldirici seçimi.
/// Hareket/çizim oyuna özeldir (balon, araba…); kurallar burada tek yerdedir.
class LetterGameCore {
  LetterGameCore({required List<GameLetter> letters, math.Random? random})
    : assert(letters.length >= 6),
      letters = List.unmodifiable(letters),
      random = random ?? math.Random();

  final List<GameLetter> letters;
  final math.Random random;

  /// Birbirine benzeyen harf aileleri (ayırt etme becerisi için).
  static const List<String> similarFamilies = [
    'بتث',
    'جحخ',
    'دذ',
    'رز',
    'سش',
    'صض',
    'طظ',
    'عغ',
  ];

  /// [char]'ın benzer harf ailesi (yoksa null).
  static String? similarFamilyOf(String char) {
    for (final f in similarFamilies) {
      if (f.contains(char)) return f;
    }
    return null;
  }

  /// Hedefin ailesinden (varsa) bir çeldirici seçilme olasılığı; geri kalanı
  /// kolay (farklı görünümlü) harfler.
  static const double similarChance = 0.4;

  // ---- durum ----------------------------------------------------------------

  GameLetter? target;
  int score = 0;
  int correct = 0;

  /// İlk denemede (yanlış dokunmadan) bulunan doğrular.
  int firstTryCorrect = 0;
  int wrongTaps = 0;
  int missedTargets = 0;

  /// Art arda ilk denemede doğru sayısı.
  int streak = 0;
  bool targetHadWrong = false;

  final List<GameLetter> _bag = [];
  GameLetter? _lastTarget;

  void reset() {
    score = correct = firstTryCorrect = wrongTaps = missedTargets = streak = 0;
    targetHadWrong = false;
    target = null;
    _lastTarget = null;
    _bag.clear();
  }

  // ---- hedef ----------------------------------------------------------------

  GameLetter _fromBag() {
    if (_bag.isEmpty) {
      _bag.addAll(letters);
      _bag.shuffle(random);
      // Yeni torbanın ilk harfi son hedefle aynı olmasın.
      if (_lastTarget != null && _bag.first.char == _lastTarget!.char) {
        final swap = 1 + random.nextInt(_bag.length - 1);
        final tmp = _bag[0];
        _bag[0] = _bag[swap];
        _bag[swap] = tmp;
      }
    }
    return _bag.removeAt(0);
  }

  /// Dengeli hedef: 28 harf karıştırılıp sırayla kullanılır, biter bitmez
  /// yeniden karıştırılır. [isFit] false dönen harf (örn. ekranda ama çok yakında
  /// çıkacak) torbanın sonuna atılır, sıradaki alınır; yine sorulur.
  GameLetter nextTarget({bool Function(GameLetter letter)? isFit}) {
    var next = _fromBag();
    for (var i = 0; i < _bag.length; i++) {
      if (isFit == null || isFit(next)) break;
      _bag.add(next);
      next = _bag.removeAt(0);
    }
    target = next;
    _lastTarget = next;
    targetHadWrong = false;
    return next;
  }

  // ---- puan -----------------------------------------------------------------

  /// Doğru: +10; ilk denemede +5; art arda her 3. ilk-deneme doğruda +5 (sade
  /// seri bonusu). Yanlış dokunma 0 puandır, puan hiçbir zaman negatif olmaz.
  int registerCorrect() {
    final firstTry = !targetHadWrong;
    var points = 10;
    if (firstTry) {
      points += 5;
      firstTryCorrect++;
      streak++;
      if (streak % 3 == 0) points += 5;
    } else {
      streak = 0;
    }
    score += points;
    correct++;
    return points;
  }

  void registerWrong() {
    wrongTaps++;
    targetHadWrong = true;
    streak = 0; // seri bozulur; puan düşmez
  }

  void registerMissed() {
    missedTargets++;
    streak = 0;
  }

  /// Doğru / (doğru + yanlış dokunma + kaçırılan hedef), yüzde.
  int get accuracyPercent {
    final total = correct + wrongTaps + missedTargets;
    return total == 0 ? 0 : (correct * 100 / total).round();
  }

  /// 1–3 yıldız: hiç yıldız verilmez diye bir durum yok, "başarısız" görünmez.
  int get stars {
    if (correct >= 15 && accuracyPercent >= 80) return 3;
    if (correct >= 8 && accuracyPercent >= 60) return 2;
    return 1;
  }

  // ---- çeldirici --------------------------------------------------------------

  /// Ekranda olmayan bir çeldirici harf: zaman zaman hedefin benzer ailesinden,
  /// çoğunlukla farklı görünümlüler (her tur aşırı zor olmasın).
  GameLetter pickDistractor(Set<String> onScreen) {
    final t = target;
    final taken = {...onScreen};
    if (t != null) taken.add(t.char);

    if (t != null && random.nextDouble() < similarChance) {
      for (final family in similarFamilies.where((f) => f.contains(t.char))) {
        final similar =
            letters
                .where(
                  (l) => family.contains(l.char) && !taken.contains(l.char),
                )
                .toList();
        if (similar.isNotEmpty) return similar[random.nextInt(similar.length)];
      }
    }
    final rest = letters.where((l) => !taken.contains(l.char)).toList();
    return rest.isEmpty
        ? letters[random.nextInt(letters.length)]
        : rest[random.nextInt(rest.length)];
  }
}
