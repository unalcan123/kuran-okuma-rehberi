import '../models/arabic_letter.dart';
import '../models/lesson.dart';
import '../models/lesson_page_layout.dart';
import '../helpers/haraka_colors.dart';
import '../helpers/arabic_colorizer.dart';
import '../models/turkish_audio.dart';

const String _ders18AudioDir = 'audio/elifba/ders_18_ceker_ustun';

/// Ders 18: "çeker üstün" (hançer elif / dagger alif, ٰ) — a small
/// superscript alef standing in for a full elongating elif, found in
/// specific Qur'anic words like "هٰذَا" and "مُوسٰى".
const List<ArabicLetter> kCekerUstunWords = [
  ArabicLetter(
    order: 1,
    isolatedForm: 'اَلصَّلَوٰةَ',
    audioAsset: '$_ders18AudioDir/01_kelime.mp3',
  ),
  ArabicLetter(
    order: 2,
    isolatedForm: 'مُوسٰى',
    audioAsset: '$_ders18AudioDir/02_kelime.mp3',
  ),
  ArabicLetter(
    order: 3,
    isolatedForm: 'إِلٰهِ',
    audioAsset: '$_ders18AudioDir/03_kelime.mp3',
  ),
  ArabicLetter(
    order: 4,
    isolatedForm: 'ذٰلِكَ',
    audioAsset: '$_ders18AudioDir/04_kelime.mp3',
  ),
  ArabicLetter(
    order: 5,
    isolatedForm: 'إِبْرٰهِيمَ',
    audioAsset: '$_ders18AudioDir/05_kelime.mp3',
  ),
  ArabicLetter(
    order: 6,
    isolatedForm: 'وَإِسْحٰقَ',
    audioAsset: '$_ders18AudioDir/06_kelime.mp3',
  ),
  ArabicLetter(
    order: 7,
    isolatedForm: 'لِلْمَلَٓئِكَةِ',
    audioAsset: '$_ders18AudioDir/07_kelime.mp3',
  ),
  ArabicLetter(
    order: 8,
    isolatedForm: 'هٰؤُلَآءِ',
    audioAsset: '$_ders18AudioDir/08_kelime.mp3',
  ),
  ArabicLetter(
    order: 9,
    isolatedForm: 'اَلسَّمٰوَاتِ',
    audioAsset: '$_ders18AudioDir/09_kelime.mp3',
  ),
  ArabicLetter(
    order: 10,
    isolatedForm: 'إِسْرٰئِيلَ',
    audioAsset: '$_ders18AudioDir/10_kelime.mp3',
  ),
];

final Lesson kCekerUstunLesson = Lesson(
  id: 'ceker-ustun',
  label: 'Ders 18',
  title: 'Çeker Üstün',
  subtitle: '10 kayıt • Hançer elif ile uzatma',
  letters: kCekerUstunWords,
  pageLayout: kCekerUstunPageLayout,
);

/// Book page 39, top half: "ÇEKER ÜSTÜN" — 2 wide cells, then 2 rows of 4.
/// The çeker üstün and the med mark are red; other harekes black (PDF).
const LessonPageLayout kCekerUstunPageLayout = LessonPageLayout([
  LessonBookPage(
    bookPage: 39,
    headingAudio: 's039_baslik_1',
    introAudio: {0: TrAudio('s039_01', 3)},
    type: LessonPageType.lesson,
    heading: 'ÇEKER ÜSTÜN',
    arabicHeading: '( ـٰـ )',
    intro: [
      '* Dik yazılan Üstün’e verilen addır.',
      '* Uzatma harfi olsun veya olmasın, üstünde bulunduğu harfin '
          'uzatılacağını gösterir.',
      '* Eğer bir uzatma harfi varsa bunun, “Elif”, “Vâv” veya “Ye” olması '
          'fark etmez. Her durumda, üstünde bulunduğu harfi yukarı doğru, '
          'üstün sesi yönünde uzatır.',
    ],
    colorProfile: ArabicColorProfile({
      ArabicPart.daggerAlif: arabicRed,
      ArabicPart.maddah: arabicRed,
    }),
    sections: [
      BookSection(
        itemCount: 10,
        rowColumns: [2, 4, 4],
        itemKind: LessonItemKind.word,
      ),
    ],
  ),
]);
