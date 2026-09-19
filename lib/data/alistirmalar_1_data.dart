import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders34AudioDir = 'audio/elifba/ders_34_alistirmalar_1';

/// Ders 34: general reading practice, first set.
const List<ArabicLetter> kAlistirmalar1Words = [
  ArabicLetter(order: 1, isolatedForm: 'فَبَشِّرْهُ', audioAsset: '$_ders34AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'أَحْصَيْنَاهُ', audioAsset: '$_ders34AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'فَعَزَّزْنَا', audioAsset: '$_ders34AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'وَفَجَّرْنَا', audioAsset: '$_ders34AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'أَحْيَيْنَاهَا', audioAsset: '$_ders34AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'تَسْنِيمٍ', audioAsset: '$_ders34AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'ذُرِّيَّتَهُمْ', audioAsset: '$_ders34AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'يَخِصِّمُونَ', audioAsset: '$_ders34AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'تَبَارَكَ', audioAsset: '$_ders34AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'غُفْرَانَكَ', audioAsset: '$_ders34AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'كَرَّتَيْنِ', audioAsset: '$_ders34AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'كُوِّرَتْ', audioAsset: '$_ders34AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'مَنَاكِبِهَا', audioAsset: '$_ders34AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'بِيَمِينِهِ', audioAsset: '$_ders34AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'فَأَنْبَتْنَا', audioAsset: '$_ders34AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'يَزَّكَّى', audioAsset: '$_ders34AudioDir/16_kelime.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'مُخْتَلِفُونَ', audioAsset: '$_ders34AudioDir/17_kelime.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'جَنَّاتٌ', audioAsset: '$_ders34AudioDir/18_kelime.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'فَصَلّٰى', audioAsset: '$_ders34AudioDir/19_kelime.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'وَتَوَاصَوْا', audioAsset: '$_ders34AudioDir/20_kelime.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'فَذَكِّرْ', audioAsset: '$_ders34AudioDir/21_kelime.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'يَسْأَلُونَكَ', audioAsset: '$_ders34AudioDir/22_kelime.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'يُدْرِيكَ', audioAsset: '$_ders34AudioDir/23_kelime.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'فَسَوَّاكَ', audioAsset: '$_ders34AudioDir/24_kelime.mp3'),
];

final Lesson kAlistirmalar1Lesson = Lesson(
  id: 'alistirmalar-1',
  label: 'Ders 34',
  title: 'Alıştırmalar 1',
  subtitle: '24 kayıt • Genel okuma alıştırması',
  letters: kAlistirmalar1Words,
);
