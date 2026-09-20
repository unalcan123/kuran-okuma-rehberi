import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders30AudioDir = 'audio/elifba/ders_30_zamir_he_uzatma_yok_cezimli';

/// Ders 30: no medd on the he, this time because a cezimli (sükûnlu) letter follows.
const List<ArabicLetter> kZamirHeUzatmaYokCezimliWords = [
  ArabicLetter(order: 1, isolatedForm: 'إِلَيْهِ رَاجِعُونَ', audioAsset: '$_ders30AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'تَلْقَوْهُ فَقَدْ', audioAsset: '$_ders30AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'فَلْيَصُمْهُ وَمَنْ', audioAsset: '$_ders30AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'مِنْهُ أَكْبَرُ', audioAsset: '$_ders30AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'يُدْخِلْهُ جَنَّاتٍ', audioAsset: '$_ders30AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'أَهْلَكَتْهُ وَمَا', audioAsset: '$_ders30AudioDir/06_kelime.mp3'),
];

final Lesson kZamirHeUzatmaYokCezimliLesson = Lesson(
  id: 'zamir-he-uzatma-yok-cezimli',
  label: 'Ders 30',
  title: 'Zamir (He) - Uzatma Yok (Cezimli)',
  subtitle: '6 kayıt • Cezimli harf öncesinde uzatma yapılmaması',
  letters: kZamirHeUzatmaYokCezimliWords,
);
