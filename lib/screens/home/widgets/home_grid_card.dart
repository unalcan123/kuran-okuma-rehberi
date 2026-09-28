import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../home_menu_item.dart';

/// A cell of the home screen's 2 x 2 grid (4:3). ([HomeMenuCard] is the
/// list-row card other menus, like Oyunlar, still use.) An item with an illustration fills the
/// whole card with it (no extra title: the picture has its own); the others
/// are placeholders (icon + title) until their illustrations arrive.
class HomeGridCard extends StatelessWidget {
  final HomeMenuItem item;

  const HomeGridCard({super.key, required this.item});

  static const double radius = 24;

  @override
  Widget build(BuildContext context) {
    final image = item.image;
    return Semantics(
      button: true,
      // The picture's title is part of the image: say it for it.
      label: image != null ? item.title : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: image == null ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.asset(
                  image,
                  key: ValueKey('home-card-image-${item.title}'),
                  // The cell has the picture's own 4:3 ratio: cover fills
                  // it without distorting (and crops nothing visible).
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                )
              else
                _Placeholder(item: item),
              // Ink ripple over the picture; the whole card is the button.
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap:
                      () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: item.screenBuilder)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.item});

  final HomeMenuItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeGridCard.radius),
        border: Border.all(color: AppColors.divider),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [item.background, AppColors.surface],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomy = constraints.maxHeight >= 150;
          final iconBox = roomy ? 64.0 : 44.0;
          return Padding(
            padding: const EdgeInsets.all(10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: math.max(0, constraints.maxWidth - 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(iconBox * 0.3),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.foreground,
                        size: iconBox * 0.52,
                      ),
                    ),
                    SizedBox(height: roomy ? 12 : 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: roomy ? null : 15,
                      ),
                    ),
                    if (roomy) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
