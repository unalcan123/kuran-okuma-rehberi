import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/core/responsive.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/home/widgets/home_menu_card.dart';
import 'package:kuran_okuma_rehberi/widgets/phone_zoom_fix.dart';

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget app(Widget home, double Function() detect) => MaterialApp(
  key: UniqueKey(),
  builder: (context, child) => PhoneZoomFix(detect: detect, child: child!),
  home: home,
);

void main() {
  testWidgets('Zoom 1 leaves everything untouched', (tester) async {
    setSize(tester, const Size(800, 1400));
    Size? seen;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return const SizedBox.expand(key: ValueKey('body'));
          },
        ),
        () => 1,
      ),
    );
    expect(seen, const Size(800, 1400));
    expect(tester.getSize(find.byKey(const ValueKey('body'))), const Size(800, 1400));
  });

  testWidgets('A wide phone page is given a phone-sized canvas that fills the page', (
    tester,
  ) async {
    setSize(tester, const Size(900, 1800));
    Size? seen;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return const SizedBox.expand(key: ValueKey('body'));
          },
        ),
        () => 2.25,
      ),
    );
    expect(seen, const Size(400, 800), reason: 'the app sees a phone');
    // ...enlarged back over the whole page.
    final rect = tester.getRect(find.byKey(const ValueKey('body')));
    expect(rect.topLeft, Offset.zero);
    expect(rect.size, const Size(900, 1800));
  });

  testWidgets('Taps land on the right widget through the enlargement', (tester) async {
    setSize(tester, const Size(900, 1800));
    var taps = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              key: const ValueKey('button'),
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox(width: 100, height: 80),
            ),
          ),
        ),
        () => 2.25,
      ),
    );
    // Bottom-right corner of the page = bottom-right of the button.
    await tester.tapAt(const Offset(890, 1790));
    expect(taps, 1);
    await tester.tapAt(const Offset(10, 10));
    expect(taps, 1);
  });

  testWidgets('The home screen switches from tablet to phone layout', (tester) async {
    setSize(tester, const Size(980, 2000));
    await tester.pumpWidget(app(const HomeScreen(), () => 1));
    await tester.pumpAndSettle();
    final tabletXs = {
      for (final e in tester.elementList(find.byType(HomeMenuCard)))
        tester.getTopLeft(find.byWidget(e.widget)).dx.round(),
    };
    expect(tabletXs.length, 2, reason: 'two columns when the page looks wide');

    await tester.pumpWidget(app(HomeScreen(key: UniqueKey()), () => 2.45));
    await tester.pumpAndSettle();
    final phoneXs = {
      for (final e in tester.elementList(find.byType(HomeMenuCard)))
        tester.getTopLeft(find.byWidget(e.widget)).dx.round(),
    };
    expect(phoneXs.length, 1, reason: 'one column, like the phone app');
    final card = tester.getRect(find.byType(HomeMenuCard).first);
    expect(card.width, greaterThan(800), reason: 'cards fill the wide page (minus the margins)');
    expect(Responsive.deviceClassOf(tester.element(find.byType(HomeScreen))), DeviceClass.mobile);
  });

  testWidgets('Follows the window: zoom is re-read when the metrics change', (
    tester,
  ) async {
    setSize(tester, const Size(900, 1800));
    var zoom = 1.0;
    Size? seen;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return const SizedBox.expand();
          },
        ),
        () => zoom,
      ),
    );
    expect(seen, const Size(900, 1800));
    zoom = 3;
    tester.view.physicalSize = const Size(900, 1801); // any change of the window
    await tester.pump();
    await tester.pump();
    expect(seen!.width, 300);
    zoom = 1;
    tester.view.physicalSize = const Size(900, 1800);
    await tester.pump();
    await tester.pump();
    expect(seen, const Size(900, 1800));
  });
}
