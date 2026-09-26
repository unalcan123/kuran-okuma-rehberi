import 'package:flutter/material.dart';

/// Elifba öğretiminde hareke, kalın harf ve uzatma harfi renkleri — tek
/// yerde. Ekranlar buradan (ya da [ColoredArabicText] üzerinden) kullanır;
/// hiçbir dosyada kırmızı/mavi/yeşili tekrar hardcode etme.
///
/// Tonlar referans kitaptan (`ELIF BA BASKI DENEME 2012.pdf`) metin
/// renkleri okunarak alındı: kırmızı #ED1C24, mavi #00AEEF, yeşil #00A650.
///
/// Kurallar (kitap s. 14-49; hangi işaretin hangi renk aldığı
/// [ArabicColorizer]'da, `lib/helpers/arabic_colorizer.dart`):
///  * KIRMIZI: üstün, cezim, iki üstün, çeker üstün (ٰ), çeker esre (ٖ),
///    med işareti (ٓ), 7 kalın harfin gövdesi, uzatma (med) elifi
///  * MAVİ:    esre, iki esre, şedde (ve şeddeli harfin harekesi), uzatma yâ'sı
///  * YEŞİL:   ötre, iki ötre, uzatma vâv'ı
const Color arabicRed = Color(0xFFED1C24);
const Color arabicBlue = Color(0xFF00AEEF);
const Color arabicGreen = Color(0xFF00A650);

const Color harakaFathaColor = arabicRed; // üstün / fetha
const Color harakaSukunColor = arabicRed; // sükûn / cezm
const Color harakaKasraColor = arabicBlue; // esre / kesra
const Color harakaShaddaColor = arabicBlue; // şedde
const Color harakaDammaColor = arabicGreen; // ötre / damme

/// 7 KALIN harfin gövdesi — hareke değil, harfin KENDİSİ.
const Color harakaThickLetterColor = arabicRed;

/// Kalın (mufahham) 7 harf: خ ص ض ط ظ غ ق. Bunların dışındaki bütün Arapça
/// harflerin gövdesi normal (mevcut) renkte kalır.
const Set<String> thickArabicLetters = {'خ', 'ص', 'ض', 'ط', 'ظ', 'غ', 'ق'};
