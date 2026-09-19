import '../../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../../../models/arabic_letter.dart';
import '../../../services/audio_service.dart';
import '../../../theme/app_colors.dart';
import 'arabic_glyph.dart';
import 'letter_page_background.dart';
import 'position_forms.dart';
import 'letter_forms_page.dart';
import 'mahrec_banner.dart';

/// The hero screen for a single letter — ONE LETTER, ONE SCREEN, ONE
/// FOCUS. Everything here exists only to let the child see, hear and
/// name the letter; deeper practice modes (tracing, matching, ...)
/// are separate screens layered on top later.
///
/// When [ArabicLetter.hasPositionForms] is true (lessons that teach
/// başta/ortada/sonda writing), a small reference row is shown below
/// the sound button — the isolated letter stays the visual hero.
///
/// Everything scales up again on tablet/desktop
/// ([Responsive.deviceClassOf]) rather than just filling the extra
/// width with empty space — this screen is meant to be read from
/// across a room, not just an arm's length away.
class LetterPage extends StatelessWidget {
  final ArabicLetter letter;
  final Widget? navigationControls;

  const LetterPage({super.key, required this.letter, this.navigationControls});

  void _playSound(BuildContext context) {
    context.read<AudioService>().playLetter(letter);
  }

  @override
  Widget build(BuildContext context) {
    if (letter.hasPositionForms) {
      return LetterFormsPage(
        letter: letter,
        navigationControls: navigationControls,
        onPlay: () => _playSound(context),
      );
    }
    final size = MediaQuery.sizeOf(context);
    final deviceClass = Responsive.deviceClassOf(context);
    final formsScale = switch (deviceClass) {
      DeviceClass.mobile => 1.0,
      DeviceClass.tablet => 1.3,
      DeviceClass.desktop => 1.4,
    };
    final letterFontSize = (size.shortestSide *
            (Responsive.isMobile(context) ? 0.56 : 0.42))
        .clamp(175.0, deviceClass == DeviceClass.mobile ? 360.0 : 460.0);

    return Stack(
      children: [
        const LetterPageBackground(),
        Column(
          children: [
            if (letter.mahrec case final mahrec?)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: MahrecBanner(mahrec: mahrec),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, letter.mahrec == null ? -40 : 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _playSound(context),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: size.width * 0.85,
                                  ),
                                  child: ReadingFittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: ArabicGlyph(
                                      letter: letter,
                                      fontSize: letterFontSize,
                                    ),
                                  ),
                                ),
                              ),
                              if (navigationControls != null) ...[
                                const SizedBox(height: 16),
                                navigationControls!,
                                const SizedBox(height: 16),
                              ] else
                                const SizedBox(height: 28),
                              _SoundButton(
                                onTap: () => _playSound(context),
                                scale: formsScale,
                              ),
                              if (letter.hasPositionForms) ...[
                                const SizedBox(height: 28),
                                PositionForms(
                                  letter: letter,
                                  scale: formsScale,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SoundButton extends StatelessWidget {
  final VoidCallback onTap;
  final double scale;

  const _SoundButton({required this.onTap, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.turquoiseSoft,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 56 * scale,
            minWidth: 56 * scale,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24 * scale,
                vertical: 14 * scale,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.turquoise,
                    size: 24 * scale,
                  ),
                  SizedBox(width: 10 * scale),
                  Text(
                    'Dinle',
                    style: TextStyle(
                      color: AppColors.turquoise,
                      fontWeight: FontWeight.w700,
                      fontSize: 16 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
