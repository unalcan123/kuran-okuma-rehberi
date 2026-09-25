import 'dart:math' as math;

import '../harf_dedektifi/dedektif_data.dart';
import 'yazi_text.dart';

/// Oyun anahtarı (Sonuçlarım'da yalnızca "Bak ve Yaz" puanlanır).
const String kArapcaYaziyorumGameKey = 'arapca_yaziyorum';
const String kBakYazGameKey = '$kArapcaYaziyorumGameKey.bak_yaz';

/// Uzunluk sınırları.
const int kNameMaxLength = 30;
const int kFreeMaxLength = 200;
const int kCopyMaxLength = 40;

class YaziKey {
  const YaziKey(this.insert, {required this.label, this.name, this.audio});

  /// Metne yazılan (ya da hareke için uygulanan) karakter.
  final String insert;

  /// Tuşta görünen (hareke tuşunda ◌ ile).
  final String label;

  /// Türkçe adı (erişilebilirlik ve alt yazı).
  final String? name;

  /// Harfin projedeki ses kaydı (Ders 1). Yoksa ses çalmaz.
  final String? audio;
}

/// Temel harfler: Elifba sırası (tuşlar sağdan sola dizilir). Tek başına
/// biçim tek tuştur; başta/ortada/sonda biçimini metin motoru üretir.
final List<YaziKey> kLetterKeys = [
  for (final l in kDetectiveLetters)
    YaziKey(l.char, label: l.char, name: l.name, audio: l.audio),
];

/// Ek harfler: hemze ve hemzeli/medli elif, yuvarlak te, elif maksura…
/// Her biri kendi Unicode karakteridir; temel harfe indirgenmez.
const List<YaziKey> kExtraKeys = [
  YaziKey('ء', label: 'ء', name: 'Hemze'),
  YaziKey('أ', label: 'أ', name: 'Üstünde hemzeli elif'),
  YaziKey('إ', label: 'إ', name: 'Altında hemzeli elif'),
  YaziKey('آ', label: 'آ', name: 'Medli elif'),
  YaziKey('ؤ', label: 'ؤ', name: 'Hemzeli vav'),
  YaziKey('ئ', label: 'ئ', name: 'Hemzeli ye'),
  YaziKey('ة', label: 'ة', name: 'Kapalı te'),
  YaziKey('ى', label: 'ى', name: 'Elif maksura'),
];

/// Harekeler: isteğe bağlı bölüm; önceki harfe uygulanır.
const List<YaziKey> kHarakaKeys = [
  YaziKey(kFatha, label: 'ـَ', name: 'Üstün'),
  YaziKey(kKasra, label: 'ـِ', name: 'Esre'),
  YaziKey(kDamma, label: 'ـُ', name: 'Ötre'),
  YaziKey(kSukun, label: 'ـْ', name: 'Cezm'),
  YaziKey(kShadda, label: 'ـّ', name: 'Şedde'),
  YaziKey(kFathatan, label: 'ـً', name: 'İki üstün'),
  YaziKey(kKasratan, label: 'ـٍ', name: 'İki esre'),
  YaziKey(kDammatan, label: 'ـٌ', name: 'İki ötre'),
];

enum KeySection { letters, extra, haraka }

KeySection? sectionOf(String ch) {
  if (kLetterKeys.any((k) => k.insert == ch)) return KeySection.letters;
  if (kExtraKeys.any((k) => k.insert == ch)) return KeySection.extra;
  if (kHarakaKeys.any((k) => k.insert == ch)) return KeySection.haraka;
  return null;
}

// ---------------------------------------------------------------------------
// Bak ve Yaz

enum CopyStage {
  letter('Tek harf'),
  twoLetters('İki harf'),
  word('Kısa kelime');

  const CopyStage(this.label);
  final String label;
}

class CopyTask {
  const CopyTask(this.text, this.stage);
  final String text;
  final CopyStage stage;
}

/// Bir oturum: 3 tek harf, 2 iki harfli, 3 kısa kelime. Hepsi harekesiz ve
/// projedeki doğrulanmış verilerden: harfler Ders 1, kelimeler Harf
/// Dedektifi'nin Ders 2 kelime havuzu (hemzesiz, lam-elifsiz). Yeni kelime
/// uydurulmaz.
List<CopyTask> buildCopyTasks(math.Random random) {
  final letters = List.of(kDetectiveLetters)..shuffle(random);
  final two = [
    for (final w in kDetectiveWords)
      if (w.letters.length == 2) w.text,
  ]..shuffle(random);
  final words = [
    for (final w in kDetectiveWords)
      if (w.letters.length >= 3 && w.letters.length <= 4) w.text,
  ]..shuffle(random);
  return [
    for (final l in letters.take(3)) CopyTask(l.char, CopyStage.letter),
    for (final w in two.take(2)) CopyTask(w, CopyStage.twoLetters),
    for (final w in words.take(3)) CopyTask(w, CopyStage.word),
  ];
}
