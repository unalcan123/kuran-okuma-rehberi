import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Accent pairs (strong, soft) shared by game pieces so every game
/// draws from the same calm palette instead of inventing its own.
class GameColors {
  GameColors._();

  static const List<(Color, Color)> accents = [
    (AppColors.turquoise, AppColors.turquoiseSoft),
    (AppColors.gold, AppColors.goldSoft),
    (AppColors.sage, AppColors.sageSoft),
    (AppColors.skyBlue, AppColors.skyBlueSoft),
    (AppColors.navySoft, Color(0xFFE4EAF2)),
  ];
}
