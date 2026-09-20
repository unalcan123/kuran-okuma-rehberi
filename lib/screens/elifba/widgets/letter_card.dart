import '../../../widgets/reading_text_settings.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import 'arabic_glyph.dart';
import 'position_forms.dart';
import 'mahrec_banner.dart';

/// A single large letter card for the "Tüm Harfler" grid.
///
/// Tap plays the letter's sound; pressing and holding opens it in the
/// full-focus "Tek Harf" pager. Two quick taps do NOT open it (they just
/// play the sound twice), and having no double-tap handler also means a
/// tap plays at once instead of waiting to see if a second one follows.
/// There is deliberately no separate icon for the second action — it stays
/// a plain, uncluttered card.
class LetterCard extends StatefulWidget {
  final ArabicLetter letter;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  const LetterCard({
    super.key,
    required this.letter,
    required this.onTap,
    required this.onOpenDetail,
  });

  @override
  State<LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<LetterCard> {
  bool _pressed = false;
  bool _highlighted = false;
  Timer? _highlightTimer;

  void _handleTap() {
    widget.onTap();
    _highlightTimer?.cancel();
    setState(() => _highlighted = true);
    _highlightTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _highlighted = false);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _pressed || _highlighted;
    final mahrecColor = widget.letter.mahrec?.color;

    return Semantics(
      button: true,
      label: widget.letter.turkishName ?? widget.letter.isolatedForm,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handleTap,
        onLongPress: widget.onOpenDetail,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color:
                  mahrecColor != null
                      ? Color.alphaBlend(
                        mahrecColor.withValues(alpha: active ? 0.18 : 0.05),
                        AppColors.surface,
                      )
                      : active
                      ? AppColors.turquoiseSoft
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    mahrecColor ??
                    (active ? AppColors.turquoise : AppColors.divider),
                width:
                    mahrecColor != null
                        ? 2
                        : active
                        ? 1.6
                        : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fontSize = (constraints.maxWidth * 0.65).clamp(
                  38.0,
                  110.0,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  child:
                      widget.letter.hasPositionForms
                          ? Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: ReadingFittedBox(
                                    fit: BoxFit.contain,
                                    child: ArabicGlyph(
                                      letter: widget.letter,
                                      fontSize: 360,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: constraints.maxHeight * 0.43,
                                child: PositionForms(
                                  letter: widget.letter,
                                  compact: true,
                                  large: true,
                                ),
                              ),
                            ],
                          )
                          : Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ArabicGlyph(
                                letter: widget.letter,
                                fontSize: fontSize,
                              ),
                            ),
                          ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
