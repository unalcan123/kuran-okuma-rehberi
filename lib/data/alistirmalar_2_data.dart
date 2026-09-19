import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders35AudioDir = 'audio/elifba/ders_35_alistirmalar_2';

/// Ders 35: general reading practice, second set.
const List<ArabicLetter> kAlistirmalar2Words = [
  ArabicLetter(order: 1, isolatedForm: 'فَبَشِّرْهُمْ', audioAsset: '$_ders35AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'فَسَتَعْلَمُونَ', audioAsset: '$_ders35AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'سَنُقْرِؤُكَ', audioAsset: '$_ders35AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'وَاَيَةٌلَهُمْ', audioAsset: '$_ders35AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'سَلاَمٌقَوْلاً', audioAsset: '$_ders35AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'فَسَنُيَسِّرُهُ', audioAsset: '$_ders35AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'عَدُوٌّمُبِينٌ', audioAsset: '$_ders35AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'رَبُّنَايَعْلَمُ', audioAsset: '$_ders35AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'وَأَجْرٍكَرِيمٍ', audioAsset: '$_ders35AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'بَيْنَ أَيْدِيهِمْ', audioAsset: '$_ders35AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'يَشْفَعُ عِنْدَهُ', audioAsset: '$_ders35AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'وَسِعَ كُرْسِيُّهُ', audioAsset: '$_ders35AudioDir/12_kelime.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'وَإِلَيْهِ تُرْجَعُونَ', audioAsset: '$_ders35AudioDir/13_kelime.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'نَوْمَكُمْ سُبَاتًا', audioAsset: '$_ders35AudioDir/14_kelime.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'وَعِنَبًاوَقَضْبً', audioAsset: '$_ders35AudioDir/15_kelime.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'أَفَلاَيَشْكُرُونُ', audioAsset: '$_ders35AudioDir/16_kelime.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'كَلاَّ سَيَعْلَمُونَ', audioAsset: '$_ders35AudioDir/17_kelime.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'كِتَابٌ مَرْقُومٌ', audioAsset: '$_ders35AudioDir/18_kelime.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'وَتَشْهَدُأَرْجُلُهُمْ', audioAsset: '$_ders35AudioDir/19_kelime.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'فَكَانَتْ سَرَابًا', audioAsset: '$_ders35AudioDir/20_kelime.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'لَتَرْكَبُنَّ طَبَقًا', audioAsset: '$_ders35AudioDir/21_kelime.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'هُوَيُبْدِئُ وَيُعِيدُ', audioAsset: '$_ders35AudioDir/22_kelime.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'لِنُخْرِجَ بِهِ حَبًّا', audioAsset: '$_ders35AudioDir/23_kelime.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'عَيْنًايَشْرَبُ', audioAsset: '$_ders35AudioDir/24_kelime.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'فِرَعَوْنَ وَثَمُودَ', audioAsset: '$_ders35AudioDir/25_kelime.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'فَأَمَّامَنْ طَغَى', audioAsset: '$_ders35AudioDir/26_kelime.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'عَلَيْهَاقُعُودٌ', audioAsset: '$_ders35AudioDir/27_kelime.mp3'),
];

final Lesson kAlistirmalar2Lesson = Lesson(
  id: 'alistirmalar-2',
  label: 'Ders 35',
  title: 'Alıştırmalar 2',
  subtitle: '27 kayıt • Genel okuma alıştırması',
  letters: kAlistirmalar2Words,
);
