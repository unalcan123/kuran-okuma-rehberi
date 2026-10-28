import '../../data/full_reading_audio.dart';
import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../data/recitation_card_images.dart';
import '../../models/dua.dart';
import '../../models/reading_segment.dart';
import '../../widgets/reading/reading_screen.dart';
import '../../widgets/reading/reading_settings_sheet.dart';

/// A prayer's reading screen: its parts on the shared children's reading
/// screen ([ReadingScreen]) — the same engine as the surahs.
class DuaDetailScreen extends StatelessWidget {
  final Dua dua;

  const DuaDetailScreen({super.key, required this.dua});

  @override
  Widget build(BuildContext context) => ReadingScreen(
    key: ValueKey('dua-${dua.id}-${context.language.code}'),
    title: context.t(kDuaDisplayTitles[dua.id] ?? dua.titleTr),
    segments: ReadingSegment.ofDua(dua, languageCode: context.language.code),
    fullAudioAsset: kFullReadingAudio[dua.id] ?? '',
    nouns: ReadingNouns.dua,
  );
}
