import 'package:flutter/material.dart';

import '../../../helpers/colored_arabic_text.dart';
import '../../../helpers/lesson_color_scope.dart';
import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';

/// Elifba'da bir harfin/kelimenin büyük gösterimi.
///
/// Renkler, öğenin kitapta basıldığı SAYFANIN renk profilinden gelir
/// ([LessonColorScope]; kitap sayfası henüz modellenmemiş derslerde bütün
/// kurallar). Kalın harfli bir KELİMEDE yalnızca kalın harf boyanır,
/// kelimenin tamamı değil. "Harflerin yazılışları" dersinde (konum biçimleri olan harfler)
/// harf bütünüyle kırmızı çizilir.
class ArabicGlyph extends StatelessWidget {
  final ArabicLetter letter;
  final double fontSize;

  const ArabicGlyph({super.key, required this.letter, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final baseColor = letter.hasPositionForms ? AppColors.red : AppColors.navy;
    final style = AppTextTheme.arabicLetter(
      fontSize: fontSize,
    ).copyWith(color: baseColor);

    return ColoredArabicText(
      letter.isolatedForm,
      style: style,
      textDirection: TextDirection.rtl,
      profile: LessonColorScope.profileOf(context, letter),
    );
  }
}
