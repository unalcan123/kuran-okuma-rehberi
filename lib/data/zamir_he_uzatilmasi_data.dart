import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders27AudioDir = 'audio/elifba/ders_27_zamir_he_uzatilmasi';

/// Ders 27: the "hu/hi" pronoun's he gets a small silent medd (ٓ) when it falls between two vowelled letters mid-recitation.
const List<ArabicLetter> kZamirHeUzatilmasiWords = [
  ArabicLetter(order: 1, isolatedForm: 'لَمْ يَرَهُٓ أَحَدٌ', audioAsset: '$_ders27AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'رَبُّهُٓ أَسْلِمْ', audioAsset: '$_ders27AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'مَالُهُٓ إِذَا', audioAsset: '$_ders27AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'عَهْدَهُٓ أَمْ', audioAsset: '$_ders27AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'وَلَهُٓ أُخْتٌ', audioAsset: '$_ders27AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'عِلْمِهِٓ إِلَّا', audioAsset: '$_ders27AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'وَإِنَّهُ عَلَى', audioAsset: '$_ders27AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'فَأُ مُّهُ هَاوِيَةٌ', audioAsset: '$_ders27AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'مَا لُهُ وَمَا كَسَبَ', audioAsset: '$_ders27AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'وَا مْرَأَتُهُ حَمَّالَةَ', audioAsset: '$_ders27AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'وَلَمْ يَكُنْ لَهُ كُفُوًا', audioAsset: '$_ders27AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'حَوْلَهُ ذَهَبَ', audioAsset: '$_ders27AudioDir/12_kelime.mp3'),
];

final Lesson kZamirHeUzatilmasiLesson = Lesson(
  id: 'zamir-he-uzatilmasi',
  label: 'Ders 27',
  title: 'Zamir (He) Uzatılması',
  subtitle: '12 kayıt • Hû/hî zamirinin uzatılması',
  letters: kZamirHeUzatilmasiWords,
);
