import 'package:flutter/material.dart';
import '../../../models/surah.dart';
import '../../../widgets/recitation_audio_controls.dart';

class SurahAudioControls extends StatelessWidget {
  final Surah surah;
  const SurahAudioControls({super.key, required this.surah});

  @override
  Widget build(BuildContext context) =>
      RecitationAudioControls(playlist: surah.playlist);
}
