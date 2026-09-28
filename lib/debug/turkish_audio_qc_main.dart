import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'turkish_audio_qc_screen.dart';

/// Türkçe Ses Kontrol ekranını tek başına açan geliştirici giriş noktası —
/// uygulamanın hiçbir menüsünde yoktur:
///
///     flutter run -d chrome -t lib/debug/turkish_audio_qc_main.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioService(),
      child: MaterialApp(
        title: 'Türkçe Ses Kontrol',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const TurkishAudioQcScreen(),
      ),
    ),
  );
}
