import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kuran_okuma_rehberi/data/dualar_data.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dua_detail_screen.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dualar_list_screen.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/reading_settings.dart';
import 'package:kuran_okuma_rehberi/widgets/reading/reading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// UI tests simulate playback; device audio decoding requires a real platform.
class TestAudioService extends ChangeNotifier implements AudioService {
  @override
  String? currentAsset;
  @override
  AudioPlaybackState state = AudioPlaybackState.stopped;
  List<String> queue = [];
  final preloaded = <List<String?>>[];
  @override
  void preload(Iterable<String?> assets) => preloaded.add(assets.toList());
  @override
  bool get isPlaying => state == AudioPlaybackState.playing;
  @override
  bool get isPaused => state == AudioPlaybackState.paused;
  @override
  Future<void> playPlaylist(List<String> assets) async {
    queue = assets;
    currentAsset = assets.first;
    state = AudioPlaybackState.playing;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    state = AudioPlaybackState.paused;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    state = AudioPlaybackState.playing;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    currentAsset = null;
    state = AudioPlaybackState.stopped;
    notifyListeners();
  }

  /// Every clip started (one by one, as the reading screen plays them).
  final played = <String>[];
  final rates = <double>[];
  @override
  double playbackRate = 1.0;

  @override
  Future<void> setPlaybackRate(double rate) async {
    playbackRate = rate;
    rates.add(rate);
  }

  @override
  Future<void> playAsset(String asset) async {
    played.add(asset);
    currentAsset = asset;
    state = AudioPlaybackState.playing;
    notifyListeners();
  }

  /// The current clip reached its end.
  void complete() {
    currentAsset = null;
    state = AudioPlaybackState.stopped;
    notifyListeners();
  }

  @override
  Future<void> playOrToggle(String asset) async {
    if (currentAsset == asset) {
      if (isPlaying) {
        await pause();
      } else {
        await resume();
      }
    } else {
      await playPlaylist([asset]);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget harness(Widget child, TestAudioService audio) =>
    ChangeNotifierProvider<AudioService>.value(
      value: audio,
      child: MaterialApp(home: child),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReadingSettings.instance.resetForTest();
  });

  test('Every source segment has an imported nonempty recording', () {
    expect(kDualar.length, 9);
    expect(kDualar.expand((dua) => dua.segments).length, 32);
    for (final dua in kDualar) {
      for (final segment in dua.segments) {
        expect(segment.arabic, isNotEmpty);
        expect(segment.meaningTr, isNotEmpty);
        expect(segment.pronunciationTr, isNull);
        expect(
          File('assets/${segment.audioAsset}').lengthSync(),
          greaterThan(0),
        );
      }
    }
  });

  for (final size in [
    const Size(360, 800),
    const Size(800, 1280),
    const Size(1280, 800),
    const Size(1440, 900),
  ]) {
    testWidgets('Dua list and every detail fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = TestAudioService();
      addTearDown(audio.dispose);
      await tester.pumpWidget(harness(const DualarListScreen(), audio));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(GridView), const Offset(0, -2500));
      await tester.pumpAndSettle();
      // Picture cards: the title is in the picture, not written again.
      expect(find.byKey(ValueKey('dua-card-${kDualar.last.id}')), findsOneWidget);
      for (final dua in kDualar) {
        await tester.pumpWidget(
          harness(DuaDetailScreen(key: ValueKey(dua.id), dua: dua), audio),
        );
        await tester.pumpAndSettle();
        final arabic = tester.widget<Text>(
          find.text(dua.segments.first.arabic),
        );
        expect(arabic.textDirection, TextDirection.rtl);
        // Default Arabic size: the earlier size (30 / 42 / 46) × 130 %.
        expect(
          arabic.style!.fontSize,
          closeTo(
            (size.width < 600
                    ? 30
                    : size.width < 1024
                    ? 42
                    : 46) *
                1.3,
            0.001,
          ),
        );
        expect(
          audio.preloaded.last,
          dua.segments.map((segment) => segment.audioAsset).toList(),
          reason: "the dua's recordings are fetched when it opens",
        );
        // Meal is off by default.
        expect(find.text('Türkçe Anlam'), findsNothing);
        expect(find.text('Türkçe Okunuş'), findsNothing);
        final list = find.byType(SingleChildScrollView).first;
        final listRect = tester.getRect(list);
        final controlsRect = tester.getRect(find.byType(ReadingPlaybackBar));
        expect(listRect.bottom, lessThanOrEqualTo(controlsRect.top));
        await tester.drag(list, const Offset(0, -10000));
        await tester.pumpAndSettle();
        expect(
          find.text(dua.segments.last.arabic).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Home navigation and shared play, pause, resume, stop, switch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    await tester.pumpWidget(harness(const HomeScreen(), audio));
    await tester.tap(find.byKey(const ValueKey('home-card-image-Namaz Duaları')));
    await tester.pumpAndSettle();
    expect(find.byType(DualarListScreen), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('dua-card-${kDualar.first.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinle'));
    await tester.pumpAndSettle();
    // Parts are played one by one on the shared player, first part first.
    expect(audio.played, [kDualar.first.playlist.first]);
    await tester.tap(find.text('Duraklat'));
    await tester.pumpAndSettle();
    expect(audio.isPaused, isTrue);
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(audio.isPlaying, isTrue);
    await tester.tap(find.byKey(const ValueKey('reading-stop')));
    await tester.pumpAndSettle();
    expect(audio.currentAsset, isNull);
    await tester.tap(find.text('Dinle'));
    await tester.pumpAndSettle();
    expect(audio.currentAsset, kDualar.first.playlist.first);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('dua-card-${kDualar[1].id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinle'));
    await tester.pumpAndSettle();
    expect(audio.currentAsset, kDualar[1].playlist.first);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
