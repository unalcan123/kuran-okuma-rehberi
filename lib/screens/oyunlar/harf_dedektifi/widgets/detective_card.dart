import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../harf_oyunlari/game_letters.dart';
import '../../widgets/shake_on_trigger.dart';

enum DetectiveCardState { idle, found, wrong, hinted }

/// Büyük harf kartı (Şekilleri Tanı, Benzer Harfler). Doğru bulununca yeşil
/// zemin + onay işareti; yanlışta hafifçe sallanır ve soluklaşır (kırmızı yok,
/// kart tekrar seçilebilir ama istatistik şişmez). İpucu kartı altın çerçeve
/// ve büyüteçle belirir. Klavyeyle Tab ile gezilir, Enter/Boşluk ile seçilir.
class DetectiveCard extends StatelessWidget {
  const DetectiveCard({
    super.key,
    required this.text,
    required this.size,
    required this.state,
    required this.onTap,
    required this.semanticLabel,
    this.shakeTrigger = 0,
    this.reduceMotion = false,
    this.fontFamily,
  });

  final String text;
  final double size;
  final DetectiveCardState state;
  final VoidCallback onTap;
  final String semanticLabel;
  final int shakeTrigger;
  final bool reduceMotion;

  /// Farklı yazı tipi (Harf Treni Seviye 4); `null` = Hasenat.
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final (background, border, borderWidth) = switch (state) {
      DetectiveCardState.found => (
        AppColors.turquoiseSoft,
        AppColors.turquoise,
        3.0,
      ),
      DetectiveCardState.hinted => (AppColors.goldSoft, AppColors.gold, 3.0),
      DetectiveCardState.wrong => (
        AppColors.background,
        AppColors.divider,
        1.5,
      ),
      DetectiveCardState.idle => (AppColors.surface, AppColors.divider, 1.5),
    };
    final badge = switch (state) {
      DetectiveCardState.found => (Icons.check_rounded, AppColors.turquoise),
      DetectiveCardState.hinted => (Icons.search_rounded, AppColors.gold),
      _ => null,
    };
    final badgeSize = (size * 0.24).clamp(20.0, 34.0);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220);

    return Semantics(
      button: true,
      label: semanticLabel,
      selected: state == DetectiveCardState.found,
      child: ShakeOnTrigger(
        trigger: reduceMotion ? 0 : shakeTrigger,
        amplitude: size * 0.05,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: duration,
                  opacity: state == DetectiveCardState.wrong ? 0.6 : 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(size * 0.16),
                      focusColor: AppColors.gold.withValues(alpha: 0.25),
                      child: AnimatedContainer(
                        duration: duration,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(size * 0.16),
                          border: Border.all(color: border, width: borderWidth),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(size * 0.1),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            text,
                            textDirection: TextDirection.rtl,
                            textScaler: TextScaler.noScaling,
                            style: singleGlyphStyle(
                              size * 0.56,
                              color:
                                  state == DetectiveCardState.found
                                      ? AppColors.turquoise
                                      : AppColors.navy,
                            ).copyWith(fontFamily: fontFamily),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -badgeSize * 0.25,
                  right: -badgeSize * 0.25,
                  child: IgnorePointer(
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: badge.$2,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        badge.$1,
                        color: Colors.white,
                        size: badgeSize * 0.65,
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
