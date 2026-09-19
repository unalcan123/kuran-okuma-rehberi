import 'package:flutter/material.dart';

import 'core/app_scroll_behavior.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/phone_zoom_fix.dart';

class KuranOkumaRehberiApp extends StatelessWidget {
  const KuranOkumaRehberiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Kur'an Okuma Rehberi",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: AppScrollBehavior(),
      builder:
          (context, child) =>
              PhoneZoomFix(child: child ?? const SizedBox.shrink()),
      home: const SplashScreen(),
    );
  }
}
