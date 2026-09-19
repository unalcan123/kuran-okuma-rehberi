import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders36AudioDir = 'audio/elifba/ders_36_alistirmalar_3';

/// Ders 36: general reading practice, third set.
const List<ArabicLetter> kAlistirmalar3Words = [
  ArabicLetter(order: 1, isolatedForm: 'وَالْحَيٰوةَ', audioAsset: '$_ders36AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'طَٓائِرُكُمْ', audioAsset: '$_ders36AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'مُتَّكِئُونَ', audioAsset: '$_ders36AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'وَالْأَفْئِدَةَ', audioAsset: '$_ders36AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'وَالْمَلَٓئِكَةُ', audioAsset: '$_ders36AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'يَتَسَٓاءَلُونَ', audioAsset: '$_ders36AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'مُسْتَبْشِرَةٌ', audioAsset: '$_ders36AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'مُطَهَّرَةٍ', audioAsset: '$_ders36AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'وَالطَّارِقِ', audioAsset: '$_ders36AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'وَاللَّيْلِ', audioAsset: '$_ders36AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'وَالْفَجْرِ', audioAsset: '$_ders36AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'وَالتَّرَٓائِبِ', audioAsset: '$_ders36AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'بِالْمَرْحَمَةِ', audioAsset: '$_ders36AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'بِالصَّبْرِ', audioAsset: '$_ders36AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'حَقَّ الْقَوْلُ', audioAsset: '$_ders36AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'وَهُوَ الْعَلِىُّ', audioAsset: '$_ders36AudioDir/16_kelime.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'سُبْحَانَ الَّذِى', audioAsset: '$_ders36AudioDir/17_kelime.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'إِلَّا الْبَلاَغُ', audioAsset: '$_ders36AudioDir/18_kelime.mp3'),
];

final Lesson kAlistirmalar3Lesson = Lesson(
  id: 'alistirmalar-3',
  label: 'Ders 36',
  title: 'Alıştırmalar 3',
  subtitle: '18 kayıt • Genel okuma alıştırması',
  letters: kAlistirmalar3Words,
);
