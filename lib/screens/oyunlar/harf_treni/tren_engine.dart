import 'dart:math' as math;

import '../harf_dedektifi/dedektif_data.dart';
import '../harf_dedektifi/dedektif_engine.dart' show DetectiveRoundFactory;

/// Oyun anahtarlarının öneki; her seviye ayrı oyundur (`harf_treni.l1` …),
/// "Sonuçlarım"da farklı seviyelerin puanları karışmaz.
const String kHarfTreniGameKey = 'harf_treni';

/// Bir oturum 5 trendir; süre ve can yok.
const int kTrainCount = 5;

/// Vagona yerleşen her yeni doğru kart. Hız bonusu ve yanlış cezası yok.
const int kTrainPointsPerCard = 10;

enum TrainLevel {
  l1(1, 'Aynı Harfi Bul', 'Aynı harfin aynı görünüşünü bul', 3, 6),
  l2(2, 'Farklı Şekilleri Tanı', 'Harfin başta, ortada, sonda biçimleri', 4, 8),
  l3(3, 'Benzer Harfleri Ayır', 'Noktalarına bakarak doğru harfi seç', 4, 8),
  l4(4, 'Farklı Yazıları Tanı', 'Aynı harf farklı yazı tiplerinde', 4, 8);

  const TrainLevel(
    this.number,
    this.title,
    this.subtitle,
    this.wagons,
    this.cards,
  );

  final int number;
  final String title;
  final String subtitle;

  /// Boş vagon sayısı = doğru kart sayısı.
  final int wagons;
  final int cards;

  String get gameKey => '$kHarfTreniGameKey.l$number';
}

/// Kart: her kartın ayrı kimliği vardır; doğruluk harf kimliğiyle ölçülür
/// (görünen metin ya da yazı tipi adıyla değil).
class TrainCard {
  const TrainCard({
    required this.id,
    required this.letterId,
    required this.form,
    required this.font,
  });

  final int id;
  final int letterId;
  final LetterForm form;

  /// Yazı tipi ailesi (Seviye 4'te değişir, diğerlerinde Hasenat).
  final String font;

  String get text => letterById(letterId).display(form);
}

class TrainRound {
  TrainRound({
    required this.level,
    required this.targetId,
    required this.cards,
  });

  final TrainLevel level;
  final int targetId;
  final List<TrainCard> cards;

  int get wagons => level.wagons;

  bool isCorrect(int cardId) =>
      cards.any((c) => c.id == cardId && c.letterId == targetId);

  TrainCard card(int id) => cards.firstWhere((c) => c.id == id);

  List<int> get correctIds => [
    for (final c in cards)
      if (c.letterId == targetId) c.id,
  ];
}

class TrainRoundFactory {
  TrainRoundFactory(this.random, {required this.fonts, required this.baseFont});

  final math.Random random;

  /// Seviye 4'te kullanılacak, YÜKLENDİĞİ doğrulanmış yazı tipleri.
  final List<String> fonts;
  final String baseFont;

  /// Seviyeye göre hedef olabilecek harfler.
  static List<int> candidatesFor(TrainLevel level) => switch (level) {
    TrainLevel.l3 => [for (final g in kSimilarGroups) ...g],
    _ => [for (final l in kDetectiveLetters) l.id],
  };

  /// 5 hedef: art arda aynı harf yok; zorlanılanlar ölçülü sıklıkta (ağırlık
  /// 1 + min(zorluk, 3)), diğerleri de gelir. Harf Dedektifi ile aynı kural.
  List<int> pickTargets(
    TrainLevel level, {
    Map<int, int> weights = const {},
    List<int> focus = const [],
  }) => DetectiveRoundFactory(random).pickTargets(
    candidatesFor(level),
    weights: weights,
    focus: focus,
    count: kTrainCount,
  );

  TrainRound build(TrainLevel level, int targetId) {
    final target = letterById(targetId);
    final specs = <(int, LetterForm, String)>[];
    switch (level) {
      case TrainLevel.l1:
        // Aynı yazı tipi, tek başına; çeldiriciler kolay ayrılan harfler.
        for (var i = 0; i < level.wagons; i++) {
          specs.add((targetId, LetterForm.isolated, baseFont));
        }
        for (final id in _easyDistractors(
          targetId,
          level.cards - level.wagons,
        )) {
          specs.add((id, LetterForm.isolated, baseFont));
        }
      case TrainLevel.l2:
        // Harfin gerçek biçimleri; bağlanmayanlarda iki biçim tekrar eder.
        final forms = _cycledForms(target, level.wagons);
        for (final f in forms) {
          specs.add((targetId, f, baseFont));
        }
        for (final id in _easyDistractors(
          targetId,
          level.cards - level.wagons,
        )) {
          final l = letterById(id);
          specs.add((id, l.forms[random.nextInt(l.forms.length)], baseFont));
        }
      case TrainLevel.l3:
        // Aynı gruptaki harfler, doğru kartlarla AYNI biçimlerde.
        final group = similarGroupOf(targetId) ?? [targetId];
        final others = [
          for (final id in group)
            if (id != targetId) id,
        ];
        final forms = _cycledForms(target, level.wagons);
        for (final f in forms) {
          specs.add((targetId, f, baseFont));
        }
        for (var i = 0; i < level.cards - level.wagons; i++) {
          specs.add((
            others[i % others.length],
            forms[i % forms.length],
            baseFont,
          ));
        }
      case TrainLevel.l4:
        // Yalnızca yazı tipi değişir: tek başına biçim, kolay çeldiriciler.
        final pool = fonts.isEmpty ? [baseFont] : fonts;
        final used = <String>[
          for (var i = 0; i < level.wagons; i++) pool[i % pool.length],
        ]..shuffle(random);
        for (final f in used) {
          specs.add((targetId, LetterForm.isolated, f));
        }
        for (final id in _easyDistractors(
          targetId,
          level.cards - level.wagons,
        )) {
          specs.add((
            id,
            LetterForm.isolated,
            pool[random.nextInt(pool.length)],
          ));
        }
    }
    specs.shuffle(random);
    return TrainRound(
      level: level,
      targetId: targetId,
      cards: [
        for (var i = 0; i < specs.length; i++)
          TrainCard(
            id: i,
            letterId: specs[i].$1,
            form: specs[i].$2,
            font: specs[i].$3,
          ),
      ],
    );
  }

  /// Harfin geçerli biçimleri sırayla [count] kadar (yapay biçim yok).
  List<LetterForm> _cycledForms(DetectiveLetter letter, int count) {
    final forms = List.of(letter.forms)..shuffle(random);
    return [for (var i = 0; i < count; i++) forms[i % forms.length]];
  }

  /// Hedefe benzemeyen, birbirinden farklı harfler.
  List<int> _easyDistractors(int targetId, int count) {
    final pool = [
      for (final l in kDetectiveLetters)
        if (!looksAlike(l.id, targetId)) l.id,
    ]..shuffle(random);
    return pool.take(count).toList();
  }
}

// ---------------------------------------------------------------------------

enum TrainTap { placed, alreadyPlaced, wrong, repeatWrong, ignored }

enum TrainFind { firstTry, afterRetry, withHint }

/// Bir trenin durumu; her tur yeni nesnedir.
class TrainRoundState {
  TrainRoundState(this.round);

  final TrainRound round;

  /// Vagonlara sırayla yerleşen kartlar (kart kimliği).
  final List<int> placed = [];
  final Set<int> wrong = {};
  int? hintedId;
  bool hintUsed = false;
  int _wrongSincePlace = 0;

  int get wagons => round.wagons;
  bool get complete => placed.length >= wagons;
  bool get hintSuggested => wrong.length >= 2 && !complete;
  bool get struggled => wrong.isNotEmpty || hintUsed;
}

class TrainSession {
  TrainSession({
    required this.level,
    required this.targets,
    required TrainRoundFactory factory,
  }) : _factory = factory {
    _current = TrainRoundState(_factory.build(level, targets.first));
  }

  final TrainLevel level;
  final List<int> targets;
  final TrainRoundFactory _factory;

  late TrainRoundState _current;
  int _index = 0;
  int _points = 0;
  int _trainsDone = 0;
  final Map<TrainFind, int> _finds = {for (final k in TrainFind.values) k: 0};
  final Map<int, int> _weak = {};
  final Set<int> _struggled = {};
  final Set<int> _clean = {};
  final Set<int> _closed = {};

  TrainRoundState get current => _current;
  int get index => _index;
  int get count => targets.length;
  bool get isLast => _index + 1 >= targets.length;
  int get points => _points;
  int get trainsDone => _trainsDone;
  int countOf(TrainFind k) => _finds[k]!;
  int get placedCount => _finds.values.fold(0, (a, b) => a + b);

  /// Dokunma. Aynı karta ikinci dokunuş (çift tıklama) hiçbir şey yapmaz;
  /// dolu trende dokunma yok sayılır.
  TrainTap tap(int cardId) {
    final s = _current;
    if (s.complete || !s.round.cards.any((c) => c.id == cardId)) {
      return TrainTap.ignored;
    }
    if (s.round.isCorrect(cardId)) {
      if (s.placed.contains(cardId)) return TrainTap.alreadyPlaced;
      s.placed.add(cardId);
      final kind =
          s.hintedId == cardId
              ? TrainFind.withHint
              : (s._wrongSincePlace > 0
                  ? TrainFind.afterRetry
                  : TrainFind.firstTry);
      if (s.hintedId == cardId) s.hintedId = null;
      s._wrongSincePlace = 0;
      _finds[kind] = _finds[kind]! + 1;
      _points += kTrainPointsPerCard;
      if (kind != TrainFind.firstTry) _addWeak(s.round.targetId);
      if (s.complete) _trainsDone++;
      return TrainTap.placed;
    }
    if (!s.wrong.add(cardId)) return TrainTap.repeatWrong;
    s._wrongSincePlace++;
    _addWeak(s.round.targetId);
    return TrainTap.wrong;
  }

  /// Yerleşmemiş bir doğru kartı gösterir (zaten gösteriliyorsa onu).
  int? hint(math.Random random) {
    final s = _current;
    if (s.complete) return null;
    if (s.hintedId != null) return s.hintedId;
    final left = [
      for (final id in s.round.correctIds)
        if (!s.placed.contains(id)) id,
    ];
    s.hintedId = left[random.nextInt(left.length)];
    s.hintUsed = true;
    return s.hintedId;
  }

  bool next() {
    if (!_current.complete || isLast) return false;
    _close();
    _index++;
    _current = TrainRoundState(_factory.build(level, targets[_index]));
    return true;
  }

  void finish() => _close();

  void _close() {
    if (!_closed.add(_index)) return;
    final t = _current.round.targetId;
    (_current.struggled ? _struggled : _clean).add(t);
  }

  void _addWeak(int id) => _weak[id] = (_weak[id] ?? 0) + 1;

  /// Tekrar çalışılabilecek en çok 3 harf.
  List<int> weakLetters([int max = 3]) {
    final ids =
        _weak.keys.toList()..sort((a, b) {
          final c = _weak[b]!.compareTo(_weak[a]!);
          return c != 0 ? c : a.compareTo(b);
        });
    return ids.take(max).toList();
  }

  Set<int> get struggledTargets => Set.of(_struggled);
  Set<int> get cleanTargets => _clean.difference(_struggled);
}
