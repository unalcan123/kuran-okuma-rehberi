import '../models/arabic_letter.dart';
import '../models/lesson.dart';
import '../models/lesson_page_layout.dart';
import '../helpers/haraka_colors.dart';
import '../helpers/arabic_colorizer.dart';
import 'uzatma_elif_data.dart';
import '../models/turkish_audio.dart';

const String _ders20AudioDir = 'audio/elifba/ders_20_tenvin_iki_ustun';

/// Ders 20, part 1: each letter with tenvin-i fetha (double üstün, ً) — an unwritten "n" sound added at the end of an indefinite noun, e.g. "باً" (ban).
const List<ArabicLetter> kTenvinIkiUstunLetters = [
  ArabicLetter(order: 1, isolatedForm: 'ءًا', turkishName: 'Elif', audioAsset: '$_ders20AudioDir/01_tenvin.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'باً', turkishName: 'Be', audioAsset: '$_ders20AudioDir/02_tenvin.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'تاً', turkishName: 'Te', audioAsset: '$_ders20AudioDir/03_tenvin.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'ثاً', turkishName: 'Se', audioAsset: '$_ders20AudioDir/04_tenvin.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'جاً', turkishName: 'Cim', audioAsset: '$_ders20AudioDir/05_tenvin.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'حاً', turkishName: 'Ha', audioAsset: '$_ders20AudioDir/06_tenvin.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'خاً', turkishName: 'Hı', isHeavyLetter: true, audioAsset: '$_ders20AudioDir/07_tenvin.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'داً', turkishName: 'Dal', audioAsset: '$_ders20AudioDir/08_tenvin.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'ذاً', turkishName: 'Zel', audioAsset: '$_ders20AudioDir/09_tenvin.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'راً', turkishName: 'Ra', audioAsset: '$_ders20AudioDir/10_tenvin.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'زاً', turkishName: 'Ze', audioAsset: '$_ders20AudioDir/11_tenvin.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'ساً', turkishName: 'Sin', audioAsset: '$_ders20AudioDir/12_tenvin.mp3'),
  ArabicLetter(order: 13, isolatedForm: 'شاً', turkishName: 'Şın', audioAsset: '$_ders20AudioDir/13_tenvin.mp3'),
  ArabicLetter(order: 14, isolatedForm: 'صاً', turkishName: 'Sad', isHeavyLetter: true, audioAsset: '$_ders20AudioDir/14_tenvin.mp3'),
  ArabicLetter(order: 15, isolatedForm: 'ضاً', turkishName: 'Dad', isHeavyLetter: true, audioAsset: '$_ders20AudioDir/15_tenvin.mp3'),
  ArabicLetter(order: 16, isolatedForm: 'طاً', turkishName: 'Tı', isHeavyLetter: true, audioAsset: '$_ders20AudioDir/16_tenvin.mp3'),
  ArabicLetter(order: 17, isolatedForm: 'ظاً', turkishName: 'Zı', isHeavyLetter: true, audioAsset: '$_ders20AudioDir/17_tenvin.mp3'),
  ArabicLetter(order: 18, isolatedForm: 'عاً', turkishName: 'Ayn', audioAsset: '$_ders20AudioDir/18_tenvin.mp3'),
  ArabicLetter(order: 19, isolatedForm: 'غاً', turkishName: 'Gayn', isHeavyLetter: true, audioAsset: '$_ders20AudioDir/19_tenvin.mp3'),
  ArabicLetter(order: 20, isolatedForm: 'فاً', turkishName: 'Fe', audioAsset: '$_ders20AudioDir/20_tenvin.mp3'),
  ArabicLetter(order: 21, isolatedForm: 'قاً', turkishName: 'Kaf', isHeavyLetter: true, audioAsset: '$_ders20AudioDir/21_tenvin.mp3'),
  ArabicLetter(order: 22, isolatedForm: 'كاً', turkishName: 'Kef', audioAsset: '$_ders20AudioDir/22_tenvin.mp3'),
  ArabicLetter(order: 23, isolatedForm: 'لًا', turkishName: 'Lam', audioAsset: '$_ders20AudioDir/23_tenvin.mp3'),
  ArabicLetter(order: 24, isolatedForm: 'مًا', turkishName: 'Mim', audioAsset: '$_ders20AudioDir/24_tenvin.mp3'),
  ArabicLetter(order: 25, isolatedForm: 'ناً', turkishName: 'Nun', audioAsset: '$_ders20AudioDir/25_tenvin.mp3'),
  ArabicLetter(order: 26, isolatedForm: 'واً', turkishName: 'Vav', audioAsset: '$_ders20AudioDir/26_tenvin.mp3'),
  ArabicLetter(order: 27, isolatedForm: 'هـاً', turkishName: 'He', audioAsset: '$_ders20AudioDir/27_tenvin.mp3'),
  ArabicLetter(order: 28, isolatedForm: 'ياً', turkishName: 'Ye', audioAsset: '$_ders20AudioDir/28_tenvin.mp3'),
];

/// Ders 20, part 2: practice words carrying tenvin-i fetha.
const List<ArabicLetter> kTenvinIkiUstunWords = [
  ArabicLetter(order: 29, isolatedForm: 'إِذًا', audioAsset: '$_ders20AudioDir/29_kelime.mp3'),
  ArabicLetter(order: 30, isolatedForm: 'غَدًا', audioAsset: '$_ders20AudioDir/30_kelime.mp3'),
  ArabicLetter(order: 31, isolatedForm: 'دَمًا', audioAsset: '$_ders20AudioDir/31_kelime.mp3'),
  ArabicLetter(order: 32, isolatedForm: 'أَبًا', audioAsset: '$_ders20AudioDir/32_kelime.mp3'),
  ArabicLetter(order: 33, isolatedForm: 'رَغَدًا', audioAsset: '$_ders20AudioDir/33_kelime.mp3'),
  ArabicLetter(order: 34, isolatedForm: 'مَثَلًا', audioAsset: '$_ders20AudioDir/34_kelime.mp3'),
  ArabicLetter(order: 35, isolatedForm: 'ثَمَنًا', audioAsset: '$_ders20AudioDir/35_kelime.mp3'),
  ArabicLetter(order: 36, isolatedForm: 'رِبًا', audioAsset: '$_ders20AudioDir/36_kelime.mp3'),
  ArabicLetter(order: 37, isolatedForm: 'شَيْئًا', audioAsset: '$_ders20AudioDir/37_kelime.mp3'),
  ArabicLetter(order: 38, isolatedForm: 'جُنْدًا', audioAsset: '$_ders20AudioDir/38_kelime.mp3'),
  ArabicLetter(order: 39, isolatedForm: 'خَوْفًا', audioAsset: '$_ders20AudioDir/39_kelime.mp3'),
  ArabicLetter(order: 40, isolatedForm: 'أَمْنًا', audioAsset: '$_ders20AudioDir/40_kelime.mp3'),
  ArabicLetter(order: 41, isolatedForm: 'بَسًّا', audioAsset: '$_ders20AudioDir/41_kelime.mp3'),
  ArabicLetter(order: 42, isolatedForm: 'إِلاًّ', audioAsset: '$_ders20AudioDir/42_kelime.mp3'),
  ArabicLetter(order: 43, isolatedForm: 'إِدًّا', audioAsset: '$_ders20AudioDir/43_kelime.mp3'),
  ArabicLetter(order: 44, isolatedForm: 'أَيًّا', audioAsset: '$_ders20AudioDir/44_kelime.mp3'),
  ArabicLetter(order: 45, isolatedForm: 'وَدًّا', audioAsset: '$_ders20AudioDir/45_kelime.mp3'),
  ArabicLetter(order: 46, isolatedForm: 'رَجًّا', audioAsset: '$_ders20AudioDir/46_kelime.mp3'),
  ArabicLetter(order: 47, isolatedForm: 'صَبًّا', audioAsset: '$_ders20AudioDir/47_kelime.mp3'),
  ArabicLetter(order: 48, isolatedForm: 'حَقًّا', audioAsset: '$_ders20AudioDir/48_kelime.mp3'),
  ArabicLetter(order: 49, isolatedForm: 'مَالًا', audioAsset: '$_ders20AudioDir/49_kelime.mp3'),
  ArabicLetter(order: 50, isolatedForm: 'قَاعًا', audioAsset: '$_ders20AudioDir/50_kelime.mp3'),
  ArabicLetter(order: 51, isolatedForm: 'عَادًا', audioAsset: '$_ders20AudioDir/51_kelime.mp3'),
  ArabicLetter(order: 52, isolatedForm: 'بَابًا', audioAsset: '$_ders20AudioDir/52_kelime.mp3'),
  ArabicLetter(order: 53, isolatedForm: 'كَاتِبًا', audioAsset: '$_ders20AudioDir/53_kelime.mp3'),
  ArabicLetter(order: 54, isolatedForm: 'حَافِظًا', audioAsset: '$_ders20AudioDir/54_kelime.mp3'),
  ArabicLetter(order: 55, isolatedForm: 'شَاكِرًا', audioAsset: '$_ders20AudioDir/55_kelime.mp3'),
  ArabicLetter(order: 56, isolatedForm: 'اٰمِنًا', audioAsset: '$_ders20AudioDir/56_kelime.mp3'),
  ArabicLetter(order: 57, isolatedForm: 'وَاسِعًا', audioAsset: '$_ders20AudioDir/57_kelime.mp3'),
  ArabicLetter(order: 58, isolatedForm: 'صَابِرًا', audioAsset: '$_ders20AudioDir/58_kelime.mp3'),
  ArabicLetter(order: 59, isolatedForm: 'حَكِيمًا', audioAsset: '$_ders20AudioDir/59_kelime.mp3'),
  ArabicLetter(order: 60, isolatedForm: 'صَالِحًا', audioAsset: '$_ders20AudioDir/60_kelime.mp3'),
  ArabicLetter(order: 61, isolatedForm: 'وَاحِدًا', audioAsset: '$_ders20AudioDir/61_kelime.mp3'),
  ArabicLetter(order: 62, isolatedForm: 'خَالِدًا', audioAsset: '$_ders20AudioDir/62_kelime.mp3'),
  ArabicLetter(order: 63, isolatedForm: 'خَالِصًا', audioAsset: '$_ders20AudioDir/63_kelime.mp3'),
  ArabicLetter(order: 64, isolatedForm: 'سَائِغًا', audioAsset: '$_ders20AudioDir/64_kelime.mp3'),
  ArabicLetter(order: 65, isolatedForm: 'حَاصِبًا', audioAsset: '$_ders20AudioDir/65_kelime.mp3'),
  ArabicLetter(order: 66, isolatedForm: 'وَاصِبًا', audioAsset: '$_ders20AudioDir/66_kelime.mp3'),
  ArabicLetter(order: 67, isolatedForm: 'قَائِمًا', audioAsset: '$_ders20AudioDir/67_kelime.mp3'),
  ArabicLetter(order: 68, isolatedForm: 'قَاعِدًا', audioAsset: '$_ders20AudioDir/68_kelime.mp3'),
  ArabicLetter(order: 69, isolatedForm: 'قَاصِدًا', audioAsset: '$_ders20AudioDir/69_kelime.mp3'),
  ArabicLetter(order: 70, isolatedForm: 'قَانِتًا', audioAsset: '$_ders20AudioDir/70_kelime.mp3'),
  ArabicLetter(order: 71, isolatedForm: 'باَزِغًا', audioAsset: '$_ders20AudioDir/71_kelime.mp3'),
  ArabicLetter(order: 72, isolatedForm: 'حَاضِرًا', audioAsset: '$_ders20AudioDir/72_kelime.mp3'),
  ArabicLetter(order: 73, isolatedForm: 'مَاٰبًا', audioAsset: '$_ders20AudioDir/73_kelime.mp3'),
  ArabicLetter(order: 74, isolatedForm: 'وَادِيًا', audioAsset: '$_ders20AudioDir/74_kelime.mp3'),
  ArabicLetter(order: 75, isolatedForm: 'ظَاهِرَةً', audioAsset: '$_ders20AudioDir/75_kelime.mp3'),
  ArabicLetter(order: 76, isolatedForm: 'بَاطِنَةً', audioAsset: '$_ders20AudioDir/76_kelime.mp3'),
  ArabicLetter(order: 77, isolatedForm: 'دِينًا', audioAsset: '$_ders20AudioDir/77_kelime.mp3'),
  ArabicLetter(order: 78, isolatedForm: 'رِيحًا', audioAsset: '$_ders20AudioDir/78_kelime.mp3'),
  ArabicLetter(order: 79, isolatedForm: 'شِيبًا', audioAsset: '$_ders20AudioDir/79_kelime.mp3'),
  ArabicLetter(order: 80, isolatedForm: 'طِينًا', audioAsset: '$_ders20AudioDir/80_kelime.mp3'),
  ArabicLetter(order: 81, isolatedForm: 'عِيداً', audioAsset: '$_ders20AudioDir/81_kelime.mp3'),
  ArabicLetter(order: 82, isolatedForm: 'نُورًا', audioAsset: '$_ders20AudioDir/82_kelime.mp3'),
  ArabicLetter(order: 83, isolatedForm: 'رُوحًا', audioAsset: '$_ders20AudioDir/83_kelime.mp3'),
  ArabicLetter(order: 84, isolatedForm: 'نُوحًا', audioAsset: '$_ders20AudioDir/84_kelime.mp3'),
  ArabicLetter(order: 85, isolatedForm: 'هُوداً', audioAsset: '$_ders20AudioDir/85_kelime.mp3'),
  ArabicLetter(order: 86, isolatedForm: 'لُوطًا', audioAsset: '$_ders20AudioDir/86_kelime.mp3'),
  ArabicLetter(order: 87, isolatedForm: 'طُولاً', audioAsset: '$_ders20AudioDir/87_kelime.mp3'),
  ArabicLetter(order: 88, isolatedForm: 'حُوبًا', audioAsset: '$_ders20AudioDir/88_kelime.mp3'),
];

final Lesson kTenvinIkiUstunLesson = Lesson(
  id: 'tenvin-iki-ustun',
  label: 'Ders 20',
  title: 'Tenvin - İki Üstün',
  subtitle: '88 kayıt • Harf + tenvin ve kelime okuma',
  letters: [...kTenvinIkiUstunLetters, ...kTenvinIkiUstunWords],
  pageLayout: kTenvinIkiUstunPageLayout,
);

/// Book pages 40-43, "TENVİNLER – İKİ ÜSTÜNLÜ HARFLER" (colors read from
/// the PDF): p. 40 the 28 letters with iki üstün (tenvin red); p. 41 the same letters "Geçildiğinde" (tenvin red) next
/// to "Durulduğunda" (the üstün printed blue); p. 42-43 "ÖRNEKLER" (tenvin
/// red; on p. 42 the şedde of إِلاًّ إِدًّا وَدًّا حَقًّا and the elif of
/// وَدًّا are red too). The 7 thick letters are red everywhere (global rule, `thickArabicLetters`), whatever the PDF prints.
const ArabicColorProfile _tenvinUstunColors = ArabicColorProfile({
  ArabicPart.fathatan: arabicRed,
});
const ArabicColorProfile _tenvinUstunRedShadda = ArabicColorProfile({
  ArabicPart.fathatan: arabicRed,
  ArabicPart.shadda: arabicRed,
});

const LessonPageLayout kTenvinIkiUstunPageLayout = LessonPageLayout([
  LessonBookPage(
    bookPage: 40,
    headingAudio: 's040_baslik_1',
    introAudio: {0: TrAudio('s040_01', 2), 2: TrAudio('s040_02', 2)},
    type: LessonPageType.lesson,
    heading: 'TENVİNLER',
    subheading: '(ÇİFT HAREKELER)',
    intro: [
      '«Tenvin:» Bir harfe, aynı hareke, iki kere konursa buna “Tenvin” '
          'denir ve geçerek okuyuşta harfin sonunu “Cezimli Nûn” ( «نْ» ) '
          'varmış gibi okutur.',
      'Üç çeşit Tenvin vardır: “İki Üstün”, “İki Esre” ve “İki Ötre”.',
      '* Harfin üzerine konan, sol taraftan aşağı doğru eğik, üst üste, '
          'küçük çift çizgidir.',
      '* Geçişte, ince harflere “En”, kalın harflere ise “An” sesi verir.',
    ],
    colorProfile: _tenvinUstunColors,
    sections: [
      BookSection(
        title: 'İKİ ÜSTÜNLÜ HARFLER ( ـً ) فَتْحَتَيْنِ',
        titleAudio: 's040_baslik_2',
        itemCount: 28,
        columns: 4,
      ),
    ],
  ),
  LessonBookPage(
    bookPage: 41,
    introAudio: {0: TrAudio('s041_01', 2)},
    type: LessonPageType.lesson,
    intro: [
      '* “İki Üstün” alan harfin soluna, genellikle “Elif” harfi de yazılır.',
      '* Geçişte okunmayan bu Elif, durulduğunda uzatma harfi görevi yapar. '
          'İki üstündeki Nûn sesi kalkar ve harf, üstün yönünde iki hareke '
          'miktarı uzatılarak okunur. Harf kalın ise “A” sesiyle, ince ise '
          '“E-A” arası bir sesle uzatır.',
    ],
    colorProfile: _tenvinUstunColors,
    sections: [
      BookSection(
        refs: [
          0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, //
          14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
        ],
        derived: DerivedForm.waqfOnFathatan,
        derivedAudioItems: kUzatmaElifLetters,
        derivedProfile: ArabicColorProfile({ArabicPart.fatha: arabicBlue}),
        columns: 4,
        itemKind: LessonItemKind.letter,
        headers: [
          'Geçildiğinde',
          'Durulduğunda',
          'Geçildiğinde',
          'Durulduğunda',
        ],
      ),
    ],
  ),
  LessonBookPage(
    bookPage: 42,
    type: LessonPageType.examples,
    heading: 'ÖRNEKLER',
    arabicHeading: 'فَتْحَتَيْنِ',
    mark: 'ـً',
    colorProfile: _tenvinUstunColors,
    sections: [
      BookSection(
        itemCount: 32,
        columns: 4,
        itemKind: LessonItemKind.word,
        itemProfiles: {
          13: _tenvinUstunRedShadda,
          14: _tenvinUstunRedShadda,
          16: ArabicColorProfile({
            ArabicPart.fathatan: arabicRed,
            ArabicPart.shadda: arabicRed,
          }, clusterBodies: {2: arabicRed}),
          19: _tenvinUstunRedShadda,
        },
      ),
    ],
  ),
  LessonBookPage(
    bookPage: 43,
    type: LessonPageType.examples,
    itemCount: 28,
    columns: 4,
    itemKind: LessonItemKind.word,
    colorProfile: _tenvinUstunColors,
  ),
]);
