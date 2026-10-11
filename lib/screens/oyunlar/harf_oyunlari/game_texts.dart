import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';

/// Harf oyunlarının (Bul & Patlat, Harf Arabaları) ve oyuncu profili
/// ekranlarının metinleri tek yerde. Metin Türkçe yazılır ve [language]
/// diline çevrilir (çeviriler `lib/l10n/strings/ui_games_harf_oyunlari.dart`).
/// `const GameTexts()` Türkçedir; ekranlar `GameTexts.of(context)` kullanır.
class GameTexts {
  const GameTexts([this.language = AppLanguage.tr]);

  /// Ekranın o anki dili (kapsam yoksa Türkçe).
  GameTexts.of(BuildContext context) : language = context.language;

  final AppLanguage language;

  String get back => L10n.text(language, 'Geri');
  String get bpAccuracy => L10n.text(language, 'Doğruluk');
  String get bpBackToGames => L10n.text(language, 'Oyunlara Dön');
  String get bpBest => L10n.text(language, 'En İyi');
  String get bpCompleted => L10n.text(language, 'Bul & Patlat Tamamlandı');
  String get bpCorrect => L10n.text(language, 'Doğru');
  String get bpDesc =>
      L10n.text(language, 'Sesi dinle, doğru harfi bul ve balonu patlat!');
  String get bpGame => L10n.text(language, 'Bul & Patlat');
  String get bpLevel => L10n.text(language, 'Seviye');
  String get bpLevel1 => L10n.text(language, 'Yavaş');
  String get bpLevel2 => L10n.text(language, 'Biraz Hızlı');
  String get bpLevel3 => L10n.text(language, 'Hızlı');
  String get bpListenAgain => L10n.text(language, 'Sesi tekrar dinle');
  String get bpListenAndFind => L10n.text(language, 'Dinle ve bul');
  String get bpMissed => L10n.text(language, 'Kaçan');
  String get bpStart => L10n.text(language, 'BAŞLA');
  String get bpTotalBalloons => L10n.text(language, 'Toplam balon');
  String get bpWrongTaps => L10n.text(language, 'Yanlış dokunma');
  String get haCars => L10n.text(language, 'Geçen Araba');
  String get haCompleted => L10n.text(language, 'Harf Arabaları Tamamlandı');
  String get haDesc =>
      L10n.text(language, 'Sesi dinle, doğru harfli arabayı yakala!');
  String get haGame => L10n.text(language, 'Harf Arabaları');
  String get haMissedTarget => L10n.text(language, 'Kaçırılan Hedef');
  String get haWrong => L10n.text(language, 'Yanlış');
  String get lbTitle => L10n.text(language, 'Genel Sıralama');
  String get lbMenuSubtitle =>
      L10n.text(language, 'Tüm oyuncular arasında sıran');
  String get onTitle => L10n.text(language, 'Genel Sıralama');
  String get onLoading => L10n.text(language, 'Sıralama yükleniyor…');
  String get onYou => L10n.text(language, 'SEN');
  String onRankLine(int rank, int total) => L10n.text(
    language,
    '{total} oyuncu arasında {rank}. sıradasın',
    {'total': total, 'rank': rank},
  );
  String onPlayers(int total) =>
      L10n.text(language, '{total} oyuncu', {'total': total});
  String get onOffline => L10n.text(
    language,
    'Skorun bu cihaza kaydedildi. İnternet olunca genel sıralama güncellenecek.',
  );
  String get onLoadFailed =>
      L10n.text(language, 'Genel sıralama şu anda yüklenemiyor.');
  String get onRetry => L10n.text(language, 'Tekrar dene');
  String get onNoPlayer => L10n.text(
    language,
    'Genel sıralamada yer almak için bir oyuncu adı seç.',
  );
  String get onInvalidName => L10n.text(
    language,
    'Bu oyuncu adı genel sıralamada kullanılamıyor; yeni bir oyuncu adı oluştur.',
  );
  String get onEmpty => L10n.text(language, 'Henüz kimse yok. İlk sen ol!');
  String get onBestOnline => L10n.text(language, 'Genel en iyin');
  String get plErrEmpty => L10n.text(language, 'Bir ad yaz.');
  String get plErrLong => L10n.text(language, 'En fazla 16 harf.');
  String get plErrShort => L10n.text(language, 'En az 2 harf.');
  String get plErrChars =>
      L10n.text(language, 'Sadece harf, rakam ve boşluk kullan.');
  String get plErrNotAllowed => L10n.text(language, 'Başka bir ad seç.');
  String get plErrTaken => L10n.text(language, 'Bu ad zaten kullanılıyor.');
  String get plLabel => L10n.text(language, 'Oyuncu');
  String get plEnterName => L10n.text(language, 'Adını yaz');
  String get plNameIntro => L10n.text(
    language,
    'Genel sıralamada bu adla görüneceksin. Sonra istersen düzeltebilirsin.',
  );
  String get plContinue => L10n.text(language, 'Devam');
  String get plSave => L10n.text(language, 'Kaydet');
  String get plNameHint =>
      L10n.text(language, 'Takma ad yeterli, tam adını yazma');
  String get plNameLabel => L10n.text(language, 'Oyuncu Adın');
  String get playAgain => L10n.text(language, 'Tekrar Oyna');
  String get score => L10n.text(language, 'Puan');

  /// "Oyuncu: Elif" (oyuncunun adı çevrilmez).
  String playerLine(String name) =>
      L10n.text(language, 'Oyuncu: {name}', {'name': name});

  /// Yüzde: Türkçede "%85", diğer dillerde "85 %" / "85%".
  String percent(int value) => L10n.text(language, '%{n}', {'n': value});
}
