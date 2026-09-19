import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders25AudioDir = 'audio/elifba/ders_25_el_takisi_hemze';

/// Ders 25: the definite article meeting a hemze-initial word.
const List<ArabicLetter> kElTakisiHemzeWords = [
  ArabicLetter(order: 1, isolatedForm: 'وَالْعَصْرِ', audioAsset: '$_ders25AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'مَا الْقَارِعَةُ', audioAsset: '$_ders25AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'هُوَ الْمَلِكُ', audioAsset: '$_ders25AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'وَالنُّورِ', audioAsset: '$_ders25AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'بِالتَّقْوٰى', audioAsset: '$_ders25AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'وَالسَّابِحَاتِ', audioAsset: '$_ders25AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'اَلنُّورِ', audioAsset: '$_ders25AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'اَلْقَارِعَةُ', audioAsset: '$_ders25AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'اَلْمَلِكُ', audioAsset: '$_ders25AudioDir/09_kelime.mp3'),
];

final Lesson kElTakisiHemzeLesson = Lesson(
  id: 'el-takisi-hemze',
  label: 'Ders 25',
  title: 'El Takısı ve Hemze',
  subtitle: '9 kayıt • El takısı ve hemzeli kelime okuma',
  letters: kElTakisiHemzeWords,
);
