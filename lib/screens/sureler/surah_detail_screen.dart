import '../../data/full_reading_audio.dart';
import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../models/reading_segment.dart';
import '../../models/surah.dart';
import '../../theme/app_text_theme.dart';
import '../../widgets/reading/reading_screen.dart';
import '../../widgets/reading/reading_settings_sheet.dart';

/// A surah's reading screen: its besmele (own recording, read first, as in
/// the dataset) and ayetler on the shared children's reading screen
/// ([ReadingScreen]: Dinle, repeat, speed, auto-scroll, memorizing).
class SurahDetailScreen extends StatelessWidget {
  final Surah surah;

  const SurahDetailScreen({super.key, required this.surah});

  @override
  Widget build(BuildContext context) => ReadingScreen(
    key: ValueKey('surah-${surah.id}-${context.language.code}'),
    title: context.t(surah.titleTr),
    arabicTitle: surah.arabicName,
    segments: ReadingSegment.ofSurah(
      surah,
      languageCode: context.language.code,
    ),
    fullAudioAsset: kFullReadingAudio[surah.id] ?? '',
    nouns: ReadingNouns.surah,
    arabicFontFamily: AppTextTheme.quranFontFamily,
  );
}
