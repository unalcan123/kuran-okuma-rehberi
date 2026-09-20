import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders31AudioDir = 'audio/elifba/ders_31_zamir_he_uzatma_yok_cezimli_seddeli';

/// Ders 31: no medd on the he, here alongside a şeddeli el takısı meeting, e.g. "أَنَّهُ الْحَقُّ".
const List<ArabicLetter> kZamirHeUzatmaYokCezimliSeddeliWords = [
  ArabicLetter(order: 1, isolatedForm: 'أَنَّهُ الْحَقُّ', audioAsset: '$_ders31AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'لَهُ الْمُلْكُ', audioAsset: '$_ders31AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'لَهُ اتَّقِ اللَّهَ', audioAsset: '$_ders31AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'هَذِهِ الْقَرْيَةِ', audioAsset: '$_ders31AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'لِقَوْمِهِ اسْتَعِينُوا', audioAsset: '$_ders31AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'بِهِ الْمَآءَ', audioAsset: '$_ders31AudioDir/06_kelime.mp3'),
];

final Lesson kZamirHeUzatmaYokCezimliSeddeliLesson = Lesson(
  id: 'zamir-he-uzatma-yok-cezimli-seddeli',
  label: 'Ders 31',
  title: 'Zamir (He) - Uzatma Yok (Cezimli, Şeddeli)',
  subtitle: '6 kayıt • Şeddeli el takısıyla uzatma yapılmaması',
  letters: kZamirHeUzatmaYokCezimliSeddeliWords,
);
