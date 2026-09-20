import 'package:flutter/material.dart';

import '../../../data/letters_data.dart';
import '../../../theme/app_text_theme.dart';

/// Harf oyunlarının (Bul & Patlat, Harf Arabaları) ortak harf verisi.
///
/// Yeni bir 28 harflik liste tutulmaz: uygulamanın tek doğruluk kaynağı olan
/// [kArabicLetters] kullanılır; ses dosyaları o listedeki gerçek asset
/// yollarıdır (`assets` klasörüne göreli).
class GameLetter {
  const GameLetter(this.char, this.audio);

  /// Ekranda gösterilen harf (tek Text: harf birleşimi bozulmaz).
  final String char;

  /// `assets` klasörüne göreli ses dosyası (ör. `audio/elifba/.../02_be.mp3`).
  final String audio;
}

final List<GameLetter> kGameLetters = [
  for (final letter in kArabicLetters)
    if (letter.audioAsset != null)
      GameLetter(letter.isolatedForm, letter.audioAsset!),
];

/// Ekranlar harfleri bu arayüzle alır; veri sabit olduğu için anında döner.
Future<List<GameLetter>> loadGameLetters() async => kGameLetters;

/// Harekeler üstten/alttan kesilmesin diye Arapça için Latin'deki sıkı satır
/// yüksekliği kullanılmaz.
const double kArabicLineHeight = 1.55;

TextStyle lessonArabicStyle(double fontSize, {Color? color}) =>
    AppTextTheme.arabicSmall(
      fontSize: fontSize,
    ).copyWith(height: kArabicLineHeight, color: color);
