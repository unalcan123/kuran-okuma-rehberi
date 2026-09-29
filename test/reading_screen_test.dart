// Sure ve dua okuma ekranları (ortak ReadingScreen): meal varsayılan kapalı,
// Arapça %130, ayarlar kalıcı, hız, tekrar 1-10, Dinle → ilk bölüme kaydırma,
// aktif bölüm ilerler ve görünür kalır, ezber modları, metni gizle, aynı
// motor, ses eşleşmesi bozulmadı.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/models/reading_segment.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dua_detail_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/services/reading_playback_controller.dart';
import 'package:kuran_okuma_rehberi/services/reading_settings.dart';
import 'package:kuran_okuma_rehberi/widgets/reading/reading_screen.dart';
import 'package:kuran_okuma_rehberi/widgets/reading/reading_settings_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dualar_test.dart' show TestAudioService, harness;

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

ReadingSettings get settings => ReadingSettings.instance;

Future<TestAudioService> openSurah(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  int surah = 0,
}) async {
  setSize(tester, size);
  final audio = TestAudioService();
  addTearDown(audio.dispose);
  await tester.pumpWidget(
    harness(SurahDetailScreen(surah: kSureler[surah]), audio),
  );
  await tester.pumpAndSettle();
  return audio;
}

ReadingPlaybackController playerOf(WidgetTester tester) =>
    tester.state<ReadingScreenState>(find.byType(ReadingScreen)).player;

Finder get list => find.descendant(
  of: find.byType(ReadingScreen),
  matching: find.byType(SingleChildScrollView),
);

double fontOf(WidgetTester tester, String arabic) =>
    tester.widget<Text>(find.text(arabic)).style!.fontSize!;

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('reading-settings-button')));
  await tester.pumpAndSettle();
}

/// Scrolls the settings sheet until [finder] is built and on screen.
Future<void> inSheet(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable:
        find
            .descendant(
              of: find.byType(ReadingSettingsSheet),
              matching: find.byType(Scrollable),
            )
            .first,
  );
  await tester.pumpAndSettle();
}

Future<void> closeSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Kapat'));
  await tester.pumpAndSettle();
}

/// The clip ends and the pause after it passes.
Future<void> finishClip(TestAudioService audio, WidgetTester tester) async {
  audio.complete();
  await tester.pump();
  await tester.pump(Duration(seconds: settings.pauseSeconds));
  await tester.pumpAndSettle();
}

/// Whether [finder] is wholly inside the reading list's visible part.
bool fullyVisible(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  final view = tester.getRect(list);
  return rect.top >= view.top - 0.5 && rect.bottom <= view.bottom + 0.5;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings.resetForTest();
  });

  group('varsayılanlar ve ayarlar', () {
    testWidgets('meal varsayılan KAPALI, Arapça varsayılan %130', (
      tester,
    ) async {
      await openSurah(tester);
      final fatiha = kSureler.first;
      expect(settings.showMeaning, isFalse);
      expect(find.text(fatiha.ayetler.first.meaningTr), findsNothing);
      expect(find.text('Türkçe Anlam'), findsNothing);
      // Earlier phone size 30 × 1.3.
      expect(fontOf(tester, fatiha.ayetler.first.arabic), closeTo(39, 0.001));
      expect(settings.arabicScale, 1.3);

      // Meal açılınca ayetin altında görünür.
      await openSettings(tester);
      await tester.tap(find.byKey(const ValueKey('show-meaning')));
      await tester.pumpAndSettle();
      await closeSettings(tester);
      expect(find.text(fatiha.ayetler.first.meaningTr), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool('reading.showMeaning'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('yazı boyutu tercihi çalışır ve saklanır', (tester) async {
      await openSurah(tester);
      final ayet = kSureler.first.ayetler.first.arabic;
      await openSettings(tester);
      await tester.tap(find.byKey(const ValueKey('arabic-size-%160')));
      await tester.pumpAndSettle();
      await closeSettings(tester);
      expect(fontOf(tester, ayet), closeTo(48, 0.001));
      await openSettings(tester);
      await tester.tap(find.byKey(const ValueKey('arabic-size-down')));
      await tester.pumpAndSettle();
      await closeSettings(tester);
      expect(settings.arabicScale, 1.45);
      expect(
        (await SharedPreferences.getInstance()).getDouble(
          'reading.arabicScale',
        ),
        1.45,
      );
    });

    testWidgets('okuma hızı aynı çalara uygulanır (0.75x - 1.25x)', (
      tester,
    ) async {
      final audio = await openSurah(tester);
      expect(audio.rates.last, 1.0);
      await openSettings(tester);
      for (final label in ['0.75x', '0.85x', '1.15x', '1.25x']) {
        await tester.tap(find.byKey(ValueKey('speed-$label')));
        await tester.pumpAndSettle();
        expect(audio.playbackRate, double.parse(label.replaceAll('x', '')));
      }
      await closeSettings(tester);
      // Leaving the screen: normal speed again for the other screens.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(audio.playbackRate, 1.0);
    });

    testWidgets('tekrar sayısı 1-10', (tester) async {
      await openSurah(tester);
      await openSettings(tester);
      final up = find.byKey(const ValueKey('repeat-up'));
      final down = find.byKey(const ValueKey('repeat-down'));
      await inSheet(tester, up);
      expect(find.text('1x'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.descendant(of: down, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNull,
      );
      for (var i = 0; i < 12; i++) {
        await tester.tap(up);
        await tester.pump();
      }
      expect(settings.repeatCount, 10);
      expect(find.text('10x'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.descendant(of: up, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(down);
      await tester.pump();
      expect(settings.repeatCount, 9);
    });

    test('ayarlar cihazdan okunur (bir sonraki açılışta)', () async {
      SharedPreferences.setMockInitialValues({
        'reading.arabicScale': 1.6,
        'reading.speed': 0.85,
        'reading.showMeaning': true,
        'reading.repeatCount': 4,
        'reading.pauseSeconds': 5,
        'reading.mode': 'shuffled',
        'reading.hideTextWhileMemorizing': true,
      });
      settings.resetForTest();
      await settings.ensureLoaded();
      expect(settings.arabicScale, 1.6);
      expect(settings.speed, 0.85);
      expect(settings.showMeaning, isTrue);
      expect(settings.repeatCount, 4);
      expect(settings.pauseSeconds, 5);
      expect(settings.mode, MemorizationMode.shuffled);
      expect(settings.hideTextWhileMemorizing, isTrue);
    });
  });

  group('Dinle, aktif bölüm, otomatik kaydırma', () {
    testWidgets('Dinle → ilk bölüme kaydırır ve oradan başlar', (tester) async {
      final audio = await openSurah(tester);
      await tester.drag(list, const Offset(0, -900));
      await tester.pumpAndSettle();
      final first = find.byKey(const ValueKey('reading-segment-0'));
      expect(fullyVisible(tester, first), isFalse);

      await tester.tap(find.byKey(const ValueKey('reading-listen')));
      await tester.pumpAndSettle();
      expect(audio.played, [kSureler.first.besmeleAudioAsset]);
      expect(playerOf(tester).activeIndex, 0);
      expect(fullyVisible(tester, first), isTrue);
      expect(
        find.byKey(const ValueKey('reading-active-mark-0')),
        findsOneWidget,
      );
      expect(find.text('Duraklat'), findsOneWidget);
    });

    testWidgets('okuma ilerledikçe aktif bölüm değişir ve görünür kalır', (
      tester,
    ) async {
      final audio = await openSurah(tester, size: const Size(360, 640));
      final fatiha = kSureler.first;
      await tester.tap(find.byKey(const ValueKey('reading-listen')));
      await tester.pumpAndSettle();
      for (var i = 1; i <= fatiha.ayetler.length; i++) {
        await finishClip(audio, tester);
        expect(playerOf(tester).activeIndex, i);
        expect(audio.played.last, fatiha.ayetler[i - 1].audioAsset);
        expect(
          fullyVisible(tester, find.byKey(ValueKey('reading-segment-$i'))),
          isTrue,
          reason: 'ayet $i',
        );
        expect(find.byKey(ValueKey('reading-active-mark-$i')), findsOneWidget);
        expect(
          find.byKey(ValueKey('reading-active-mark-${i - 1}')),
          findsNothing,
        );
      }
      // "Sadece Dinle": the dataset's order (besmele, then the ayetler).
      expect(audio.played, fatiha.playlist);
      audio.complete();
      await tester.pumpAndSettle();
      expect(playerOf(tester).isActive, isFalse);
      expect(find.text('Dinle'), findsOneWidget);
    });

    testWidgets('elle kaydırınca sayfa zorla geri çekilmez', (tester) async {
      final audio = await openSurah(tester, size: const Size(390, 1200));
      await tester.tap(find.byKey(const ValueKey('reading-listen')));
      await tester.pumpAndSettle();
      final position =
          tester
              .state<ScrollableState>(
                find
                    .descendant(of: list, matching: find.byType(Scrollable))
                    .first,
              )
              .position;
      // The student scrolls a little (the next part is still in view).
      await tester.drag(list, const Offset(0, -60));
      await tester.pumpAndSettle();
      final byHand = position.pixels;
      await finishClip(audio, tester);
      expect(playerOf(tester).activeIndex, 1);
      expect(position.pixels, byHand);
    });

    testWidgets('tek bölüm düğmesi yalnız o bölümü çalar ve vurgular', (
      tester,
    ) async {
      final audio = await openSurah(tester);
      final play = find.byKey(const ValueKey('reading-play-3'));
      final size = tester.getSize(play);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      await tester.ensureVisible(play);
      await tester.tap(play);
      await tester.pumpAndSettle();
      expect(audio.played, [kSureler.first.ayetler[2].audioAsset]);
      expect(
        find.byKey(const ValueKey('reading-active-mark-3')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('reading-active-mark-0')), findsNothing);
      // Again: pause.
      await tester.tap(play);
      await tester.pumpAndSettle();
      expect(audio.isPaused, isTrue);
      // It ends: nothing else plays.
      await tester.tap(play);
      await tester.pumpAndSettle();
      await finishClip(audio, tester);
      expect(audio.played, hasLength(1));
      expect(playerOf(tester).isActive, isFalse);
    });

    testWidgets('Duraklat / Devam Et / Durdur', (tester) async {
      final audio = await openSurah(tester);
      await tester.tap(find.byKey(const ValueKey('reading-listen')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duraklat'));
      await tester.pumpAndSettle();
      expect(audio.isPaused, isTrue);
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(audio.isPlaying, isTrue);
      await tester.tap(find.byKey(const ValueKey('reading-stop')));
      await tester.pumpAndSettle();
      expect(audio.currentAsset, isNull);
      expect(find.text('Dinle'), findsOneWidget);
    });
  });

  group('ezber', () {
    final fatiha = ReadingSegment.ofSurah(kSureler.first);

    test('Ayet Ayet, tekrar = 3: her bölüm 3 kez, sonra sıradaki', () {
      final plan = buildPlaybackPlan(
        fatiha,
        mode: MemorizationMode.stepByStep,
        repeatCount: 3,
      );
      expect(plan.length, fatiha.length * 3);
      expect(plan.take(4).toList(), [
        const PlaybackStep(0, repeat: 1, of: 3),
        const PlaybackStep(0, repeat: 2, of: 3),
        const PlaybackStep(0, repeat: 3, of: 3),
        const PlaybackStep(1, repeat: 1, of: 3),
      ]);
    });

    test('Sadece Dinle: baştan sona sırayla', () {
      final plan = buildPlaybackPlan(
        fatiha,
        mode: MemorizationMode.listenOnly,
        repeatCount: 1,
      );
      expect(plan.map((s) => s.segment), [
        for (var i = 0; i < fatiha.length; i++) i,
      ]);
    });

    test(
      'Karışık: besmele başta, her ayet tekrar kadar, arka arkaya aynısı yok',
      () {
        for (var seed = 0; seed < 50; seed++) {
          final plan = buildPlaybackPlan(
            fatiha,
            mode: MemorizationMode.shuffled,
            repeatCount: 3,
            random: math.Random(seed),
          );
          final order = plan.map((s) => s.segment).toList();
          expect(order.first, 0); // besmele (dataset order)
          for (var i = 1; i < fatiha.length; i++) {
            expect(order.where((s) => s == i).length, 3);
          }
          for (var i = 1; i < order.length; i++) {
            expect(order[i], isNot(order[i - 1]), reason: 'seed $seed: $order');
          }
        }
        // The data itself is unchanged.
        expect(fatiha.map((s) => s.audioAsset), kSureler.first.playlist);
      },
    );

    testWidgets('tekrar = 3 aynı bölümü 3 kez çalar (ekranda)', (tester) async {
      settings.mode = MemorizationMode.stepByStep;
      settings.repeatCount = 3;
      final audio = await openSurah(tester);
      await tester.tap(find.byKey(const ValueKey('reading-listen')));
      await tester.pumpAndSettle();
      expect(find.text('Duraklat  ·  1/3'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        audio.complete();
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      }
      final besmele = kSureler.first.besmeleAudioAsset;
      final ayet1 = kSureler.first.ayetler.first.audioAsset;
      expect(audio.played, [besmele, besmele, besmele, ayet1]);
    });

    testWidgets('Karışık mod ekranda da tek tek çalar', (tester) async {
      settings.mode = MemorizationMode.shuffled;
      final audio = await openSurah(tester);
      await tester.tap(find.byKey(const ValueKey('reading-listen')));
      await tester.pumpAndSettle();
      final plan = playerOf(tester).plan;
      for (var i = 1; i < plan.length; i++) {
        await finishClip(audio, tester);
      }
      final segments = ReadingSegment.ofSurah(kSureler.first);
      expect(audio.played, [
        for (final step in plan) segments[step.segment].audioAsset,
      ]);
      expect(audio.played.toSet(), kSureler.first.playlist.toSet());
    });

    testWidgets('metni gizle: dinledikten sonra "Şimdi sen oku", Göster', (
      tester,
    ) async {
      settings.mode = MemorizationMode.stepByStep;
      settings.repeatCount = 2;
      settings.hideTextWhileMemorizing = true;
      final audio = await openSurah(tester);
      final besmele = kSureler.first.besmele;
      await tester.tap(find.byKey(const ValueKey('reading-listen')));
      await tester.pumpAndSettle();
      // First time: seen and heard.
      expect(find.text(besmele), findsOneWidget);
      audio.complete();
      await tester.pump();
      // Now the student recites.
      expect(find.byKey(const ValueKey('reading-hidden-0')), findsOneWidget);
      expect(find.text('Şimdi sen oku'), findsOneWidget);
      expect(find.text(besmele), findsNothing);
      await tester.tap(find.byKey(const ValueKey('reading-reveal-0')));
      await tester.pump();
      expect(find.text(besmele), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(besmele), findsOneWidget); // stays shown for this part
    });

    testWidgets('metni gizle başlangıçta KAPALI ve yalnız Ayet Ayet modunda', (
      tester,
    ) async {
      await openSurah(tester);
      expect(settings.hideTextWhileMemorizing, isFalse);
      await openSettings(tester);
      final hide = find.byKey(const ValueKey('hide-text'));
      await inSheet(tester, hide);
      expect(
        tester
            .widget<SwitchListTile>(
              find.descendant(of: hide, matching: find.byType(SwitchListTile)),
            )
            .onChanged,
        isNull,
      );
      await inSheet(tester, find.byKey(const ValueKey('mode-stepByStep')));
      await tester.tap(find.byKey(const ValueKey('mode-stepByStep')));
      await tester.pumpAndSettle();
      await inSheet(tester, hide);
      expect(
        tester
            .widget<SwitchListTile>(
              find.descendant(of: hide, matching: find.byType(SwitchListTile)),
            )
            .onChanged,
        isNotNull,
      );
    });
  });

  group('sure ve dua aynı altyapı', () {
    test('ses eşleşmesi: bölümler verinin kayıtlarıyla aynı sırada', () {
      for (final surah in kSureler) {
        expect(
          ReadingSegment.ofSurah(surah).map((s) => s.audioAsset),
          surah.playlist,
          reason: surah.id,
        );
      }
      for (final dua in kDualar) {
        expect(
          ReadingSegment.ofDua(dua).map((s) => s.audioAsset),
          dua.playlist,
          reason: dua.id,
        );
        expect(
          ReadingSegment.ofDua(dua).map((s) => s.arabic),
          dua.segments.map((s) => s.arabic),
        );
      }
    });

    testWidgets('dua ekranı aynı ekran ve motor; Bölüm Bölüm, tekrar', (
      tester,
    ) async {
      setSize(tester, const Size(390, 844));
      settings.mode = MemorizationMode.stepByStep;
      settings.repeatCount = 2;
      final audio = TestAudioService();
      addTearDown(audio.dispose);
      final dua = kDualar.first;
      await tester.pumpWidget(harness(DuaDetailScreen(dua: dua), audio));
      await tester.pumpAndSettle();
      expect(find.byType(ReadingScreen), findsOneWidget);
      await openSettings(tester);
      await inSheet(tester, find.text('Bölüm Bölüm'));
      await inSheet(tester, find.text('Bölümler Arası Bekleme'));
      await closeSettings(tester);
      await tester.tap(find.byKey(const ValueKey('reading-listen')));
      await tester.pumpAndSettle();
      audio.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await finishClip(audio, tester);
      expect(audio.played, [
        dua.segments[0].audioAsset,
        dua.segments[0].audioAsset,
        dua.segments[1].audioAsset,
      ]);
    });
  });

  for (final size in const [
    Size(360, 640),
    Size(800, 1280),
    Size(1280, 800),
    Size(800, 360),
  ]) {
    testWidgets('$size: %160 yazıda ve meal açıkken bütün sure/dualar sığar', (
      tester,
    ) async {
      setSize(tester, size);
      settings.arabicScale = 1.6;
      settings.showMeaning = true;
      final audio = TestAudioService();
      addTearDown(audio.dispose);
      for (final screen in <Widget>[
        for (final s in kSureler)
          SurahDetailScreen(key: ValueKey(s.id), surah: s),
        for (final d in kDualar) DuaDetailScreen(key: ValueKey(d.id), dua: d),
      ]) {
        await tester.pumpWidget(harness(screen, audio));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$screen');
        // No sideways scrolling: every card is as wide as the list.
        final listWidth = tester.getSize(list).width;
        for (final card
            in find
                .byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'reading-segment-',
                      ),
                )
                .evaluate()) {
          final box = card.renderObject! as RenderBox;
          expect(box.size.width, lessThanOrEqualTo(listWidth));
        }
        await tester.drag(list, const Offset(0, -20000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$screen');
      }
    });
  }
}
