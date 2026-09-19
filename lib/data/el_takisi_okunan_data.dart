import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders23AudioDir = 'audio/elifba/ders_23_el_takisi_okunan';

/// Ders 23: the definite article "el" (اَلْ) before a kameri (moon) letter — the lam is pronounced.
const List<ArabicLetter> kElTakisiOkunanWords = [
  ArabicLetter(order: 1, isolatedForm: 'اَلْإِنْسَانُ', audioAsset: '$_ders23AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'اَلْبَيْتُ', audioAsset: '$_ders23AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'اَلْغَافِلِينَ', audioAsset: '$_ders23AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'اَلْحَمْدُ', audioAsset: '$_ders23AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'اَلْجَنَّةَ', audioAsset: '$_ders23AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'اَلْكَافِرُونَ', audioAsset: '$_ders23AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'اَلْوَعْدُ', audioAsset: '$_ders23AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'اَلْخَنَّاسِ', audioAsset: '$_ders23AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'اَلْفَضْلَ', audioAsset: '$_ders23AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'اَلْعَالَمِينَ', audioAsset: '$_ders23AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'اَلْقَيُّومُ', audioAsset: '$_ders23AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'اَلْيَوْمَ', audioAsset: '$_ders23AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'اَلْمُلْكُ', audioAsset: '$_ders23AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'اَلْهُدَى', audioAsset: '$_ders23AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'اَلْقُدُّوسُ', audioAsset: '$_ders23AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'اَلْمُهَيْمِنُ', audioAsset: '$_ders23AudioDir/16_kelime.mp3'),
];

final Lesson kElTakisiOkunanLesson = Lesson(
  id: 'el-takisi-okunan',
  label: 'Ders 23',
  title: 'El Takısı - Okunan Harfler',
  subtitle: '16 kayıt • Kameri harflerde el takısının okunuşu',
  letters: kElTakisiOkunanWords,
);
