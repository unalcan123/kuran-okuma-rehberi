import 'package:flutter/painting.dart';

/// The picture of each lesson's card in the lesson list (lesson id → asset).
/// Cropped from `assets/images/lessons/lesson_cards_master.png` by
/// `tool/crop_lesson_cards.py` (not redrawn). The title and the Arabic
/// sample painted into the picture are not trusted (some were wrong): the
/// card covers them ([kLessonCardArt]) and writes the lesson's own label,
/// title and a correct sample over them.
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

/// One Arabic sample the card writes on a letter tile of its picture:
/// [rect] (fractions of the picture) covers the tile's painted text.
class LessonCardTile {
  final Rect rect;
  final String arabic;

  const LessonCardTile(this.rect, this.arabic);
}

/// Where a card picture's painted texts are, as fractions of the picture
/// ([size] in pixels): [title] covers the "Ders N" badge and the title;
/// each of [tiles] covers a letter tile's text. Measured by eye on the
/// cropped pictures (re-measure if they are cropped again).
class LessonCardArt {
  final Size size;
  final Rect title;
  final List<LessonCardTile> tiles;

  const LessonCardArt({
    required this.size,
    required this.title,
    this.tiles = const [],
  });
}

/// Every picture in [kLessonCardImages], by lesson id. The samples show
/// each lesson's own sign on ب (üstün بَ, esre بِ, ötre بُ, cezm بْ …) or a
/// word from the lesson's own list.
const Map<String, LessonCardArt> kLessonCardArt = {
  'giris-harflerin-cikis-yerleri': LessonCardArt(
    size: Size(245, 169),
    title: Rect.fromLTRB(0.03, 0.03, 0.56, 0.54),
  ),
  'harfleri-taniyalim': LessonCardArt(
    size: Size(250, 169),
    title: Rect.fromLTRB(0.03, 0.03, 0.46, 0.54),
  ),
  'harflerin-yazilislari': LessonCardArt(
    size: Size(244, 170),
    title: Rect.fromLTRB(0.03, 0.03, 0.48, 0.54),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.2, 0.5, 0.57, 0.9), 'بـ ـبـ ـب'),
    ],
  ),
  'ustun': LessonCardArt(
    size: Size(242, 169),
    title: Rect.fromLTRB(0.03, 0.03, 0.36, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.18, 0.42, 0.47, 0.86), 'بَ'),
    ],
  ),
  'esre': LessonCardArt(
    size: Size(248, 170),
    title: Rect.fromLTRB(0.03, 0.03, 0.36, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.2, 0.42, 0.47, 0.85), 'بِ'),
    ],
  ),
  'otre': LessonCardArt(
    size: Size(247, 170),
    title: Rect.fromLTRB(0.03, 0.03, 0.36, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.21, 0.42, 0.49, 0.84), 'بُ'),
    ],
  ),
  'cikis-yerleri': LessonCardArt(
    size: Size(245, 160),
    title: Rect.fromLTRB(0.03, 0.03, 0.76, 0.37),
  ),
  'cezm': LessonCardArt(
    size: Size(251, 160),
    title: Rect.fromLTRB(0.03, 0.03, 0.34, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.55, 0.34, 0.82, 0.86), 'بْ'),
    ],
  ),
  'harekeler-alistirmalari': LessonCardArt(
    size: Size(246, 160),
    title: Rect.fromLTRB(0.03, 0.03, 0.58, 0.47),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.53, 0.5, 0.78, 0.8), 'قُلْ'),
    ],
  ),
  'sedde': LessonCardArt(
    size: Size(242, 160),
    title: Rect.fromLTRB(0.03, 0.03, 0.34, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.43, 0.64, 0.69, 0.93), 'بَّ'),
    ],
  ),
  'alistirmalar-sedde': LessonCardArt(
    size: Size(248, 160),
    title: Rect.fromLTRB(0.03, 0.03, 0.8, 0.37),
  ),
  'uzatma-elif': LessonCardArt(
    size: Size(247, 160),
    title: Rect.fromLTRB(0.03, 0.03, 0.79, 0.5),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.42, 0.47, 0.7, 0.9), 'بَا'),
    ],
  ),
  'uzatma-elif-alistirmalari': LessonCardArt(
    size: Size(246, 177),
    title: Rect.fromLTRB(0.03, 0.03, 0.76, 0.46),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.4, 0.56, 0.53, 0.78), 'يَا'),
      LessonCardTile(Rect.fromLTRB(0.57, 0.56, 0.7, 0.78), 'تَا'),
      LessonCardTile(Rect.fromLTRB(0.75, 0.56, 0.88, 0.78), 'جَا'),
    ],
  ),
  'uzatma-ya': LessonCardArt(
    size: Size(250, 177),
    title: Rect.fromLTRB(0.03, 0.03, 0.73, 0.43),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.58, 0.55, 0.78, 0.88), 'بِي'),
    ],
  ),
  'uzatma-ya-alistirmalari': LessonCardArt(
    size: Size(246, 177),
    title: Rect.fromLTRB(0.03, 0.03, 0.74, 0.46),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.6, 0.55, 0.85, 0.86), 'حِينَ'),
    ],
  ),
  'uzatma-vav': LessonCardArt(
    size: Size(242, 176),
    title: Rect.fromLTRB(0.03, 0.03, 0.74, 0.46),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.58, 0.48, 0.83, 0.9), 'بُو'),
    ],
  ),
  'uzatma-vav-alistirmalari': LessonCardArt(
    size: Size(248, 177),
    title: Rect.fromLTRB(0.03, 0.03, 0.72, 0.46),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.18, 0.5, 0.33, 0.7), 'دُو'),
      LessonCardTile(Rect.fromLTRB(0.43, 0.47, 0.58, 0.66), 'تُو'),
      LessonCardTile(Rect.fromLTRB(0.67, 0.52, 0.81, 0.71), 'نُو'),
    ],
  ),
  'uzatma-vav-kelime-sonunda': LessonCardArt(
    size: Size(247, 177),
    title: Rect.fromLTRB(0.03, 0.03, 0.82, 0.46),
  ),
  'ceker-ustun': LessonCardArt(
    size: Size(246, 166),
    title: Rect.fromLTRB(0.03, 0.03, 0.55, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.28, 0.45, 0.55, 0.85), 'مُوسٰى'),
    ],
  ),
  'ceker-esre': LessonCardArt(
    size: Size(251, 166),
    title: Rect.fromLTRB(0.03, 0.03, 0.47, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.2, 0.5, 0.44, 0.9), 'بِهٖ'),
    ],
  ),
  'tenvin-iki-ustun': LessonCardArt(
    size: Size(246, 166),
    title: Rect.fromLTRB(0.03, 0.03, 0.76, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.56, 0.47, 0.84, 0.88), 'بً'),
    ],
  ),
  'tenvin-iki-esre': LessonCardArt(
    size: Size(242, 166),
    title: Rect.fromLTRB(0.03, 0.03, 0.7, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.28, 0.46, 0.52, 0.88), 'بٍ'),
    ],
  ),
  'tenvin-iki-otre': LessonCardArt(
    size: Size(248, 166),
    title: Rect.fromLTRB(0.03, 0.03, 0.68, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.58, 0.4, 0.82, 0.85), 'بٌ'),
    ],
  ),
  'el-takisi-okunan': LessonCardArt(
    size: Size(247, 166),
    title: Rect.fromLTRB(0.03, 0.03, 0.97, 0.45),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.59, 0.5, 0.85, 0.86), 'اَلْبَيْتُ'),
    ],
  ),
  'el-takisi-okunmayan': LessonCardArt(
    size: Size(246, 161),
    title: Rect.fromLTRB(0.03, 0.03, 0.97, 0.45),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.25, 0.46, 0.5, 0.86), 'اَلشَّمْسُ'),
    ],
  ),
  'el-takisi-hemze': LessonCardArt(
    size: Size(250, 161),
    title: Rect.fromLTRB(0.03, 0.03, 0.74, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.49, 0.47, 0.72, 0.88), 'وَالْعَصْرِ'),
    ],
  ),
  'el-takisi-hemze-vasil': LessonCardArt(
    size: Size(246, 161),
    title: Rect.fromLTRB(0.03, 0.03, 0.72, 0.47),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.37, 0.52, 0.65, 0.82), 'وَٱللّٰهُ'),
    ],
  ),
  'zamir-he-uzatilmasi': LessonCardArt(
    size: Size(242, 161),
    title: Rect.fromLTRB(0.03, 0.03, 0.85, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.15, 0.42, 0.42, 0.88), 'وَلَهُٓ'),
    ],
  ),
  'zamir-he-uzatma-med': LessonCardArt(
    size: Size(248, 162),
    title: Rect.fromLTRB(0.03, 0.03, 0.78, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.54, 0.36, 0.8, 0.68), 'سُوٓءَ'),
    ],
  ),
  'kapali-te': LessonCardArt(
    size: Size(247, 162),
    title: Rect.fromLTRB(0.03, 0.03, 0.41, 0.37),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.27, 0.47, 0.52, 0.88), 'ثَمَرَةٍ'),
    ],
  ),
  'kelime-sonu-duraklar': LessonCardArt(
    size: Size(400, 247),
    title: Rect.fromLTRB(0.02, 0.03, 0.62, 0.46),
    tiles: [
      LessonCardTile(Rect.fromLTRB(0.24, 0.47, 0.53, 0.8), 'صُدُورْ'),
    ],
  ),
  'alistirmalar-1': LessonCardArt(
    size: Size(245, 149),
    title: Rect.fromLTRB(0.03, 0.03, 0.58, 0.37),
  ),
  'alistirmalar-2': LessonCardArt(
    size: Size(249, 149),
    title: Rect.fromLTRB(0.03, 0.03, 0.58, 0.37),
  ),
  'alistirmalar-3': LessonCardArt(
    size: Size(246, 149),
    title: Rect.fromLTRB(0.03, 0.03, 0.58, 0.37),
  ),
  'alistirmalar-4': LessonCardArt(
    size: Size(271, 149),
    title: Rect.fromLTRB(0.03, 0.03, 0.58, 0.37),
  ),
};
