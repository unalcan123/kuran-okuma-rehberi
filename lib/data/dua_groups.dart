import '../models/dua.dart';
import 'additional_dualar_data.dart';

/// A card on the Dualar home: a set of prayers opened as their own grid.
class DuaGroup {
  const DuaGroup({
    required this.id,
    required this.titleTr,
    required this.ids,
    this.notesTr = const {},
  });

  /// Path segment (`/dualar/<id>`).
  final String id;
  final String titleTr;

  /// Prayer ids ([Dua.id]) in the order shown.
  final List<String> ids;

  /// When a prayer is read (shown on its card instead of "Dua n").
  final Map<String, String> notesTr;

  List<Dua> get duas => [
    for (final id in ids) kAllDualar.firstWhere((d) => d.id == id),
  ];
}

/// The Dualar home (user's grouping, 2026-10-31): the 8 prayers read in
/// the prayer, those read after it, everyday prayers, and the call to
/// prayer with the prayer's spoken phrases.
const kDuaGroups = <DuaGroup>[
  DuaGroup(
    id: 'namaz',
    titleTr: 'Namazda Okunan Dualar',
    ids: [
      '1_subhaneke_duasi',
      '2_ettahiyatu_duasi',
      '3_salli_duasi',
      '4_barik_duasi',
      '5_atina_duasi',
      '6_rabbenafirli_duasi',
      '7_kunut1_duasi',
      '8_kunut2_duasi',
    ],
  ),
  DuaGroup(
    id: 'namaz-sonrasi',
    titleTr: 'Namazdan Sonra Okunan Dualar',
    ids: ['12_namaz_tesbihati', '14_salaten_tuncina'],
  ),
  DuaGroup(
    id: 'gunluk',
    titleTr: 'Günlük Dualar',
    ids: ['9_amentu_duasi', '13_yemek_duasi', '15_tefriciye'],
  ),
  DuaGroup(
    id: 'ezan-kamet',
    titleTr: 'Ezan, Kamet, Namaz Lafızları',
    ids: ['10_ezan_duasi', '11_namaz_tekbir_tesbih'],
  ),
];
