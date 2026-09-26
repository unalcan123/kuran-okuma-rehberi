import '../models/arabic_letter.dart';
import '../models/lesson.dart';
import '../models/lesson_page_layout.dart';
import 'book_highlights.dart';
import 'zamir_he_uzatma_yok_data.dart';
import 'zamir_he_uzatma_yok_cezimli_data.dart';
import 'zamir_he_uzatma_yok_cezimli_seddeli_data.dart';

const String _ders27AudioDir = 'audio/elifba/ders_27_zamir_he_uzatilmasi';

/// Ders 27: the "hu/hi" pronoun's he gets a small silent medd (ٓ) when it falls between two vowelled letters mid-recitation.
const List<ArabicLetter> kZamirHeUzatilmasiWords = [
  ArabicLetter(order: 1, isolatedForm: 'لَمْ يَرَهُٓ أَحَدٌ', audioAsset: '$_ders27AudioDir/01_kelime.mp3'),
  ArabicLetter(order: 2, isolatedForm: 'رَبُّهُٓ أَسْلِمْ', audioAsset: '$_ders27AudioDir/02_kelime.mp3'),
  ArabicLetter(order: 3, isolatedForm: 'مَالُهُٓ إِذَا', audioAsset: '$_ders27AudioDir/03_kelime.mp3'),
  ArabicLetter(order: 4, isolatedForm: 'عَهْدَهُٓ أَمْ', audioAsset: '$_ders27AudioDir/04_kelime.mp3'),
  ArabicLetter(order: 5, isolatedForm: 'وَلَهُٓ أُخْتٌ', audioAsset: '$_ders27AudioDir/05_kelime.mp3'),
  ArabicLetter(order: 6, isolatedForm: 'عِلْمِهِٓ إِلَّا', audioAsset: '$_ders27AudioDir/06_kelime.mp3'),
  ArabicLetter(order: 7, isolatedForm: 'وَإِنَّهُ عَلَى', audioAsset: '$_ders27AudioDir/07_kelime.mp3'),
  ArabicLetter(order: 8, isolatedForm: 'فَأُمُّهُ هَاوِيَةٌ', audioAsset: '$_ders27AudioDir/08_kelime.mp3'),
  ArabicLetter(order: 9, isolatedForm: 'مَالُهُ وَمَا كَسَبَ', audioAsset: '$_ders27AudioDir/09_kelime.mp3'),
  ArabicLetter(order: 10, isolatedForm: 'وَامْرَأَتُهُ حَمَّالَةَ', audioAsset: '$_ders27AudioDir/10_kelime.mp3'),
  ArabicLetter(order: 11, isolatedForm: 'وَلَمْ يَكُنْ لَهُ كُفُوًا', audioAsset: '$_ders27AudioDir/11_kelime.mp3'),
  ArabicLetter(order: 12, isolatedForm: 'حَوْلَهُ ذَهَبَ', audioAsset: '$_ders27AudioDir/12_kelime.mp3'),
  // PDF p. 54 bottom and p. 55 top continue the same pronoun lesson.
  // Reuse the existing items verbatim, including their audio references.
  ...kZamirHeUzatmaYokWords,
  ...kZamirHeUzatmaYokCezimliWords,
  ...kZamirHeUzatmaYokCezimliSeddeliWords,
];

final Lesson kZamirHeUzatilmasiLesson = Lesson(
  id: 'zamir-he-uzatilmasi',
  label: 'Ders 27',
  title: 'Zamir (He) Uzatılması',
  subtitle: '30 örnek • Hû/hî zamirinin uzatıldığı ve uzatılmadığı hâller',
  letters: kZamirHeUzatilmasiWords,
  pageLayout: kZamirHeUzatilmasiPageLayout,
);

// Visually checked against the PDF: three six-item tables on p. 54,
// two on p. 55, ending before UZUN MED İŞARETİ. The page number is not
// an exclusive owner: Ders 28 also uses its own section of p. 55.
final LessonPageLayout kZamirHeUzatilmasiPageLayout = LessonPageLayout([
  LessonBookPage(
    bookPage: 54,
    type: LessonPageType.lesson,
    kicker: 'ZAMİR "HE" ( ه ـه )’NİN',
    heading: 'UZATILMASI',
    sections: [
      _pronounSection(0, const [
        '«He» Harfi Hangi Durumlarda Uzatılır?',
        '* «He»’den önceki harf harekeli ise uzatılarak okunur. Ne kadar uzatılacağını ise, «He»’den sonra gelen harf belirler. Şöyle ki:',
        '- Uzatılan «He»’den sonra Hemze gelirse 4 hareke miktarı uzatılır.',
        '«Örnekler:»',
      ]),
      _pronounSection(6, const [
        'Uzatılan «He»’den sonra Hemze’nin dışında herhangi bir harf gelirse 2 hareke miktarı uzatılır.',
        '«Örnekler:»',
      ]),
      _pronounSection(12, const [
        '«He» Harfi Hangi Durumlarda Uzatılmaz?',
        '* «He»’den önce uzatma harflerinden biri gelirse He uzatılmadan okunur.',
        '«He»’den sonra ise, hangi harf gelirse gelsin, durumu etkilemez.',
        '«Örnekler:»',
      ]),
    ],
  ),
  LessonBookPage(
    bookPage: 55,
    type: LessonPageType.lesson,
    sections: [
      _pronounSection(18, const [
        '* He’den önce cezimli herhangi bir harf gelirse, yine uzatılmadan okunur.',
        'He’den sonra ise, hangi harf gelirse gelsin durumu etkilemez.',
        '«Örnekler:»',
      ]),
      _pronounSection(24, const [
        '* He harfinden (önce harekeli bir harf olsa bile) önündeki kelimeye cezimli veya şeddeli bir harfe bağlanarak geçiş yapılırsa yine "He" uzatılmadan okunur.',
        '«Örnekler:»',
      ]),
    ],
  ),
]);

BookSection _pronounSection(int start, List<String> intro) => BookSection(
  intro: intro,
  itemCount: 6,
  columns: 3,
  itemKind: LessonItemKind.phrase,
  itemProfiles: {
    for (var i = 0; i < 6; i++)
      i:
          bookHighlightProfile(
            'zamir-he-uzatilmasi',
            kZamirHeUzatilmasiWords[start + i],
            start + i,
          )!,
  },
);
