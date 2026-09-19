import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders37AudioDir = 'audio/elifba/ders_37_alistirmalar_4';

/// Ders 37: general reading practice, fourth and final set.
const List<ArabicLetter> kAlistirmalar4Words = [
  ArabicLetter(order: 1, isolatedForm: 'يٰسٓ', audioAsset: '$_ders37AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'وَالْقُرْآنِ الْحَكِيمِ', audioAsset: '$_ders37AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'اِنَّكَ لَمِنَ الْمُرْسَلِينَ', audioAsset: '$_ders37AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'اَلَّذِى فَطَرَنِى', audioAsset: '$_ders37AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'كَالْعُرْجُونِ الْقَدِيمِ', audioAsset: '$_ders37AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'خَلَقَ الْأَزْوَاجَ', audioAsset: '$_ders37AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'مِنَ الْأَجْدَاثِ', audioAsset: '$_ders37AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'وَصَدَقَ الْمُرْسَلُونَ', audioAsset: '$_ders37AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'وَعَدَ الرَّحْمٰنُ', audioAsset: '$_ders37AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'صَيْحَةً وَاحِدَةً', audioAsset: '$_ders37AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'أَصْحَابَ الْجَنَّةِ', audioAsset: '$_ders37AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'أَبْصَارُهَا خَاشِعَةٌ', audioAsset: '$_ders37AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'وَالْجِبَالَ أَوْتَادًا', audioAsset: '$_ders37AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'عَلَى الْأَرَٓائِكِ', audioAsset: '$_ders37AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'وَالنَّازِعَاتِ غَرْقًا', audioAsset: '$_ders37AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'وَسُيِّرَتِ الْجِبَالُ', audioAsset: '$_ders37AudioDir/16_kelime.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'فَالسَّابِقَاتِ سَبْقًا', audioAsset: '$_ders37AudioDir/17_kelime.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'وَالسَّابِحَاتِ سَبْحًا', audioAsset: '$_ders37AudioDir/18_kelime.mp3'),
];

final Lesson kAlistirmalar4Lesson = Lesson(
  id: 'alistirmalar-4',
  label: 'Ders 37',
  title: 'Alıştırmalar 4',
  subtitle: '18 kayıt • Genel okuma alıştırması',
  letters: kAlistirmalar4Words,
);
