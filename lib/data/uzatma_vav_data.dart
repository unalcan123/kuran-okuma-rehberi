import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders15AudioDir = 'audio/elifba/ders_15_uzatma_vav';

/// Ders 15: each letter with ötre followed by a bare vav — the
/// "uzatma" (medd) that lengthens the vowel, e.g. "بُو" (bû).
const List<ArabicLetter> kUzatmaVavLetters = [
  ArabicLetter(order: 1, isolatedForm: 'ءُو', turkishName: 'Hemze', audioAsset: '$_ders15AudioDir/01_uzatma.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'بُو', turkishName: 'Be', audioAsset: '$_ders15AudioDir/02_uzatma.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'تُو', turkishName: 'Te', audioAsset: '$_ders15AudioDir/03_uzatma.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'ثُو', turkishName: 'Se', audioAsset: '$_ders15AudioDir/04_uzatma.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'جُو', turkishName: 'Cim', audioAsset: '$_ders15AudioDir/05_uzatma.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'حُو', turkishName: 'Ha', audioAsset: '$_ders15AudioDir/06_uzatma.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'خُو', turkishName: 'Hı', isHeavyLetter: true, audioAsset: '$_ders15AudioDir/07_uzatma.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'دُو', turkishName: 'Dal', audioAsset: '$_ders15AudioDir/08_uzatma.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'ذُو', turkishName: 'Zel', audioAsset: '$_ders15AudioDir/09_uzatma.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'رُو', turkishName: 'Ra', audioAsset: '$_ders15AudioDir/10_uzatma.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'زُو', turkishName: 'Ze', audioAsset: '$_ders15AudioDir/11_uzatma.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'سُو', turkishName: 'Sin', audioAsset: '$_ders15AudioDir/12_uzatma.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'شُو', turkishName: 'Şın', audioAsset: '$_ders15AudioDir/13_uzatma.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'صُو', turkishName: 'Sad', isHeavyLetter: true, audioAsset: '$_ders15AudioDir/14_uzatma.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'ضُو', turkishName: 'Dad', isHeavyLetter: true, audioAsset: '$_ders15AudioDir/15_uzatma.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'طُو', turkishName: 'Tı', isHeavyLetter: true, audioAsset: '$_ders15AudioDir/16_uzatma.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'ظُو', turkishName: 'Zı', isHeavyLetter: true, audioAsset: '$_ders15AudioDir/17_uzatma.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'عُو', turkishName: 'Ayn', audioAsset: '$_ders15AudioDir/18_uzatma.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'غُو', turkishName: 'Gayn', isHeavyLetter: true, audioAsset: '$_ders15AudioDir/19_uzatma.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'فُو', turkishName: 'Fe', audioAsset: '$_ders15AudioDir/20_uzatma.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'قُو', turkishName: 'Kaf', isHeavyLetter: true, audioAsset: '$_ders15AudioDir/21_uzatma.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'كُو', turkishName: 'Kef', audioAsset: '$_ders15AudioDir/22_uzatma.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'لُو', turkishName: 'Lam', audioAsset: '$_ders15AudioDir/23_uzatma.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'مُو', turkishName: 'Mim', audioAsset: '$_ders15AudioDir/24_uzatma.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'نُو', turkishName: 'Nun', audioAsset: '$_ders15AudioDir/25_uzatma.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'وُو', turkishName: 'Vav', audioAsset: '$_ders15AudioDir/26_uzatma.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'هـُو', turkishName: 'He', audioAsset: '$_ders15AudioDir/27_uzatma.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'يُو', turkishName: 'Ye', audioAsset: '$_ders15AudioDir/28_uzatma.mp3'),
];

final Lesson kUzatmaVavLesson = Lesson(
  id: 'uzatma-vav',
  label: 'Ders 15',
  title: 'Uzatma Harfleri - Vav',
  subtitle: '28 kayıt • Ötre + vav ile uzatma',
  letters: kUzatmaVavLetters,
);
