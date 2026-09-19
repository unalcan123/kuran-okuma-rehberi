import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders28AudioDir = 'audio/elifba/ders_28_zamir_he_uzatma_med';

/// Ders 28: a related case marked with the small madda (ٓ) sign, e.g. "الْمَلٓئِكَةُ".
const List<ArabicLetter> kZamirHeUzatmaMedWords = [
  ArabicLetter(order: 1, isolatedForm: 'اَلْمَلٓئِكَةُ', audioAsset: '$_ders28AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'سُوٓءَ', audioAsset: '$_ders28AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'وَلَاالضَّٓالِّينَ', audioAsset: '$_ders28AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'يٰسٓ', audioAsset: '$_ders28AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'نٓ', audioAsset: '$_ders28AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'صٓ', audioAsset: '$_ders28AudioDir/06_kelime.mp3'),
];

final Lesson kZamirHeUzatmaMedLesson = Lesson(
  id: 'zamir-he-uzatma-med',
  label: 'Ders 28',
  title: 'Zamir (He) - Med İle Uzatma',
  subtitle: '6 kayıt • Med işaretiyle uzatma',
  letters: kZamirHeUzatmaMedWords,
);
