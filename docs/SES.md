# Ses: kayıtlar, önbellek ve web'de gecikme

Son güncelleme: 2026-09-19. Web'de sesler geç geliyor / gelmiyor şikâyeti üzerine yapıldı.

## Sorun neydi
audioplayers **web'de her çalışta yeni bir ses öğesi kurup dosyayı ağdan yeniden ister**.
Elifba kayıtları da 320 kbps stereo mp3'tü (toplam 106 MB, harf başına ~30–55 KB), bu yüzden
her dokunuş ağa bağlıydı; hızlı tıklamada istekler birbirini kesiyordu. Ayrıca yeni bir
dokunuş, eski isteğin hata durumunu geri yazıp yeni sesin durumunu bozabiliyordu.

## Çözüm (üç parça)
1. **Kayıtlar küçültüldü** (106 MB → ~22 MB). `assets/audio/`:
   - `elifba/`: mono, 32 kHz, 64 kbps mp3 (harf başına ~7–11 KB)
   - `sureler/`, `dualar/`: mono, 44,1 kHz, 80 kbps mp3
   - `oyunlar/dogru.mp3`: mono, 44,1 kHz, 64 kbps (eskiden 123 KB'lık `dogru.wav`)
   - Süreler birebir aynı; ses düzeyi ~0,4 dB farkla korundu.
   - **Orijinal 320 kbps dosyalar git geçmişinde**: ilk commit `b53b7bc`
     (`git show b53b7bc:assets/audio/elifba/ders_1_harfler/01_elif.mp3 > x.mp3`).
2. **Ön yükleme + bellekten çalma** (`lib/services/sound_cache.dart`, `audio_service.dart`):
   - Ekran açılınca `AudioService.preload([...])` o ekranın tüm seslerini arka planda indirir
     (6 dosya birden). Çağıranlar: Elifba dersi (`lesson_letters_screen`), Sürükle & Bırak,
     Dinle ve Seç (ders sesleri + `dogru.mp3`), sure ve dua detayı.
   - Çalarken web'de ses bellekteyse `BytesSource` (data-URI) ile çalınır: dokununca ağ yok.
     Bellekte yoksa önce yüklenir (bir dahaki sefere hazır olur).
   - Sure/dua dizilerinde sıradaki klip önceden hazırlanır (klipler arası boşluk kısalır).
   - Yalnızca **web'de** çalışır (`kIsWeb`); telefon/masaüstü uygulamasında dosyalar zaten
     yerel, `AssetSource` aynen kullanılır.
   - Her yeni çalma isteği bir **sıra numarası** (`_playToken`) alır; bekleyen eski istek,
     araya yeni dokunuş ya da `stop()` girdiyse vazgeçer ve durumu bozmaz.
3. **Kalıcılık (bir dahaki açılış)**: web'de indirilen her ses, tarayıcının **Cache Storage**'ına
   `kuran-sounds-<sürüm>` adıyla yazılır (`lib/services/sound_store_web.dart`); bir dahaki
   açılışta (sayfa yenileme, tarayıcıyı kapatıp açma) `SoundCache` önce oradan okur, sunucudan
   **hiç indirmez**. Telefon/masaüstü uygulamasında depo yoktur (`sound_store_stub.dart`, dosyalar
   zaten yerel).
   - Neden Flutter'ın kendi service worker'ı değil: `flutter_service_worker.js` yalnızca **alan adının
     köküne** yayınlanan sitelerde dosyaları önbellekler (anahtarı `url.substring(origin.length+1)`
     ile üretiyor). Şu an site GitHub Pages alt yolunda (`/kuran-okuma-rehberi/`) olduğu için
     hiçbir şeyi önbelleklemiyordu; ölçümle doğrulandı. Kendi depomuz her yayın biçiminde çalışır.
   - **Sürüm kuralı:** `kSoundCacheVersion` (`lib/services/sound_cache.dart`) `assets/audio/`
     dosyalarının parmak izidir. Bir ses dosyası eklenir/değişirse `test/audio_assets_test.dart`
     kırılır ve yeni değeri yazar; sabiti güncelle. Böylece ziyaretçiler eski kaydı duymaz;
     eski sürümlerin önbelleği otomatik silinir.
   - Depolama dolu / özel mod gibi durumlarda yazma sessizce atlanır, ses yine çalar.
   - Safari, sık kullanılmayan sitelerin depolamasını ~7 günde silebilir (o zaman yeniden iner).

## Ölçüm (gerçek Chrome, headless, 2026-09-19, tek bilgisayar / hızlı bağlantı)
| | Eski (yayındaki) | Yeni |
|---|---|---|
| Dokunmadan sesin başlamasına | ort. 116 ms (ağa bağlı) | ort. 24 ms (ağdan bağımsız) |
| Dokunuş başına ağ isteği | 2 | 0 |
| Ders 1 açılışı | – | 28 ses dosyası ~0,8 sn'de iner |
| Sayfa yenilendikten sonra (2. ziyaret) | 28 indirme | **0 indirme** (28/28 cihazdaki depodan) |
Yavaş mobil ağda eski sürümün gecikmesi çok daha kötüdür; yeninin dokunma gecikmesi ağdan bağımsızdır.

Betikler: `tools/web_audio_check/` (`npm i` → derlenmiş siteyi sun → `node latency.js <url> <etiket>`,
`node storage.js <url>` (cihazda saklama + 2. ziyarette indirme sayısı) — alt yol testi için siteyi `site/kuran-okuma-rehberi/` altından sun). Chrome yolu `CHROME` ortam değişkeniyle verilir. Flutter web
canvas olduğu için betik erişilebilirlik ağını açıp düğümlere tıklar.

## Yeni ses eklerken (önemli)
Kaynak kaydı **küçültmeden** ekleme; `test/audio_assets_test.dart` büyük dosyayı reddeder
(dosya başına 250 KB, toplam 30 MB, Elifba klibi 60 KB). Dönüştürme:
```
ffmpeg -i girdi.mp3 -af "pan=mono|c0=0.5*c0+0.5*c1" -ar 32000 -c:a libmp3lame -b:a 64k -map_metadata -1 cikti.mp3
```
(sure/dua için `-ar 44100 -b:a 80k`). **`pan` filtresini kullan**: `-ac 1` tek başına kanalları
toplayıp sesi ~3 dB yükseltir ve kırpar.

## Bilinen sınırlar
- Tarayıcılar, kullanıcı ekrana dokunmadan sesi başlatmayı engeller (özellikle iOS Safari).
  Dinle ve Seç'te ilk soru sesi kendiliğinden çalmazsa çocuk Dinle butonuna dokunur.
- `assets/audio/oyunlar/yanlis.wav` (222 KB) kullanılmıyor; kullanıcı ekledi, dokunulmadı.
