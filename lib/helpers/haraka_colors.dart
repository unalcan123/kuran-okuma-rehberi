import 'package:flutter/material.dart';

/// Elifba öğretiminde hareke ve kalın harf renklendirme sistemi — D:\Elifbe2025
/// projesinde geliştirilip cihazda doğrulanan renkler, tek yerde. Ekranlar
/// buradan kullanır; hiçbir dosyada kırmızı/mavi/yeşili tekrar hardcode etme.
///
/// Kural (Elifbe2025'te sabitlenen, buraya aynen taşınan):
///  * üstün / fetha (U+064E) → KIRMIZI
///  * sükûn / cezm  (U+0652) → KIRMIZI (fethayla aynı)
///  * esre / kesra  (U+0650) → MAVİ
///  * şedde         (U+0651) → MAVİ (esreyle aynı)
///  * ötre / damme  (U+064F) → YEŞİL
///  * 7 kalın harf (خ ص ض ط ظ غ ق) gövdesi → KIRMIZI (fethayla aynı renk)
///
/// Tenvin, med, hemze vb. için renk uydurulmadı; mevcut normal metin
/// rengiyle çizilirler (bkz. [colored_arabic_text.dart]).
const Color harakaFathaColor = Color(0xFFDC2626); // üstün / fetha
const Color harakaSukunColor = harakaFathaColor; // sükûn / cezm
const Color harakaKasraColor = Color(0xFF2563EB); // esre / kesra
const Color harakaShaddaColor = harakaKasraColor; // şedde
const Color harakaDammaColor = Color(0xFF16A34A); // ötre / damme

/// Unicode kod noktasından renklendirilecek hareke rengine bakış tablosu.
/// Burada olmayan her karakter (harfler, tenvin, med, boşluk...) rengini
/// çevresindeki normal metin stilinden alır.
const Map<int, Color> harakaColorByCodePoint = {
  0x064E: harakaFathaColor, // ARABIC FATHA
  0x0652: harakaSukunColor, // ARABIC SUKUN
  0x0650: harakaKasraColor, // ARABIC KASRA
  0x0651: harakaShaddaColor, // ARABIC SHADDA
  0x064F: harakaDammaColor, // ARABIC DAMMA
};

/// 7 KALIN harfin gövdesi de renklendirilir — hareke değil, harfin
/// KENDİSİ (harekesi olsun ya da olmasın). Fetha rengiyle aynıdır.
const Color harakaThickLetterColor = harakaFathaColor;

/// Kalın (mufahham) 7 harf: خ ص ض ط ظ غ ق. Bunların dışındaki bütün Arapça
/// harflerin gövdesi normal (mevcut) renkte kalır.
const Set<String> thickArabicLetters = {'خ', 'ص', 'ض', 'ط', 'ظ', 'غ', 'ق'};
