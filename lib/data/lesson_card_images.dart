/// The picture of each lesson's card in the lesson list (lesson id → asset).
/// Cropped from `assets/images/lessons/lesson_cards_master.png` by
/// `tool/crop_lesson_cards.py` (not redrawn). The picture already carries the
/// lesson's number and title, so the card writes nothing over it.
///
/// "kelime-sonu-duraklar" (Ders 30) is not in the master picture; its card
/// is cropped from its own picture (same script). A lesson without a picture
/// gets a text card.
const String _dir = 'assets/images/lessons/cards';

const Map<String, String> kLessonCardImages = {
  'giris-harflerin-cikis-yerleri': '$_dir/intro_harflerin_cikis_yerleri.png',
  'harfleri-taniyalim': '$_dir/lesson_01.png',
  'harflerin-yazilislari': '$_dir/lesson_02.png',
  'ustun': '$_dir/lesson_03.png',
  'esre': '$_dir/lesson_04.png',
  'otre': '$_dir/lesson_05.png',
  'cikis-yerleri': '$_dir/lesson_06.png',
  'cezm': '$_dir/lesson_07.png',
  'harekeler-alistirmalari': '$_dir/lesson_08.png',
  'sedde': '$_dir/lesson_09.png',
  'alistirmalar-sedde': '$_dir/lesson_10.png',
  'uzatma-elif': '$_dir/lesson_11.png',
  'uzatma-elif-alistirmalari': '$_dir/lesson_12.png',
  'uzatma-ya': '$_dir/lesson_13.png',
  'uzatma-ya-alistirmalari': '$_dir/lesson_14.png',
  'uzatma-vav': '$_dir/lesson_15.png',
  'uzatma-vav-alistirmalari': '$_dir/lesson_16.png',
  'uzatma-vav-kelime-sonunda': '$_dir/lesson_17.png',
  'ceker-ustun': '$_dir/lesson_18.png',
  'ceker-esre': '$_dir/lesson_19.png',
  'tenvin-iki-ustun': '$_dir/lesson_20.png',
  'tenvin-iki-esre': '$_dir/lesson_21.png',
  'tenvin-iki-otre': '$_dir/lesson_22.png',
  'el-takisi-okunan': '$_dir/lesson_23.png',
  'el-takisi-okunmayan': '$_dir/lesson_24.png',
  'el-takisi-hemze': '$_dir/lesson_25.png',
  'el-takisi-hemze-vasil': '$_dir/lesson_26.png',
  'zamir-he-uzatilmasi': '$_dir/lesson_27.png',
  'zamir-he-uzatma-med': '$_dir/lesson_28.png',
  'kapali-te': '$_dir/lesson_29.png',
  'kelime-sonu-duraklar': '$_dir/lesson_30.png',
  'alistirmalar-1': '$_dir/lesson_31.png',
  'alistirmalar-2': '$_dir/lesson_32.png',
  'alistirmalar-3': '$_dir/lesson_33.png',
  'alistirmalar-4': '$_dir/lesson_34.png',
};
