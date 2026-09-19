import '../../../widgets/reading_text_settings.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import 'letter_page_background.dart';

/// Viewport-sized reading layout for positional forms, separate from the grid.
class LetterFormsPage extends StatelessWidget {
  final ArabicLetter letter;
  final Widget? navigationControls;
  final VoidCallback onPlay;

  const LetterFormsPage({
    super.key,
    required this.letter,
    this.navigationControls,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const LetterPageBackground(),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= 900 &&
                      constraints.maxWidth > constraints.maxHeight;
                  final scale = math
                      .min(
                        constraints.maxWidth / 390,
                        constraints.maxHeight / 650,
                      )
                      .clamp(1.0, 1.6);
                  final narrow = constraints.maxWidth < 300;
                  final formsHeight = narrow ? 244.0 : 260.0 * scale;
                  // Only exceptionally short windows or large accessibility text scroll.
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final minHeight = wide ? 430.0 : formsHeight + 260;
                  final height = math.max(
                    constraints.maxHeight,
                    minHeight + math.max(0, textScale - 1) * 120,
                  );
                  return SingleChildScrollView(
                    child: SizedBox(
                      height: height,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 28 : 12,
                          8,
                          wide ? 28 : 12,
                          8,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child:
                                  wide
                                      ? Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: _hero(context, scale),
                                          ),
                                          const SizedBox(width: 28),
                                          Expanded(
                                            flex: 6,
                                            child: _forms(
                                              context,
                                              scale,
                                              false,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Column(
                                        children: [
                                          Expanded(
                                            child: _hero(context, scale),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            height: formsHeight,
                                            child: _forms(
                                              context,
                                              scale,
                                              narrow,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                            if (navigationControls != null) ...[
                              const SizedBox(height: 8),
                              navigationControls!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context, double scale) => Column(
    children: [
      Expanded(
        child: Semantics(
          button: true,
          label: '${letter.turkishName ?? ''} harfini dinle',
          child: GestureDetector(
            onTap: onPlay,
            behavior: HitTestBehavior.opaque,
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ReadingFittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    letter.isolatedForm,
                    key: const ValueKey('forms-hero-glyph'),
                    textDirection: TextDirection.rtl,
                    style: AppTextTheme.arabicLetter(
                      fontSize: 440,
                    ).copyWith(color: AppColors.red),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: onPlay,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.turquoiseSoft,
          foregroundColor: AppColors.turquoise,
          minimumSize: Size(140 * scale, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        icon: const Icon(Icons.volume_up_rounded),
        label: const Text(
          'Dinle',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  Widget _forms(BuildContext context, double scale, bool narrow) {
    final forms = [letter.initialForm!, letter.medialForm!, letter.finalForm!];
    const labels = ['Başta', 'Ortada', 'Sonda'];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Divider(color: AppColors.divider, height: 12),
        Text(
          'Kelime İçindeki Yazılışı',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        if (narrow)
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  Expanded(
                    child: _FormTile(
                      label: labels[i],
                      form: forms[i],
                      example: letter.positionExamples?[i],
                      scale: scale,
                      horizontal: true,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Flexible(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _FormTile(
                        label: labels[i],
                        form: forms[i],
                        example: letter.positionExamples?[i],
                        scale: scale,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FormTile extends StatelessWidget {
  final String label;
  final String form;
  final String? example;
  final double scale;
  final bool horizontal;
  const _FormTile({
    required this.label,
    required this.form,
    required this.example,
    required this.scale,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = Text(
      label,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
    Widget arabic(String value, double size, Color color) => ReadingFittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value,
        textDirection: TextDirection.rtl,
        style: AppTextTheme.arabicSmall(
          fontSize: size,
        ).copyWith(color: color, height: 1.25),
      ),
    );
    // Whole words stay in one text run to preserve Arabic joining/ligatures.
    final formText = arabic(
      form,
      (horizontal ? 48 : 66) * scale,
      AppColors.red,
    );
    final exampleText =
        example == null
            ? const SizedBox.shrink()
            : arabic(example!, (horizontal ? 38 : 44) * scale, AppColors.navy);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: horizontal ? 4 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.18)),
      ),
      child:
          horizontal
              ? Row(
                children: [
                  Expanded(child: title),
                  Expanded(child: formText),
                  Expanded(child: exampleText),
                ],
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  title,
                  const SizedBox(height: 6),
                  Expanded(flex: 3, child: formText),
                  const SizedBox(height: 6),
                  Expanded(flex: 2, child: exampleText),
                ],
              ),
    );
  }
}
