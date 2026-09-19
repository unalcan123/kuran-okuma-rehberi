import '../../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';
import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import 'letter_page_background.dart';

/// Native lesson content with the supplied book’s ornamental header.
class LessonOneBook extends StatelessWidget {
  const LessonOneBook({
    super.key,
    required this.letters,
    required this.onTapLetter,
  });
  final List<ArabicLetter> letters;
  final ValueChanged<ArabicLetter> onTapLetter;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const LetterPageBackground(),
      LayoutBuilder(
        builder: (context, constraints) {
          final pageWidth = constraints.maxWidth.clamp(0.0, 820.0);
          final scale = (pageWidth / 390).clamp(0.85, 1.8);
          final heavy =
              letters.where((letter) => letter.isHeavyLetter).toList();
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final columns =
              MediaQuery.orientationOf(context) == Orientation.portrait &&
                      ReadingTextScale.factorOf(context) > 1
                  ? 1
                  : 4;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: pageWidth < 400 ? 8 : 20,
              vertical: 14,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      const _BookHeader(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scale,
                          vertical: 16 * scale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Kur’ân-ı Kerîm harfleri ${letters.length} tanedir.',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                height: 1.5,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bunların ${heavy.length}’si kalın, ${letters.length - heavy.length}’i ince harf olarak kabul edilir.',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                height: 1.5,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.all(10 * scale),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kalın harfler',
                                    style: TextStyle(
                                      fontSize: 13 * scale,
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      heavy
                                          .map((letter) => letter.isolatedForm)
                                          .join('  '),
                                      textDirection: TextDirection.rtl,
                                      style: AppTextTheme.arabicSmall(
                                        fontSize: 24 * scale,
                                      ).copyWith(color: AppColors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: LayoutBuilder(
                          builder:
                              (context, gridConstraints) => GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: letters.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisExtent: (86 * scale * textScale)
                                          .clamp(76.0, 260.0),
                                    ),
                                itemBuilder: (context, index) {
                                  final letter = letters[index];
                                  return Semantics(
                                    button: true,
                                    label:
                                        '${letter.turkishName}, ${letter.isHeavyLetter ? "kalın harf" : "ince harf"}. Dinle',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        key: ValueKey(
                                          'book-letter-${letter.order}',
                                        ),
                                        onTap: () => onTapLetter(letter),
                                        splashColor: AppColors.turquoiseSoft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: const BorderSide(
                                                color: AppColors.divider,
                                              ),
                                              left:
                                                  index % columns == columns - 1
                                                      ? BorderSide.none
                                                      : const BorderSide(
                                                        color:
                                                            AppColors.divider,
                                                      ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Center(
                                            child: ReadingFittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                letter.isolatedForm,
                                                textDirection:
                                                    TextDirection.rtl,
                                                style: AppTextTheme.arabicSmall(
                                                  fontSize: 48 * scale,
                                                ).copyWith(
                                                  color:
                                                      letter.isHeavyLetter
                                                          ? AppColors.red
                                                          : AppColors.navy,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 16 * scale,
                          bottom: 6 * scale,
                        ),
                        child: Text(
                          'Dinlemek için bir harfe dokun.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}

/// Display only the ornamental header of the supplied 543 × 768 reference.
/// The letters and lesson content below remain interactive Flutter widgets.
class _BookHeader extends StatelessWidget {
  const _BookHeader();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'HARFLER',
    child: AspectRatio(
      aspectRatio: 484 / 134,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 484;
          return ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: -28 * scale,
                  top: -30 * scale,
                  width: 543 * scale,
                  height: 768 * scale,
                  child: Image.asset(
                    'assets/lazim/ders1.png',
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
