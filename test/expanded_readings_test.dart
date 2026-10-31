import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/full_reading_audio.dart';
import 'package:kuran_okuma_rehberi/data/supplementary_sureler_data.dart';
import 'package:kuran_okuma_rehberi/data/surah_meanings.dart';
import 'package:kuran_okuma_rehberi/models/reading_segment.dart';
import 'package:kuran_okuma_rehberi/services/reading_playback_controller.dart';
import 'dualar_test.dart' show TestAudioService;
void main() {
 test('All new readings preserve Diyanet Arabic and seven published editions', () {
  final source = jsonDecode(File('tool/sources/diyanet_arabic_extract.json').readAsStringSync()) as Map;
  final numbers = {'nebe-son':78,'duha':93,'insirah':94,'tin':95,'kadir':97,'zilzal':99,'adiyat':100,'karia':101,'tekasur':102,'asr':103,'humeze':104};
  for(final surah in kSupplementarySureler) {
   for(final (i, ayah) in surah.ayetler.indexed) {
    if (ayah.verse == null) {
     expect(ayah.arabic, source['${numbers[surah.id]}:${ayah.number}']['text']);
     continue;
    }
    // Read in phrases (Nebe, like its recording): each phrase is part of
    // its verse; the verse's first phrase starts it, its last one ends it.
    final verse = source['${numbers[surah.id]}:${ayah.verse}']['text'] as String;
    expect(verse, contains(ayah.arabic));
    if (i == 0 || surah.ayetler[i-1].verse != ayah.verse) expect(verse, startsWith(ayah.arabic));
    if (i == surah.ayetler.length-1 || surah.ayetler[i+1].verse != ayah.verse) expect(verse, endsWith(ayah.arabic));
   }
  }
  for(final surah in kAllNamazTexts) {
   expect(kSurahMeanings[surah.id]!.keys.toSet(), {'tr','es','fr','de','en','bs','nl'});
   expect(kSurahMeanings[surah.id]!['tr']!.title, 'Suat Yıldırım');
   for(final code in kSurahMeanings[surah.id]!.keys) {
    if (surah.ayetler.any((a)=>a.verse != null)) {
     // Verses read in phrases: Turkish meal split with them; other
     // languages: the whole verse on its first phrase, the rest empty.
     final parts = ReadingSegment.ofSurah(surah, languageCode:code).where((p)=>!p.isOpening).toList();
     expect(parts.map((p)=>p.number).toSet(), surah.ayetler.map((a)=>a.verse).toSet());
     for (var i = 0; i < parts.length; i++) {
      final first = i == 0 || parts[i-1].number != parts[i].number;
      if (code == 'tr') {
       expect(parts[i].meaning, isNotEmpty);
      } else {
       expect(parts[i].meaning, first ? kSurahMeanings[surah.id]![code]!.verses[parts[i].number] : '');
      }
     }
     continue;
    }
    for(final part in ReadingSegment.ofSurah(surah, languageCode:code).where((p)=>!p.isOpening)) {
     expect(part.meaning, kSurahMeanings[surah.id]![code]!.verses[part.number]);
    }
   }
  }
  expect(kSupplementarySureler.first.ayetler.map((a)=>a.verse).toSet(), List.generate(10,(i)=>31+i).toSet());
 });
 test('Full recording plays once without false verse highlighting and supports pause', () async {
  final audio = TestAudioService();
  final segments = ReadingSegment.ofSurah(kSupplementKadir);
  // A complete recording (none ships now; the engine still supports one).
  const full = 'audio/full_readings/test.mp3';
  final controller = ReadingPlaybackController(segments:segments, audio:audio, fullAudioAsset:full);
  await controller.start();
  expect(audio.currentAsset, full);
  expect(controller.plan, hasLength(1));
  expect(controller.activeIndex, isNull);
  await controller.pause();expect(controller.isPaused,isTrue);
  await controller.resume();expect(controller.isPlaying,isTrue);
  audio.complete();expect(controller.isActive,isFalse);
  controller.dispose();await Future<void>.delayed(Duration.zero);audio.dispose();
  for(final path in kFullReadingAudio.values) {expect(File('assets/$path').existsSync(),isTrue);}
  expect(kFullReadingAudio, isEmpty);
 });
  test('waqf signs without a glyph in Hasenat are not drawn', () {
    // Kadir 5 (qif), Tîn 4 and Hümeze 4 (small high zain): the data keeps
    // them, the screen leaves them out.
    for (final surah in kAllNamazTexts) {
      for (final part in ReadingSegment.ofSurah(surah)) {
        expect(part.arabic, isNot(contains('ࣞ')), reason: surah.id);
        expect(part.arabic, isNot(contains('ؗ')), reason: surah.id);
      }
    }
    expect(kSupplementKadir.ayetler.last.arabic, contains('ࣞ'));
  });
}
