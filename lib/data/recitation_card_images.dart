/// Pictures of the surah and prayer cards in their lists (stable id →
/// asset), cropped by `tool/crop_lesson_cards.py` from
/// `assets/images/lessons/sure kartlari.png` and `duakartlari.png` (not
/// redrawn). The picture carries the title; the card writes nothing over it.
///
/// A card is listed here only when the master's card IS that surah / prayer
/// (checked card by card; "Sure 1" … "Sure 11" = [kSureler] in order). An
/// item without a picture gets a text card of the same shape.
const String _sureler = 'assets/images/lessons/sureler';
const String _dualar = 'assets/images/lessons/dualar';

/// Surah id ([Surah.id]) → card picture.
const Map<String, String> kSurahCardImages = {
  'fatiha': '$_sureler/sure_01.png',
  'fil': '$_sureler/sure_02.png',
  'kureysh': '$_sureler/sure_03.png',
  'maun': '$_sureler/sure_04.png',
  'ihlas': '$_sureler/sure_05.png',
  'kevser': '$_sureler/sure_06.png',
  'nas': '$_sureler/sure_07.png',
  'felak': '$_sureler/sure_08.png',
  'nasr': '$_sureler/sure_09.png',
  'tebbet': '$_sureler/sure_10.png',
  'kafirun': '$_sureler/sure_11.png',
};

/// Prayer id ([Dua.id]) → card picture ("Dua 1" … "Dua 9").
const Map<String, String> kDuaCardImages = {
  '1_subhaneke_duasi': '$_dualar/dua_01.png',
  '2_ettahiyatu_duasi': '$_dualar/dua_02.png',
  '3_salli_duasi': '$_dualar/dua_03.png',
  '4_barik_duasi': '$_dualar/dua_04.png',
  '5_atina_duasi': '$_dualar/dua_05.png',
  '6_rabbenafirli_duasi': '$_dualar/dua_06.png',
  '7_kunut1_duasi': '$_dualar/dua_07.png',
  '8_kunut2_duasi': '$_dualar/dua_08.png',
  '9_amentu_duasi': '$_dualar/dua_09.png',
};

/// The prayers' titles as shown to the user on their cards (the ids and the
/// data's own `titleTr` stay as they are).
const Map<String, String> kDuaDisplayTitles = {
  '1_subhaneke_duasi': 'Sübhâneke Duası',
  '2_ettahiyatu_duasi': 'Ettehiyyâtü Duası',
  '3_salli_duasi': 'Allâhümme Salli Duası',
  '4_barik_duasi': 'Allâhümme Bârik Duası',
  '5_atina_duasi': 'Rabbenâ Âtinâ Duası',
  '6_rabbenafirli_duasi': 'Rabbenâğfirlî Duası',
  '7_kunut1_duasi': 'Allâhümme İnnâ Nesteînüke (Kunut 1)',
  '8_kunut2_duasi': 'Allâhümme İyyâke Na’büdü (Kunut 2)',
  '9_amentu_duasi': 'Âmentü Duası',
};

/// Shape of the cards: width : height and corner radius relative to the
/// width. The prayer pictures are 1.50-1.56; the surah pictures 1.88-2.14
/// (Tebbet and Kafirun, the master's wider last row, 2.60 — fitted whole,
/// a little shorter than the others).
const double kDuaCardAspectRatio = 1.53;
const double kDuaCardRadiusFactor = 20 / 490;
const double kSurahCardAspectRatio = 2.0;
const double kSurahCardRadiusFactor = 20 / 491;
