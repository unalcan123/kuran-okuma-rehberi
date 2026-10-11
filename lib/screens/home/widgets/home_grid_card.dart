import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../l10n/l10n.dart';
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
      label: image != null ? context.t(item.title) : null,
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
              if (image != null && context.language != AppLanguage.tr)
                _LocalizedSign(image: image, title: context.t(item.title)),
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
                      context.t(item.title),
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
                        context.t(item.subtitle),
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

/// Only the original sign's lettering area is covered. All illustration pixels
/// outside that area continue to come from the original asset in every language.
class _LocalizedSign extends StatelessWidget {
  const _LocalizedSign({required this.image, required this.title});
  final String image;
  final String title;
  static const _areas = {
    'kuran_okuma_rehberi': Rect.fromLTWH(.28, .715, .55, .20),
    'namaz_dualari': Rect.fromLTWH(.24, .725, .52, .205),
    'namaz_sureleri': Rect.fromLTWH(.25, .69, .53, .20),
    'oyunlar': Rect.fromLTWH(.25, .745, .50, .13),
  };
  String _lines() {
    final words = title.toUpperCase().split(' ');
    final lines = <String>[];
    var line = '';
    for (final word in words) {
      if (line.isNotEmpty && line.length + word.length + 1 > 19) {
        lines.add(line);
        line = word;
      } else {
        line = line.isEmpty ? word : '$line $word';
      }
    }
    if (line.isNotEmpty) lines.add(line);
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final name = image.split('/').last.replaceFirst('.webp', '');
    final area = _areas[name];
    if (area == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder:
              (context, size) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipPath(
                    clipper: _SignClipper(area),
                    child: Image.asset(
                      'assets/images/home/localized/${name}_blank.webp',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  Positioned(
                    left: size.maxWidth * area.left,
                    top: size.maxHeight * area.top,
                    width: size.maxWidth * area.width,
                    height: size.maxHeight * area.height,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 2,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _lines(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3C1603),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _SignClipper extends CustomClipper<Path> {
  const _SignClipper(this.area);
  final Rect area;
  @override
  Path getClip(Size size) =>
      Path()..addRect(
        Rect.fromLTWH(
          area.left * size.width,
          area.top * size.height,
          area.width * size.width,
          area.height * size.height,
        ),
      );
  @override
  bool shouldReclip(_SignClipper oldClipper) => area != oldClipper.area;
}
