import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../harf_oyunlari/game_letters.dart';
import '../tren_engine.dart';

/// Lokomotif (hedef harf + dinle düğmesi) ve vagonlar.
///
/// Tren ekranın genişliğine sığacak şekilde ölçülür; harfler okunaklı
/// kalsın diye vagon genişliğinin alt sınırı vardır. Kalkış animasyonu
/// bütün treni YALNIZCA kaydırır (Transform.translate): hiçbir şey
/// aynalanmaz, harflerin görünüşü değişmez. Vagon sırası bir okuma dersi
/// değildir; bulunan kart sıradaki boş vagona gider.
class TrainView extends StatelessWidget {
  const TrainView({
    super.key,
    required this.targetChar,
    required this.targetName,
    required this.wagons,
    required this.placed,
    required this.onListen,
    required this.muted,
    required this.departure,
    this.wagonKeys = const [],
  });

  final String targetChar;
  final String targetName;
  final int wagons;

  /// Vagonlara yerleşmiş kartlar (sırayla).
  final List<TrainCard> placed;
  final VoidCallback onListen;
  final bool muted;

  /// 0 = istasyonda bekliyor, 1 = gitti.
  final double departure;

  /// Uçan kartın hedefi olarak vagonların konumu.
  final List<GlobalKey> wagonKeys;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      const gap = 6.0;
      final width = c.maxWidth;
      final loco = math.min(170.0, math.max(118.0, width * 0.34));
      final wagon = ((width - loco - gap * wagons) / wagons).clamp(48.0, 120.0);
      final height = math.max(loco * 0.82, wagon * 1.05);
      final trainWidth = loco + (wagon + gap) * wagons;
      // Stack, Transform ile kayan treni kendiliğinden kırpmaz (yerleşimde
      // taşma görünmez): giden tren alanın dışına çizilmesin.
      return ClipRect(
        child: SizedBox(
          height: height + 14,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Ray
              Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                child: Container(
                  height: 4,
                  color: AppColors.navySoft.withValues(alpha: 0.35),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  children: [
                    for (var i = 0; i < 40; i++) ...[
                      Container(width: 6, height: 4, color: AppColors.divider),
                      const Spacer(),
                    ],
                  ],
                ),
              ),
              // İstasyon: tren gidince görünür.
              if (departure > 0.6)
                Positioned.fill(
                  bottom: 12,
                  child: Opacity(
                    opacity: ((departure - 0.6) / 0.4).clamp(0.0, 1.0),
                    child: const _Station(),
                  ),
                ),
              Positioned(
                left: 0,
                bottom: 10,
                child: Transform.translate(
                  offset: Offset(-departure * (trainWidth + 40), 0),
                  child: SizedBox(
                    width: math.min(trainWidth, width),
                    height: height,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Locomotive(
                            size: loco,
                            char: targetChar,
                            name: targetName,
                            onListen: onListen,
                            muted: muted,
                          ),
                          for (var i = 0; i < wagons; i++) ...[
                            const SizedBox(width: gap),
                            _Wagon(
                              key: i < wagonKeys.length ? wagonKeys[i] : null,
                              size: wagon,
                              card: i < placed.length ? placed[i] : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Locomotive extends StatelessWidget {
  const _Locomotive({
    required this.size,
    required this.char,
    required this.name,
    required this.onListen,
    required this.muted,
  });

  final double size;
  final String char;
  final String name;
  final VoidCallback onListen;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final h = size * 0.82;
    return SizedBox(
      width: size,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _LocoPainter())),
          // Hedef harf: gövdedeki büyük beyaz pano.
          Positioned(
            left: size * 0.05,
            top: h * 0.16,
            width: size * 0.58,
            height: h * 0.62,
            child: Semantics(
              label: 'Hedef harf: $name',
              child: Container(
                key: const ValueKey('target-glyph'),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      char,
                      textScaler: TextScaler.noScaling,
                      style: singleGlyphStyle(size * 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Dinle düğmesi: kabinde (harfin üstüne binmez).
          Positioned(
            left: size * 0.68,
            width: size * 0.3,
            top: h * 0.18,
            child: Center(
              child: IconButton.filled(
                key: const ValueKey('listen-button'),
                tooltip: muted ? 'Ses kapalı' : 'Harfin sesini dinle',
                onPressed: muted ? null : onListen,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.square(44),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final body = Paint()..color = AppColors.turquoise;
    final dark = Paint()..color = AppColors.navy;
    // Baca
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.14, 0, s.width * 0.12, s.height * 0.2),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.gold,
    );
    // Gövde
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, s.height * 0.14, s.width * 0.72, s.height * 0.68),
        Radius.circular(s.height * 0.12),
      ),
      body,
    );
    // Kabin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.66, 0, s.width * 0.34, s.height * 0.82),
        Radius.circular(s.height * 0.1),
      ),
      dark,
    );
    // Tekerlekler
    final r = s.height * 0.11;
    for (final x in [0.16, 0.44, 0.82]) {
      canvas.drawCircle(Offset(s.width * x, s.height - r), r, dark);
      canvas.drawCircle(
        Offset(s.width * x, s.height - r),
        r * 0.4,
        Paint()..color = AppColors.goldSoft,
      );
    }
  }

  @override
  bool shouldRepaint(_LocoPainter old) => false;
}

class _Wagon extends StatelessWidget {
  const _Wagon({super.key, required this.size, required this.card});

  final double size;
  final TrainCard? card;

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    final h = size * 1.05;
    return Semantics(
      label: card == null ? 'Boş vagon' : 'Dolu vagon',
      child: SizedBox(
        width: size,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: h * 0.16,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      card == null
                          ? AppColors.goldSoft
                          : AppColors.turquoiseSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: card == null ? AppColors.gold : AppColors.turquoise,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(5),
                child:
                    card == null
                        ? DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                          ),
                        )
                        : TweenAnimationBuilder<double>(
                          key: ValueKey(card.id),
                          tween: Tween(begin: 0.6, end: 1),
                          duration:
                              MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          builder:
                              (context, t, child) =>
                                  Transform.scale(scale: t, child: child),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Text(
                                  card.text,
                                  textDirection: TextDirection.rtl,
                                  textScaler: TextScaler.noScaling,
                                  style: singleGlyphStyle(
                                    size * 0.45,
                                  ).copyWith(fontFamily: card.font),
                                ),
                              ),
                            ),
                          ),
                        ),
              ),
            ),
            if (card != null)
              Positioned(
                top: -8,
                right: -6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.turquoise,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            for (final x in [0.25, 0.75])
              Positioned(
                left: size * x - h * 0.08,
                bottom: 0,
                child: Container(
                  width: h * 0.16,
                  height: h * 0.16,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Station extends StatelessWidget {
  const _Station();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.train_rounded,
              color: AppColors.turquoise,
              size: 34,
            ),
            const SizedBox(width: 8),
            Text(
              'İstasyon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded, color: AppColors.turquoise),
          ],
        ),
      ),
    ],
  );
}
