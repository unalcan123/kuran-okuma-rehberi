import '../models/arabic_letter.dart';
import '../models/lesson.dart';

const String _ders19AudioDir = 'audio/elifba/ders_19_ceker_esre';

/// Ders 19: "çeker esre" (subscript alef, ٖ) — a small mark under the
/// letter standing in for a full elongating ye, found in specific
/// Qur'anic words like "بِهٖ".
const List<ArabicLetter> kCekerEsreWords = [
  ArabicLetter(order: 1, isolatedForm: 'بِهٖ', audioAsset: '$_ders19AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'بِأَمْرِهٖ', audioAsset: '$_ders19AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'يَهْدٖي', audioAsset: '$_ders19AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'لِقَوْمِهٖ', audioAsset: '$_ders19AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'وَمَلَٓئِكَتِهٖ', audioAsset: '$_ders19AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'وَزَوْجِهٖ', audioAsset: '$_ders19AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'بَعْدِهٖ', audioAsset: '$_ders19AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'هٰزِهٖ', audioAsset: '$_ders19AudioDir/08_kelime.mp3'),
];

final Lesson kCekerEsreLesson = Lesson(
  id: 'ceker-esre',
  label: 'Ders 19',
  title: 'Çeker Esre',
  subtitle: '8 kayıt • Alt hançer ile uzatma',
  letters: kCekerEsreWords,
);
