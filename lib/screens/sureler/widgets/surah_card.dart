import 'package:flutter/material.dart';
import '../../../models/surah.dart';
import '../../../widgets/recitation_card.dart';

class SurahCard extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;
  const SurahCard({super.key, required this.surah, required this.onTap});
  @override
  Widget build(BuildContext context) => RecitationCard(
    title: surah.titleTr,
    arabic: surah.arabicName,
    onTap: onTap,
  );
}
