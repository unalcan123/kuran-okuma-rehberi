import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders18AudioDir = 'audio/elifba/ders_18_ceker_ustun';

/// Ders 18: "çeker üstün" (hançer elif / dagger alif, ٰ) — a small
/// superscript alef standing in for a full elongating elif, found in
/// specific Qur'anic words like "هٰذَا" and "مُوسٰى".
const List<ArabicLetter> kCekerUstunWords = [
  ArabicLetter(order: 1, isolatedForm: 'اَلصَّلَوٰةَ', audioAsset: '$_ders18AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'مُوسٰى', audioAsset: '$_ders18AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'إِلٰهِ', audioAsset: '$_ders18AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'ذٰلِكَ', audioAsset: '$_ders18AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'إِبْرٰهِيمَ', audioAsset: '$_ders18AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'وَإِسْحٰقَ', audioAsset: '$_ders18AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'لِلْمَلَٓئِكَةِ', audioAsset: '$_ders18AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'هٰؤُلَآءِ', audioAsset: '$_ders18AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'اَسَّمٰوَاتِ', audioAsset: '$_ders18AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'إِسْرٰئِيلَ', audioAsset: '$_ders18AudioDir/10_kelime.mp3'),
];

final Lesson kCekerUstunLesson = Lesson(
  id: 'ceker-ustun',
  label: 'Ders 18',
  title: 'Çeker Üstün',
  subtitle: '10 kayıt • Hançer elif ile uzatma',
  letters: kCekerUstunWords,
);
