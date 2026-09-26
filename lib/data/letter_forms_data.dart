import '../models/arabic_letter.dart';
import '../models/lesson.dart';
import '../models/lesson_page_layout.dart';
import '../helpers/haraka_colors.dart';
import '../helpers/arabic_colorizer.dart';

const String _ders2AudioDir = 'audio/elifba/ders_2_harfler';

/// Ders 2: the same alphabet, now with each letter's initial/medial/
/// final (başta/ortada/sonda) written forms — plus the lam-elif (لا)
/// ligature. A separate list from [kArabicLetters] because it is a
/// different lesson's written forms and extra letter. The 28 shared
/// letters use copies of Ders 1 recordings; only lam-elif has its own recording.
const List<ArabicLetter> kLetterFormLetters = [
  ArabicLetter(
    order: 1,
    isolatedForm: 'ا',
    formExamples: [
      [],
      [
        FormWord('بارك', [1]),
      ],
      [
        FormWord('وما', [2]),
      ],
    ],
    formNote: '(elif kelimenin başında bulunmaz, hemze ise bulunur.)',
    turkishName: 'Elif',
    initialForm: 'ا',
    medialForm: 'ـا',
    finalForm: 'ـا',
    positionExamples: ['أب', 'باب', 'ما'],
    audioAsset: '$_ders2AudioDir/01_elif.mp3',
  ),
  ArabicLetter(
    order: 2,
    isolatedForm: 'ب',
    formExamples: [
      [
        FormWord('برز', [0]),
      ],
      [
        FormWord('لبرز', [1]),
      ],
      [
        FormWord('ذهب', [2]),
      ],
    ],
    turkishName: 'Be',
    initialForm: 'بـ',
    medialForm: 'ـبـ',
    finalForm: 'ـب',
    positionExamples: ['برج', 'حبل', 'كتب'],
    audioAsset: '$_ders2AudioDir/02_be.mp3',
  ),
  ArabicLetter(
    order: 3,
    isolatedForm: 'ت',
    formExamples: [
      [
        FormWord('ترك', [0]),
      ],
      [
        FormWord('كتب', [1]),
      ],
      [
        FormWord('سكت', [2]),
        FormWord('كلمة', [3]),
        FormWord('امرأة', [4]),
      ],
    ],
    turkishName: 'Te',
    initialForm: 'تـ',
    medialForm: 'ـتـ',
    finalForm: 'ـت',
    positionExamples: ['تمر', 'كتب', 'بيت'],
    audioAsset: '$_ders2AudioDir/03_te.mp3',
  ),
  ArabicLetter(
    order: 4,
    isolatedForm: 'ث',
    formExamples: [
      [
        FormWord('ثقلت', [0]),
      ],
      [
        FormWord('مثل', [1]),
      ],
      [
        FormWord('بعث', [2]),
      ],
    ],
    turkishName: 'Se',
    initialForm: 'ثـ',
    medialForm: 'ـثـ',
    finalForm: 'ـث',
    positionExamples: ['ثوب', 'مثل', 'بحث'],
    audioAsset: '$_ders2AudioDir/04_se.mp3',
  ),
  ArabicLetter(
    order: 5,
    isolatedForm: 'ج',
    formExamples: [
      [
        FormWord('جعل', [0]),
      ],
      [
        FormWord('تجد', [1]),
      ],
      [
        FormWord('يلج', [2]),
      ],
    ],
    turkishName: 'Cim',
    initialForm: 'جـ',
    medialForm: 'ـجـ',
    finalForm: 'ـج',
    positionExamples: ['جمل', 'سجد', 'خرج'],
    audioAsset: '$_ders2AudioDir/05_cim.mp3',
  ),
  ArabicLetter(
    order: 6,
    isolatedForm: 'ح',
    formExamples: [
      [
        FormWord('حول', [0]),
      ],
      [
        FormWord('نحن', [1]),
      ],
      [
        FormWord('فتح', [2]),
      ],
    ],
    turkishName: 'Ha',
    initialForm: 'حـ',
    medialForm: 'ـحـ',
    finalForm: 'ـح',
    positionExamples: ['حبل', 'بحر', 'فتح'],
    audioAsset: '$_ders2AudioDir/06_ha.mp3',
  ),
  ArabicLetter(
    order: 7,
    isolatedForm: 'خ',
    formExamples: [
      [
        FormWord('خلت', [0]),
      ],
      [
        FormWord('تخرج', [1]),
      ],
      [
        FormWord('نفخ', [2]),
      ],
    ],
    turkishName: 'Hı',
    initialForm: 'خـ',
    medialForm: 'ـخـ',
    finalForm: 'ـخ',
    positionExamples: ['خبز', 'دخل', 'صرخ'],
    audioAsset: '$_ders2AudioDir/07_hi.mp3',
  ),
  ArabicLetter(
    order: 8,
    isolatedForm: 'د',
    formExamples: [
      [
        FormWord('دمت', [0]),
      ],
      [
        FormWord('بدأ', [1]),
      ],
      [
        FormWord('تجد', [2]),
      ],
    ],
    turkishName: 'Dal',
    initialForm: 'د',
    medialForm: 'ـد',
    finalForm: 'ـد',
    positionExamples: ['درس', 'مدرس', 'يد'],
    audioAsset: '$_ders2AudioDir/08_dal.mp3',
  ),
  ArabicLetter(
    order: 9,
    isolatedForm: 'ذ',
    formExamples: [
      [
        FormWord('ذهب', [0]),
      ],
      [
        FormWord('تذر', [1]),
      ],
      [
        FormWord('أخذ', [2]),
      ],
    ],
    turkishName: 'Zel',
    initialForm: 'ذ',
    medialForm: 'ـذ',
    finalForm: 'ـذ',
    positionExamples: ['ذهب', 'مذهب', 'خذ'],
    audioAsset: '$_ders2AudioDir/09_zel.mp3',
  ),
  ArabicLetter(
    order: 10,
    isolatedForm: 'ر',
    formExamples: [
      [
        FormWord('رزق', [0]),
      ],
      [
        FormWord('برز', [1]),
      ],
      [
        FormWord('أخر', [2]),
      ],
    ],
    turkishName: 'Ra',
    initialForm: 'ر',
    medialForm: 'ـر',
    finalForm: 'ـر',
    positionExamples: ['رجل', 'مرآة', 'بحر'],
    audioAsset: '$_ders2AudioDir/10_ra.mp3',
  ),
  ArabicLetter(
    order: 11,
    isolatedForm: 'ز',
    formExamples: [
      [
        FormWord('زبر', [0]),
      ],
      [
        FormWord('نزل', [1]),
      ],
      [
        FormWord('رجز', [2]),
      ],
    ],
    turkishName: 'Ze',
    initialForm: 'ز',
    medialForm: 'ـز',
    finalForm: 'ـز',
    positionExamples: ['زهر', 'مزرعة', 'خبز'],
    audioAsset: '$_ders2AudioDir/11_ze.mp3',
  ),
  ArabicLetter(
    order: 12,
    isolatedForm: 'س',
    formExamples: [
      [
        FormWord('سأل', [0]),
      ],
      [
        FormWord('حسد', [1]),
      ],
      [
        FormWord('يئس', [2]),
      ],
    ],
    turkishName: 'Sin',
    initialForm: 'سـ',
    medialForm: 'ـسـ',
    finalForm: 'ـس',
    positionExamples: ['سمك', 'مسجد', 'درس'],
    audioAsset: '$_ders2AudioDir/12_sin.mp3',
  ),
  ArabicLetter(
    order: 13,
    isolatedForm: 'ش',
    formExamples: [
      [
        FormWord('شرب', [0]),
      ],
      [
        FormWord('يشرب', [1]),
      ],
      [
        FormWord('بطش', [2]),
      ],
    ],
    turkishName: 'Şın',
    initialForm: 'شـ',
    medialForm: 'ـشـ',
    finalForm: 'ـش',
    positionExamples: ['شمس', 'مشط', 'عش'],
    audioAsset: '$_ders2AudioDir/13_shin.mp3',
  ),
  ArabicLetter(
    order: 14,
    isolatedForm: 'ص',
    formExamples: [
      [
        FormWord('صدق', [0]),
      ],
      [
        FormWord('حصحص', [1]),
      ],
      [
        FormWord('حصحص', [3]),
      ],
    ],
    turkishName: 'Sad',
    initialForm: 'صـ',
    medialForm: 'ـصـ',
    finalForm: 'ـص',
    positionExamples: ['صبر', 'عصر', 'قص'],
    audioAsset: '$_ders2AudioDir/14_sad.mp3',
  ),
  ArabicLetter(
    order: 15,
    isolatedForm: 'ض',
    formExamples: [
      [
        FormWord('ضيف', [0]),
      ],
      [
        FormWord('حضر', [1]),
      ],
      [
        FormWord('أنقض', [3]),
      ],
    ],
    turkishName: 'Dad',
    initialForm: 'ضـ',
    medialForm: 'ـضـ',
    finalForm: 'ـض',
    positionExamples: ['ضفدع', 'حضر', 'بيض'],
    audioAsset: '$_ders2AudioDir/15_dad.mp3',
  ),
  ArabicLetter(
    order: 16,
    isolatedForm: 'ط',
    formExamples: [
      [
        FormWord('طرفك', [0]),
      ],
      [
        FormWord('بطش', [1]),
      ],
      [
        FormWord('يبسط', [3]),
      ],
    ],
    turkishName: 'Tı',
    initialForm: 'طـ',
    medialForm: 'ـطـ',
    finalForm: 'ـط',
    positionExamples: ['طفل', 'بطل', 'حائط'],
    audioAsset: '$_ders2AudioDir/16_ti.mp3',
  ),
  ArabicLetter(
    order: 17,
    isolatedForm: 'ظ',
    formExamples: [
      [
        FormWord('ظلم', [0]),
      ],
      [
        FormWord('نظر', [1]),
      ],
      [
        FormWord('حفظ', [2]),
      ],
    ],
    turkishName: 'Zı',
    initialForm: 'ظـ',
    medialForm: 'ـظـ',
    finalForm: 'ـظ',
    positionExamples: ['ظرف', 'نظر', 'حفظ'],
    audioAsset: '$_ders2AudioDir/17_zi.mp3',
  ),
  ArabicLetter(
    order: 18,
    isolatedForm: 'ع',
    formExamples: [
      [
        FormWord('عن', [0]),
      ],
      [
        FormWord('فعل', [1]),
      ],
      [
        FormWord('طبع', [2]),
      ],
    ],
    turkishName: 'Ayn',
    initialForm: 'عـ',
    medialForm: 'ـعـ',
    finalForm: 'ـع',
    positionExamples: ['علم', 'لعب', 'سمع'],
    audioAsset: '$_ders2AudioDir/18_ayn.mp3',
  ),
  ArabicLetter(
    order: 19,
    isolatedForm: 'غ',
    formExamples: [
      [
        FormWord('غير', [0]),
      ],
      [
        FormWord('يغفر', [1]),
      ],
      [
        FormWord('أسبغ', [3]),
      ],
    ],
    turkishName: 'Gayn',
    initialForm: 'غـ',
    medialForm: 'ـغـ',
    finalForm: 'ـغ',
    positionExamples: ['غزال', 'رغيف', 'صبغ'],
    audioAsset: '$_ders2AudioDir/19_gayn.mp3',
  ),
  ArabicLetter(
    order: 20,
    isolatedForm: 'ف',
    formExamples: [
      [
        FormWord('فقد', [0]),
      ],
      [
        FormWord('حفظ', [1]),
      ],
      [
        FormWord('ضيف', [2]),
      ],
    ],
    turkishName: 'Fe',
    initialForm: 'فـ',
    medialForm: 'ـفـ',
    finalForm: 'ـف',
    positionExamples: ['فم', 'مفتاح', 'خوف'],
    audioAsset: '$_ders2AudioDir/20_fe.mp3',
  ),
  ArabicLetter(
    order: 21,
    isolatedForm: 'ق',
    formExamples: [
      [
        FormWord('قبل', [0]),
      ],
      [
        FormWord('فقد', [1]),
      ],
      [
        FormWord('صدق', [2]),
      ],
    ],
    turkishName: 'Kaf',
    initialForm: 'قـ',
    medialForm: 'ـقـ',
    finalForm: 'ـق',
    positionExamples: ['قلم', 'عقرب', 'خلق'],
    audioAsset: '$_ders2AudioDir/21_kaf.mp3',
  ),
  ArabicLetter(
    order: 22,
    isolatedForm: 'ك',
    formExamples: [
      [
        FormWord('كتب', [0]),
      ],
      [
        FormWord('بكت', [1]),
      ],
      [
        FormWord('أتتك', [3]),
      ],
    ],
    turkishName: 'Kef',
    initialForm: 'كـ',
    medialForm: 'ـكـ',
    finalForm: 'ـك',
    positionExamples: ['كتاب', 'مكتب', 'سمك'],
    audioAsset: '$_ders2AudioDir/22_kef.mp3',
  ),
  ArabicLetter(
    order: 23,
    isolatedForm: 'ل',
    formExamples: [
      [
        FormWord('لك', [0]),
      ],
      [
        FormWord('تلك', [1]),
      ],
      [
        FormWord('تصل', [2]),
      ],
    ],
    turkishName: 'Lam',
    initialForm: 'لـ',
    medialForm: 'ـلـ',
    finalForm: 'ـل',
    positionExamples: ['لبن', 'قلم', 'رجل'],
    audioAsset: '$_ders2AudioDir/23_lam.mp3',
  ),
  ArabicLetter(
    order: 24,
    isolatedForm: 'م',
    formExamples: [
      [
        FormWord('مرج', [0]),
      ],
      [
        FormWord('ثمره', [1]),
      ],
      [FormWord('ظلم')],
    ],
    turkishName: 'Mim',
    initialForm: 'مـ',
    medialForm: 'ـمـ',
    finalForm: 'ـم',
    positionExamples: ['موز', 'شمس', 'علم'],
    audioAsset: '$_ders2AudioDir/24_mim.mp3',
  ),
  ArabicLetter(
    order: 25,
    isolatedForm: 'ن',
    formExamples: [
      [
        FormWord('نظر', [0]),
      ],
      [
        FormWord('منع', [1]),
      ],
      [
        FormWord('عن', [1]),
      ],
    ],
    turkishName: 'Nun',
    initialForm: 'نـ',
    medialForm: 'ـنـ',
    finalForm: 'ـن',
    positionExamples: ['نهر', 'منزل', 'عين'],
    audioAsset: '$_ders2AudioDir/25_nun.mp3',
  ),
  ArabicLetter(
    order: 26,
    isolatedForm: 'و',
    formExamples: [
      [
        FormWord('ورد', [0]),
      ],
      [
        FormWord('سوف', [1]),
      ],
      [
        FormWord('لو', [1]),
      ],
    ],
    turkishName: 'Vav',
    initialForm: 'و',
    medialForm: 'ـو',
    finalForm: 'ـو',
    positionExamples: ['ورد', 'جوز', 'هو'],
    audioAsset: '$_ders2AudioDir/26_vav.mp3',
  ),
  ArabicLetter(
    order: 27,
    isolatedForm: 'هـ',
    formExamples: [
      [
        FormWord('هو', [0]),
      ],
      [
        FormWord('فهو', [1]),
      ],
      [
        FormWord('له', [1]),
      ],
    ],
    turkishName: 'He',
    initialForm: 'هـ',
    medialForm: 'ـهـ',
    finalForm: 'ـه',
    positionExamples: ['هو', 'فهم', 'له'],
    audioAsset: '$_ders2AudioDir/27_he.mp3',
  ),
  ArabicLetter(
    order: 28,
    isolatedForm: 'لا',
    turkishName: 'Lam Elif',
    initialForm: 'لا',
    medialForm: 'ـلا',
    finalForm: 'ـلا',
    positionExamples: ['لاعب', 'سلام', 'إلا'],
    audioAsset: '$_ders2AudioDir/28_lamelif.mp3',
  ),
  ArabicLetter(
    order: 29,
    isolatedForm: 'ي',
    formExamples: [
      [
        FormWord('يدل', [0]),
      ],
      [
        FormWord('ضيف', [1]),
      ],
      [
        FormWord('في', [1]),
      ],
    ],
    turkishName: 'Ye',
    initialForm: 'يـ',
    medialForm: 'ـيـ',
    finalForm: 'ـي',
    positionExamples: ['يد', 'بيت', 'في'],
    audioAsset: '$_ders2AudioDir/29_ye.mp3',
  ),
];

final Lesson kHarflerinYazilislariLesson = Lesson(
  id: 'harflerin-yazilislari',
  label: 'Ders 2',
  title: 'Harflerin Yazılışları',
  subtitle: '29 harf • Baş, orta, son yazılışları',
  letters: kLetterFormLetters,
  pageLayout: kHarflerinYazilislariPageLayout,
);

/// The book's hemze row under elif (s. 10): hemze written at the start,
/// middle and end of words. Shown only on the book page (no recording).
const ArabicLetter kHemzeFormRow = ArabicLetter(
  order: 0,
  isolatedForm: 'أ',
  formExamples: [
    [
      FormWord('اذن', [0]),
      FormWord('أذن', [0]),
      FormWord('اِرم', [0]),
      FormWord('إرم', [0]),
    ],
    [
      FormWord('سال', [1]),
      FormWord('سأل', [1]),
      FormWord('يئس', [1]),
      FormWord('رؤس', [1]),
    ],
    [
      FormWord('نبا', [2]),
      FormWord('نبأ', [2]),
      FormWord('نبا', [2]),
      FormWord('نبإ', [2]),
      FormWord('قرئ', [2]),
    ],
  ],
);

/// Book pages 8-13 (in book order): s. 8 "LÂM - ELİF" (its shapes; لا is
/// this lesson's item), s. 9 "SIRASIZ YAZILAN HARFLER" (the letters out of
/// order, the 7 thick ones red), s. 10-13 "HARFLERİN BAŞTA, ORTADA, SONDA
/// YAZILIŞLARINA ÖRNEKLER" (the letter red; in the example words the
/// letters the book prints red). Colors read from the PDF.
const ArabicColorProfile _formsThickRed = ArabicColorProfile({
  ArabicPart.thickLetter: arabicRed,
});
const ArabicColorProfile _formsLetterRed = ArabicColorProfile({
  ArabicPart.letter: arabicRed,
});

const LessonPageLayout kHarflerinYazilislariPageLayout = LessonPageLayout([
  LessonBookPage(
    bookPage: 8,
    type: LessonPageType.lesson,
    heading: 'LÂM - ELİF',
    arabicHeading: 'لا',
    intro: [
      '* «LÂMELİF» ( «لا» ): Lâm ( «ل» ) harfinin, Elif veya Hemze ( «ا ء» ) '
          'ile bitişme durumunu gösteren özel bir şekildir. Harf değildir.',
      '* «LÂMELİF» adından da anlaşılacağı gibi önce Lâm, sonra Elif okunur. '
          'Sağ tarafı Lâm’ı, sol tarafı ise Elif’i gösterir.',
      '* Lâm’a bitişen harekesiz Elif ise; Lâm’ı uzatarak “Lâ” şeklinde '
          'okutur.',
      '* Eğer Lâm’a bitişen Hemze ise; her ikisi de kendi harekesi ile '
          'okunur.',
      '* Lâm-Elif diğer harflere yalnızca sağından birleşir.',
      'Yazılış durumları şöyledir:',
    ],
    colorProfile: ArabicColorProfile.none,
    sections: [
      BookSection(
        title: 'LÂM - ELİF ŞEKİLLERİ',
        texts: ['لا', 'ـلا', 'لآ', 'ـلآ', 'لأ', 'ـلأ', 'لإ', 'ـلإ'],
        textItems: {0: 27},
        rowLabels: [
          'Lâm + Elif',
          'Lâm + Uzatmalı Hemze',
          'Lâm + Üstünlü veya Ötreli Hemze',
          'Lâm + Esreli Hemze',
        ],
        columns: 3,
        headers: ['', 'AYRI', 'BİTİŞİK'],
      ),
    ],
  ),
  LessonBookPage(
    bookPage: 9,
    type: LessonPageType.exercise,
    kicker: 'SIRASIZ YAZILAN',
    heading: 'HARFLER',
    colorProfile: _formsThickRed,
    sections: [
      BookSection(
        refs: [
          23, 5, 7, 1, 12, 20, 28, 25, 21, 18, 0, 19, 10, 26, //
          6, 13, 14, 9, 16, 22, 15, 11, 17, 8, 4, 2, 24, 3,
        ],
        columns: 4,
      ),
    ],
  ),
  LessonBookPage(
    bookPage: 10,
    type: LessonPageType.lesson,
    kicker: 'HARFLERİN',
    heading: 'BAŞTA, ORTADA, SONDA YAZILIŞLARINA',
    subheading: 'ÖRNEKLER',
    intro: [
      '* Kelimeyi oluşturan her harfin kendinden önceki harfe bitiştiğini ve '
          '( «ا د ذ ر ز و» ) harflerinin, kendilerinden sonra gelen harflere '
          'bitişmediğini hatırlayalım.',
      '«Not:» Harflerin kelimelere nasıl bitiştiğini görelim. Kelimeleri '
          'okumaya çalışmayalım. Henüz harekeleri öğrenmedik.',
    ],
    colorProfile: _formsLetterRed,
    sections: [
      BookSection(
        kind: BookSectionKind.forms,
        refs: [0],
        extraRows: {1: kHemzeFormRow},
      ),
    ],
  ),
  LessonBookPage(
    bookPage: 11,
    type: LessonPageType.lesson,
    colorProfile: _formsLetterRed,
    sections: [
      BookSection(
        kind: BookSectionKind.forms,
        refs: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      ),
    ],
  ),
  LessonBookPage(
    bookPage: 12,
    type: LessonPageType.lesson,
    colorProfile: _formsLetterRed,
    sections: [
      BookSection(
        kind: BookSectionKind.forms,
        refs: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
      ),
    ],
  ),
  LessonBookPage(
    bookPage: 13,
    type: LessonPageType.lesson,
    colorProfile: _formsLetterRed,
    sections: [
      BookSection(kind: BookSectionKind.forms, refs: [23, 24, 25, 26, 28]),
    ],
  ),
]);
