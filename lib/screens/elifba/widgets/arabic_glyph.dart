import 'package:flutter/material.dart';

import '../../../helpers/colored_arabic_text.dart';
import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';

/// Elifba'da bir harfin/kelimenin büyük gösterimi.
///
/// İki ayrı renklendirme katmanı birlikte çalışır:
///  * bu ekranın kendi kuralı (aşağıdaki [baseColorOf]) — hemzeli elif
///    (أ/إ) ve önceki harfin harekesini uzatan medd harfi (ا و ي) kırmızı;
///    ayrıca gövdenin genel rengi (hasPositionForms/isHeavyLetter) kırmızı
///    olabilir — bunlar bu widget'a daha önce ait, değiştirilmedi;
///  * [ColoredArabicText]'in genel Elifba kuralı: 7 kalın harfin
///    (خ ص ض ط ظ غ ق) gövdesi kırmızı, hareke/okuma işaretleri (üstün/sükûn
///    kırmızı, esre/şedde mavi, ötre yeşil) SADECE işaretin kendisinde —
///    harfin gövdesine hiç taşmaz. İki katman aynı harf kümesinde birlikte
///    çalışır (örn. "خِ": خ kırmızı çünkü kalın harf, ِ mavi çünkü esre).
class ArabicGlyph extends StatelessWidget {
  final ArabicLetter letter;
  final double fontSize;

  const ArabicGlyph({super.key, required this.letter, required this.fontSize});

  static const _meddLetters = {'ا', 'و', 'ي'};

  @override
  Widget build(BuildContext context) {
    final baseColor =
        letter.hasPositionForms || letter.isHeavyLetter
            ? AppColors.red
            : AppColors.navy;
    final style = AppTextTheme.arabicLetter(
      fontSize: fontSize,
    ).copyWith(color: baseColor);

    return ColoredArabicText(
      letter.isolatedForm,
      style: style,
      textDirection: TextDirection.rtl,
      baseColorOf: (baseChar, {required isFirstCluster, required hasOwnMarks}) {
        final hasHamza = baseChar == 'أ' || baseChar == 'إ';
        // A bare ا/و/ي with no hareke of its own, coming after something
        // else in the same word, is a medd (uzatma) letter — it's what's
        // stretching the previous vowel, so it gets called out in red
        // too (e.g. the "ا" in "بَا").
        final isMeddLetter =
            !hasOwnMarks && !isFirstCluster && _meddLetters.contains(baseChar);
        return (hasHamza || isMeddLetter) ? AppColors.red : null;
      },
    );
  }
}
