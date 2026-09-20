import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'services/audio_service.dart';
import 'services/game_score_store.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioService()),
        Provider(create: (_) => GameScoreStore()),
        // Yerel oyuncu profilleri + oyun başına skor tabloları.
        ChangeNotifierProvider(create: (_) => PlayerRepository()..load()),
      ],
      child: const KuranOkumaRehberiApp(),
    ),
  );
}
