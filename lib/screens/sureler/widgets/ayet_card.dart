import '../../../widgets/reading_arabic_text.dart';
import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../models/surah.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../../../widgets/reading_text_settings.dart';

/// One verse: a small number badge, the Arabic text as the clear
/// visual priority, and — kept clearly separate, never interleaved —
/// its Turkish meaning underneath. Arabic sizing scales up again on
/// tablet/desktop instead of staying phone-sized on a bigger screen.
///
/// Tapping the card plays just this ayet's own recording via [onTap]
/// — independent of the surah-wide "Dinle" playlist. Tapping it again
/// while it's the current asset toggles pause/resume rather than
/// restarting, so [isPlaying] (distinct from [isHighlighted], which
/// also covers "this is current but paused") picks the icon.
class AyetCard extends StatelessWidget {
  final Ayet ayet;
  final bool isHighlighted;
  final bool isPlaying;
  final VoidCallback? onTap;

  const AyetCard({
    super.key,
    required this.ayet,
    this.isHighlighted = false,
    this.isPlaying = false,
    this.onTap,
  });

  double _arabicFontSize(DeviceClass deviceClass) => switch (deviceClass) {
    DeviceClass.mobile => 30,
    DeviceClass.tablet => 42,
    DeviceClass.desktop => 46,
  };

  @override
  Widget build(BuildContext context) {
    final deviceClass = Responsive.deviceClassOf(context);
    final arabicFontSize = _arabicFontSize(deviceClass);

    return Material(
      color: isHighlighted ? AppColors.turquoiseSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHighlighted ? AppColors.turquoise : AppColors.divider,
              width: isHighlighted ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.goldSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${ayet.number}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isHighlighted
                        ? (isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded)
                        : Icons.play_circle_outline_rounded,
                    color:
                        isHighlighted
                            ? AppColors.turquoise
                            : AppColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.rtl,
                child: ReadingArabicText(ayet.arabic,
                  style: AppTextTheme.arabicSmall(
                    fontSize: arabicFontSize,
                  ).copyWith(color: AppColors.navy, height: 1.9),
                ),
              ),
              if (ayet.meaningTr.isNotEmpty)
                ReadingMeaning(
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: 14),
                      Text(
                        ayet.meaningTr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
