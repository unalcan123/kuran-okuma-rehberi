import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders32AudioDir = 'audio/elifba/ders_32_kapali_te';

/// Ders 32: the kapalı te (ة) — each pair shows the same word read on, then how it's read at a pause (waqf), where the ة becomes a plain he (ه).
const List<ArabicLetter> kKapaliTeWords = [
  ArabicLetter(order: 1, isolatedForm: 'ثَمَرَةٍ', audioAsset: '$_ders32AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'ثَمَرَهْ', audioAsset: '$_ders32AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'لَيْلَةٍ', audioAsset: '$_ders32AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'لَيْلَهْ', audioAsset: '$_ders32AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'بِقُوَّةٍ', audioAsset: '$_ders32AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'بِقُوَّهْ', audioAsset: '$_ders32AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'اُمَّةٌ', audioAsset: '$_ders32AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'اُمَّهْ', audioAsset: '$_ders32AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'شَهَادَةً', audioAsset: '$_ders32AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'شَهَادَهْ', audioAsset: '$_ders32AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'اَلصَّلَةَ', audioAsset: '$_ders32AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'اَلصَّلَهْ', audioAsset: '$_ders32AudioDir/12_kelime.mp3'),
];

final Lesson kKapaliTeLesson = Lesson(
  id: 'kapali-te',
  label: 'Ders 32',
  title: 'Kapalı Te',
  subtitle: '12 kayıt • Durak hâlinde kapalı tenin okunuşu',
  letters: kKapaliTeWords,
);
