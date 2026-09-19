import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

/// Shared entry card for recitations. A preview is source text, not a title.
class RecitationCard extends StatelessWidget {
  final String title;
  final String arabic;
  final bool isPreview;
  final VoidCallback onTap;
  const RecitationCard({
    super.key,
    required this.title,
    required this.arabic,
    this.isPreview = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              if (isPreview)
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) => Center(
                    child: FittedBox(fit: BoxFit.scaleDown, child: SizedBox(
                      width: constraints.maxWidth,
                      child: Text(
                      arabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppTextTheme.arabicSmall(
                        fontSize: 30,
                      ).copyWith(color: AppColors.turquoise, height: 1.7),
                    ),
                    )),
                  )),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        arabic,
                        style: AppTextTheme.arabicSmall(
                          fontSize: 40,
                        ).copyWith(color: AppColors.turquoise),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.turquoiseSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.turquoise,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
