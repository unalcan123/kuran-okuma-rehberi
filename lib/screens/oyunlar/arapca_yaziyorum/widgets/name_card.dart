import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_theme.dart';

/// İsim kartının sade renk seçenekleri: (zemin, çerçeve).
const List<(Color, Color)> kCardPalettes = [
  (AppColors.turquoiseSoft, AppColors.turquoise),
  (AppColors.goldSoft, AppColors.gold),
  (AppColors.sageSoft, AppColors.sage),
  (AppColors.skyBlueSoft, AppColors.skyBlue),
];

enum CardFrame {
  simple('Sade'),
  double('Çift çizgi'),
  stars('Yıldızlı');

  const CardFrame(this.label);
  final String label;
}

/// Çocuğun yazdığı adı gösteren kart. Metin sıradan bir [Text]'tir
/// (HTML/çalıştırılabilir içerik olarak yorumlanmaz); harfleri metin motoru
/// birleştirir. Kaydedilen görsel bu widget'ın kendisinden alınır, yani
/// ekrandakiyle aynıdır.
class NameCard extends StatelessWidget {
  const NameCard({
    super.key,
    required this.name,
    required this.palette,
    required this.frame,
  });

  final String name;
  final int palette;
  final CardFrame frame;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = kCardPalettes[palette % kCardPalettes.length];
    final inner = Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: fg, width: frame == CardFrame.simple ? 4 : 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (frame == CardFrame.stars) Icon(Icons.star_rounded, color: fg),
              const SizedBox(width: 6),
              Text(
                'Benim adım',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 6),
              if (frame == CardFrame.stars) Icon(Icons.star_rounded, color: fg),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name.trim(),
              key: const ValueKey('card-name'),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                fontFamily: AppTextTheme.arabicFontFamily,
                fontSize: 64,
                height: 1.7,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child:
          frame == CardFrame.double
              ? Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: fg, width: 2),
                ),
                child: inner,
              )
              : inner,
    );
  }
}

/// [key]'in altındaki kartı PNG'ye çevirir (yüksek çözünürlük).
Future<List<int>?> renderCardPng(GlobalKey key, {double pixelRatio = 3}) async {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderRepaintBoundary) return null;
  final image = await box.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}
