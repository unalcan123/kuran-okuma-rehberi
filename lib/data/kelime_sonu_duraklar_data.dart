import '../models/arabic_letter.dart';
import '../models/lesson.dart';
import '../models/waqf_example.dart';

const String _ders33AudioDir = 'audio/elifba/ders_33_kelime_sonu_duraklar';

/// Ders 33: how a word's final hareke or tenvin changes when reading stops there (waqf) instead of continuing.
const List<ArabicLetter> kKelimeSonuDuraklarWords = [
  ArabicLetter(order: 1, isolatedForm: 'صُدُورِ', audioAsset: '$_ders33AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'صُدُورْ', audioAsset: '$_ders33AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'اَبَابِيلَ', audioAsset: '$_ders33AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'اَبَابِيلْ', audioAsset: '$_ders33AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'مَوَازِينُهُ', audioAsset: '$_ders33AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'مَوَازِينُهْ', audioAsset: '$_ders33AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'خَيْرًا', audioAsset: '$_ders33AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'خَيْرَا', audioAsset: '$_ders33AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'تَوَّابًا', audioAsset: '$_ders33AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'تَوَّابَا', audioAsset: '$_ders33AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'مَآءً', audioAsset: '$_ders33AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'مَآءَا', audioAsset: '$_ders33AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'خُسْرٍ', audioAsset: '$_ders33AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'خُسْرْ', audioAsset: '$_ders33AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'أَحَدٌ', audioAsset: '$_ders33AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'أَحَدْ', audioAsset: '$_ders33AudioDir/16_kelime.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'بِنَآءً', audioAsset: '$_ders33AudioDir/17_kelime.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'بِنَآءَا', audioAsset: '$_ders33AudioDir/18_kelime.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'مُطَهَّرَةً', audioAsset: '$_ders33AudioDir/19_kelime.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'مُطَهَّرَهْ', audioAsset: '$_ders33AudioDir/20_kelime.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'مَرْضِيَّةً', audioAsset: '$_ders33AudioDir/21_kelime.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'مَرْضِيَّهْ', audioAsset: '$_ders33AudioDir/22_kelime.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'قَالُوا', audioAsset: '$_ders33AudioDir/23_kelime.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'قَالُوا', audioAsset: '$_ders33AudioDir/24_kelime.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'وَهُوَ', audioAsset: '$_ders33AudioDir/25_kelime.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'وَهُو', audioAsset: '$_ders33AudioDir/26_kelime.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'خَشِىَ', audioAsset: '$_ders33AudioDir/27_kelime.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'خَشِى', audioAsset: '$_ders33AudioDir/28_kelime.mp3'),
];

final Lesson kKelimeSonuDuraklarLesson = Lesson(
  id: 'kelime-sonu-duraklar',
  label: 'Ders 33',
  title: 'Kelime Sonu Durakları (Duruş)',
  subtitle: '28 kayıt • Durak hâlinde kelime sonlarının okunuşu',
  letters: kKelimeSonuDuraklarWords,
);

/// Harekeli letter at the end: no üstün/esre/ötre, read as if with cezim.
const List<WaqfExample> kWaqfHarekeliExamples = [
  WaqfExample(kKelimeSonuDuraklarWords, 1),
  WaqfExample(kKelimeSonuDuraklarWords, 2),
  WaqfExample(kKelimeSonuDuraklarWords, 3),
];

/// "İki üstün" written with an elif: one üstün is dropped and the letter is
/// held for two harekes.
const List<WaqfExample> kWaqfElifliTenvinExamples = [
  WaqfExample(kKelimeSonuDuraklarWords, 4, passRedLetters: 2, stopRedLetters: 2),
  WaqfExample(kKelimeSonuDuraklarWords, 5, passRedLetters: 2, stopRedLetters: 2),
];

/// "İki üstün" on a hemze without an elif: read as if an elif followed.
const List<WaqfExample> kWaqfHemzeTenvinExamples = [
  WaqfExample(kKelimeSonuDuraklarWords, 6, stopRedLetters: 2),
];

/// İki esre / iki ötre: stop with cezim.
const List<WaqfExample> kWaqfIkiEsreOtreExamples = [
  WaqfExample(kKelimeSonuDuraklarWords, 7),
  WaqfExample(kKelimeSonuDuraklarWords, 8),
];

/// "Diğer bazı örnekler" (p. 59).
const List<WaqfExample> kWaqfOtherExamples = [
  WaqfExample(kKelimeSonuDuraklarWords, 9, stopRedLetters: 2),
  WaqfExample(kKelimeSonuDuraklarWords, 10),
  WaqfExample(kKelimeSonuDuraklarWords, 11),
  WaqfExample(kKelimeSonuDuraklarWords, 12, passRedLetters: 2, stopRedLetters: 2),
  WaqfExample(kKelimeSonuDuraklarWords, 13),
  WaqfExample(kKelimeSonuDuraklarWords, 14),
];

/// All examples in book order.
const List<WaqfExample> kWaqfAllExamples = [
  ...kWaqfHarekeliExamples,
  ...kWaqfElifliTenvinExamples,
  ...kWaqfHemzeTenvinExamples,
  ...kWaqfIkiEsreOtreExamples,
  ...kWaqfOtherExamples,
];
