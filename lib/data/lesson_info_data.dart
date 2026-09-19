import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

/// Rich "ders açıklaması" content shown from the info (ⓘ) button on a
/// lesson screen. Adapted from the original Elifbe2025 project's
/// per-lesson description text — its numbering doesn't line up with
/// this app's lesson ids one-to-one (some old lessons were merged,
/// split or renumbered here), so entries are matched by topic, not by
/// number, and keyed by [Lesson.id].
class LessonInfo {
  final String title;
  final List<InlineSpan> body;

  const LessonInfo({required this.title, required this.body});
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
      _b('Kendisinden sonra gelen harf, Lâm’ın nasıl okunacağını belirler:\n\n'),
      _ar('ء ب ج ح خ ع غ ف ق ك م و هـ ى', fontSize: 26),
      _b('\n\nBu harflerden biri gelirse Lâm cezimli olarak okunur — bunlar kameri harflerdir.'),
    ],
  ),

  'el-takisi-okunmayan': LessonInfo(
    title: 'El Takısı - Okunmayan Harfler',
    body: [
      _b('Lâm’dan sonra geriye kalan 14 harften\n', color: AppColors.red),
      _ar('ض ص ش س ز ر د ذ ت ث ط ظ ل ن', fontSize: 24, color: AppColors.textPrimary),
      _b('\n\nbiri geldiğinde ise '),
      _b('Lâm okunmaz. ', color: AppColors.red),
      _b('Sonraki harf mutlaka şeddeli okunur — bunlar şemsi harflerdir.'),
    ],
  ),

  'el-takisi-hemze': LessonInfo(
    title: 'El Takısı ve Hemze',
    body: [
      _b('Lâm’dan önce gelen hemze\n\n'),
      _n(
        'Bir önceki harften veya kelimeden geçiş yapılırken el takısındaki hemze okunmaz. Ancak öncesiyle birleşmeden, kelime başında ilk harf olarak okunursa hemze her zaman üstünlü olarak okunur.',
      ),
    ],
  ),

  'el-takisi-hemze-vasil': LessonInfo(
    title: 'El Takısı - Hemze-i Vasıl',
    body: [
      _b('Okunmayan Hemze (Vasıl Hemzesi)\n\n', color: AppColors.gold),
      _n(
        'Kelime başında bulunan bazı hemzeler, önceki kelime veya harfle beraber okunurken harekesi düşer; orada sanki bir hemze yokmuş gibi okunur. Hareketsiz elif (ا) şeklinde yazılır ve küçük bir vasıl işareti (ٱ) konulur.\n\n',
      ),
      _n(
        'Eğer öncesiyle beraber değil de kelime başında ilk harf olarak okunursa, harekesi verilerek okunur.',
      ),
    ],
  ),

  'zamir-he-uzatilmasi': LessonInfo(
    title: 'Zamir (He) Uzatılması',
    body: [
      _b('Zamir “He” (هُ - هِ) nin uzatılması\n\n', color: AppColors.gold),
      _n(
        'He’den önceki harf harekeli ise uzatılarak okunur. Ne kadar uzatılacağını He’den sonra gelen harf belirler:\n\n',
      ),
      _n('• Uzatılan He’den sonra hemze gelirse '),
      _b('4 hareke '),
      _n('miktarı uzatılır.\n'),
      _n('• Hemze dışında herhangi bir harf gelirse '),
      _b('2 hareke '),
      _n('miktarı uzatılır.'),
    ],
  ),

  'zamir-he-uzatma-med': LessonInfo(
    title: 'Zamir (He) - Med İle Uzatma',
    body: [
      _b('Uzun Med İşareti (ـــ)\n\n', color: AppColors.gold),
      _n(
        'Uzatma miktarı 2 harekenin üzerinde olan bazı med çeşitlerinin üzerinde bulunur.',
      ),
    ],
  ),

  'zamir-he-uzatma-yok': LessonInfo(
    title: 'Zamir (He) - Uzatma Yok',
    body: [
      _b('He harfi hangi durumlarda uzatılmaz?\n\n'),
      _n(
        'He’den önce uzatma harflerinden biri gelirse He uzatılmadan okunur. He’den sonra hangi harf gelirse gelsin durum değişmez.',
      ),
    ],
  ),

  'zamir-he-uzatma-yok-cezimli': LessonInfo(
    title: 'Zamir (He) - Uzatma Yok (Cezimli)',
    body: [
      _n(
        'He’den önce cezimli herhangi bir harf gelirse yine uzatılmadan okunur. He’den sonra hangi harf gelirse gelsin durumu etkilemez.',
      ),
    ],
  ),

  'zamir-he-uzatma-yok-cezimli-seddeli': LessonInfo(
    title: 'Zamir (He) - Uzatma Yok (Cezimli, Şeddeli)',
    body: [
      _n(
        'He harfinden önce harekeli bir harf olsa bile, önündeki kelimeye cezimli veya şeddeli bir harfe bağlanarak geçiş yapılırsa yine “He” uzatılmadan okunur.',
      ),
    ],
  ),

  'kapali-te': LessonInfo(
    title: 'Kapalı Te',
    body: [
      _b('Kapalı “Te” (ة - ت)\n\n', color: AppColors.gold),
      _n(
        'Bazen “Te” harfi “kapalı te” denilen şekilde yazılır — bu sadece kelime sonunda olur. Önceki harfe bitişirse (ة) şeklinde, bitişmediği durumlarda ise (ه) şeklinde yazılır.\n\n',
      ),
      _n(
        'Sonunda kapalı te olan kelimede durulduğunda cezimli He gibi okunur. Sonraki kelimeye geçildiğinde ise yine “Te” olarak harekesiyle okunur.',
      ),
    ],
  ),

  'kelime-sonu-duraklar': LessonInfo(
    title: 'Kelime Sonu Durakları (Duruş)',
    body: [
      _b(
        'Kelime sonundaki harekeli harfte nasıl durulur?\n\n',
        color: AppColors.gold,
      ),
      _n(
        'Kur’an okurken genellikle ayet sonlarında, durak işaretlerinde veya nefes almamız gerektiğinde dururuz. Bu duruş sadece kelime sonlarında olabilir.\n\n',
      ),
      _b('Üstün, esre veya ötre harekeleri ile duruş yapılmaz.\n\n', color: AppColors.red),
      _n(
        'Kelime sonundaki harf sakin değilse harekesi okunmaz ve harf sanki üzerinde cezim varmış gibi okunur. Tenvinli harflerde elif ile yazılıysa tek üstünle iki hareke uzatılır; iki esre veya iki ötrede ise cezimle durulur.',
      ),
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
