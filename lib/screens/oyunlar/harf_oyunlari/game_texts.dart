/// Harf oyunlarının (Bul & Patlat, Harf Arabaları) ve oyuncu profili
/// ekranlarının Türkçe metinleri. Bu uygulamada l10n yok; metinler tek
/// yerde durur.
class GameTexts {
  const GameTexts();

  String get back => 'Geri';
  String get bpAccuracy => 'Doğruluk';
  String get bpBackToGames => 'Oyunlara Dön';
  String get bpBest => 'En İyi';
  String get bpCompleted => 'Bul & Patlat Tamamlandı';
  String get bpCorrect => 'Doğru';
  String get bpDesc => 'Sesi dinle, doğru harfi bul ve balonu patlat!';
  String get bpGame => 'Bul & Patlat';
  String get bpLevel => 'Seviye';
  String get bpLevel1 => 'Yavaş';
  String get bpLevel2 => 'Biraz Hızlı';
  String get bpLevel3 => 'Hızlı';
  String get bpListenAgain => 'Sesi tekrar dinle';
  String get bpListenAndFind => 'Dinle ve bul';
  String get bpMissed => 'Kaçan';
  String get bpStart => 'BAŞLA';
  String get bpTotalBalloons => 'Toplam balon';
  String get bpWrongTaps => 'Yanlış dokunma';
  String get haCars => 'Geçen Araba';
  String get haCompleted => 'Harf Arabaları Tamamlandı';
  String get haDesc => 'Sesi dinle, doğru harfli arabayı yakala!';
  String get haGame => 'Harf Arabaları';
  String get haMissedTarget => 'Kaçırılan Hedef';
  String get haWrong => 'Yanlış';
  String get lbTitle => 'Genel Sıralama';
  String get lbMenuSubtitle => 'Tüm oyuncular arasında sıran';
  String get onTitle => 'Genel Sıralama';
  String get onLoading => 'Sıralama yükleniyor…';
  String get onYou => 'SEN';
  String onRankLine(int rank, int total) =>
      '$total oyuncu arasında $rank. sıradasın';
  String onPlayers(int total) => '$total oyuncu';
  String get onOffline =>
      'Skorun bu cihaza kaydedildi. İnternet olunca genel sıralama güncellenecek.';
  String get onLoadFailed => 'Genel sıralama şu anda yüklenemiyor.';
  String get onRetry => 'Tekrar dene';
  String get onNoPlayer =>
      'Genel sıralamada yer almak için bir oyuncu adı seç.';
  String get onInvalidName =>
      'Bu oyuncu adı genel sıralamada kullanılamıyor; yeni bir oyuncu adı oluştur.';
  String get onEmpty => 'Henüz kimse yok. İlk sen ol!';
  String get onBestOnline => 'Genel en iyin';
  String get plErrEmpty => 'Bir ad yaz.';
  String get plErrLong => 'En fazla 16 harf.';
  String get plErrShort => 'En az 2 harf.';
  String get plErrChars => 'Sadece harf, rakam ve boşluk kullan.';
  String get plErrNotAllowed => 'Başka bir ad seç.';
  String get plErrTaken => 'Bu ad zaten kullanılıyor.';
  String get plLabel => 'Oyuncu';
  String get plEnterName => 'Adını yaz';
  String get plNameIntro =>
      'Genel sıralamada bu adla görüneceksin. Sonra istersen düzeltebilirsin.';
  String get plContinue => 'Devam';
  String get plSave => 'Kaydet';
  String get plNameHint => 'Takma ad yeterli, tam adını yazma';
  String get plNameLabel => 'Oyuncu Adın';
  String get playAgain => 'Tekrar Oyna';
  String get score => 'Puan';
}
