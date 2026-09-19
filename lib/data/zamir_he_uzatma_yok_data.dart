import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders29AudioDir = 'audio/elifba/ders_29_zamir_he_uzatma_yok';

/// Ders 29: the "hu/hi" pronoun's he stays short — no medd — when what follows breaks the vowel-vowel condition.
const List<ArabicLetter> kZamirHeUzatmaYokWords = [
  ArabicLetter(order: 1, isolatedForm: 'رَدَدْنَاهُ أَسْفَلَ', audioAsset: '$_ders29AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'أَنْزَلْنَاهُ فِى', audioAsset: '$_ders29AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'فِيهِ هُدًى', audioAsset: '$_ders29AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'بَنِيهِ وَيَعْقُوبُ', audioAsset: '$_ders29AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'عَقَلُوهُ وَهُمْ', audioAsset: '$_ders29AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'تَكْتُبُوهُ صَغِيرًا', audioAsset: '$_ders29AudioDir/06_kelime.mp3'),
];

final Lesson kZamirHeUzatmaYokLesson = Lesson(
  id: 'zamir-he-uzatma-yok',
  label: 'Ders 29',
  title: 'Zamir (He) - Uzatma Yok',
  subtitle: '6 kayıt • Uzatma yapılmayan hâller',
  letters: kZamirHeUzatmaYokWords,
);
