import '../../../widgets/reading_arabic_text.dart';
import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../models/dua.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../../../widgets/reading_text_settings.dart';

class DuaSegmentCard extends StatelessWidget {
  final DuaSegment segment;
  final int number;
  final bool isHighlighted;
  final bool isPlaying;
  final VoidCallback onTap;

  const DuaSegmentCard({
    super.key,
    required this.segment,
    required this.number,
    required this.isHighlighted,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final device = Responsive.deviceClassOf(context);
    final fontSize = switch (device) {
      DeviceClass.mobile => 30.0,
      DeviceClass.tablet => 42.0,
      DeviceClass.desktop => 46.0,
    };
    final bodySize = device == DeviceClass.mobile ? 16.0 : 19.0;
    Widget section(String title, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.turquoise,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: bodySize,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    return Material(
      color: isHighlighted ? AppColors.turquoiseSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHighlighted ? AppColors.turquoise : AppColors.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.goldSoft,
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onTap,
                    tooltip: isPlaying ? 'Duraklat' : 'Parçayı dinle',
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_outline_rounded,
                      color: AppColors.turquoise,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ReadingArabicText(segment.arabic,
                style: AppTextTheme.arabicSmall(
                  fontSize: fontSize,
                ).copyWith(height: 1.9),
              ),
              if (segment.pronunciationTr case final pronunciation?
                  when pronunciation.isNotEmpty)
                section('Türkçe Okunuş', pronunciation),
              if (segment.meaningTr.isNotEmpty)
                ReadingMeaning(
                  child: section('Türkçe Anlam', segment.meaningTr),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
