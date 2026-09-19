import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kuran_okuma_rehberi/app.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';

void main() {
  testWidgets('Splash shows the cover then opens home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AudioService(),
        child: const KuranOkumaRehberiApp(),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/splash/kapak_splash.png',
      ),
      findsOneWidget,
    );

    // Let the splash timer fire and the fade transition finish so no
    // timers are left pending when the test tears down.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
