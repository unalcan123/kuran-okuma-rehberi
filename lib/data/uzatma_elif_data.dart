import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders11AudioDir = 'audio/elifba/ders_11_uzatma_elif';

/// Ders 11: each letter with üstün followed by a bare elif — the
/// "uzatma" (medd) that lengthens the vowel, e.g. "بَا" (bâ).
const List<ArabicLetter> kUzatmaElifLetters = [
  ArabicLetter(order: 1, isolatedForm: 'ءَا', turkishName: 'Hemze', audioAsset: '$_ders11AudioDir/01_uzatma.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'بَا', turkishName: 'Be', audioAsset: '$_ders11AudioDir/02_uzatma.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'تَا', turkishName: 'Te', audioAsset: '$_ders11AudioDir/03_uzatma.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'ثَا', turkishName: 'Se', audioAsset: '$_ders11AudioDir/04_uzatma.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'جَا', turkishName: 'Cim', audioAsset: '$_ders11AudioDir/05_uzatma.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'حَا', turkishName: 'Ha', audioAsset: '$_ders11AudioDir/06_uzatma.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'خَا', turkishName: 'Hı', isHeavyLetter: true, audioAsset: '$_ders11AudioDir/07_uzatma.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'دَا', turkishName: 'Dal', audioAsset: '$_ders11AudioDir/08_uzatma.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'ذَا', turkishName: 'Zel', audioAsset: '$_ders11AudioDir/09_uzatma.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'رَا', turkishName: 'Ra', audioAsset: '$_ders11AudioDir/10_uzatma.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'زَا', turkishName: 'Ze', audioAsset: '$_ders11AudioDir/11_uzatma.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'سَا', turkishName: 'Sin', audioAsset: '$_ders11AudioDir/12_uzatma.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'شَا', turkishName: 'Şın', audioAsset: '$_ders11AudioDir/13_uzatma.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'صَا', turkishName: 'Sad', isHeavyLetter: true, audioAsset: '$_ders11AudioDir/14_uzatma.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'ضَا', turkishName: 'Dad', isHeavyLetter: true, audioAsset: '$_ders11AudioDir/15_uzatma.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'طَا', turkishName: 'Tı', isHeavyLetter: true, audioAsset: '$_ders11AudioDir/16_uzatma.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'ظَا', turkishName: 'Zı', isHeavyLetter: true, audioAsset: '$_ders11AudioDir/17_uzatma.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'عَا', turkishName: 'Ayn', audioAsset: '$_ders11AudioDir/18_uzatma.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'غَا', turkishName: 'Gayn', isHeavyLetter: true, audioAsset: '$_ders11AudioDir/19_uzatma.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'فَا', turkishName: 'Fe', audioAsset: '$_ders11AudioDir/20_uzatma.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'قَا', turkishName: 'Kaf', isHeavyLetter: true, audioAsset: '$_ders11AudioDir/21_uzatma.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'كَا', turkishName: 'Kef', audioAsset: '$_ders11AudioDir/22_uzatma.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'لَا', turkishName: 'Lam', audioAsset: '$_ders11AudioDir/23_uzatma.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'مَا', turkishName: 'Mim', audioAsset: '$_ders11AudioDir/24_uzatma.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'نَا', turkishName: 'Nun', audioAsset: '$_ders11AudioDir/25_uzatma.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'وَا', turkishName: 'Vav', audioAsset: '$_ders11AudioDir/26_uzatma.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'هـَا', turkishName: 'He', audioAsset: '$_ders11AudioDir/27_uzatma.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'يَا', turkishName: 'Ye', audioAsset: '$_ders11AudioDir/28_uzatma.mp3'),
];

final Lesson kUzatmaElifLesson = Lesson(
  id: 'uzatma-elif',
  label: 'Ders 11',
  title: 'Uzatma Harfleri - Elif',
  subtitle: '28 kayıt • Üstün + elif ile uzatma',
  letters: kUzatmaElifLetters,
);
