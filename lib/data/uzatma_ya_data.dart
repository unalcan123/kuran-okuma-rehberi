import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders13AudioDir = 'audio/elifba/ders_13_uzatma_ya';

/// Ders 13: each letter with esre followed by a bare ye — the
/// "uzatma" (medd) that lengthens the vowel, e.g. "بِي" (bî).
const List<ArabicLetter> kUzatmaYaLetters = [
  ArabicLetter(order: 1, isolatedForm: 'إِي', turkishName: 'Elif', audioAsset: '$_ders13AudioDir/01_uzatma.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'بِي', turkishName: 'Be', audioAsset: '$_ders13AudioDir/02_uzatma.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'تِي', turkishName: 'Te', audioAsset: '$_ders13AudioDir/03_uzatma.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'ثِي', turkishName: 'Se', audioAsset: '$_ders13AudioDir/04_uzatma.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'جِي', turkishName: 'Cim', audioAsset: '$_ders13AudioDir/05_uzatma.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'حِي', turkishName: 'Ha', audioAsset: '$_ders13AudioDir/06_uzatma.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'خِي', turkishName: 'Hı', isHeavyLetter: true, audioAsset: '$_ders13AudioDir/07_uzatma.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'دِي', turkishName: 'Dal', audioAsset: '$_ders13AudioDir/08_uzatma.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'ذِي', turkishName: 'Zel', audioAsset: '$_ders13AudioDir/09_uzatma.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'رِي', turkishName: 'Ra', audioAsset: '$_ders13AudioDir/10_uzatma.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'زِي', turkishName: 'Ze', audioAsset: '$_ders13AudioDir/11_uzatma.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'سِي', turkishName: 'Sin', audioAsset: '$_ders13AudioDir/12_uzatma.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'شِي', turkishName: 'Şın', audioAsset: '$_ders13AudioDir/13_uzatma.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'صِي', turkishName: 'Sad', isHeavyLetter: true, audioAsset: '$_ders13AudioDir/14_uzatma.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'ضِي', turkishName: 'Dad', isHeavyLetter: true, audioAsset: '$_ders13AudioDir/15_uzatma.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'طِي', turkishName: 'Tı', isHeavyLetter: true, audioAsset: '$_ders13AudioDir/16_uzatma.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'ظِي', turkishName: 'Zı', isHeavyLetter: true, audioAsset: '$_ders13AudioDir/17_uzatma.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'عِي', turkishName: 'Ayn', audioAsset: '$_ders13AudioDir/18_uzatma.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'غِي', turkishName: 'Gayn', isHeavyLetter: true, audioAsset: '$_ders13AudioDir/19_uzatma.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'فِي', turkishName: 'Fe', audioAsset: '$_ders13AudioDir/20_uzatma.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'قِي', turkishName: 'Kaf', isHeavyLetter: true, audioAsset: '$_ders13AudioDir/21_uzatma.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'كِي', turkishName: 'Kef', audioAsset: '$_ders13AudioDir/22_uzatma.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'لِي', turkishName: 'Lam', audioAsset: '$_ders13AudioDir/23_uzatma.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'مِي', turkishName: 'Mim', audioAsset: '$_ders13AudioDir/24_uzatma.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'نِي', turkishName: 'Nun', audioAsset: '$_ders13AudioDir/25_uzatma.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'هـِي', turkishName: 'He', audioAsset: '$_ders13AudioDir/26_uzatma.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'وِي', turkishName: 'Vav', audioAsset: '$_ders13AudioDir/27_uzatma.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'يِي', turkishName: 'Ye', audioAsset: '$_ders13AudioDir/28_uzatma.mp3'),
];

final Lesson kUzatmaYaLesson = Lesson(
  id: 'uzatma-ya',
  label: 'Ders 13',
  title: 'Uzatma Harfleri - Ya',
  subtitle: '28 kayıt • Esre + ye ile uzatma',
  letters: kUzatmaYaLetters,
);
