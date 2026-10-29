import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/core/app_routes.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/l10n/l10n.dart';
import 'package:kuran_okuma_rehberi/helpers/haraka_colors.dart';
import 'package:kuran_okuma_rehberi/theme/app_colors.dart';
import 'package:kuran_okuma_rehberi/theme/app_theme.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sources/sources_screen.dart';
import 'package:kuran_okuma_rehberi/screens/privacy/privacy_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_page_view.dart';
import 'dualar_test.dart' show TestAudioService, harness;

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

void main() {
  test('Primary controls and Arabic accents have readable contrast', () {
    for (final color in [
      AppColors.turquoise,
      AppColors.skyBlue,
      AppColors.gold,
      arabicRed,
    ]) {
      expect(contrast(color, Colors.white), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(AppColors.navy, const Color(0xFFFFFCF4)), greaterThan(7));
  });
  test('Fatiha has no detached terminal haraka', () {
    expect(kFatiha.besmele, isNot(matches(RegExp(r'\s[\u064B-\u065F]+$'))));
  });
  testWidgets('Deep links resolve to the correct surah and lesson', (
    tester,
  ) async {
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    for (final path in ['/sure/fatiha', '/ders/1']) {
      final route = AppRoutes.generate(RouteSettings(name: path))!;
      await tester.pumpWidget(
        harness(Navigator(onGenerateRoute: (_) => route), audio),
      );
      await tester.pumpAndSettle();
      if (path.startsWith('/sure')) {
        expect(
          tester
              .widget<SurahDetailScreen>(find.byType(SurahDetailScreen))
              .surah
              .id,
          'fatiha',
        );
      } else {
        expect(
          tester
              .widget<LessonLettersScreen>(find.byType(LessonLettersScreen))
              .lesson,
          kElifbaLessons.first,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('Sources and privacy are reachable from home', (tester) async {
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    for (final key in ['home-sources', 'home-privacy']) {
      await tester.pumpWidget(harness(const HomeScreen(), audio));
      await tester.pumpAndSettle();
      final entry = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(
        entry,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Fully on screen (the home page is enlarged 1.2x on tablets).
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(
        key == 'home-sources'
            ? find.byType(SourcesScreen)
            : find.byType(PrivacyScreen),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('Page controls stay 48 pixels on short phones', (tester) async {
    tester.view.physicalSize = const Size(390, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: BookPageBar(
              page: kElifbaLessons.first.pageLayout!.pages.first,
              index: 0,
              count: 2,
              onPrevious: () {},
              onNext: () {},
            ),
          ),
        ),
      ),
    );
    for (final key in ['page-next', 'page-previous']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
  test('Audited UI labels are translated in every active language', () {
    for (final language in AppLanguage.active.where(
      (l) => l != AppLanguage.tr,
    )) {
      for (final source in [
        'Giriş',
        'Harflerin Çıkış Yerleri',
        'Kelime',
        '▦ Izgara',
      ]) {
        expect(L10n.translationOf(language, source), isNotNull);
        expect(L10n.translationOf(language, source), isNot(source));
      }
    }
  });
}
