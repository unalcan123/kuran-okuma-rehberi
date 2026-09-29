import 'package:flutter/material.dart';

import '../../models/reading_segment.dart';
import '../../models/surah.dart';
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
    title: surah.titleTr,
    arabicTitle: surah.arabicName,
    segments: ReadingSegment.ofSurah(surah),
    nouns: ReadingNouns.surah,
  );
}
