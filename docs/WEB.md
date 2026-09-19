# Web sürümü: telefonda görünüm ve yayın notları

Son güncelleme: 2026-09-20.

## Telefonda "her şey küçük" sorunu (çözüldü)
**Belirti:** Kullanıcının telefonunda (Samsung, Android) web sürümü tablet düzeninde açılıyordu:
ana sayfada 2 sütun, Ders 1'de 5 sütun harf, hepsi küçücük. Tablette sorun yoktu.

**Neden:** Telefon tarayıcısı sayfayı cihazın genişliğinde (~393 px) değil, **~880–980 px genişliğinde**
yerleştirip ekrana sığdırmak için küçültüyordu ("masaüstü sitesi" modu, uygulama içi tarayıcı, ana ekrana
eklenmiş kısayol vb.). Uygulama genişliği ≥ 600 görünce tablet düzenini seçiyordu. Yayındaki eski
sürümde `index.html`'de görüntü alanı (viewport) etiketi de yoktu.

**Çözüm (iki katman):**
1. `web/index.html`: sabit `<meta name="viewport" content="width=device-width, initial-scale=1.0, ...">`.
2. `PhoneZoomFix` (`lib/widgets/phone_zoom_fix.dart`, `MaterialApp.builder`'da): tarayıcının yerleşim
   genişliği (`innerWidth`) telefonun gerçek ekran genişliğinin (`screen.width`) 1,25 katından fazlaysa
   **ve** ekranın kısa kenarı < 600 ise (`lib/core/phone_zoom_detect_web.dart`), uygulamaya telefon boyutunda
   bir tuval verir (telefon düzeni seçilir) ve tuvali sayfayı dolduracak kadar büyütür; tarayıcı bunu
   küçültünce görünüm **telefon uygulamasıyla aynı** olur. Normal telefon, tablet ve masaüstünde etkisizdir
   (çarpan 1). Telefon/masaüstü uygulamasında (web değil) hiç çalışmaz (`phone_zoom_detect_stub.dart`).
3. Test: `test/phone_zoom_fix_test.dart` (tuval boyutu, dokunma koordinatları, ana ekranın tek sütuna
   geçmesi, pencere değişince yeniden okuma).

**Gerçek tarayıcıda doğrulama:** `tools/web_audio_check/phone_wide.js <url> <önek> 880` — Chrome'a
"yerleşim 880 px, cihaz ekranı 393 px" durumunu (CDP `setDeviceMetricsOverride` + `screenWidth`) taklit
ettirir ve telefonun göreceği ölçekte ekran görüntüsü alır. Eski sürüm kullanıcının ekran görüntüsünü
birebir üretti; yeni sürüm telefon düzenini verdi.

Kullanıcının telefonda görebilmesi için sayfayı yenilemesi yetmeyebilir: Flutter'ın service worker'ı yeni
sürümü ilk açılışta indirir, **ikinci açılışta** kullanır (uygulamayı/sekmeyi tamamen kapatıp yeniden aç).
Ana ekrana eklenmiş kısayol varsa kaldırıp yeniden eklemek en kesini yapar.

## Yayın (kısa)
GitHub Actions, `main`'e her push'ta analiz + test + derleme + Pages. Ayrıntı: `CLAUDE.md`. Alt yol
(`/kuran-okuma-rehberi/`) nedeniyle Flutter'ın kendi service worker önbelleği dosyaları saklamaz; sesler
için kendi depomuz var (`docs/SES.md`).
