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
   for(final ayah in surah.ayetler) {
    expect(ayah.arabic, source['${numbers[surah.id]}:${ayah.number}']['text']);
   }
  }
  for(final surah in kAllNamazTexts) {
   expect(kSurahMeanings[surah.id]!.keys.toSet(), {'tr','es','fr','de','en','bs','nl'});
   expect(kSurahMeanings[surah.id]!['tr']!.title, 'Suat Yıldırım');
   for(final code in kSurahMeanings[surah.id]!.keys) {
    for(final part in ReadingSegment.ofSurah(surah, languageCode:code).where((p)=>!p.isOpening)) {
     expect(part.meaning, kSurahMeanings[surah.id]![code]!.verses[part.number]);
    }
   }
  }
  expect(kSupplementarySureler.first.ayetler.map((a)=>a.number), List.generate(10,(i)=>31+i));
 });
 test('Full recording plays once without false verse highlighting and supports pause', () async {
  final audio = TestAudioService();
  final segments = ReadingSegment.ofSurah(kSupplementDuha);
  final controller = ReadingPlaybackController(segments:segments, audio:audio, fullAudioAsset:kFullReadingAudio['duha']!);
  await controller.start();
  expect(audio.currentAsset, kFullReadingAudio['duha']);
  expect(controller.plan, hasLength(1));
  expect(controller.activeIndex, isNull);
  await controller.pause();expect(controller.isPaused,isTrue);
  await controller.resume();expect(controller.isPlaying,isTrue);
  audio.complete();expect(controller.isActive,isFalse);
  controller.dispose();await Future<void>.delayed(Duration.zero);audio.dispose();
  for(final path in kFullReadingAudio.values) {expect(File('assets/$path').existsSync(),isTrue);}
  expect(kFullReadingAudio,hasLength(13));
 });
}
