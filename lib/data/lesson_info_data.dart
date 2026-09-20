import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';
import '../widgets/waqf_examples_table.dart';
import '../models/arabic_letter.dart';
import '../models/word_highlight.dart';
import '../widgets/word_grid_table.dart';
import 'el_takisi_hemze_data.dart';
import 'el_takisi_hemze_vasil_data.dart';
import 'el_takisi_okunan_data.dart';
import 'el_takisi_okunmayan_data.dart';
import 'zamir_he_uzatilmasi_data.dart';
import 'zamir_he_uzatma_med_data.dart';
import 'zamir_he_uzatma_yok_cezimli_data.dart';
import 'zamir_he_uzatma_yok_cezimli_seddeli_data.dart';
import 'zamir_he_uzatma_yok_data.dart';
import '../models/waqf_example.dart';
import 'kapali_te_data.dart';
import 'kelime_sonu_duraklar_data.dart';

/// Rich "ders açıklaması" content shown from the info (ⓘ) button on a
/// lesson screen. Adapted from the original Elifbe2025 project's
/// per-lesson description text — its numbering doesn't line up with
/// this app's lesson ids one-to-one (some old lessons were merged,
/// split or renumbered here), so entries are matched by topic, not by
/// number, and keyed by [Lesson.id].
class LessonInfo {
  final String title;
  final List<InlineSpan> body;

  /// True when the first span only restates the heading of the lesson's
  /// book page (Ders 33), so the page leaves it out.
  final bool firstSpanIsBookHeading;

  const LessonInfo({
    required this.title,
    required this.body,
    this.firstSpanIsBookHeading = false,
  });
}

TextSpan _n(String text, {double height = 1.5}) => TextSpan(
  text: text,
  style: TextStyle(color: AppColors.textPrimary, height: height),
);

TextSpan _b(String text, {double height = 1.5, Color? color}) => TextSpan(
  text: text,
  style: TextStyle(
    color: color ?? AppColors.textPrimary,
    fontWeight: FontWeight.w700,
    height: height,
  ),
);

TextSpan _h(String text, {Color? color}) => TextSpan(
  text: text,
  style: TextStyle(
    color: color ?? AppColors.red,
    fontWeight: FontWeight.w800,
  ),
);

TextSpan _ar(String text, {double fontSize = 26, Color? color}) => TextSpan(
  text: text,
  style: AppTextTheme.arabicSmall(
    fontSize: fontSize,
  ).copyWith(color: color ?? AppColors.red, height: 1.9),
);

/// A "Durulduğunda / Geçildiğinde" table, like the ones in the book.
WidgetSpan _table(List<WaqfExample> examples) => WidgetSpan(
  child: SizedBox(
    width: double.infinity,
    child: WaqfExamplesTable(examples: examples),
  ),
);

/// A grid of the book's example words (the lesson's own words, tappable).
WidgetSpan _grid(
  List<ArabicLetter> words, {
  WordHighlight highlight = WordHighlight.none,
  int columns = 3,
  double minCellWidth = 150,
}) => WidgetSpan(
  child: SizedBox(
    width: double.infinity,
    child: WordGridTable(
      words: words,
      highlight: highlight,
      columns: columns,
      minCellWidth: minCellWidth,
    ),
  ),
);

/// Every second word of [words], starting at [start] (0 or 1).
List<ArabicLetter> _everyOther(List<ArabicLetter> words, int start) => [
  for (var i = start; i < words.length; i += 2) words[i],
];

/// The word "He" in red bold, as the book prints it.
final TextSpan _he = _b('He', color: AppColors.red);

final Map<String, LessonInfo> kLessonInfo = {
  'harfleri-taniyalim': LessonInfo(
    title: 'Kur’ân-ı Kerîm Harfleri',
    body: [
      _n(
        'Kur’ân-ı Kerîm harfleri 28 tanedir. Bunların 7’si kalın, 21’i ise ince harf olarak kabul edilir.\n\n',
      ),
      _b('Kalın harfler şunlardır:\n\n'),
      _ar('خ ص ض ط ظ غ ق', fontSize: 30),
    ],
  ),

  'harflerin-yazilislari': LessonInfo(
    title: 'Harflerin Yazılışları',
    body: [
      _b('Kelimeyi oluşturan her harf, kendinden önceki harfe bitişir. '),
      _n('Şu harfler ise '),
      _ar('ذ د ا ز ر و', fontSize: 28),
      _n(
        ' kendilerinden sonra gelen harflere bitişmez.\n\nHarflerin kelimelere nasıl bitiştiğini görelim. Kelimeleri okumaya çalışmayalım — harekeleri henüz öğrenmedik.',
      ),
    ],
  ),

  'ustun': LessonInfo(
    title: 'Üstün Harekesi',
    body: [
      _b('Üstün, '),
      _n(
        'harfin üzerine konan ve sol tarafından aşağı doğru eğik küçük bir çizgidir. İnce harflere ',
      ),
      _h('“E” '),
      _n('kalın harflere ise '),
      _h('“A” '),
      _n('sesi verir.'),
    ],
  ),

  'esre': LessonInfo(
    title: 'Esre Harekesi',
    body: [
      _b('Esre, '),
      _n(
        'harfin altına konan ve sol taraftan aşağı doğru eğik küçük bir çizgidir. İnce harflere ',
      ),
      _h('“İ” '),
      _n('kalın harflere ise '),
      _h('“I” '),
      _n('dan “İ”ye doğru yönelen bir ses verir.'),
    ],
  ),

  'otre': LessonInfo(
    title: 'Ötre Harekesi',
    body: [
      _b('Ötre, '),
      _n('harfin üstüne konan ve küçük '),
      _h('“Vâv” '),
      _n('harfine benzer bir şekildir.\n\nİnce harflere '),
      _h('“U-Ü” '),
      _n('arası bir ses, kalın harflere ise '),
      _h('“U” '),
      _n('sesi verir.'),
    ],
  ),

  'cikis-yerleri': LessonInfo(
    title: 'Çıkış Yerleri Sıralı',
    body: [
      _n(
        'Bu ders, harfleri alfabetik sırayla değil, ağızdaki çıkış (mahreç) yerlerine göre sıralar — her harf üç harekesiyle (üstün, esre, ötre) birlikte okunur.',
      ),
    ],
  ),

  'cezm': LessonInfo(
    title: 'Cezm',
    body: [
      _b('Cezm, '),
      _n(
        'harfin üstüne konan yuvarlak ve küçük bir şekildir.\n\nGörevi, üzerine geldiği harfi bir önceki harfe bağlayarak okutmasıdır.',
      ),
    ],
  ),

  'harekeler-alistirmalari': LessonInfo(
    title: 'Harekeler Alıştırmaları',
    body: [
      _n(
        'Üstün, esre, ötre ve cezmi bir arada kullanan karma kelime okuma pratiği.',
      ),
    ],
  ),

  'sedde': LessonInfo(
    title: 'Şedde',
    body: [
      _b(
        'Şedde, harfi iki kere okutur. Şeddeli harf aynı zamanda harekeli olur.\n\n',
        color: AppColors.gold,
      ),
      _b('Mesela: cennet, anne, himmet', color: AppColors.turquoise),
    ],
  ),

  'alistirmalar-sedde': LessonInfo(
    title: 'Şedde Alıştırmaları',
    body: [_n('Şeddeli harflerle kelime okuma pratiği.')],
  ),

  'uzatma-elif': LessonInfo(
    title: 'Uzatma Harfleri - Elif',
    body: [
      _b('Uzatma (MED) Harfleri ', color: AppColors.red),
      _ar('(و ا ي): ', fontSize: 22),
      _n('Kısaca '),
      _h('“VAY”'),
      _n(
        ' harfleri dediğimiz (و), (ا) ve (ي) harfleridir. Bir önceki harfi uzatarak okutur.\n\n',
      ),
      _b('Elif: ', color: AppColors.gold),
      _n('Üstünlü harfi iki hareke miktarı uzatır. Harf kalın ise '),
      _h('“A” '),
      _n('sesiyle, ince ise '),
      _h('“E-A” '),
      _n('arası bir sesle uzatır.'),
    ],
  ),

  'uzatma-elif-alistirmalari': LessonInfo(
    title: 'Uzatma Harfleri - Elif Alıştırmaları',
    body: [_n('Elif uzatmalı (medli) kelimelerle okuma pratiği.')],
  ),

  'uzatma-ya': LessonInfo(
    title: 'Uzatma Harfleri - Ya',
    body: [
      _n('Kendinden önceki esreli harfi iki hareke miktarı uzatır. Harf ince ise '),
      _h('“İ” ', color: AppColors.turquoise),
      _n('sesiyle, kalın ise '),
      _h('“I” ', color: AppColors.turquoise),
      _n('sesine yakın uzatılır.'),
    ],
  ),

  'uzatma-ya-alistirmalari': LessonInfo(
    title: 'Uzatma Harfleri - Ya Alıştırmaları',
    body: [_n('Ye uzatmalı (medli) kelimelerle okuma pratiği.')],
  ),

  'uzatma-vav': LessonInfo(
    title: 'Uzatma Harfleri - Vav',
    body: [
      _n('Kendinden önceki ötreli harfi iki hareke miktarı uzatır. Harf kalın ise '),
      _h('“U” ', color: AppColors.turquoise),
      _n('sesiyle, ince ise '),
      _h('“U-Ü” ', color: AppColors.turquoise),
      _n('arasında bir sesle uzatır.'),
    ],
  ),

  'uzatma-vav-alistirmalari': LessonInfo(
    title: 'Uzatma Harfleri - Vav Alıştırmaları',
    body: [_n('Vav uzatmalı (medli) kelimelerle okuma pratiği.')],
  ),

  'uzatma-vav-kelime-sonunda': LessonInfo(
    title: 'Uzatma Harfleri - Vav Kelime Sonunda',
    body: [
      _n('Bazen kelime sonunda gelen harekesiz Vâv, bittiği ötreli harfi tek başına uzatır. '),
      _b('(ذُو “Zû”) ', color: AppColors.sage),
      _n('gibi.\n\n'),
      _n(
        'Çoğu kez bu Vâv’dan sonra Elif bulunur. Bu durumda Elif ilave bir uzatma görevi yapmaz — uzatma miktarı yine iki hareke olur.',
      ),
    ],
  ),

  'ceker-ustun': LessonInfo(
    title: 'Çeker Üstün',
    body: [
      _b('Çeker Üstün (ـٰـ)\n\n'),
      _n(
        'Dik yazılan üstüne verilen addır. Uzatma harfi olsun veya olmasın, üstünde bulunduğu harfin uzatılacağını gösterir.',
      ),
    ],
  ),

  'ceker-esre': LessonInfo(
    title: 'Çeker Esre',
    body: [
      _b('Çeker Esre ( ِ )\n\n'),
      _n(
        'Dik yazılan esreye verilen addır. Altına yazıldığı harfi esre yönünde uzatarak okutur.',
      ),
    ],
  ),

  'tenvin-iki-ustun': LessonInfo(
    title: 'Tenvin - İki Üstün',
    body: [
      _b('Tenvin: ', color: AppColors.red),
      _n(
        'Bir harfe aynı hareke iki kere konursa buna “tenvin” denir ve geçerek okunuş yapılır — kelime sonunda yazıya geçmeyen bir “n” sesi eklenir.',
      ),
    ],
  ),

  'tenvin-iki-esre': LessonInfo(
    title: 'Tenvin - İki Esre',
    body: [
      _b('Tenvin: ', color: AppColors.red),
      _n(
        'Bir harfe aynı hareke iki kere konursa buna “tenvin” denir ve geçerek okunuş yapılır — kelime sonunda yazıya geçmeyen bir “n” sesi eklenir.',
      ),
    ],
  ),

  'tenvin-iki-otre': LessonInfo(
    title: 'Tenvin - İki Ötre',
    body: [
      _b('Tenvin: ', color: AppColors.red),
      _n(
        'Bir harfe aynı hareke iki kere konursa buna “tenvin” denir ve geçerek okunuş yapılır — kelime sonunda yazıya geçmeyen bir “n” sesi eklenir.',
      ),
    ],
  ),

  'el-takisi-okunan': LessonInfo(
    title: 'El Takısı - Okunan Harfler',
    body: [
      _n('Bir kelimede önce Lâm '),
      _ar('(ل)', fontSize: 24),
      _n(', sonra Elif '),
      _ar('(ا)', fontSize: 24),
      _n(' yazılması gerektiğinde, bunun için Lâmelif’in '),
      _ar('(لا)', fontSize: 24),
      _n(' kullanıldığını görmüştük.\n\n'),
      _n('Eğer önce Elif '),
      _ar('(ا)', fontSize: 24),
      _n(', sonra cezimli Lâm '),
      _ar('(لْ)', fontSize: 24),
      _n(' kelimenin başında bulunursa; buna '),
      _b('Elif-Lâm takısı'),
      _n(' veya kısaca '),
      _b('El takısı '),
      _ar('(اَلْ)', fontSize: 24),
      _n(' denir.\n\n'),
      _n('Lâm '),
      _ar('(ل)', fontSize: 24),
      _n('’dan önceki Elif '),
      _ar('(ا)', fontSize: 24),
      _n(', burada '),
      _b('Hemze'),
      _n(
        ' pozisyonundadır. Çünkü harekeli okunabilecek bir konumdadır. Uzatma görevi olmayan, harekeli Elif’lere ',
      ),
      _b('Hemze'),
      _n(' dendiğini unutmayalım.\n\n'),
      _n('Kendisinden sonra gelen harf, Lâm’ın nasıl okunacağını belirler.\n\nBuna göre:\n'),
      _ar('(أَبْغِ حَجَّكَ وَخَفْ عَقِيمَهُ)', fontSize: 28),
      _n('\ncümlesini oluşturan\n'),
      _ar('(ء ب ج ح خ ع غ ف ق ك م و هـ ى)', fontSize: 28),
      _n('\nHarflerinden biri gelirse; '),
      _b('Lâm cezimli olarak okunur.', color: AppColors.red),
      _n('\nBu harfler, tamamı 28 olan Kur’an harflerinin yarısıdır.\n\n'),
      _b('Örnekler:\n', color: AppColors.gold),
      _grid(
        kElTakisiOkunanWords,
        highlight: WordHighlight.elLam,
        columns: 4,
        minCellWidth: 90,
      ),
    ],
  ),

  'el-takisi-okunmayan': LessonInfo(
    title: 'El Takısı - Okunmayan Harfler',
    body: [
      _n('Geriye kalan 14 harften\n'),
      _ar('(ض ص ش س ز ر د ذ ت ث ط ظ ل ن)', fontSize: 28),
      _n('\nbiri geldiğinde ise; '),
      _b('Lâm okunmaz.', color: AppColors.red),
      _n(' Sonraki harf mutlaka şeddeli okunur.\n\n'),
      _b('Örnekler:\n', color: AppColors.gold),
      _grid(
        kElTakisiOkunmayanWords,
        highlight: WordHighlight.elLam,
        columns: 4,
        minCellWidth: 90,
      ),
    ],
  ),

  'el-takisi-hemze': LessonInfo(
    title: 'El Takısı ve Hemze',
    body: [
      _b('El takısı '),
      _ar('(اَلْ)', fontSize: 24),
      _n('’ndaki Lâm’ın, iki şekildeki farklı okunuşunu görmüş olduk.\n\n'),
      _n('Lâm’dan önceki '),
      _b('Hemze'),
      _n('’ye gelince;\n\n'),
      _n('• Bir önceki harften veya kelimeden geçiş yaparken, '),
      _b('El takısı '),
      _ar('(اَلْ)', fontSize: 24),
      _n('’ndaki '),
      _b('Hemze okunmaz.', color: AppColors.red),
      _n(' Örnekler:\n'),
      _grid(kElTakisiHemzeWords.sublist(0, 6), highlight: WordHighlight.elAlif),
      _n('\n\n'),
      _n('• Eğer okumaya '),
      _b('El takısı '),
      _ar('(اَلْ)', fontSize: 24),
      _n('’nın Hemze’siyle başlanırsa, bu durumda '),
      _b('Hemze her zaman üstünlü olarak okunur.', color: AppColors.red),
      _n(' Örnekler:\n'),
      _grid(kElTakisiHemzeWords.sublist(6), highlight: WordHighlight.elAlif),
      _n('\n\n'),
      _n('• Harekesi kalıcı olmadığından dolayı bu Hemze’yi '),
      _b('Vasıl Hemze'),
      _n('’si olarak tanımlamak daha doğrudur.'),
    ],
  ),

  'el-takisi-hemze-vasil': LessonInfo(
    title: 'El Takısı - Hemze-i Vasıl',
    body: [
      _n('Kelime başında bulunan bazı '),
      _b('Hemze'),
      _n(
        '’ler, önceki kelime veya harfle beraber okunurken harekesi düşer, orada sanki bir hemze yokmuş gibi okunur.\n\n',
      ),
      _n('Harekesiz Elif '),
      _ar('(ا)', fontSize: 24),
      _n(' şeklinde yazılır. Bazen üzerine, okunmadığını gösteren küçük bir “vasıl işareti” '),
      _ar('(ٱ)', fontSize: 24),
      _n(' konur.\nBu durumdaki hemzelere '),
      _b('Vasıl Hemzesi', color: AppColors.red),
      _n(' denir. Örnekler:\n'),
      // The lesson lists each word twice: read on with the previous word
      // (odd entries here) and read first (even entries).
      _grid(_everyOther(kElTakisiHemzeVasilWords, 1), highlight: WordHighlight.vasl),
      _n('\n\n'),
      _n(
        'Eğer öncesiyle beraber değil de, kelime başında ilk harf olarak okunursa; harekesi verilerek okunur. Örnekler:\n',
      ),
      _grid(_everyOther(kElTakisiHemzeVasilWords, 0), highlight: WordHighlight.firstLetter),
      _n('\n\n'),
      _n('Her Elif-Lâm takısı '),
      _ar('(اَلْ)', fontSize: 24),
      _n('’nın Elif’inin de böyle olduğunu bir önceki derste görmüştük.'),
    ],
  ),

  'zamir-he-uzatilmasi': LessonInfo(
    title: 'Zamir (He) Uzatılması',
    body: [
      _b('He Harfi Hangi Durumlarda Uzatılır?\n\n', color: AppColors.gold),
      _he,
      _n('’den önceki harf harekeli ise uzatılarak okunur. Ne kadar uzatılacağını ise, '),
      _he,
      _n('’den sonra gelen harf belirler. Şöyle ki:\n\n'),
      _n('• Uzatılan '),
      _he,
      _n('’den sonra Hemze gelirse '),
      _b('4 hareke', color: AppColors.red),
      _n(' miktarı uzatılır. Örnekler:\n'),
      _grid(kZamirHeUzatilmasiWords.sublist(0, 6), highlight: WordHighlight.he, minCellWidth: 200),
      _n('\n\n'),
      _n('• Uzatılan '),
      _he,
      _n('’den sonra Hemze’nin dışında herhangi bir harf gelirse '),
      _b('2 hareke', color: AppColors.red),
      _n(' miktarı uzatılır. Örnekler:\n'),
      _grid(kZamirHeUzatilmasiWords.sublist(6), highlight: WordHighlight.he, minCellWidth: 200),
    ],
  ),

  'zamir-he-uzatma-med': LessonInfo(
    title: 'Zamir (He) - Med İle Uzatma',
    body: [
      _n(
        'Uzatma miktarı 2 harekenin üzerinde olan bazı Med çeşitlerinin üzerinde bulunur. Tecvid derslerinde ayrıntılı bilgi verilecektir.\n\n',
      ),
      _grid(kZamirHeUzatmaMedWords, highlight: WordHighlight.med, minCellWidth: 110),
    ],
  ),

  'zamir-he-uzatma-yok': LessonInfo(
    title: 'Zamir (He) - Uzatma Yok',
    body: [
      _b('He Harfi Hangi Durumlarda Uzatılmaz?\n\n', color: AppColors.gold),
      _n('• '),
      _he,
      _n('’den önce uzatma harflerinden biri gelirse '),
      _he,
      _n(' uzatılmadan okunur. '),
      _he,
      _n('’den sonra ise, hangi harf gelirse gelsin, durumu etkilemez. Örnekler:\n'),
      _grid(kZamirHeUzatmaYokWords, highlight: WordHighlight.he, minCellWidth: 200),
    ],
  ),

  'zamir-he-uzatma-yok-cezimli': LessonInfo(
    title: 'Zamir (He) - Uzatma Yok (Cezimli)',
    body: [
      _n('• '),
      _he,
      _n('’den önce cezimli herhangi bir harf gelirse, yine uzatılmadan okunur. '),
      _he,
      _n('’den sonra ise, hangi harf gelirse gelsin durumu etkilemez. Örnekler:\n'),
      _grid(kZamirHeUzatmaYokCezimliWords, highlight: WordHighlight.he, minCellWidth: 200),
    ],
  ),

  'zamir-he-uzatma-yok-cezimli-seddeli': LessonInfo(
    title: 'Zamir (He) - Uzatma Yok (Cezimli, Şeddeli)',
    body: [
      _n('• '),
      _he,
      _n(' harfinden (önce harekeli bir harf olsa bile) önündeki kelimeye cezimli veya şeddeli bir harfe bağlanarak geçiş yapılırsa yine “'),
      _he,
      _n('” uzatılmadan okunur. Örnekler:\n'),
      _grid(kZamirHeUzatmaYokCezimliSeddeliWords, highlight: WordHighlight.he, minCellWidth: 200),
    ],
  ),

  'kapali-te': LessonInfo(
    title: 'Kapalı Te',
    body: [
      _n('Bazen “Te '),
      _ar('(ت)', fontSize: 26),
      _n('” harfi, “Kapalı Te” denilen şekilde yazılır: '),
      _ar('(ة ، ـة)', fontSize: 26),
      _n('. Bu sadece kelime sonunda olur.\n\n'),
      _n('Önceki harfe bitişirse '),
      _ar('(ـة)', fontSize: 26),
      _n(' şeklinde, bitişmediği durumlarda ise '),
      _ar('(ة)', fontSize: 26),
      _n(' şeklinde yazılır.\n\n'),
      _n('Sonunda “Kapalı Te” olan kelimede durulduğunda cezimli He '),
      _ar('(ـهْ)', fontSize: 26),
      _n(' gibi okunur. Sonraki kelimeye geçildiğinde ise yine '),
      _b('“Te”', color: AppColors.red),
      _n(' olarak, harekesiyle okunur.\n\n'),
      _b('Örneklerle uygulamayı görelim:\n', color: AppColors.gold),
      _table(kKapaliTeExamples),
    ],
  ),

  'kelime-sonu-duraklar': LessonInfo(
    title: 'Kelime Sonu Durakları (Duruş)',
    firstSpanIsBookHeading: true,
    body: [
      _b(
        'Kelime sonundaki harekeli harfte nasıl durulur?\n\n',
        color: AppColors.gold,
      ),
      _n('Kur’an okurken, genellikle:\n'),
      _n(
        '• ayet sonlarında,\n• durak işaretlerinde\n• veya nefes almamız gerektiğinde dururuz. (Bu duruş da, sadece kelime sonlarında olabilir.)\n\n',
      ),
      _b('Üstün, Esre veya Ötre harekeleri ile duruş yapılmaz. ', color: AppColors.red),
      _n(
        'Kelime sonundaki harf sakin değilse (yani cezimli bir harf veya uzatma harfi değilse); harekesi okunmaz ve harf, sanki üzerinde cezim varmış gibi okunur.\n\n',
      ),
      _b('Örnekler:\n', color: AppColors.gold),
      _table(kWaqfHarekeliExamples),
      _n('\n\n'),
      _b('Tenvinlilerde ise uygulama şöyledir;\n\n'),
      _n(
        '• Elif ile birlikte yazılan “İki Üstün”lü de; Üstün’ün biri kaldırılır. Harf, tek üstün ile, iki hareke miktarı uzatılarak okunur.\n\n',
      ),
      _b('Örnekler:\n', color: AppColors.gold),
      _table(kWaqfElifliTenvinExamples),
      _n('\n\n'),
      _n(
        '• Elifsiz yazılan “İki Üstün”lü bir Hemzede durulduğunda da yanında elif varmış gibi, iki hareke miktarı uzatılarak okunur.\n\n',
      ),
      _b('Örnekler:\n', color: AppColors.gold),
      _table(kWaqfHemzeTenvinExamples),
      _n('\n\n'),
      _n('• İki Esre veya İki Ötreli harflerde ise, Cezim’le durulur.\n\n'),
      _b('Örnekler:\n', color: AppColors.gold),
      _table(kWaqfIkiEsreOtreExamples),
      _n('\n\n'),
      _b('Diğer bazı örnekler:\n', color: AppColors.gold),
      _table(kWaqfOtherExamples),
    ],
  ),

  'alistirmalar-1': LessonInfo(
    title: 'Alıştırmalar 1',
    body: [_n('Öğrenilen kuralların hepsini bir araya getiren genel okuma alıştırması.')],
  ),
  'alistirmalar-2': LessonInfo(
    title: 'Alıştırmalar 2',
    body: [_n('Öğrenilen kuralların hepsini bir araya getiren genel okuma alıştırması.')],
  ),
  'alistirmalar-3': LessonInfo(
    title: 'Alıştırmalar 3',
    body: [_n('Öğrenilen kuralların hepsini bir araya getiren genel okuma alıştırması.')],
  ),
  'alistirmalar-4': LessonInfo(
    title: 'Alıştırmalar 4',
    body: [_n('Öğrenilen kuralların hepsini bir araya getiren genel okuma alıştırması.')],
  ),
};
