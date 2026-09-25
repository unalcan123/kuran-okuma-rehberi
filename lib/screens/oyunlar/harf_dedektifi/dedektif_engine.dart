import 'dart:math' as math;

import 'dedektif_data.dart';

/// Oyun anahtarlarının öneki; her mod ayrı oyundur (`harf_dedektifi.sekiller`
/// …), böylece "Sonuçlarım"da farklı modların puanları karışmaz.
const String kHarfDedektifiGameKey = 'harf_dedektifi';

/// Bir oturum 5 kısa turdur; süre sınırı yoktur.
const int kDetectiveRoundCount = 5;

/// Bulunan her yeni doğru örnek. Hız, seri ya da ilk deneme bonusu yok.
const int kDetectivePointsPerFind = 10;

enum DetectiveMode {
  shapes('sekiller', 'Şekilleri Tanı', 'Bir harfin bütün yazılışlarını bul'),
  similar('benzer', 'Benzer Harfler', 'Noktalarından doğru harfi ayırt et'),
  words('kelime', 'Kelime Dedektifi', 'Harfi gerçek kelimelerin içinde bul');

  const DetectiveMode(this.key, this.title, this.subtitle);

  final String key;
  final String title;
  final String subtitle;

  String get gameKey => '$kHarfDedektifiGameKey.$key';
}

// ---------------------------------------------------------------------------
// Turlar

/// Şekil kartı: harf kimliği + bağlantı biçimi. Doğruluk kimlikle ölçülür.
class ShapeCard {
  const ShapeCard(this.letterId, this.form);

  final int letterId;
  final LetterForm form;

  String get text => letterById(letterId).display(form);
}

sealed class DetectiveRound {
  const DetectiveRound(this.targetId);

  final int targetId;

  /// Dokunulabilecek bütün öğeler (kart 'c3', kelimedeki harf 'w1.2').
  Iterable<String> get itemIds;

  bool isCorrect(String itemId);

  /// Öğenin biçimi (şekil kartlarında); kelimede görünüm bağlama bağlıdır.
  LetterForm? formOf(String itemId) => null;

  /// Dokunulan öğenin harf kimliği (yanlışta "Bu Te harfi" demek için).
  int? letterIdOf(String itemId);

  List<String> get correctIds => [
    for (final id in itemIds)
      if (isCorrect(id)) id,
  ];
}

class CardRound extends DetectiveRound {
  CardRound(super.targetId, this.cards);

  final List<ShapeCard> cards;

  static String idOf(int index) => 'c$index';

  ShapeCard? cardOf(String itemId) {
    final index = int.tryParse(itemId.substring(1));
    if (!itemId.startsWith('c') || index == null) return null;
    if (index < 0 || index >= cards.length) return null;
    return cards[index];
  }

  @override
  Iterable<String> get itemIds => [
    for (var i = 0; i < cards.length; i++) idOf(i),
  ];

  @override
  bool isCorrect(String itemId) => cardOf(itemId)?.letterId == targetId;

  @override
  LetterForm? formOf(String itemId) => cardOf(itemId)?.form;

  @override
  int? letterIdOf(String itemId) => cardOf(itemId)?.letterId;
}

class WordRound extends DetectiveRound {
  WordRound(super.targetId, this.words);

  final List<DetectiveWord> words;

  static String idOf(int word, int letter) => 'w$word.$letter';

  WordLetter? letterAt(String itemId) {
    if (!itemId.startsWith('w')) return null;
    final parts = itemId.substring(1).split('.');
    if (parts.length != 2) return null;
    final w = int.tryParse(parts[0]);
    final l = int.tryParse(parts[1]);
    if (w == null || l == null || w < 0 || w >= words.length) return null;
    final letters = words[w].letters;
    if (l < 0 || l >= letters.length) return null;
    return letters[l];
  }

  @override
  Iterable<String> get itemIds => [
    for (var w = 0; w < words.length; w++)
      for (var l = 0; l < words[w].letters.length; l++) idOf(w, l),
  ];

  @override
  bool isCorrect(String itemId) => letterAt(itemId)?.letterId == targetId;

  @override
  int? letterIdOf(String itemId) => letterAt(itemId)?.letterId;
}

/// Oturumun turlarını üretir. [random] testte sabitlenir.
class DetectiveRoundFactory {
  DetectiveRoundFactory(this.random);

  final math.Random random;

  /// Moda göre hedef olabilecek harfler; seçilen grupta hiç yoksa `null`
  /// (ekran "tüm harflerle oynanır" der ve [fallbackCandidates] kullanılır).
  static List<int> candidatesFor(DetectiveMode mode, List<int> allowed) {
    final usable = switch (mode) {
      DetectiveMode.shapes => [for (final l in kDetectiveLetters) l.id],
      DetectiveMode.similar => [for (final g in kSimilarGroups) ...g],
      DetectiveMode.words => wordModeLetterIds(),
    };
    final picked = [
      for (final id in allowed)
        if (usable.contains(id)) id,
    ];
    return picked.isEmpty ? usable : picked;
  }

  /// Seçilen grupta bu mod için harf var mı? (yoksa ekranda not gösterilir)
  static bool choiceFits(DetectiveMode mode, List<int> allowed) {
    final usable = candidatesFor(mode, const []);
    return allowed.any(usable.contains);
  }

  /// 5 hedef. Zorlanılan harfler ([weights], 0–5) daha sık gelir ama
  /// diğerleri de gelmeye devam eder (ağırlık 1 + zorluk). [focus] verilirse
  /// ("Zorlandıklarımı Çalış") turların çoğu o harflerdir.
  List<int> pickTargets(
    List<int> candidates, {
    Map<int, int> weights = const {},
    List<int> focus = const [],
    int count = kDetectiveRoundCount,
  }) {
    final targets = <int>[];
    if (focus.isNotEmpty) {
      final focusRounds = math.min(count, math.max(3, focus.length));
      for (var i = 0; i < focusRounds; i++) {
        targets.add(focus[i % focus.length]);
      }
    }
    final unused = <int>{...candidates}..removeAll(targets);
    while (targets.length < count) {
      if (unused.isEmpty) unused.addAll(candidates);
      final pool = unused.toList();
      if (pool.length > 1 && targets.isNotEmpty) pool.remove(targets.last);
      final id = _weighted(pool, weights);
      targets.add(id);
      unused.remove(id);
    }
    if (focus.isNotEmpty) _spreadOut(targets);
    return targets;
  }

  int _weighted(List<int> pool, Map<int, int> weights) {
    final w = [for (final id in pool) 1 + (weights[id] ?? 0).clamp(0, 3)];
    var roll = random.nextInt(w.fold(0, (a, b) => a + b));
    for (var i = 0; i < pool.length; i++) {
      roll -= w[i];
      if (roll < 0) return pool[i];
    }
    return pool.last;
  }

  // Karıştırır, mümkünse aynı harf art arda gelmesin.
  void _spreadOut(List<int> targets) {
    for (var attempt = 0; attempt < 20; attempt++) {
      targets.shuffle(random);
      var ok = true;
      for (var i = 1; i < targets.length; i++) {
        if (targets[i] == targets[i - 1]) ok = false;
      }
      if (ok) return;
    }
  }

  DetectiveRound build(DetectiveMode mode, int targetId, int roundIndex) =>
      switch (mode) {
        DetectiveMode.shapes => shapesRound(targetId, roundIndex),
        DetectiveMode.similar => similarRound(targetId),
        DetectiveMode.words => wordsRound(targetId),
      };

  /// İlk iki tur 6 kart, sonra 8, son tur 9 kart.
  static int shapeCardCount(int roundIndex) =>
      roundIndex < 2 ? 6 : (roundIndex < 4 ? 8 : 9);

  CardRound shapesRound(int targetId, int roundIndex) {
    final target = letterById(targetId);
    final cards = [for (final form in target.forms) ShapeCard(targetId, form)];
    final total = shapeCardCount(roundIndex);
    // İlk turlarda çeldiriciler gözle kolay ayrılan harflerdir; sonra en çok
    // iki benzer harf karışır.
    final alikeAllowed = roundIndex < 2 ? 0 : 2;
    final others = [
      for (final l in kDetectiveLetters)
        if (l.id != targetId) l.id,
    ]..shuffle(random);
    final alike = others.where((id) => looksAlike(id, targetId)).toList();
    final distinct = others.where((id) => !looksAlike(id, targetId)).toList();
    final chosen = [...alike.take(alikeAllowed), ...distinct];
    final texts = {for (final c in cards) c.text};
    for (final id in chosen) {
      if (cards.length >= total) break;
      final letter = letterById(id);
      final form = letter.forms[random.nextInt(letter.forms.length)];
      final card = ShapeCard(id, form);
      if (texts.add(card.text)) cards.add(card);
    }
    cards.shuffle(random);
    return CardRound(targetId, cards);
  }

  /// Aynı gruptaki harfler, hedefle AYNI bağlantı biçimlerinde yan yana:
  /// yalnızca noktalar farklıdır.
  CardRound similarRound(int targetId) {
    final group = similarGroupOf(targetId) ?? [targetId];
    final target = letterById(targetId);
    final formCount = group.length >= 3 ? 2 : (target.joinsNext ? 3 : 2);
    final forms = (List.of(target.forms)..shuffle(random)).take(formCount);
    final cards = [
      for (final id in group)
        for (final form in forms) ShapeCard(id, form),
    ]..shuffle(random);
    return CardRound(targetId, cards);
  }

  /// Hedefin geçtiği 2–3 gerçek kelime (havuzdan; kelime üretilmez).
  WordRound wordsRound(int targetId) {
    final words = wordsContaining(targetId)..shuffle(random);
    return WordRound(targetId, words.take(3).toList());
  }
}

// ---------------------------------------------------------------------------
// Oturum

enum TapResult { found, alreadyFound, wrong, repeatWrong, ignored }

/// Doğru bir örneğin nasıl bulunduğu (öğrenme değerlendirmesi).
enum FindKind { firstTry, afterRetry, withHint }

/// Tekrar çalışılacak harf (ve varsa biçim).
class WeakSpot {
  const WeakSpot(this.letterId, this.form);

  final int letterId;
  final LetterForm? form;

  @override
  bool operator ==(Object other) =>
      other is WeakSpot && other.letterId == letterId && other.form == form;

  @override
  int get hashCode => Object.hash(letterId, form);
}

/// Bir turun durumu. Her tur yeni nesnedir; önceki turdan hiçbir şey taşımaz.
class RoundState {
  RoundState(this.round) : correctIds = round.correctIds.toSet();

  final DetectiveRound round;
  final Set<String> correctIds;
  final Set<String> found = {};

  /// Farklı yanlış öğeler: aynı yanlışa tekrar basmak sayılmaz.
  final Set<String> wrong = {};
  final Map<String, FindKind> kinds = {};
  String? hintedId;
  bool hintUsed = false;
  int _wrongSinceFind = 0;

  int get total => correctIds.length;
  bool get complete => found.length == total;

  /// Yanlış denemeler arttıkça ipucu düğmesi belirginleşir.
  bool get hintSuggested => wrong.length >= 2 && !complete;

  /// Tur zorlandı mı (bir yanlış ya da ipucu)? Kalıcı zorluk için.
  bool get struggled => wrong.isNotEmpty || hintUsed;
}

class DetectiveSession {
  DetectiveSession({
    required this.mode,
    required this.targets,
    required DetectiveRoundFactory factory,
  }) : _factory = factory {
    _current = RoundState(_factory.build(mode, targets.first, 0));
  }

  final DetectiveMode mode;
  final List<int> targets;
  final DetectiveRoundFactory _factory;

  late RoundState _current;
  int _index = 0;
  int _points = 0;
  final Map<FindKind, int> _kinds = {for (final k in FindKind.values) k: 0};
  final Map<WeakSpot, int> _weak = {};
  final Set<int> _struggled = {};
  final Set<int> _clean = {};

  RoundState get current => _current;
  int get roundIndex => _index;
  int get roundCount => targets.length;
  bool get isLastRound => _index + 1 >= targets.length;
  int get points => _points;
  int get foundCount => _kinds.values.fold(0, (a, b) => a + b);
  int countOf(FindKind kind) => _kinds[kind]!;

  /// Harfler ilk kez görülüyor mu (Şekilleri Tanı'da önce tanıtılır).
  bool isFirstAppearance(int roundIndex) =>
      !targets.take(roundIndex).contains(targets[roundIndex]);

  TapResult tap(String itemId) {
    final state = _current;
    if (state.complete || !state.round.itemIds.contains(itemId)) {
      return TapResult.ignored;
    }
    final target = state.round.targetId;
    if (state.correctIds.contains(itemId)) {
      if (!state.found.add(itemId)) return TapResult.alreadyFound;
      final kind =
          state.hintedId == itemId
              ? FindKind.withHint
              : (state._wrongSinceFind > 0
                  ? FindKind.afterRetry
                  : FindKind.firstTry);
      if (state.hintedId == itemId) state.hintedId = null;
      state._wrongSinceFind = 0;
      state.kinds[itemId] = kind;
      _kinds[kind] = _kinds[kind]! + 1;
      _points += kDetectivePointsPerFind;
      if (kind != FindKind.firstTry) {
        _addWeak(WeakSpot(target, state.round.formOf(itemId)));
      }
      return TapResult.found;
    }
    if (!state.wrong.add(itemId)) return TapResult.repeatWrong;
    state._wrongSinceFind++;
    // Benzer Harfler'de karıştırılan biçim de kaydedilir.
    final form =
        mode == DetectiveMode.similar ? state.round.formOf(itemId) : null;
    _addWeak(WeakSpot(target, form));
    return TapResult.wrong;
  }

  /// Bulunmamış bir doğru öğeyi gösterir; zaten gösteriliyorsa onu döndürür.
  String? hint(math.Random random) {
    final state = _current;
    if (state.complete) return null;
    if (state.hintedId != null) return state.hintedId;
    final left = state.correctIds.difference(state.found).toList()..sort();
    final id = left[random.nextInt(left.length)];
    state.hintedId = id;
    state.hintUsed = true;
    return id;
  }

  /// Bir sonraki tura geçer. Son turdaysa `false`.
  bool next() {
    if (!_current.complete || isLastRound) return false;
    _closeRound();
    _index++;
    _current = RoundState(_factory.build(mode, targets[_index], _index));
    return true;
  }

  /// Son tur bitince çağrılır (kalıcı zorluk bilgisi için).
  void finish() => _closeRound();

  final Set<int> _closedRounds = {};
  void _closeRound() {
    if (!_closedRounds.add(_index)) return;
    final target = _current.round.targetId;
    if (_current.struggled) {
      _struggled.add(target);
    } else {
      _clean.add(target);
    }
  }

  void _addWeak(WeakSpot spot) => _weak[spot] = (_weak[spot] ?? 0) + 1;

  /// En çok zorlanılan en fazla 3 harf/biçim.
  List<WeakSpot> weakSpots([int max = 3]) {
    final entries =
        _weak.entries.toList()..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          return byCount != 0
              ? byCount
              : a.key.letterId.compareTo(b.key.letterId);
        });
    final spots = <WeakSpot>[];
    for (final e in entries) {
      if (spots.length >= max) break;
      spots.add(e.key);
    }
    return spots;
  }

  /// Zorlanılan harfler (tekrar çalışma turu için, en fazla 3).
  List<int> weakLetterIds() {
    final ids = <int>[];
    for (final spot in weakSpots(10)) {
      if (!ids.contains(spot.letterId)) ids.add(spot.letterId);
      if (ids.length == 3) break;
    }
    return ids;
  }

  /// Oturumda zorlanılan / rahat bulunan hedefler (kalıcı ağırlık için).
  Set<int> get struggledTargets => Set.of(_struggled);
  Set<int> get cleanTargets => _clean.difference(_struggled);
}
