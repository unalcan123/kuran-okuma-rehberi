import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders17AudioDir = 'audio/elifba/ders_17_uzatma_vav_kelime_sonunda';

/// Ders 17: vav uzatması landing at the very end of a word (the
/// "vav-ı cemi" pattern common in plural verb forms), a specific case
/// worth its own short practice set.
const List<ArabicLetter> kUzatmaVavKelimeSonundaWords = [
  ArabicLetter(order: 1, isolatedForm: 'اُمِرُوا', audioAsset: '$_ders17AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'وَأْتُوا', audioAsset: '$_ders17AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'كَزَّبُوا', audioAsset: '$_ders17AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'نَقَمُوا', audioAsset: '$_ders17AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'يَتُوبُوا', audioAsset: '$_ders17AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'لِيَعْبُدُوا', audioAsset: '$_ders17AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'رُزِقُوا', audioAsset: '$_ders17AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'يَتْلُوا', audioAsset: '$_ders17AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'اَلْقُوا', audioAsset: '$_ders17AudioDir/09_kelime.mp3'),
];

final Lesson kUzatmaVavKelimeSonundaLesson = Lesson(
  id: 'uzatma-vav-kelime-sonunda',
  label: 'Ders 17',
  title: 'Uzatma Harfleri - Vav Kelime Sonunda',
  subtitle: '9 kayıt • Kelime sonunda vav uzatması',
  letters: kUzatmaVavKelimeSonundaWords,
);
