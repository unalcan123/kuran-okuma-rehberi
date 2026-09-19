import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders9AudioDir = 'audio/elifba/ders_9_sedde';
const String _harfSeddeGroup = 'Harf + Şedde';

/// Ders 9, part 1: for each of the 28 letters, two tiles sharing the
/// same recording — the "unmerged" cezmli+harekeli pair (e.g. "أَبْ
/// بَ") followed by how it's actually written once merged with şedde
/// (e.g. "أَبَّ") — since both are pronounced identically, that's the
/// whole point of the lesson.
const List<ArabicLetter> kSeddeLetters = [
  ArabicLetter(order: 1, isolatedForm: 'أَأْ أَ', turkishName: 'Elif', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/01_sedde.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'أَأَّ', turkishName: 'Elif', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/02_sedde.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'أَبْ بَ', turkishName: 'Be', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/03_sedde.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'أَبَّ', turkishName: 'Be', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/04_sedde.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'أَتْ تَ', turkishName: 'Te', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/05_sedde.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'أَتَّ', turkishName: 'Te', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/06_sedde.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'أَثْ ثَ', turkishName: 'Se', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/07_sedde.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'أَثَّ', turkishName: 'Se', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/08_sedde.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'أَجْ جَ', turkishName: 'Cim', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/09_sedde.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'أَجَّ', turkishName: 'Cim', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/10_sedde.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'أَحْ حَ', turkishName: 'Ha', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/11_sedde.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'أَحَّ', turkishName: 'Ha', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/12_sedde.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'أَخْ خَ', turkishName: 'Hı', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/13_sedde.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'أَخَّ', turkishName: 'Hı', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/14_sedde.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'أَدْ دَ', turkishName: 'Dal', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/15_sedde.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'أَدَّ', turkishName: 'Dal', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/16_sedde.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'أَذْ ذَ', turkishName: 'Zel', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/17_sedde.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'أَذَّ', turkishName: 'Zel', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/18_sedde.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'أَرْ رَ', turkishName: 'Ra', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/19_sedde.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'أَرَّ', turkishName: 'Ra', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/20_sedde.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'أَزْ زَ', turkishName: 'Ze', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/21_sedde.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'أَزَّ', turkishName: 'Ze', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/22_sedde.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'أَسْ سَ', turkishName: 'Sin', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/23_sedde.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'أَسَّ', turkishName: 'Sin', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/24_sedde.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'أَشْ شَ', turkishName: 'Şın', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/25_sedde.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'أَشَّ', turkishName: 'Şın', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/26_sedde.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'أَصْ صَ', turkishName: 'Sad', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/27_sedde.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'أَصَّ', turkishName: 'Sad', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/28_sedde.mp3'),
  ArabicLetter(order: 29, isolatedForm: 'أَضْ ضَ', turkishName: 'Dad', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/29_sedde.mp3'),
  ArabicLetter(order: 30, isolatedForm: 'أَضَّ', turkishName: 'Dad', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/30_sedde.mp3'),
  ArabicLetter(order: 31, isolatedForm: 'أَطْ طَ', turkishName: 'Tı', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/31_sedde.mp3'),
  ArabicLetter(order: 32, isolatedForm: 'أَطَّ', turkishName: 'Tı', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/32_sedde.mp3'),
  ArabicLetter(order: 33, isolatedForm: 'أَظْ ظَ', turkishName: 'Zı', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/33_sedde.mp3'),
  ArabicLetter(order: 34, isolatedForm: 'أَظَّ', turkishName: 'Zı', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/34_sedde.mp3'),
  ArabicLetter(order: 35, isolatedForm: 'أَعْ عَ', turkishName: 'Ayn', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/35_sedde.mp3'),
  ArabicLetter(order: 36, isolatedForm: 'أَعَّ', turkishName: 'Ayn', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/36_sedde.mp3'),
  ArabicLetter(order: 37, isolatedForm: 'أَغْ غَ', turkishName: 'Gayn', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/37_sedde.mp3'),
  ArabicLetter(order: 38, isolatedForm: 'أَغَّ', turkishName: 'Gayn', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/38_sedde.mp3'),
  ArabicLetter(order: 39, isolatedForm: 'أَفْ فَ', turkishName: 'Fe', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/39_sedde.mp3'),
  ArabicLetter(order: 40, isolatedForm: 'أَفَّ', turkishName: 'Fe', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/40_sedde.mp3'),
  ArabicLetter(order: 41, isolatedForm: 'أَقْ قَ', turkishName: 'Kaf', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/41_sedde.mp3'),
  ArabicLetter(order: 42, isolatedForm: 'أَقَّ', turkishName: 'Kaf', isHeavyLetter: true, groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/42_sedde.mp3'),
  ArabicLetter(order: 43, isolatedForm: 'أَكْ كَ', turkishName: 'Kef', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/43_sedde.mp3'),
  ArabicLetter(order: 44, isolatedForm: 'أَكَّ', turkishName: 'Kef', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/44_sedde.mp3'),
  ArabicLetter(order: 45, isolatedForm: 'أَلْ لَ', turkishName: 'Lam', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/45_sedde.mp3'),
  ArabicLetter(order: 46, isolatedForm: 'أَلَّ', turkishName: 'Lam', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/46_sedde.mp3'),
  ArabicLetter(order: 47, isolatedForm: 'أَمْ مَ', turkishName: 'Mim', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/47_sedde.mp3'),
  ArabicLetter(order: 48, isolatedForm: 'أَمَّ', turkishName: 'Mim', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/48_sedde.mp3'),
  ArabicLetter(order: 49, isolatedForm: 'أَنْ نَ', turkishName: 'Nun', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/49_sedde.mp3'),
  ArabicLetter(order: 50, isolatedForm: 'أَنَّ', turkishName: 'Nun', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/50_sedde.mp3'),
  ArabicLetter(order: 51, isolatedForm: 'أَوْ وَ', turkishName: 'Vav', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/51_sedde.mp3'),
  ArabicLetter(order: 52, isolatedForm: 'أَوَّ', turkishName: 'Vav', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/52_sedde.mp3'),
  ArabicLetter(order: 53, isolatedForm: 'أَهـْ هـَ', turkishName: 'He', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/53_sedde.mp3'),
  ArabicLetter(order: 54, isolatedForm: 'أَهـَّ', turkishName: 'He', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/54_sedde.mp3'),
  ArabicLetter(order: 55, isolatedForm: 'أَىْ ىَ', turkishName: 'Ye', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/55_sedde.mp3'),
  ArabicLetter(order: 56, isolatedForm: 'أَىَّ', turkishName: 'Ye', groupLabel: _harfSeddeGroup, audioAsset: '$_ders9AudioDir/56_sedde.mp3'),
];

final Lesson kSeddeLesson = Lesson(
  id: 'sedde',
  label: 'Ders 9',
  title: 'Şedde',
  subtitle: '56 kayıt • Harf + şedde çiftleri',
  letters: kSeddeLetters,
);
