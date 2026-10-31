import 'dart:ui';

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
  // Cards 12-23 (`assets_src/lessons/sure_kartlari_12_23.jpeg`) =
  // kAllNamazTexts after kSureler, in order.
  'ayetel-kursi': '$_sureler/sure_12.png',
  'nebe-son': '$_sureler/sure_13.png',
  'duha': '$_sureler/sure_14.png',
  'insirah': '$_sureler/sure_15.png',
  'tin': '$_sureler/sure_16.png',
  'kadir': '$_sureler/sure_17.png',
  'zilzal': '$_sureler/sure_18.png',
  'adiyat': '$_sureler/sure_19.png',
  'karia': '$_sureler/sure_20.png',
  'tekasur': '$_sureler/sure_21.png',
  'asr': '$_sureler/sure_22.png',
  'humeze': '$_sureler/sure_23.png',
};

/// Prayer id ([Dua.id]) → old card picture (with its title drawn in;
/// "Dua 1" … "Dua 9" from the master, 10-15 from Gemini). Kept; a
/// text-free picture in [kDuaTextFreeImages] replaces it.
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
  '10_ezan_duasi': '$_dualar/dua_10.png',
  '11_namaz_tekbir_tesbih': '$_dualar/dua_11.png',
  '12_namaz_tesbihati': '$_dualar/dua_12.png',
  '13_yemek_duasi': '$_dualar/dua_13.png',
  '14_salaten_tuncina': '$_dualar/dua_14.png',
  '15_tefriciye': '$_dualar/dua_15.png',
};

/// New pictures WITHOUT any text (`assets/images/lessons/yazisiz/`): the app
/// writes number and title under the card. Prayers: ChatGPT's 5×3 sheet
/// (`assets_src/chatgpt_kartlar/NN_*.png`), matched by meaning, not by the
/// sheet's order (e.g. Mescid-i Nebevî → Allâhümme Salli, Kâbe → Rabbenâ
/// Âtinâ, after-meal → Yemek Duası).
///
/// Add an id here (or run
/// `tool/install_dua_card.py`) and its old card is replaced; the old
/// pictures stay (backup copies in `assets_src/kart_yedek/`).
const String _yazisiz = 'assets/images/lessons/yazisiz';
const Map<String, String> kDuaTextFreeImages = {
  '1_subhaneke_duasi': '$_yazisiz/dualar/dua_01.png',
  '2_ettahiyatu_duasi': '$_yazisiz/dualar/dua_02.png',
  '3_salli_duasi': '$_yazisiz/dualar/dua_03.png',
  '4_barik_duasi': '$_yazisiz/dualar/dua_04.png',
  '5_atina_duasi': '$_yazisiz/dualar/dua_05.png',
  '6_rabbenafirli_duasi': '$_yazisiz/dualar/dua_06.png',
  '7_kunut1_duasi': '$_yazisiz/dualar/dua_07.png',
  '8_kunut2_duasi': '$_yazisiz/dualar/dua_08.png',
  '9_amentu_duasi': '$_yazisiz/dualar/dua_09.png',
  '10_ezan_duasi': '$_yazisiz/dualar/dua_10.png',
  '11_namaz_tekbir_tesbih': '$_yazisiz/dualar/dua_11.png',
  '12_namaz_tesbihati': '$_yazisiz/dualar/dua_12.png',
  '13_yemek_duasi': '$_yazisiz/dualar/dua_13.png',
  '14_salaten_tuncina': '$_yazisiz/dualar/dua_14.png',
  '15_tefriciye': '$_yazisiz/dualar/dua_15.png',
};

/// Surah id → text-free picture: ChatGPT's 6×4 sheet
/// (`assets_src/chatgpt_sure_kartlari/NN.png`), matched by meaning, not by
/// the sheet's order (elephant → Fil, caravan → Kureyş, fire → Tebbet, earth
/// in space → Âyetel Kürsî, cracked ground → Zilzâl, fig tree → Tîn …).
const Map<String, String> kSurahTextFreeImages = {
  'fatiha': '$_yazisiz/sureler/sure_01.png',
  'fil': '$_yazisiz/sureler/sure_02.png',
  'kureysh': '$_yazisiz/sureler/sure_03.png',
  'maun': '$_yazisiz/sureler/sure_04.png',
  'kevser': '$_yazisiz/sureler/sure_05.png',
  'kafirun': '$_yazisiz/sureler/sure_06.png',
  'nasr': '$_yazisiz/sureler/sure_07.png',
  'tebbet': '$_yazisiz/sureler/sure_08.png',
  'ihlas': '$_yazisiz/sureler/sure_09.png',
  'felak': '$_yazisiz/sureler/sure_10.png',
  'nas': '$_yazisiz/sureler/sure_11.png',
  'ayetel-kursi': '$_yazisiz/sureler/sure_12.png',
  'nebe-son': '$_yazisiz/sureler/sure_13.png',
  'duha': '$_yazisiz/sureler/sure_14.png',
  'insirah': '$_yazisiz/sureler/sure_15.png',
  'tin': '$_yazisiz/sureler/sure_16.png',
  'kadir': '$_yazisiz/sureler/sure_17.png',
  'zilzal': '$_yazisiz/sureler/sure_18.png',
  'adiyat': '$_yazisiz/sureler/sure_19.png',
  'karia': '$_yazisiz/sureler/sure_20.png',
  'tekasur': '$_yazisiz/sureler/sure_21.png',
  'asr': '$_yazisiz/sureler/sure_22.png',
  'humeze': '$_yazisiz/sureler/sure_23.png',
  // Âmenerrasûlü (read at night): the bedtime scene of the prayer sheet,
  // also Kunut 2's, until a picture of its own comes.
  'amenerrasulu': '$_yazisiz/sureler/sure_24.png',
  // Hüvellezî (read after the prayer): Namaz Tesbihatı's child with the
  // prayer beads, cut square, until a picture of its own comes.
  'huvellezi': '$_yazisiz/sureler/sure_25.png',
};

/// The picture a prayer card shows: the text-free one when there is one.
String? duaCardImage(String id) => kDuaTextFreeImages[id] ?? kDuaCardImages[id];

/// The picture a surah card shows: the text-free one when there is one.
String? surahCardImage(String id) =>
    kSurahTextFreeImages[id] ?? kSurahCardImages[id];

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
/// width. The prayer cards follow the text-free pictures, portrait 296×336
/// (an old 3:2 card is fitted whole inside); the surah cards follow theirs,
/// square 240×240 (an old 1.88-2.60 card is fitted whole inside).
const double kDuaCardAspectRatio = 296 / 336;
const double kDuaCardRadiusFactor = 12 / 296;

/// Pixel size of the text-free prayer pictures.
const Size kDuaCardImageSize = Size(296, 336);
const double kSurahCardAspectRatio = 1.0;
const double kSurahCardRadiusFactor = 10 / 240;

/// Pixel size of the text-free surah pictures (square).
const Size kSurahCardImageSize = Size(240, 240);
