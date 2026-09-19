import '../models/arabic_letter.dart';
import '../models/lesson.dart';
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
import 'zamir_he_uzatma_yok_cezimli_data.dart';
import 'zamir_he_uzatma_yok_cezimli_seddeli_data.dart';
import 'zamir_he_uzatma_yok_data.dart';

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
  kZamirHeUzatmaYokLesson,
  kZamirHeUzatmaYokCezimliLesson,
  kZamirHeUzatmaYokCezimliSeddeliLesson,
  kKapaliTeLesson,
  kKelimeSonuDuraklarLesson,
  kAlistirmalar1Lesson,
  kAlistirmalar2Lesson,
  kAlistirmalar3Lesson,
  kAlistirmalar4Lesson,
];
