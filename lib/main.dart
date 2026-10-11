import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'l10n/l10n.dart';
import 'firebase_options.dart';
import 'screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'services/audio_service.dart';
import 'services/game_score_store.dart';
import 'services/leaderboard/firebase_leaderboard_backend.dart';
import 'services/leaderboard/leaderboard_backend.dart';
import 'services/leaderboard/leaderboard_service.dart';
import 'services/reading_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Çevrimiçi sıralama: Firebase arka planda başlar; uygulama onu beklemez,
  // başlatılamazsa (internet yok vb.) oyunlar yine oynanır.
  final leaderboard = LeaderboardService(
    backend: _initFirebase(),
    games: kOnlineLeaderboardGames,
  );
  unawaited(leaderboard.init());
  // Sure/dua okuma ayarları (yazı boyutu, hız, meal, tekrar…) cihazdan.
  unawaited(ReadingSettings.instance.ensureLoaded());

  final language = LanguageController();
  await language.load();

  runApp(
    MultiProvider(
      providers: [
        // Hemen kurulur (lazy değil): web'de ses bağlamı ilk dokunuşta açılsın.
        ChangeNotifierProvider(create: (_) => AudioService(), lazy: false),
        Provider(create: (_) => GameScoreStore()),
        // Yerel oyuncu profilleri + oyun başına skor tabloları.
        ChangeNotifierProvider(create: (_) => PlayerRepository()..load()),
        Provider<LeaderboardService>.value(value: leaderboard),
      ],
      child: AppLanguageScope(controller: language, child: const KuranOkumaRehberiApp()),
    ),
  );
}

Future<LeaderboardBackend?> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Cihazda Firestore önbelleği tutulmaz: bekleyen skorlar zaten
  // LeaderboardService kuyruğunda; sıralama her zaman sunucudan okunur.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  return FirebaseLeaderboardBackend();
}
