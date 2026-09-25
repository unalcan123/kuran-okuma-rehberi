import 'package:flutter/widgets.dart';

import '../../../theme/app_text_theme.dart';

/// Seviye 4'te kullanılan, okunaklı ve uygulamaya dahil Arapça yazı tipleri.
///
///  * Hasenat — uygulamanın mushaf yazısı.
///  * NotoNaskhArabic — matbaa nesih (SIL OFL, assets/fonts/OFL-NotoArabic.txt).
///  * NotoSansArabic — sade yazı (SIL OFL).
///
/// Kitabın paketindeki Scheherazade eklenmedi: Hasenat'la neredeyse aynı
/// görünüyor (tool/harf_treni ölçümü, ortalama şekil farkı %17); "farklı
/// yazı" diye göstermek yanıltıcı olurdu. Diğer kitap fontları (Adobe
/// Arabic, Traditional Naskh, Allame Gulten, Lotus, Traditional Arabic, Al
/// Bayan, WinSoft) ticari / "tüm hakları saklı" olduğu için dahil edilemez.
const List<String> kTrainFontFamilies = [
  AppTextTheme.arabicFontFamily,
  'NotoNaskhArabic',
  'NotoSansArabic',
];

/// Gerçekten yüklenmiş ve birbirinden farklı çizilen yazı tipleri.
///
/// Yazı tipi yüklenmemişse Flutter sessizce yedek yazı tipine düşer; o zaman
/// bu seviye "çalışıyor" sayılmamalı. Aynı Arapça metin her ailede ölçülür:
/// yedekle aynı genişlikte çıkan (yüklenmemiş) ya da başka bir ailenin
/// aynısı olan elenir. Seviye 4 en az 2 yazı tipi ister.
List<String> verifiedTrainFonts() {
  const probe = 'بحث سمك';
  double widthOf(String family) {
    final painter = TextPainter(
      text: TextSpan(
        text: probe,
        style: TextStyle(fontFamily: family, fontSize: 100),
      ),
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  final fallback = widthOf('__yuklenmemis_yazi_tipi__');
  final result = <String>[];
  final widths = <double>[];
  for (final family in kTrainFontFamilies) {
    final w = widthOf(family);
    if ((w - fallback).abs() < 0.5) continue;
    if (widths.any((o) => (o - w).abs() < 0.5)) continue;
    result.add(family);
    widths.add(w);
  }
  return result;
}
