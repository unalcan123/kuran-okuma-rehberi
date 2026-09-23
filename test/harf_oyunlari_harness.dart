import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/services/leaderboard/leaderboard_service.dart';
import 'package:kuran_okuma_rehberi/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Gerçek ses çalmayan, çağrıları kaydeden sahte ses servisi.
class FakeGameAudio extends ChangeNotifier implements AudioService {
  String? _current;
  final effects = <String>[];

  @override
  String? get currentAsset => _current;

  @override
  void preload(Iterable<String?> assets) {}

  @override
  Future<void> playAsset(String assetPath) async => _current = assetPath;

  @override
  Future<void> stop() async => _current = null;

  @override
  Future<void> playEffect(String assetPath) async => effects.add(assetPath);

  @override
  Future<void> stopEffect() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Her testte yeniden oluşturulur (setUp).
FakeGameAudio gameAudio = FakeGameAudio();

/// [players] verilmezse boş bir PlayerRepository kurulur ve "Kim oynuyor?"
/// penceresi açılmaz; profil akışı testleri kendi repository'sini verir.
Widget gameApp(
  Widget home, {
  PlayerRepository? players,
  LeaderboardService? leaderboard,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AudioService>.value(value: gameAudio),
      Provider<GameScoreStore>(create: (_) => GameScoreStore()),
      if (players == null)
        ChangeNotifierProvider(
          create: (_) => PlayerRepository()..promptedThisSession = true,
        )
      else
        ChangeNotifierProvider.value(value: players),
      if (leaderboard != null)
        Provider<LeaderboardService>.value(value: leaderboard),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
      home: home,
    ),
  );
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
  }
  await loader.load();
}

/// Gerçek yazı tipleri: Ahem (test varsayılanı) metni gerçekte olduğundan çok
/// geniş ölçer ve sahte taşma raporlar.
Future<void> setUpTestEnvironment() async {
  const sdkFonts = 'D:/src/flutter/bin/cache/artifacts/material_fonts';
  await _loadFont('Roboto', [
    '$sdkFonts/roboto-regular.ttf',
    '$sdkFonts/roboto-bold.ttf',
  ]);
}
