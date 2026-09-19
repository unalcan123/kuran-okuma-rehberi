import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Generic "coming soon" screen used by every section that has no
/// real content yet, so they all share one consistent, on-brand
/// placeholder instead of a disabled/greyed-out card.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Color accentSoft;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: accent),
              ),
              const SizedBox(height: 24),
              Text(
                'Yakında',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$title bölümü üzerinde çalışıyoruz.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
