import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'screens/oyunlar/harf_oyunlari/profil/player_models.dart';
import 'screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'services/audio_service.dart';
import 'services/game_score_store.dart';
import 'services/leaderboard/firebase_leaderboard_backend.dart';
import 'services/leaderboard/leaderboard_backend.dart';
import 'services/leaderboard/leaderboard_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Çevrimiçi sıralama: Firebase arka planda başlar; uygulama onu beklemez,
  // başlatılamazsa (internet yok vb.) oyunlar yine oynanır.
  final leaderboard = LeaderboardService(
    backend: _initFirebase(),
    games: kOnlineLeaderboardGames,
  );
  unawaited(leaderboard.init());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioService()),
        Provider(create: (_) => GameScoreStore()),
        // Yerel oyuncu profilleri + oyun başına skor tabloları.
        ChangeNotifierProvider(create: (_) => PlayerRepository()..load()),
        Provider<LeaderboardService>.value(value: leaderboard),
      ],
      child: const KuranOkumaRehberiApp(),
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
