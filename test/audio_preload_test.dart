import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:provider/provider.dart';

class FakeAudio extends ChangeNotifier implements AudioService {
  final preloaded = <List<String?>>[];

  @override
  String? currentAsset;
  @override
  AudioPlaybackState state = AudioPlaybackState.stopped;
  @override
  bool get isPlaying => false;
  @override
  bool get isPaused => false;

  @override
  void preload(Iterable<String?> assets) => preloaded.add(assets.toList());

  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget harness(Widget child, FakeAudio audio) =>
    ChangeNotifierProvider<AudioService>.value(
      value: audio,
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('An Elifba lesson fetches all of its sounds when it opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    for (final lesson in [kElifbaLessons[0], kElifbaLessons[2], kElifbaLessons[6]]) {
      await tester.pumpWidget(
        harness(LessonLettersScreen(key: UniqueKey(), lesson: lesson), audio),
      );
      await tester.pump();
      expect(
        audio.preloaded.last,
        lesson.letters.map((letter) => letter.audioAsset).toList(),
        reason: lesson.title,
      );
      expect(audio.preloaded.last.whereType<String>().length, lesson.letters.length);
    }
  });

  testWidgets('A surah fetches its besmele and every ayet when it opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = FakeAudio();
    addTearDown(audio.dispose);
    final surah = kSureler.first;
    await tester.pumpWidget(harness(SurahDetailScreen(surah: surah), audio));
    await tester.pump();
    expect(audio.preloaded.last, [
      surah.besmeleAudioAsset,
      for (final ayet in surah.ayetler) ayet.audioAsset,
    ]);
    expect(audio.preloaded.last.length, surah.ayetler.length + 1);
  });
}
