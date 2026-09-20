import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../services/audio_service.dart';
import 'game_letters.dart';

/// "Sesi dinle, doğru harfi bul" oyunlarının ortak ekran altyapısı:
///  * tek bir [Ticker] ile oyun zamanı (öğe başına AnimationController yok),
///  * uygulama arka plana alınınca duraklatma / öne gelince devam,
///  * hedef harf sesi ve "sesi tekrar dinle" (uygulamanın ortak [AudioService]'i),
///  * ekrandan çıkınca ticker, zamanlayıcı ve sesin temizlenmesi.
///
/// Kullanım: `State` sınıfı `WidgetsBindingObserver` ve
/// `SingleTickerProviderStateMixin` ile birlikte bu mixin'i uygular ve
/// [gameRunning], [currentTarget], [onRunnerFrame] üyelerini sağlar.
mixin LetterGameRunner<T extends StatefulWidget>
    on State<T>, TickerProvider, WidgetsBindingObserver {
  /// Her karede yükseltilir; oyun alanı bunu dinleyerek yeniden çizilir.
  final ValueNotifier<int> frame = ValueNotifier<int>(0);

  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  Timer? _speakTimer;
  bool _pausedByLifecycle = false;
  AudioService? _audio;

  /// Uygulamanın ortak ses servisi (Provider'dan; dispose'da da kullanılabilsin diye saklanır).
  AudioService get audio => _audio ??= context.read<AudioService>();

  bool get pausedByLifecycle => _pausedByLifecycle;

  /// Oyun şu an çalışıyor mu (bitmiş/başlamamış değil).
  bool get gameRunning;

  /// Şu anki hedef harf.
  GameLetter? get currentTarget;

  /// Her ticker karesinde çağrılır. [dt] saniyedir (en çok 0.1: uzun kare
  /// gecikmesinde oyun zamanı sıçramaz). Oyun çalışmıyorsa 0 gelir; yine de
  /// bekleyen olayları (ör. oyun bitişi) işlemek için çağrılır.
  void onRunnerFrame(double dt);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    final dt =
        gameRunning
            ? ((elapsed - _lastElapsed).inMicroseconds / 1e6)
                .clamp(0.0, 0.1)
                .toDouble()
            : 0.0;
    _lastElapsed = elapsed;
    onRunnerFrame(dt);
    frame.value++;
  }

  /// Ticker'ı (yeniden) başlatır.
  void startRunner() {
    _pausedByLifecycle = false;
    _lastElapsed = Duration.zero;
    final t = _ticker!;
    if (t.isActive) t.stop();
    t.start();
  }

  /// Oyun bitince: ticker ve bekleyen sesler durur.
  void stopRunner() {
    _ticker?.stop();
    _speakTimer?.cancel();
    audio.stop();
  }

  /// Hedef harfin sesini [delayMs] sonra çalar (öncekini keser, üst üste binmez).
  /// Doğru cevabın efekt sesi bitsin diye bazen biraz geciktirilir.
  void speakLater(GameLetter letter, int delayMs) {
    _speakTimer?.cancel();
    _speakTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || !gameRunning || _pausedByLifecycle) return;
      audio.playAsset(letter.audio);
    });
  }

  /// "Sesi tekrar dinle": puanı etkilemez.
  void replayTarget() {
    final target = currentTarget;
    if (target == null || !gameRunning) return;
    _speakTimer?.cancel();
    audio.playAsset(target.audio);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pausedByLifecycle && gameRunning) {
        _pausedByLifecycle = false;
        _lastElapsed = Duration.zero;
        _ticker?.start();
        final target = currentTarget;
        if (target != null) speakLater(target, 350); // hedefi tekrar duyur
      }
    } else if (gameRunning && !_pausedByLifecycle) {
      // Arka plana alınınca 2 dakikalık oyun beklemede kalır.
      _pausedByLifecycle = true;
      _ticker?.stop();
      _speakTimer?.cancel();
      audio.stop();
      audio.stopEffect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speakTimer?.cancel();
    _ticker?.dispose();
    frame.dispose();
    // dispose sırasında notifyListeners çağırmamak için ertelenir.
    final service = _audio;
    if (service != null) {
      Future.microtask(() {
        service.stop();
        service.stopEffect();
      });
    }
    super.dispose();
  }
}
