import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders12AudioDir = 'audio/elifba/ders_12_uzatma_elif_alistirmalar';

/// Ders 12: practice words carrying the elif uzatması (medd) learned
/// in Ders 11.
const List<ArabicLetter> kUzatmaElifAlistirmalariWords = [
  ArabicLetter(order: 1, isolatedForm: 'ءَامَنَ', audioAsset: '$_ders12AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'بَالُ', audioAsset: '$_ders12AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'تَابَ', audioAsset: '$_ders12AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'ثَالِثُ', audioAsset: '$_ders12AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'جَاءَ', audioAsset: '$_ders12AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'حَاشَ', audioAsset: '$_ders12AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'خَافَ', audioAsset: '$_ders12AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'دَارَ', audioAsset: '$_ders12AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'ذَاتَ', audioAsset: '$_ders12AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'رَانَ', audioAsset: '$_ders12AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'زَاغَ', audioAsset: '$_ders12AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'سَاءَ', audioAsset: '$_ders12AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'شَاءَ', audioAsset: '$_ders12AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'صَادِقَ', audioAsset: '$_ders12AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'ضَاقَتْ', audioAsset: '$_ders12AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'طَالَ', audioAsset: '$_ders12AudioDir/16_kelime.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'ظَاهِرَ', audioAsset: '$_ders12AudioDir/17_kelime.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'عاَدَ', audioAsset: '$_ders12AudioDir/18_kelime.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'غَالِبَ', audioAsset: '$_ders12AudioDir/19_kelime.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'فَازَ', audioAsset: '$_ders12AudioDir/20_kelime.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'قَالَ', audioAsset: '$_ders12AudioDir/21_kelime.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'كَانَ', audioAsset: '$_ders12AudioDir/22_kelime.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'لاَ', audioAsset: '$_ders12AudioDir/23_kelime.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'مَالِ', audioAsset: '$_ders12AudioDir/24_kelime.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'نَارُ', audioAsset: '$_ders12AudioDir/25_kelime.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'سَوَاءِ', audioAsset: '$_ders12AudioDir/26_kelime.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'هَاجَرَ', audioAsset: '$_ders12AudioDir/27_kelime.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'يَا', audioAsset: '$_ders12AudioDir/28_kelime.mp3'),
];

final Lesson kUzatmaElifAlistirmalariLesson = Lesson(
  id: 'uzatma-elif-alistirmalari',
  label: 'Ders 12',
  title: 'Uzatma Harfleri - Elif Alıştırmaları',
  subtitle: '28 kayıt • Elif uzatmalı kelime okuma',
  letters: kUzatmaElifAlistirmalariWords,
);
