import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders16AudioDir = 'audio/elifba/ders_16_uzatma_vav_alistirmalar';

/// Ders 16: practice words carrying the vav uzatması (medd) learned
/// in Ders 15.
const List<ArabicLetter> kUzatmaVavAlistirmalariWords = [
  ArabicLetter(order: 1, isolatedForm: 'أُوتُوا', audioAsset: '$_ders16AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'أَبُوكِ', audioAsset: '$_ders16AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'تُوبُوا', audioAsset: '$_ders16AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'يَرِثُونَ', audioAsset: '$_ders16AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'يَرْجُونَ', audioAsset: '$_ders16AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'فَرِحُونَ', audioAsset: '$_ders16AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'نَخُوضُ', audioAsset: '$_ders16AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'دُونِ', audioAsset: '$_ders16AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'خُذُوا', audioAsset: '$_ders16AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'هَارُونَ', audioAsset: '$_ders16AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'بَارِزُونَ', audioAsset: '$_ders16AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'رَسُولُ', audioAsset: '$_ders16AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'تَمْشُونَ', audioAsset: '$_ders16AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'تُوصُونَ', audioAsset: '$_ders16AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'رَضُوا', audioAsset: '$_ders16AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'بُطُونِ', audioAsset: '$_ders16AudioDir/16_kelime.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'حَافِظُونَ', audioAsset: '$_ders16AudioDir/17_kelime.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'أَعُوذُ', audioAsset: '$_ders16AudioDir/18_kelime.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'يَبْغُونَ', audioAsset: '$_ders16AudioDir/19_kelime.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'يَخْلُفُونَ', audioAsset: '$_ders16AudioDir/20_kelime.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'تَقُومُ', audioAsset: '$_ders16AudioDir/21_kelime.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'لِتَكُونَ', audioAsset: '$_ders16AudioDir/22_kelime.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'يَعْمَلُونَ', audioAsset: '$_ders16AudioDir/23_kelime.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'تَعْلَمُونَ', audioAsset: '$_ders16AudioDir/24_kelime.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'نُورُهُمْ', audioAsset: '$_ders16AudioDir/25_kelime.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'يَلْوُونَ', audioAsset: '$_ders16AudioDir/26_kelime.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'تَفْقَهُونَ', audioAsset: '$_ders16AudioDir/27_kelime.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'يُولِجُ', audioAsset: '$_ders16AudioDir/28_kelime.mp3'),
];

final Lesson kUzatmaVavAlistirmalariLesson = Lesson(
  id: 'uzatma-vav-alistirmalari',
  label: 'Ders 16',
  title: 'Uzatma Harfleri - Vav Alıştırmaları',
  subtitle: '28 kayıt • Vav uzatmalı kelime okuma',
  letters: kUzatmaVavAlistirmalariWords,
);
