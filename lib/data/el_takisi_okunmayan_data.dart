import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders24AudioDir = 'audio/elifba/ders_24_el_takisi_okunmayan';

/// Ders 24: the definite article "el" (اَلْ) before a şemsi (sun) letter — the lam is silent and the following letter is doubled instead.
const List<ArabicLetter> kElTakisiOkunmayanWords = [
  ArabicLetter(order: 1, isolatedForm: 'اَلتَّائِبُونَ', audioAsset: '$_ders24AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'اَلثَّمَرَاتِ', audioAsset: '$_ders24AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'اَلدَّهْرِ', audioAsset: '$_ders24AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'اَلذَّارِيَاتِ', audioAsset: '$_ders24AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'اَلرَّاكِعُونَ', audioAsset: '$_ders24AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'اَلزَّقُومِ', audioAsset: '$_ders24AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'اَلسَّاعَةُ', audioAsset: '$_ders24AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'اَلشَّمْسُ', audioAsset: '$_ders24AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'اَلصَّابرِينَ', audioAsset: '$_ders24AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'اَلضُّحَى', audioAsset: '$_ders24AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'اَلطَّامَّةُ', audioAsset: '$_ders24AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'اَلظَّالِمُونَ', audioAsset: '$_ders24AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'اَللَّيْلِ', audioAsset: '$_ders24AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'اَلنَّارُ', audioAsset: '$_ders24AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'اَلطَّارِقُ', audioAsset: '$_ders24AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'اَلنَّهَارُ', audioAsset: '$_ders24AudioDir/16_kelime.mp3'),
];

final Lesson kElTakisiOkunmayanLesson = Lesson(
  id: 'el-takisi-okunmayan',
  label: 'Ders 24',
  title: 'El Takısı - Okunmayan Harfler',
  subtitle: '16 kayıt • Şemsi harflerde el takısının okunuşu',
  letters: kElTakisiOkunmayanWords,
);
