import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import '../../../theme/app_colors.dart';

/// Quiet, semi-transparent previous/next control. Deliberately kept
/// low-contrast so it never competes with the letter — but bigger on
/// tablet/desktop so it's still an easy target from further away.
class NavArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const NavArrowButton({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 12.0 : 18.0;
    final iconSize = isMobile ? 26.0 : 34.0;
    return Opacity(
      opacity: enabled ? 1 : 0,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Material(
          color: AppColors.surface.withValues(alpha: 0.7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Icon(icon, color: AppColors.navySoft, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
