# Namaz Duaları kaynak kaydı

Kaynak: D:/Elifbe2025/lib/elifbe_dualar_view/dua_dersleri.dart ve dua_detay_page.dart.
Başlıklar: lib/l10n/app_tr.arb. Metin: assets/jsondatalar/dualar/*.json.
Alanlar: name → arabic, basta → meaningTr, price → audioAsset. Kaynak id değerleri korunur.
Türkçe okunuş ve ayrı Arapça başlık bulunmuyor. Kartta ilk parçadan önizleme gösterilir.
Ettehiyyâtü id=3 satırı «اللَّ» ile bitiyor; bazı metinlerde yinelenen/sonda kalan harekeler mevcut. Hiçbir metin düzeltilmedi.
ortada/sonda alanları yer tutucu ve ürün URL’leri içeriyor; eski dua ekranı da bunları kullanmıyor.
Liste modelindeki audioFileName, eski detay ekranında kullanılmıyor; gerçek çalma eşleşmeleri JSON price alanından alındı.

| Dua | Kaynak JSON | Ses dosyaları (assets/audio/ → assets/audio/dualar/) |
|---|---|---|
| Sübhâneke | 1_subhaneke_duasi.json | 01_subhaneke/subhaneke1.mp3, 01_subhaneke/subhaneke2.mp3, 01_subhaneke/subhaneke3.mp3, 01_subhaneke/subhaneke4.mp3 |
| Ettehiyyâtü | 2_ettahiyatu_duasi.json | 02_ettahiyatu/etahiyyat-01.mp3, 02_ettahiyatu/etahiyyat-02.mp3, 02_ettahiyatu/etahiyyat-03.mp3, 02_ettahiyatu/etahiyyat-04.mp3, 02_ettahiyatu/etahiyyat-05.mp3 |
| Allâhumme Salli | 3_salli_duasi.json | 03_salli/salli-01.mp3, 03_salli/salli-02.mp3, 03_salli/salli-03.mp3 |
| Allâhumme Barik | 4_barik_duasi.json | 04_barik/barik-01.mp3, 04_barik/barik-02.mp3, 04_barik/barik-03.mp3 |
| Rabbenâ âtinâ | 5_atina_duasi.json | 05_atina/atina-01.mp3, 05_atina/atina-02.mp3 |
| Rabbenâğfirli | 6_rabbenafirli_duasi.json | 06_rabbenafirli/5-RABBENAGFIRLI.mp3 |
| Kunut Duası 1 | 7_kunut1_duasi.json | 07_kunut1/kunut_1-01.mp3, 07_kunut1/kunut_1-02.mp3, 07_kunut1/kunut_1-03.mp3, 07_kunut1/kunut_1-04.mp3, 07_kunut1/kunut_1-05.mp3 |
| Kunut Duası 2 | 8_kunut2_duasi.json | 08_kunut2/kunut_2-01.mp3, 08_kunut2/kunut_2-02.mp3, 08_kunut2/kunut_2-03.mp3, 08_kunut2/kunut_2-04.mp3 |
| Amentü | 9_amentu_duasi.json | 09_amentu/amentu-01.mp3, 09_amentu/amentu-02.mp3, 09_amentu/amentu-03.mp3, 09_amentu/amentu-04.mp3, 09_amentu/amentu-05.mp3 |

## Eklenen dosyalar

- lib/models/dua.dart
- lib/data/dualar_data.dart
- lib/screens/dualar/dualar_list_screen.dart
- lib/screens/dualar/dua_detail_screen.dart
- lib/screens/dualar/widgets/dua_segment_card.dart
- lib/widgets/recitation_card.dart
- lib/widgets/recitation_audio_controls.dart
- test/dualar_test.dart
- docs/dualar_source.md
- assets/audio/dualar/ altında yukarıdaki 9 klasörde toplam 32 MP3

## Ortak altyapı

AudioService, Responsive, AppColors, AppTextTheme/Hasenat, LetterPageBackground,
MaterialPageRoute yeniden kullanılır. SurahCard ve SurahAudioControls mevcut
arayüzlerini koruyarak ortak RecitationCard ve RecitationAudioControls bileşenlerine
yönlendirir. Sure ve Elifba verileri ile AudioService değiştirilmedi.
Sayfadan çıkıldığında ses, mevcut Sureler davranışı gibi devam eder.
Kaynakta Türkçe okunuş bulunmadığı için okunuş bölümü gösterilmez;
modelin isteğe bağlı pronunciationTr alanı ileride kaynak veriyle doldurulabilir.

## Doğrulama

- 32 Arapça metin ve 32 Türkçe anlam kaynak JSON ile karakter karakter aynı.
- 32 ses dosyasının SHA-256 özeti eski dosyalarla aynı.
- flutter pub get ve flutter analyze başarılı; analizde sorun yok.
- 7 Flutter testi geçti. Dua ekranları 360×800, 800×1280, 1280×800,
  1440×900 boyutlarında; RTL, son parçaya erişim ve alt çubuk ayrımı kontrol edildi.
- Ana sayfa → liste → detay → geri; dinle/duraklat/devam/durdur/yeniden başlat
  ve dua değiştirme arayüz akışları taklit ses servisiyle kontrol edildi.
- Tarayıcı aracı bağlantı hatası nedeniyle canlı web görünümü ve cihazda ses
  çözümleme/gerçek oynatma doğrulanamadı.
- Mevcut splash testi artık kapak görselini ve ana sayfaya geçişi doğruluyor.
