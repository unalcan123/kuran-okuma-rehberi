import 'dart:ui' show Color;

import '../models/arabic_letter.dart';
import '../models/lesson.dart';
import '../models/lesson_page_layout.dart';
import '../helpers/haraka_colors.dart';
import '../helpers/arabic_colorizer.dart';
import 'alistirmalar_1_data.dart';
import 'alistirmalar_2_data.dart';
import 'alistirmalar_3_data.dart';
import 'alistirmalar_4_data.dart';
import 'alistirmalar_sedde_data.dart';
import 'ceker_esre_data.dart';
import 'ceker_ustun_data.dart';
import 'cezm_data.dart';
import 'cikis_yerleri_data.dart';
import 'el_takisi_hemze_data.dart';
import 'el_takisi_hemze_vasil_data.dart';
import 'el_takisi_okunan_data.dart';
import 'el_takisi_okunmayan_data.dart';
import 'esre_data.dart';
import 'harekeler_alistirmalari_data.dart';
import 'kapali_te_data.dart';
import 'kelime_sonu_duraklar_data.dart';
import 'letter_forms_data.dart';
import 'otre_data.dart';
import 'sedde_data.dart';
import 'tenvin_iki_esre_data.dart';
import 'tenvin_iki_otre_data.dart';
import 'tenvin_iki_ustun_data.dart';
import 'ustun_data.dart';
import 'uzatma_elif_alistirmalar_data.dart';
import 'uzatma_elif_data.dart';
import 'uzatma_vav_alistirmalar_data.dart';
import 'uzatma_vav_data.dart';
import 'uzatma_vav_kelime_sonunda_data.dart';
import 'uzatma_ya_alistirmalar_data.dart';
import 'uzatma_ya_data.dart';
import 'zamir_he_uzatilmasi_data.dart';
import 'zamir_he_uzatma_med_data.dart';

// audioplayers' AudioCache already prepends "assets/" by default, so
// this must be relative to the assets folder, not repeat it.
const String _ders1AudioDir = 'audio/elifba/ders_1_harfler';

/// The 28 letters of the Arabic alphabet in classic Elifba order,
/// isolated form only. This is the single source of truth for the
/// letter, its Turkish name and its audio file — nothing about a
/// letter should be hardcoded anywhere else in the UI.
const List<ArabicLetter> kArabicLetters = [
  ArabicLetter(
    order: 1,
    isolatedForm: 'ا',
    turkishName: 'Elif',
    audioAsset: '$_ders1AudioDir/01_elif.mp3',
  ),
  ArabicLetter(
    order: 2,
    isolatedForm: 'ب',
    turkishName: 'Be',
    audioAsset: '$_ders1AudioDir/02_be.mp3',
  ),
  ArabicLetter(
    order: 3,
    isolatedForm: 'ت',
    turkishName: 'Te',
    audioAsset: '$_ders1AudioDir/03_te.mp3',
  ),
  ArabicLetter(
    order: 4,
    isolatedForm: 'ث',
    turkishName: 'Se',
    audioAsset: '$_ders1AudioDir/04_se.mp3',
  ),
  ArabicLetter(
    order: 5,
    isolatedForm: 'ج',
    turkishName: 'Cim',
    audioAsset: '$_ders1AudioDir/05_cim.mp3',
  ),
  ArabicLetter(
    order: 6,
    isolatedForm: 'ح',
    turkishName: 'Ha',
    audioAsset: '$_ders1AudioDir/06_ha.mp3',
  ),
  ArabicLetter(
    order: 7,
    isolatedForm: 'خ',
    turkishName: 'Hı',
    isHeavyLetter: true,
    audioAsset: '$_ders1AudioDir/07_hi.mp3',
  ),
  ArabicLetter(
    order: 8,
    isolatedForm: 'د',
    turkishName: 'Dal',
    audioAsset: '$_ders1AudioDir/08_dal.mp3',
  ),
  ArabicLetter(
    order: 9,
    isolatedForm: 'ذ',
    turkishName: 'Zel',
    audioAsset: '$_ders1AudioDir/09_zel.mp3',
  ),
  ArabicLetter(
    order: 10,
    isolatedForm: 'ر',
    turkishName: 'Ra',
    audioAsset: '$_ders1AudioDir/10_ra.mp3',
  ),
  ArabicLetter(
    order: 11,
    isolatedForm: 'ز',
    turkishName: 'Ze',
    audioAsset: '$_ders1AudioDir/11_ze.mp3',
  ),
  ArabicLetter(
    order: 12,
    isolatedForm: 'س',
    turkishName: 'Sin',
    audioAsset: '$_ders1AudioDir/12_sin.mp3',
  ),
  ArabicLetter(
    order: 13,
    isolatedForm: 'ش',
    turkishName: 'Şın',
    audioAsset: '$_ders1AudioDir/13_shin.mp3',
  ),
  ArabicLetter(
    order: 14,
    isolatedForm: 'ص',
    turkishName: 'Sad',
    isHeavyLetter: true,
    audioAsset: '$_ders1AudioDir/14_sad.mp3',
  ),
  ArabicLetter(
    order: 15,
    isolatedForm: 'ض',
    turkishName: 'Dad',
    isHeavyLetter: true,
    audioAsset: '$_ders1AudioDir/15_dad.mp3',
  ),
  ArabicLetter(
    order: 16,
    isolatedForm: 'ط',
    turkishName: 'Tı',
    isHeavyLetter: true,
    audioAsset: '$_ders1AudioDir/16_ti.mp3',
  ),
  ArabicLetter(
    order: 17,
    isolatedForm: 'ظ',
    turkishName: 'Zı',
    isHeavyLetter: true,
    audioAsset: '$_ders1AudioDir/17_zi.mp3',
  ),
  ArabicLetter(
    order: 18,
    isolatedForm: 'ع',
    turkishName: 'Ayn',
    audioAsset: '$_ders1AudioDir/18_ayn.mp3',
  ),
  ArabicLetter(
    order: 19,
    isolatedForm: 'غ',
    turkishName: 'Gayn',
    isHeavyLetter: true,
    audioAsset: '$_ders1AudioDir/19_gayn.mp3',
  ),
  ArabicLetter(
    order: 20,
    isolatedForm: 'ف',
    turkishName: 'Fe',
    audioAsset: '$_ders1AudioDir/20_fe.mp3',
  ),
  ArabicLetter(
    order: 21,
    isolatedForm: 'ق',
    turkishName: 'Kaf',
    isHeavyLetter: true,
    audioAsset: '$_ders1AudioDir/21_kaf.mp3',
  ),
  ArabicLetter(
    order: 22,
    isolatedForm: 'ك',
    turkishName: 'Kef',
    audioAsset: '$_ders1AudioDir/22_kef.mp3',
  ),
  ArabicLetter(
    order: 23,
    isolatedForm: 'ل',
    turkishName: 'Lam',
    audioAsset: '$_ders1AudioDir/23_lam.mp3',
  ),
  ArabicLetter(
    order: 24,
    isolatedForm: 'م',
    turkishName: 'Mim',
    audioAsset: '$_ders1AudioDir/24_mim.mp3',
  ),
  ArabicLetter(
    order: 25,
    isolatedForm: 'ن',
    turkishName: 'Nun',
    audioAsset: '$_ders1AudioDir/25_nun.mp3',
  ),
  ArabicLetter(
    order: 26,
    isolatedForm: 'و',
    turkishName: 'Vav',
    audioAsset: '$_ders1AudioDir/26_vav.mp3',
  ),
  ArabicLetter(
    order: 27,
    isolatedForm: 'هـ',
    turkishName: 'He',
    audioAsset: '$_ders1AudioDir/27_he.mp3',
  ),
  ArabicLetter(
    order: 28,
    isolatedForm: 'ي',
    turkishName: 'Ye',
    audioAsset: '$_ders1AudioDir/28_ye.mp3',
  ),
];

/// The first and, for now, only Elifba lesson: all 28 letters in
/// their isolated form.
final Lesson kHarfleriTaniyalimLesson = Lesson(
  id: 'harfleri-taniyalim',
  label: 'Ders 1',
  title: 'Harfleri Tanıyalım',
  subtitle: '28 harf • Elifba\'nın ilk adımı',
  letters: kArabicLetters,
  pageLayout: kHarfleriTaniyalimPageLayout,
);

final List<Lesson> kElifbaLessons = [
  kHarfleriTaniyalimLesson,
  kHarflerinYazilislariLesson,
  kUstunLesson,
  kEsreLesson,
  kOtreLesson,
  kCikisYerleriLesson,
  kCezmLesson,
  kHarekelerAlistirmalariLesson,
  kSeddeLesson,
  kAlistirmalarSeddeLesson,
  kUzatmaElifLesson,
  kUzatmaElifAlistirmalariLesson,
  kUzatmaYaLesson,
  kUzatmaYaAlistirmalariLesson,
  kUzatmaVavLesson,
  kUzatmaVavAlistirmalariLesson,
  kUzatmaVavKelimeSonundaLesson,
  kCekerUstunLesson,
  kCekerEsreLesson,
  kTenvinIkiUstunLesson,
  kTenvinIkiEsreLesson,
  kTenvinIkiOtreLesson,
  kElTakisiOkunanLesson,
  kElTakisiOkunmayanLesson,
  kElTakisiHemzeLesson,
  kElTakisiHemzeVasilLesson,
  kZamirHeUzatilmasiLesson,
  kZamirHeUzatmaMedLesson,
  kKapaliTeLesson,
  kKelimeSonuDuraklarLesson,
  kAlistirmalar1Lesson,
  kAlistirmalar2Lesson,
  kAlistirmalar3Lesson,
  kAlistirmalar4Lesson,
];

/// Book pages 3-7 (in book order): s. 3-5 "HARFLERİN ÇIKIŞ YERLERİ" (text
/// and the mahreç drawing), s. 6 "HARFLER" (the 28 letters, the 7 thick
/// ones red), s. 7 "HARFLERİN YAZILIŞ VE OKUNUŞLARI" (each letter's name;
/// the thick letters' names wholly red). Colors read from the PDF.
const ArabicColorProfile _thickRed = ArabicColorProfile({
  ArabicPart.thickLetter: arabicRed,
});
const ArabicColorProfile _wholeRed = ArabicColorProfile({
  ArabicPart.letter: arabicRed,
  ArabicPart.fatha: arabicRed,
  ArabicPart.sukun: arabicRed,
});

const LessonPageLayout kHarfleriTaniyalimPageLayout = LessonPageLayout([
  LessonBookPage(
    bookPage: 3,
    type: LessonPageType.info,
    heading: 'HARFLERİN ÇIKIŞ YERLERİ',
    headerImage: 'assets/images/elifba/harflerin_cikis_yerleri_header.png',
    intro: [
      'Harfin çıkış yeri “Mahreç” kelimesi ile ifade edilir. Beş ana mahreç '
          'bölgesi vardır:',
      '⟪1. CEVF:⟫ Nefes borusu ve ağız boşluğu bölgesidir.',
      'Nefesin geçtiği bu bölgeden, harekesiz ( «و ا ى» ) harfleri, yani Med '
          '(Uzatma) harfleri çıkar. Bu harfler harekesiz oldukları için tek '
          'başlarına okunamazlar. Harekeli bir harfe bitişir, onu uzatarak '
          'okuturlar.',
      '⟪2. BOĞAZ:⟫',
      '( «ء هـ» ) Boğazın göğse bitiştiği yerden çıkar. Hemze ( «ء» ), '
          'Elif’in ( «ا» ) harekeli halidir.',
      '( «ح ع» ) Boğazın ortasından çıkar.',
      '( «خ غ» ) Boğazın (ağız boşluğuna bitiştiği) üst kısmından çıkar.',
      '⟪3. DİL VE AĞIZ İÇİ:⟫',
      '( «ق» ) Dil kökü ve tavanından çıkar.',
      '( «ك» ) Dil ortası ile dil kökü arası, ağız tavanına doğru '
          'kaldırılarak çıkarılır.',
      '( «ج ش ي» ) Dil ortası ağız tavanına doğru kaldırılarak çıkarılır.',
      '( «ض» ) Dilin yan tarafı, üst azı dişlerinin iç kısmına '
          'bastırıldıktan sonra yavaşça çekilerek çıkar.',
      '( «ل» ) Dil ucu sağ veya sol köşesinin, üst ön diş etlerine '
          'değdirilmesi ile çıkar.',
      '( «ن» ) Dil ucu altının, üst ön diş etlerine değdirilmesi ile çıkar.',
    ],
  ),
  LessonBookPage(
    bookPage: 4,
    type: LessonPageType.info,
    intro: [
      '( «ر» ) Dildeki çıkış noktası, dil üstünün uca yakın kısmıdır. Dil '
          'ucu, üst ön damağa doğru kıvrılarak kaldırılır ve bu noktanın '
          'titretilmesi ile çıkar. Bu esnada dil; damak, diş gibi yerlere '
          'yapışmamalıdır.',
      '( «ط د ت» ) Dil ucu, üst ön iki dişin arkasına değdirilip '
          'çekilmesiyle çıkar. ( «ط» ) harfinde kalınlığı sağlamak için, '
          'dilin gerideki gövde kısmı da ayrıca üst damağa doğru kaldırılır.',
      '( «ص س ز» ) Dil ucu, alt ön iki dişin üst kısmına dokunur. Bu '
          'haldeyken, dil üzerinden kayan ses, alt ön dişlerin üstünden çıkar.',
      '( «ص» ) harfinde kalınlığı sağlamak için, dilin gerideki gövde kısmı '
          'da ayrıca üst damağa doğru kaldırılır.',
      '( «ظ ذ ث» ) Dil ucu, üst ön dişlerin keskin yerine değdirilerek çıkar.',
      '( «ظ» ) harfinde kalınlığı sağlamak için, dilin gerideki gövde kısmı '
          'da ayrıca üst damağa doğru kaldırılır.',
      '⟪4. DUDAK:⟫',
      '( «ف» ) Üst ön dişlerin ucu, alt dudağın içine değdirilerek çıkar.',
      '( «و م ب» ) Bu harfler iki dudak harfidir. Dudakların kapatılmasıyla '
          '( «م» ), kuvvetli kapatılıp açılmasıyla ( «ب» ), U pozisyonunda '
          'ileri uzatılmasıyla ( «و» ) çıkar. Yalnız, üstünlü ve esreli vâv '
          'harfinde ( «وِ وَ» ), dudağı uzattıktan sonra geri çekmek '
          'gerekirken, ötreli ve sakin vâvlarda ( «وْ وُ» ) sadece uzatmak '
          'yeterlidir.',
      '⟪5. GENİZ:⟫',
      'Burun içi bölgesidir. Bu mahreçten harf çıkmaz. Gunne dediğimiz, '
          'sesin iki hareke miktarı tutulması işi burada yapılır.',
      '⟪Önemli Not:⟫',
      '1. Mahreçler için mutlaka seslendirme desteği alınız.',
    ],
  ),
  LessonBookPage(
    bookPage: 5,
    type: LessonPageType.info,
    figure: 'assets/images/elifba/mahrec_sekli.png',
    figureLegend: [
      FrameRun(0, Color(0xFF8DC63F), 'Geniz'),
      FrameRun(0, Color(0xFFFFF9D6), 'Nefes Boşluğu'),
      FrameRun(0, Color(0xFFEF4F63), 'Dil'),
      FrameRun(0, Color(0xFFA7A9AC), 'Dudaklar'),
      FrameRun(0, Color(0xFFF7A941), 'Boğaz'),
    ],
  ),
  LessonBookPage(
    bookPage: 6,
    type: LessonPageType.lesson,
    heading: 'HARFLER',
    intro: [
      '- Kur’ân-ı Kerîm harfleri “28” tanedir.',
      '- Bunların “7”’si kalın, “21”’i de ince harf olarak kabul edilir.',
      '- Kalın harfler şunlardır: «﴾ خ ص ض ط ظ غ ق ﴿»',
    ],
    itemCount: 28,
    columns: 4,
    colorProfile: _thickRed,
  ),
  LessonBookPage(
    bookPage: 7,
    type: LessonPageType.lesson,
    kicker: 'HARFLERİN',
    heading: 'YAZILIŞ VE OKUNUŞLARI',
    colorProfile: ArabicColorProfile.none,
    sections: [
      BookSection(
        refs: [
          0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, //
          14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
        ],
        refTexts: [
          'أَلِفْ', 'بَا', 'تَا', 'ثَا', 'جِيمْ', 'حَا', 'خَا', 'دَالْ', //
          'ذَالْ', 'رَا', 'زَايْ', 'سِينْ', 'شِينْ', 'صَادْ', 'ضَادْ', 'طَا',
          'ظَا', 'عَيْنْ', 'غَيْنْ', 'فَا', 'قَافْ', 'كَافْ', 'لَامْ', 'مِيمْ',
          'نُونْ', 'وَاوْ', 'هَا', 'يَا',
        ],
        columns: 4,
        itemKind: LessonItemKind.word,
        itemProfiles: {
          6: _wholeRed,
          13: _wholeRed,
          14: _wholeRed,
          15: _wholeRed,
          16: _wholeRed,
          18: _wholeRed,
          20: _wholeRed,
        },
      ),
    ],
  ),
]);
