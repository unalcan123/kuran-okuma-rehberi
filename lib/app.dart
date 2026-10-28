import 'screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_scroll_behavior.dart';
import 'core/web_metadata.dart';
import 'l10n/l10n.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/phone_zoom_fix.dart';
import 'core/app_routes.dart';

class KuranOkumaRehberiApp extends StatefulWidget {
  const KuranOkumaRehberiApp({super.key});
  @override
  State<KuranOkumaRehberiApp> createState() => _KuranOkumaRehberiAppState();
}

class _KuranOkumaRehberiAppState extends State<KuranOkumaRehberiApp> {
  late final SemanticsHandle _semantics;
  @override
  void initState() {
    super.initState();
    _semantics = SemanticsBinding.instance.ensureSemantics();
  }

  @override
  void dispose() {
    _semantics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.language;
    final title = context.t("Kur'an Okuma Rehberi");
    updateWebMetadata(language.code, title);
    return MaterialApp(
      title: title,
      locale: language.locale,
      supportedLocales: [
        for (final language in AppLanguage.active) language.locale,
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: AppScrollBehavior(),
      builder:
          (context, child) =>
              PhoneZoomFix(child: child ?? const SizedBox.shrink()),
      onGenerateRoute: AppRoutes.generate,
      onGenerateInitialRoutes:
          (route) => [
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: '/'),
              builder:
                  (_) =>
                      route == '/' ? const SplashScreen() : const HomeScreen(),
            ),
            if (route != '/') AppRoutes.generate(RouteSettings(name: route))!,
          ],
    );
  }
}
