import 'dart:math' as math;

import '../game_letters.dart';
import '../letter_game_core.dart';

/// Bul & Patlat oyununun saf oyun mantığı (Flutter widget'ı içermez): hedef
/// harf seçimi, balon üretimi, hareket, kaçma, puan, süre. Ekran yalnızca
/// [tick] ile zaman verir, [tap] ile dokunuşları iletir ve [takeEvents] ile
/// sonuçları (ses, animasyon) okur. Bu yüzden deterministik olarak test edilir.

/// Ortak harf modeli (bkz. oyunlar/ortak/game_letters.dart).
typedef BpLetter = GameLetter;

enum BpStatus { ready, running, over }

enum BpEndReason { time, missed }

class BpBalloon {
  BpBalloon({
    required this.id,
    required this.letter,
    required this.x,
    required this.y,
    required this.size,
    required this.speedFactor,
    required this.swayPhase,
    required this.colorIndex,
  });

  final int id;
  final BpLetter letter;

  /// Sol kenar (px, oyun alanına göre) ve üst kenar (px, 0 = tavan).
  double x;
  double y;

  /// Balon gövdesinin genişliği; toplam yükseklik için [boxHeight].
  final double size;
  final double speedFactor;
  final double swayPhase;
  final int colorIndex;

  /// Yanlış dokunuşta 1'den 0'a azalan titreme.
  double shake = 0;
  bool popped = false;
  bool escaped = false;

  double get bodyHeight => size * 1.18;
  double get boxHeight => bodyHeight + size * 0.34; // ip kısa tutulur
  bool get alive => !popped && !escaped;

  /// Hafif yanal salınım (px).
  double swayOffset(double time) =>
      math.sin(time * 1.4 + swayPhase) * size * 0.05;
}

/// Patlayan balonun parçacık efekti (ekran çizer).
class BpPop {
  BpPop({
    required this.cx,
    required this.cy,
    required this.colorIndex,
    required this.seed,
  });

  final double cx;
  final double cy;
  final int colorIndex;
  final int seed;
  double age = 0;

  static const double lifetime = 0.55;
  bool get done => age >= lifetime;
}

sealed class BpEvent {
  const BpEvent();
}

/// Yeni hedef seçildi: ekran harfin sesini çalmalı.
class BpTargetChanged extends BpEvent {
  const BpTargetChanged(this.letter, {required this.afterPop});
  final BpLetter letter;

  /// Doğru balon az önce patladı: pop sesi bitsin diye ses biraz geciktirilir.
  final bool afterPop;
}

class BpPopped extends BpEvent {
  const BpPopped(this.points, this.firstTry);
  final int points;
  final bool firstTry;
}

class BpWrongTap extends BpEvent {
  const BpWrongTap();
}

class BpTargetMissed extends BpEvent {
  const BpTargetMissed();
}

class BpGameOver extends BpEvent {
  const BpGameOver(this.reason);
  final BpEndReason reason;
}

/// Seviye ayarı (ortak: [GameLevelSettings]).
typedef BpLevelSettings = GameLevelSettings;

class BulPatlatEngine {
  BulPatlatEngine({
    required List<BpLetter> letters,
    math.Random? random,
    double duration = 120,
    int maxMissed = 5,
  }) : this._(
         LetterGameCore(letters: letters, random: random),
         duration,
         maxMissed,
       );

  BulPatlatEngine._(this.core, this.duration, this.maxMissed)
    : letters = core.letters,
      _random = core.random;

  /// Ortak kurallar: hedef torbası, puan/seri, istatistik, çeldirici seçimi.
  final LetterGameCore core;
  final List<BpLetter> letters;
  final double duration; // sn
  final int maxMissed;
  final math.Random _random;

  // ---- ayarlar ------------------------------------------------------------

  /// Birbirine benzeyen harf aileleri (ayırt etme becerisi için).
  static const List<String> similarFamilies = LetterGameCore.similarFamilies;

  /// Benzer harf balonunun (varsa) seçilme olasılığı; geri kalanı kolay.
  static const double similarChance = LetterGameCore.similarChance;

  /// Seviyeler: 1 yavaş, 2 biraz hızlı, 3 hızlı. Hız, oyun alanı yüksekliğinin
  /// saniyede kesridir ve oyun boyunca `speedStart` → `speedEnd` arasında çok
  /// hafif artar; balon üretim aralığı da seviyeyle sıklaşır. Yine de refleks
  /// oyununa dönmemesi için ılımlı tutulur.
  static const Map<int, BpLevelSettings> levels = {
    1: BpLevelSettings(
      speedStart: 0.09,
      speedEnd: 0.12,
      spawnMin: 1.3,
      spawnMax: 2.3,
    ),
    2: BpLevelSettings(
      speedStart: 0.12,
      speedEnd: 0.17,
      spawnMin: 1.2,
      spawnMax: 2.2,
    ),
    3: BpLevelSettings(
      speedStart: 0.17,
      speedEnd: 0.23,
      spawnMin: 1.0,
      spawnMax: 1.9,
    ),
  };
  static const int minLevel = 1;
  static const int maxLevel = 3;

  /// Seçili seviye (1–3). [start] ile değiştirilir.
  int level = 2;

  BpLevelSettings get _settings => levels[level]!;
  double get speedStart => _settings.speedStart;
  double get speedEnd => _settings.speedEnd;
  double get spawnIntervalMin => _settings.spawnMin;
  double get spawnIntervalMax => _settings.spawnMax;

  // ---- alan ---------------------------------------------------------------

  double width = 0;
  double height = 0;

  void resize(double w, double h) {
    // Oyun sürerken alan değişirse (döndürme/pencere) balonlar orantılı taşınır.
    if (width > 0 && height > 0 && (w != width || h != height)) {
      final fx = w / width;
      final fy = h / height;
      for (final b in balloons) {
        b.x = (b.x * fx).clamp(0.0, math.max(0.0, w - b.size)).toDouble();
        b.y *= fy;
      }
    }
    width = w;
    height = h;
  }

  /// Balon gövde genişliği: telefonda ~86, tablette 170'e kadar (dokunma alanı
  /// en az ~78 px). Alçak/geniş ekranda yüksekliğe de bakılır.
  double get baseSize =>
      math.min(width * 0.24, height * 0.2).clamp(78.0, 170.0).toDouble();

  /// Aynı anda ekranda bulunabilecek balon sayısı (4–7): alan büyüdükçe artar.
  int get maxAlive {
    final s = baseSize;
    if (width <= 0 || height <= 0) return 4;
    return (width * height / (s * s * 6)).floor().clamp(4, 7);
  }

  // ---- durum --------------------------------------------------------------

  BpStatus status = BpStatus.ready;
  BpEndReason? endReason;
  double elapsed = 0;
  double time = 0; // sinüs salınımı için sürekli zaman

  int get score => core.score;
  int get correct => core.correct;
  int get wrongTaps => core.wrongTaps;
  int get missedTargets => core.missedTargets;
  int get streak => core.streak;
  int spawned = 0;

  BpLetter? get target => core.target;
  final List<BpBalloon> balloons = [];
  final List<BpPop> pops = [];
  final List<BpEvent> _events = [];

  int _nextId = 1;
  double _spawnIn = 0;

  int get remainingSeconds => math.max(0, (duration - elapsed).ceil());
  double get speedFraction =>
      speedStart +
      (speedEnd - speedStart) * (elapsed / duration).clamp(0.0, 1.0);

  /// Yüzde olarak doğruluk ve yıldız: ortak çekirdekte.
  int get accuracyPercent => core.accuracyPercent;
  int get stars => core.stars;

  List<BpEvent> takeEvents() {
    final out = List<BpEvent>.of(_events);
    _events.clear();
    return out;
  }

  // ---- akış ---------------------------------------------------------------

  void start({int? level}) {
    if (level != null) this.level = level.clamp(minLevel, maxLevel);
    status = BpStatus.running;
    endReason = null;
    elapsed = 0;
    time = 0;
    core.reset();
    spawned = 0;
    balloons.clear();
    pops.clear();
    _events.clear();
    _spawnIn = 0.3;
    _advanceTarget(afterPop: false);
  }

  void _end(BpEndReason reason) {
    status = BpStatus.over;
    endReason = reason;
    _events.add(BpGameOver(reason));
  }

  /// [dt] saniye ilerletir. Duraklatılmış oyunda çağrılmaz.
  void tick(double dt) {
    if (status != BpStatus.running || width <= 0 || height <= 0) return;
    elapsed += dt;
    time += dt;

    // Hareket
    final v = height * speedFraction;
    for (final b in balloons) {
      if (!b.alive) continue;
      b.y -= v * b.speedFactor * dt;
      if (b.shake > 0) b.shake = math.max(0, b.shake - dt * 2.5);
    }

    // Patlama efektleri
    for (final p in pops) {
      p.age += dt;
    }
    pops.removeWhere((p) => p.done);

    // Tavana ulaşan (tamamen çıkan) balonlar. Yalnızca HEDEF harfin kaçması
    // sayılır ("kaçan"): hedef olmayan balonlara zaten dokunulmaz, hepsini
    // saymak oyunu saniyeler içinde bitirirdi.
    var targetEscaped = false;
    for (final b in balloons) {
      if (b.alive && b.y + b.boxHeight < 0) {
        b.escaped = true;
        if (b.letter.char == target?.char) targetEscaped = true;
      }
    }
    balloons.removeWhere((b) => !b.alive);
    if (targetEscaped) {
      core.registerMissed();
      _events.add(const BpTargetMissed());
      if (missedTargets >= maxMissed) {
        _end(BpEndReason.missed);
        return;
      }
      // Çocuk ekranda olmayan bir hedefi aramasın: yeni hedef seçilir.
      _advanceTarget(afterPop: false);
    }

    if (elapsed >= duration) {
      _end(BpEndReason.time);
      return;
    }

    // Üretim
    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      if (balloons.length < maxAlive) {
        _spawn(_pickDistractor());
      }
      _spawnIn =
          spawnIntervalMin +
          _random.nextDouble() * (spawnIntervalMax - spawnIntervalMin);
    }

    _ensureTargetOnScreen();
  }

  /// Dokunulan balon. Doğruysa patlar; yanlışsa yerinde kalır (hafif titrer).
  void tap(int balloonId) {
    if (status != BpStatus.running) return;
    final index = balloons.indexWhere((b) => b.id == balloonId && b.alive);
    if (index < 0) return;
    final b = balloons[index];

    if (b.letter.char == target?.char) {
      b.popped = true;
      balloons.removeAt(index);
      pops.add(
        BpPop(
          cx: b.x + b.size / 2,
          cy: b.y + b.bodyHeight / 2,
          colorIndex: b.colorIndex,
          seed: _random.nextInt(1 << 30),
        ),
      );

      final firstTry = !core.targetHadWrong;
      final points = core.registerCorrect();
      _events.add(BpPopped(points, firstTry));
      _advanceTarget(afterPop: true);
    } else {
      core.registerWrong();
      b.shake = 1;
      _events.add(const BpWrongTap());
    }
  }

  // ---- hedef seçimi -------------------------------------------------------

  /// Hedef harfin balonu (ekrandaysa) tavana ulaşmadan en az bu kadar saniye
  /// bulunmalı; aksi halde çocuğa bulma şansı kalmaz. Hızlı seviyede balonun
  /// tüm yolculuğu kısa olduğu için pay, geçiş süresiyle orantılı küçülür.
  double get minTargetSeconds {
    final v = height * speedFraction;
    if (v <= 0) return 4.5;
    final crossing = (height + baseSize * 1.5) / v;
    return (crossing * 0.6).clamp(3.0, 4.5).toDouble();
  }

  /// Balonun tavandan çıkmasına kalan tahmini süre (sn).
  double _secondsToEscape(BpBalloon b) {
    final v = height * speedFraction * b.speedFactor;
    return v <= 0 ? double.infinity : (b.y + b.boxHeight) / v;
  }

  void _advanceTarget({required bool afterPop}) {
    // Sıradaki harfin balonu zaten ekranda ama tavana çok yakınsa çocuk onu
    // bulamadan kaçar: o harf torbada sona atılır (yine sorulur), sıradaki alınır.
    final next = core.nextTarget(
      isFit: (letter) {
        final onScreen = balloons.where(
          (b) => b.alive && b.letter.char == letter.char,
        );
        return onScreen.isEmpty ||
            onScreen.any((b) => _secondsToEscape(b) >= minTargetSeconds);
      },
    );
    _events.add(BpTargetChanged(next, afterPop: afterPop));
    _ensureTargetOnScreen();
  }

  /// Hedef harfin ekranda (veya hemen alttan gelirken) mutlaka bir balonu olur:
  /// yoksa aynı harfle yeni bir balon üretilir.
  void _ensureTargetOnScreen() {
    final t = target;
    if (t == null || width <= 0 || height <= 0) return;
    final present = balloons.any((b) => b.alive && b.letter.char == t.char);
    if (!present) _spawn(t, preferSeparation: true);
  }

  // ---- üretim -------------------------------------------------------------

  BpLetter _pickDistractor() =>
      core.pickDistractor({for (final b in balloons) b.letter.char});

  void _spawn(BpLetter letter, {bool preferSeparation = false}) {
    // Hafif boyut farkı; dokunma alanı hiçbir zaman 72 px'in altına inmez.
    final size = math.max(
      72.0,
      baseSize * (0.92 + _random.nextDouble() * 0.16),
    );
    const margin = 6.0;
    final maxX = math.max(margin, width - size - margin);

    // Alt bölgedeki (yeni doğmuş) balonlarla yatay çakışmayı önlemeye çalışır.
    final nearBottom =
        balloons.where((b) => b.alive && b.y > height * 0.4).toList();
    double bestX = margin + _random.nextDouble() * (maxX - margin);
    var bestSep = -1.0;
    final tries = preferSeparation ? 24 : 14;
    for (var i = 0; i < tries; i++) {
      final x = margin + _random.nextDouble() * (maxX - margin);
      var sep = double.infinity;
      for (final b in nearBottom) {
        final d =
            ((x + size / 2) - (b.x + b.size / 2)).abs() / ((size + b.size) / 2);
        sep = math.min(sep, d);
      }
      if (sep > bestSep) {
        bestSep = sep;
        bestX = x;
      }
      if (sep >= 1.05) break; // yeterince ayrık
    }

    balloons.add(
      BpBalloon(
        id: _nextId++,
        letter: letter,
        x: bestX,
        y: height + 4, // hemen alttan
        size: size,
        speedFactor: 0.94 + _random.nextDouble() * 0.12,
        swayPhase: _random.nextDouble() * math.pi * 2,
        colorIndex: _random.nextInt(6),
      ),
    );
    spawned++;
  }
}
