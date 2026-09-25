import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../theme/app_colors.dart';
import 'yazi_mode_screens.dart';

/// Arapça Yazıyorum: üç mod. İlk görev "Adını yaz!".
class ArapcaYaziyorumScreen extends StatelessWidget {
  const ArapcaYaziyorumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final modes = [
      (
        'mode-name',
        Icons.badge_rounded,
        'Adını Yaz',
        'İlk görev: adını Arapça harflerle yaz, isim kartını yap.',
        AppColors.goldSoft,
        AppColors.gold,
        () => const NameModeScreen(),
      ),
      (
        'mode-copy',
        Icons.visibility_rounded,
        'Bak ve Yaz',
        'Harfleri ve kısa kelimeleri örneğe bakarak yaz.',
        AppColors.turquoiseSoft,
        AppColors.turquoise,
        () => const CopyModeScreen(),
      ),
      (
        'mode-free',
        Icons.edit_rounded,
        'Serbest Yaz',
        'İstediğin harfleri, kelimeleri yaz.',
        AppColors.sageSoft,
        AppColors.sage,
        () => const FreeModeScreen(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Arapça Yazıyorum')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 760 : 640,
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Ekrandaki Arapça klavyeyle yaz; harfler kendiliğinden birleşir.',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              for (final (key, icon, title, subtitle, bg, fg, builder)
                  in modes) ...[
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    key: ValueKey(key),
                    borderRadius: BorderRadius.circular(20),
                    onTap:
                        () => Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => builder())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, color: fg, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.navySoft,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
