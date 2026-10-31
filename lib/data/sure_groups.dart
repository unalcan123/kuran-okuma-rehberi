import '../models/surah.dart';
import 'ayetel_kursi_data.dart';
import 'supplementary_sureler_data.dart';
import 'sureler_data.dart';

/// A card on the Sureler home: a set of readings opened as their own grid.
class SureGroup {
  const SureGroup({
    required this.id,
    required this.titleTr,
    required this.surahs,
    this.notesTr = const {},
  });

  /// Path segment (`/sureler/<id>`).
  final String id;
  final String titleTr;
  final List<Surah> surahs;

  /// When a reading is read (shown on its card instead of "Sure n").
  final Map<String, String> notesTr;
}

/// The Sureler home (user's grouping, 2026-10-31): the short surahs read
/// in the prayer, the Amme part's aşirs, and what is read after the prayers.
final kSureGroups = <SureGroup>[
  const SureGroup(
    id: 'namaz',
    titleTr: 'Namazda Okunan Kısa Sureler',
    surahs: kSureler,
  ),
  SureGroup(
    id: 'amme',
    titleTr: 'Amme Cüzündeki Aşirler',
    surahs: [
      for (final s in kSupplementarySureler)
        if (s.id != kSupplementNebeSon.id) s,
    ],
  ),
  const SureGroup(
    id: 'namaz-sonrasi',
    titleTr: 'Namazlardan Sonra Okunan Sureler, Aşirler',
    surahs: [
      kAyatelKursi,
      kHuvallahullezi,
      kHuvellezi,
      kSupplementNebeSon,
      kAmenerrasulu,
    ],
    notesTr: {
      'ayetel-kursi': 'Her namazdan sonra',
      'huvallahullezi': 'Sabah ve akşam namazlarından sonra',
      'huvellezi': 'Öğle namazından sonra',
      'nebe-son': 'İkindi namazından sonra',
      'amenerrasulu': 'Yatsı namazından sonra',
    },
  ),
];
