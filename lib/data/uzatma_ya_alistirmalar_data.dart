import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders14AudioDir = 'audio/elifba/ders_14_uzatma_ya_alistirmalar';

/// Ders 14: practice words carrying the ye uzatması (medd) learned in
/// Ders 13.
const List<ArabicLetter> kUzatmaYaAlistirmalariWords = [
  ArabicLetter(order: 1, isolatedForm: 'إِي', audioAsset: '$_ders14AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'أَبِي', audioAsset: '$_ders14AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'وَالِدَتِي', audioAsset: '$_ders14AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'مَاكِثِينَ', audioAsset: '$_ders14AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'يُجِيرُ', audioAsset: '$_ders14AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'حِينَ', audioAsset: '$_ders14AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'أَخِيهِ', audioAsset: '$_ders14AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'حَدِيثُ', audioAsset: '$_ders14AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'آخِذِيهِ', audioAsset: '$_ders14AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'سَرِيعُ', audioAsset: '$_ders14AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'زِينَةَ', audioAsset: '$_ders14AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'سِيءَ', audioAsset: '$_ders14AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'خَشِيتُ', audioAsset: '$_ders14AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'يُصِيبُ', audioAsset: '$_ders14AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'يُضِيعُ', audioAsset: '$_ders14AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'أَسَاطِيرُ', audioAsset: '$_ders14AudioDir/16_kelime.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'حَافِظِينَ', audioAsset: '$_ders14AudioDir/17_kelime.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'أَرْبَعِينَ', audioAsset: '$_ders14AudioDir/18_kelime.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'يَغِيظُ', audioAsset: '$_ders14AudioDir/19_kelime.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'فِيهَا', audioAsset: '$_ders14AudioDir/20_kelime.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'قِيلَ', audioAsset: '$_ders14AudioDir/21_kelime.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'تَذْكِيرِي', audioAsset: '$_ders14AudioDir/22_kelime.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'فَاعِلِينَ', audioAsset: '$_ders14AudioDir/23_kelime.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'تَمِيدَ', audioAsset: '$_ders14AudioDir/24_kelime.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'بَنِينَ', audioAsset: '$_ders14AudioDir/25_kelime.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'تَأْوِيلُ', audioAsset: '$_ders14AudioDir/26_kelime.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'نُهِيتُ', audioAsset: '$_ders14AudioDir/27_kelime.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'يُحْيِيكُمْ', audioAsset: '$_ders14AudioDir/28_kelime.mp3'),
];

final Lesson kUzatmaYaAlistirmalariLesson = Lesson(
  id: 'uzatma-ya-alistirmalari',
  label: 'Ders 14',
  title: 'Uzatma Harfleri - Ya Alıştırmaları',
  subtitle: '28 kayıt • Ye uzatmalı kelime okuma',
  letters: kUzatmaYaAlistirmalariWords,
);
