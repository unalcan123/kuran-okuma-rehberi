import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuran_okuma_rehberi/data/reading_word_timings.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/data/additional_dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/supplementary_sureler_data.dart';
import 'package:kuran_okuma_rehberi/models/reading_segment.dart';
import 'package:kuran_okuma_rehberi/services/reading_playback_controller.dart';
import 'package:kuran_okuma_rehberi/services/reading_settings.dart';
import 'package:kuran_okuma_rehberi/widgets/reading_arabic_text.dart';
import 'dualar_test.dart' show TestAudioService;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReadingSettings.instance.resetForTest();
  });
  testWidgets('Highlight follows media position, pauses, repeats and clears', (
    tester,
  ) async {
    final audio = TestAudioService();
    final parts = ReadingSegment.ofSurah(kSureler.first);
    final player = ReadingPlaybackController(segments: parts, audio: audio);
    final words = readingWordTimings(parts.first);
    expect(words.length, 4);
    await player.playFromStart(0);
    expect(player.activeWord, isNull); // loading is not playback
    audio.position = Duration(milliseconds: words[1].startMs + 1);
    await tester.pump(const Duration(milliseconds: 40));
    expect(player.activeWord, same(words[1]));
    await player.pause();
    expect(player.activeWord, isNull);
    await tester.pump(const Duration(seconds: 2));
    expect(player.activeWord, isNull);
    await player.resume();
    await tester.pump(const Duration(milliseconds: 40));
    expect(player.activeWord, same(words[1]));
    // Media position already includes speed changes; no wall-clock estimate.
    ReadingSettings.instance.speed = 1.25;
    audio.position = Duration(milliseconds: words[3].startMs + 1);
    await tester.pump(const Duration(milliseconds: 40));
    expect(player.activeWord, same(words[3]));
    audio.position = Duration(milliseconds: words.first.startMs + 1);
    await player.playFromStart(0);
    expect(player.activeWord, same(words.first));
    await player.stop();
    expect(player.activeWord, isNull);
    player.dispose();
    await tester.pump();
    audio.dispose();
  });

  testWidgets('Arabic glyphs and whitespace survive word highlighting', (
    tester,
  ) async {
    const arabic = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingArabicText(
            arabic,
            style: TextStyle(fontSize: 39),
            highlightStart: 0,
            highlightEnd: 6,
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text(arabic));
    expect(text.textSpan!.toPlainText(), arabic);
    final spans = (text.textSpan as TextSpan).children!;
    expect(
      (spans[1] as TextSpan).style!.backgroundColor,
      const Color(0xFFFFE49A),
    );
    expect(text.textDirection, TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The highlighted word scrolls into view inside a long passage', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final text = List.filled(100, 'الرَّحْمٰنِ').join(' ');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 180,
            width: 260,
            child: SingleChildScrollView(
              controller: scroll,
              child: ReadingArabicText(
                text,
                style: const TextStyle(fontSize: 40, height: 1.9),
                highlightStart: text.lastIndexOf('الرَّحْمٰنِ'),
                highlightEnd: text.length,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(100));
    expect(tester.takeException(), isNull);
  });

  test('Timing data has valid word boundaries and no overlap', () {
    for (final entry in kReadingWordTimings.entries) {
      final text = entry.key.substring(entry.key.indexOf('|') + 1);
      var lastEnd = 0;
      for (final word in entry.value) {
        expect(word.startMs, greaterThanOrEqualTo(lastEnd));
        expect(word.endMs, greaterThan(word.startMs));
        expect(text.substring(word.start, word.end).trim(), isNotEmpty);
        lastEnd = word.endMs;
      }
    }
  });

  test('Every existing surah and prayer recording has word timings', () {
    final segments = [
      for (final surah in kAllNamazTexts) ...ReadingSegment.ofSurah(surah),
      for (final dua in kAllDualar) ...ReadingSegment.ofDua(dua),
    ];
    for (final part in segments.where((part) => part.audioAsset.isNotEmpty)) {
      final words = readingWordTimings(part);
      expect(words, isNotEmpty, reason: part.audioAsset);
      expect(words.length, RegExp(r'\S+').allMatches(part.arabic).length);
    }
  });
}
