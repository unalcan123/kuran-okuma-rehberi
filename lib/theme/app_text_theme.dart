import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Central place for the two font families used across the app:
/// a warm rounded UI font for Turkish text, and the bundled "Hasenat"
/// Qur'an font for Arabic letters. Kept separate on purpose — the
/// Arabic font can be swapped again later by editing only this file.
class AppTextTheme {
  AppTextTheme._();

  static const String arabicFontFamily = 'Hasenat';

  static TextTheme get uiTextTheme =>
      GoogleFonts.nunitoTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );

  /// Style for a large, isolated-form Arabic letter shown as the hero
  /// of a learning screen.
  static TextStyle arabicLetter({required double fontSize}) {
    return TextStyle(
      fontFamily: arabicFontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.navy,
      height: 1.0,
    );
  }

  static TextStyle arabicSmall({double fontSize = 28}) {
    return TextStyle(
      fontFamily: arabicFontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.navy,
    );
  }
}
