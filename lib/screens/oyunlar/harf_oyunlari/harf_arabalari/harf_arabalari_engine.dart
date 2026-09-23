import 'dart:math' as math;

import '../game_letters.dart';
import '../letter_game_core.dart';

/// Harf Arabaları oyununun saf oyun mantığı (Flutter widget'ı içermez).
///
/// Arabalar ekranın SOLUNDAN girip SAĞINDAN çıkar; 3–5 yatay şeritte gider.
/// Hedef torbası, puan, istatistik ve çeldirici seçimi Bul & Patlat ile ORTAK
/// çekirdekten ([LetterGameCore]) gelir; buradaki yalnızca şerit/araba hareketi,
/// takip mesafesi ve kaçırılan hedefin yönetimidir.

enum HaStatus { ready, running, over }

class HaCar {
  HaCar({
    required this.id,
    required this.letter,
    required this.lane,
    required this.x,
    required this.height,
    required this.speedFactor,
    required this.colorIndex,
  });

  final int id;
  final GameLetter letter;
  final int lane;

  /// Sol kenar (px). Soldan girerken negatiftir.
  double x;

  /// Araba yüksekliği; genişlik [width].
  final double height;
  final double speedFactor;
  final int colorIndex;

  /// Yanlış dokunuşta 1'den 0'a azalan titreme.
  double shake = 0;

  /// Doğru yakalandı: kısa hızlanıp solarak çıkar.
  bool caught = false;
  double caughtAge = 0;
  bool exited = false;

  double get width => height * 1.85;
  bool get alive => !exited;
  bool get catchable => !caught && !exited;

  static const double caughtLifetime = 0.8;
}

/// "+15" ve ♪ efekti (ekran çizer).
class HaFloat {
  HaFloat({required this.cx, required this.cy, required this.points});

  final double cx;
  final double cy;
  final int points;
  double age = 0;

  static const double lifetime = 0.9;
  bool get done => age >= lifetime;
}

sealed class HaEvent {
  const HaEvent();
}

/// Yeni hedef (ya da kaçırılan hedefin tekrarı): ekran harfin sesini çalmalı.
class HaTargetChanged extends HaEvent {
  const HaTargetChanged(this.letter, {required this.afterCatch});
  final GameLetter letter;

  /// Doğru araba az önce yakalandı: efekt sesi bitsin diye ses biraz geciktirilir.
  final bool afterCatch;
}

class HaCaught extends HaEvent {
  const HaCaught(this.points, this.firstTry);
  final int points;
  final bool firstTry;
}

class HaWrongTap extends HaEvent {
  const HaWrongTap();
}

class HaTargetMissed extends HaEvent {
  const HaTargetMissed();
}

class HaGameOver extends HaEvent {
  const HaGameOver();
}

class HarfArabalariEngine {
  HarfArabalariEngine({
    required List<GameLetter> letters,
    math.Random? random,
    this.duration = 120,
  }) : core = LetterGameCore(letters: letters, random: random),
       _random = random ?? math.Random();

  final LetterGameCore core;
  final double duration; // sn
  final math.Random _random;

  /// [char]'ın benzer harf ailesi (ortak çekirdekten).
  static String? similarFamilyOf(String char) =>
      LetterGameCore.similarFamilyOf(char);

  // ---- ayarlar ------------------------------------------------------------

  /// Seviyeler: 1 yavaş, 2 biraz hızlı (ilk sürümün hızı), 3 hızlı. Hız, oyun
  /// alanı GENİŞLİĞİNİN saniyede kesridir ve oyun boyunca çok hafif artar;
  /// geçiş süresi alan genişliğinden bağımsız olduğu için geniş ekranda araba
  /// uzun süre sürünmez. Hızlı seviye de refleks oyununa dönmesin diye ılımlı.
  static const Map<int, GameLevelSettings> levels = {
    1: GameLevelSettings(
      speedStart: 0.08,
      speedEnd: 0.11,
      spawnMin: 1.3,
      spawnMax: 2.3,
    ),
    2: GameLevelSettings(
      speedStart: 0.105,
      speedEnd: 0.15,
      spawnMin: 1.0,
      spawnMax: 1.9,
    ),
    3: GameLevelSettings(
      speedStart: 0.14,
      speedEnd: 0.19,
      spawnMin: 0.9,
      spawnMax: 1.7,
    ),
  };
  static const int minLevel = 1;
  static const int maxLevel = 3;

  /// Seçili seviye (1–3). [start] ile değiştirilir.
  int level = 2;

  GameLevelSettings get _settings => levels[level]!;
  double get speedStart => _settings.speedStart;
  double get speedEnd => _settings.speedEnd;
  double get spawnIntervalMin => _settings.spawnMin;
  double get spawnIntervalMax => _settings.spawnMax;

  /// Bir hedefin arabası kaçırılırsa aynı harfle yeni araba en fazla bu kadar
  /// kez gönderilir; sonra yeni hedef seçilir (aynı harfe takılıp kalınmaz).
  static const int maxRespawnsPerTarget = 1;

  // ---- alan ---------------------------------------------------------------

  double width = 0;
  double height = 0;
  int lanes = 3;
  double laneHeight = 0;
  double carHeight = 0;

  double get carWidth => carHeight * 1.85;

  void resize(double w, double h) {
    final oldW = width;
    final oldH = height;
    width = w;
    height = h;
    // Araba yüksekliği: telefonda ~86, tablette 130'a kadar; şeritten büyük olmaz.
    final base = math.min(w * 0.24, h * 0.19).clamp(66.0, 130.0).toDouble();
    lanes = (h / (base * 1.5)).floor().clamp(3, 5);
    laneHeight = h / lanes;
    carHeight = math.min(base, laneHeight * 0.8);
    // Oyun sürerken alan değişirse arabalar orantılı taşınır.
    if (oldW > 0 && oldH > 0 && (oldW != w || oldH != h)) {
      // Şerit sayısı değişmiş olabilir: en yakın şeride oturt.
      for (final c in cars) {
        c.x *= w / oldW;
      }
    }
  }

  /// Aynı anda ekranda bulunabilecek araba sayısı (3–6): şerit sayısına bağlı.
  int get maxAlive => (lanes + 1).clamp(3, 6);

  // ---- durum --------------------------------------------------------------

  HaStatus status = HaStatus.ready;
  double elapsed = 0;

  int get score => core.score;
  int get correct => core.correct;
  int get wrongTaps => core.wrongTaps;
  int get missedTargets => core.missedTargets;
  int get streak => core.streak;
  GameLetter? get target => core.target;

  /// Oyun alanına giren toplam harfli araba ("Geçen araba").
  int spawned = 0;

  final List<HaCar> cars = [];
  final List<HaFloat> floats = [];
  final List<HaEvent> _events = [];

  int _nextId = 1;
  double _spawnIn = 0;
  int _respawns = 0;

  int get remainingSeconds => math.max(0, (duration - elapsed).ceil());
  double get speedFraction =>
      speedStart +
      (speedEnd - speedStart) * (elapsed / duration).clamp(0.0, 1.0);

  /// Piksel/sn cinsinden temel hız.
  double get _baseSpeed => width * speedFraction;

  int get accuracyPercent => core.accuracyPercent;
  int get stars => core.stars;

  List<HaEvent> takeEvents() {
    final out = List<HaEvent>.of(_events);
    _events.clear();
    return out;
  }

  // ---- akış ---------------------------------------------------------------

  void start({int? level}) {
    if (level != null) this.level = level.clamp(minLevel, maxLevel);
    status = HaStatus.running;
    elapsed = 0;
    spawned = 0;
    _respawns = 0;
    core.reset();
    cars.clear();
    floats.clear();
    _events.clear();
    _spawnIn = 0.4;
    _advanceTarget(afterCatch: false);
  }

  /// [dt] saniye ilerletir. Duraklatılmış oyunda çağrılmaz.
  void tick(double dt) {
    if (status != HaStatus.running || width <= 0 || height <= 0) return;
    elapsed += dt;

    _moveCars(dt);

    for (final f in floats) {
      f.age += dt;
    }
    floats.removeWhere((f) => f.done);

    // Sağdan çıkan arabalar. Yalnızca HEDEF harfin çıkması "kaçırılan hedef".
    var targetExited = false;
    for (final c in cars) {
      final gone =
          c.x > width + 4 || (c.caught && c.caughtAge >= HaCar.caughtLifetime);
      if (c.alive && gone) {
        c.exited = true;
        if (!c.caught && c.letter.char == target?.char) targetExited = true;
      }
    }
    cars.removeWhere((c) => !c.alive);
    if (targetExited) _onTargetMissed();

    if (elapsed >= duration) {
      status = HaStatus.over;
      _events.add(const HaGameOver());
      return;
    }

    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      if (cars.where((c) => !c.caught).length < maxAlive) {
        _spawn(core.pickDistractor({for (final c in cars) c.letter.char}));
      }
      _spawnIn =
          spawnIntervalMin +
          _random.nextDouble() * (spawnIntervalMax - spawnIntervalMin);
    }
    _ensureTargetOnScreen();
  }

  void _moveCars(double dt) {
    final v = _baseSpeed;
    // Her şeritte önden arkaya: arkadaki araba öndekine yaklaşırsa yavaşlar,
    // hiçbir zaman üstüne binmez (takip mesafesi).
    for (var lane = 0; lane < lanes; lane++) {
      final inLane =
          cars.where((c) => c.lane == lane && !c.caught).toList()
            ..sort((a, b) => b.x.compareTo(a.x));
      HaCar? leader;
      for (final c in inLane) {
        var nx = c.x + v * c.speedFactor * dt;
        if (leader != null) {
          nx = math.min(nx, leader.x - c.width - carWidth * 0.12);
        }
        c.x = nx;
        if (c.shake > 0) c.shake = math.max(0, c.shake - dt * 2.5);
        leader = c;
      }
    }
    for (final c in cars.where((c) => c.caught)) {
      c.caughtAge += dt;
      c.x += v * 3.2 * dt; // yakalanan araba kısa süre hızlanıp çıkar
    }
  }

  /// Dokunulan araba. Doğruysa yakalanır; yanlışsa yerinde kalır (hafif titrer).
  void tap(int carId) {
    if (status != HaStatus.running) return;
    final index = cars.indexWhere((c) => c.id == carId && c.catchable);
    if (index < 0) return;
    final c = cars[index];

    if (c.letter.char == target?.char) {
      final firstTry = !core.targetHadWrong;
      final points = core.registerCorrect();
      c.caught = true;
      floats.add(
        HaFloat(
          cx: c.x + c.width / 2,
          cy: c.lane * laneHeight + laneHeight / 2,
          points: points,
        ),
      );
      _events.add(HaCaught(points, firstTry));
      _advanceTarget(afterCatch: true);
    } else {
      core.registerWrong();
      c.shake = 1;
      _events.add(const HaWrongTap());
    }
  }

  // ---- hedef ----------------------------------------------------------------

  /// Hedef harfin arabası (ekrandaysa) sağdan çıkmadan en az bu kadar saniye
  /// görünür kalmalı; aksi halde çocuğa bulma şansı kalmaz. Hızlı seviyede
  /// arabanın tüm geçişi kısa olduğu için pay, geçiş süresiyle orantılı küçülür
  /// (seviye 1–2'de hep 4 sn).
  double get minTargetSeconds {
    final crossing = 1 / (speedFraction * 1.06);
    return (crossing * 0.75).clamp(3.0, 4.0).toDouble();
  }

  double _secondsToExit(HaCar c) {
    final v = _baseSpeed * c.speedFactor;
    return v <= 0 ? double.infinity : (width - c.x) / v;
  }

  void _advanceTarget({required bool afterCatch}) {
    _respawns = 0;
    final next = core.nextTarget(
      isFit: (letter) {
        final onScreen = cars.where(
          (c) => c.catchable && c.letter.char == letter.char,
        );
        return onScreen.isEmpty ||
            onScreen.any((c) => _secondsToExit(c) >= minTargetSeconds);
      },
    );
    _events.add(HaTargetChanged(next, afterCatch: afterCatch));
    _ensureTargetOnScreen();
  }

  /// Hedefin arabası kaçtı: ilkinde aynı harfle yeni araba hemen gelir (çocuk
  /// aynı sesi tekrar duyar); yine kaçarsa yeni hedef seçilir.
  void _onTargetMissed() {
    core.registerMissed();
    _events.add(const HaTargetMissed());
    if (_respawns < maxRespawnsPerTarget) {
      _respawns++;
      final t = target!;
      _events.add(HaTargetChanged(t, afterCatch: false));
      _spawn(t, urgent: true);
    } else {
      _advanceTarget(afterCatch: false);
    }
  }

  /// Hedef harfin ekranda (veya hemen soldan girerken) mutlaka bir arabası olur.
  void _ensureTargetOnScreen() {
    final t = target;
    if (t == null || width <= 0 || height <= 0) return;
    final present = cars.any((c) => c.catchable && c.letter.char == t.char);
    if (!present) _spawn(t, urgent: true);
  }

  // ---- üretim -------------------------------------------------------------

  /// Soldan giren araba. Şeritte önceki arabanın arkası yeterince açılmadan
  /// yeni araba girmez (üst üste binme yok). [urgent] (hedef): en boş şerit.
  void _spawn(GameLetter letter, {bool urgent = false}) {
    // Her şeridin en arkadaki (sol uçtaki) arabasının sol kenarı.
    final clearance = <int, double>{};
    for (var lane = 0; lane < lanes; lane++) {
      final inLane = cars.where((c) => c.lane == lane && !c.caught);
      clearance[lane] =
          inLane.isEmpty
              ? double.infinity
              : inLane.map((c) => c.x).reduce(math.min);
    }
    final minClear = carWidth * 0.35;
    var open = [
      for (final e in clearance.entries)
        if (e.value >= minClear) e.key,
    ];
    if (open.isEmpty) {
      if (!urgent) return; // hedef dışı arabalar bekler
      // Hedef için en boş şeridi seç; takip mesafesi çakışmayı yine önler.
      final best = clearance.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      open = [best.key];
    }

    // Aynı şeride arka arkaya değil: mümkünse en boş şeritlerden rastgele.
    open.sort((a, b) => clearance[b]!.compareTo(clearance[a]!));
    final pool = urgent ? open.take(2).toList() : open;
    final lane = pool[_random.nextInt(pool.length)];

    cars.add(
      HaCar(
        id: _nextId++,
        letter: letter,
        lane: lane,
        x: -carWidth,
        height: carHeight,
        speedFactor: 0.94 + _random.nextDouble() * 0.12,
        colorIndex: _random.nextInt(6),
      ),
    );
    spawned++;
  }
}
