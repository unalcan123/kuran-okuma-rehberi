import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders26AudioDir = 'audio/elifba/ders_26_el_takisi_hemze_vasil';

/// Ders 26: hemze-i vasıl (connecting hemze) — each pair shows the word's stand-alone form, then how the same hemze is elided (ٱ) once it's connected to what comes before it.
const List<ArabicLetter> kElTakisiHemzeVasilWords = [
  ArabicLetter(order: 1, isolatedForm: 'اَللّٰهُ', audioAsset: '$_ders26AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'وَٱللّٰهُ', audioAsset: '$_ders26AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'اِذْهَبْ', audioAsset: '$_ders26AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'فَٱذْهَبْ', audioAsset: '$_ders26AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'اِغْفِرْ', audioAsset: '$_ders26AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'وَٱغْفِرْ', audioAsset: '$_ders26AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'اَلَّذِى', audioAsset: '$_ders26AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'وَٱلَّذِي', audioAsset: '$_ders26AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'اِهْبِطُوا', audioAsset: '$_ders26AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'قُلْنَا ٱهْبِطُوا', audioAsset: '$_ders26AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'اِمْرِئٍ', audioAsset: '$_ders26AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'لِكُلِّ ٱمْرِئٍ', audioAsset: '$_ders26AudioDir/12_kelime.mp3'),
];

final Lesson kElTakisiHemzeVasilLesson = Lesson(
  id: 'el-takisi-hemze-vasil',
  label: 'Ders 26',
  title: 'El Takısı - Hemze-i Vasıl',
  subtitle: '12 kayıt • Yalın ve bitişik hemze-i vasıl karşılaştırması',
  letters: kElTakisiHemzeVasilWords,
);
