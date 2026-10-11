import 'content_strings.g.dart';
import 'game_narrations.g.dart';
import 'ui_common.dart';
import 'ui_elifba.dart';
import 'ui_games_core.dart';
import 'ui_games_dedektif.dart';
import 'ui_games_harf_oyunlari.dart';
import 'ui_games_yazi_cizim.dart';
import 'ui_home.dart';
import 'ui_reading.dart';

/// Every translation table: Turkish text → [es, fr, de, en, bs].
const List<Map<String, List<String>>> kStringTables = [
  kUiCommon,
  kUiHome,
  kUiElifba,
  kUiReading,
  kUiGamesCore,
  kUiGamesHarfOyunlari,
  kUiGamesYaziCizim,
  kUiGamesDedektif,
  kContentStrings,
  kGameNarrationStrings,
];
