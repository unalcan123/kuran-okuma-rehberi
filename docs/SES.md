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
   - Çalarken web'de ses bellekten çalınır: dokununca ağ yok. Bellekte yoksa önce yüklenir
     (bir dahaki sefere hazır olur). 2026-10-10'dan beri data-URI değil, aşağıdaki "Web ses motoru".
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

## Web ses motoru (2026-10-10, iPhone/iPad Safari cızırtı / yarım harf şikâyeti)
Uygulamalar (Android, Windows, ileride iOS) `audioplayers` ile çalmaya devam eder
(`PluginAudioEngine`). **Web'de** `audioplayers` her sesi `<audio>` → Web Audio köprüsünden
(MediaElementAudioSourceNode) geçiriyor, her dokunuşta yeni öğe + başa sarma (seek) yapıyordu;
Safari'deki bozulmanın en güçlü şüphelisi bu köprü (araştırma raporu, bkz. kullanıcı klasörü).
Artık web kendi motorunu kullanır; `AudioService`'in dışa açık hali aynı.

- Dosyalar: `lib/services/audio_engine.dart` (arayüz, platform seçimi), `plugin_audio_engine.dart`
  (audioplayers), `web_audio/web_audio_engine.dart` (mantık: istek kimlikleri, yönlendirme, ön bellek;
  tarayıcısız test edilir), `web_audio/js_web_audio_port.dart` (gerçek tarayıcı), `web_audio/audio_diagnostics_web.dart`.
- **Kısa sesler** (`audio/elifba/`, `audio/oyunlar/`, hız 1,0, ≤ 96 KB): tek AudioContext, her kayıt
  bir kez `decodeAudioData` ile çözülür, her çalış yeni AudioBufferSourceNode (→ GainNode → çıkış).
  Önceki harf ~12 ms kısılarak durur (tık sesi olmasın), düğümler ayrılır. Çözülmüş ses ön belleği
  **sınırlı** (20 MB, en eski kullanılan atılır; bir ders ~4-5 MB). Ekran açılınca `preload` o ekranın
  kısa seslerini sırayla çözer — ama bağlam ilk dokunuşta kurulduktan sonra. Efekt kanalı ayrı (harfi kesmez).
- **Sure/dua, Türkçe açıklama ve hız ≠ 1,0 olan her şey**: Web Audio'ya **bağlanmamış** tek `<audio>`
  öğesi (kanal başına bir tane, yeniden kullanılır), kayıt bellekten object URL ile. Hız `play()`'den
  **önce** `defaultPlaybackRate` + `playbackRate` olarak verilir (yeni kaynak hızı sıfırlamasın),
  `preservesPitch` açık. Buffer hızı perdeyi değiştirdiği için Kur'an okuması asla buffer'dan çalmaz.
- **İlk dokunuş**: pencerede capture dinleyicisi, Flutter dokunuşu işlemeden ve hiç `await` olmadan
  bağlamı kurar/uyandırır, bir sessiz örnek çalar, `<audio>` öğelerine `load()` der (iOS sonra
  dokunuşsuz çalmaya — sıradaki ayete — izin versin). `interrupted` kalıp uyanmayan bağlam bir
  sonraki dokunuşta yenilenir (WebKit 276016).
- **Kendiliğinden ses yok**: bağlam çalışmıyorsa istek düşer (sonra çalmaz). Arka plana geçince ve
  kesintide (`interrupted`/`suspended`) çalan harf/efekt durur; geri dönünce yalnız bağlam uyandırılır.
- **Yarışlar**: her ana kanal isteğinin kimliği var; eski isteğin indirme/çözme/bağlam beklemesi yeni
  istek ya da `stop()` gelince vazgeçer; eski sesin geç gelen "bitti" olayı yenisini bitirmez
  (`AudioService` de kimliğe bakar). Hız 1,0'a dönüşü ses dururken de saklanır.
- **Deneme bayrakları** (yalnız adreste, çocuğa görünmez): `?ses=eski` = eski audioplayers yolu
  (karşılaştırma için), `?sesTani=1` = sol altta günlük kutusu (bağlam durumu, örnekleme hızı,
  gecikmeler, öğe olayları, gerçek hız/perde, takılma ölçümü; "Günlüğü kopyala"). Derleme etiketi:
  `--dart-define=KURAN_BUILD=...`.
- **Cihaz tanı sayfası** `web/ses-tani.html` (derlemeyle yayına girer, `noindex`): aynı kayıtla
  P1 eski köprülü yol (audioplayers 5.2.0 taklidi) / P2 seek'siz / P3 köprüsüz yeni öğe / P3b
  köprüsüz tek öğe (yeni sure yolu) / P4 çözülmüş buffer (yeni harf yolu); hız 0,75-1,25, 20 hızlı
  dokunuş, 200 tekrar, arka plan, takılma ölçümü, derleme kimliği, ana ekran tespiti.
- Testler: `test/web_audio_engine_test.dart` (sahte tarayıcıyla gerçek motor). **Chrome'da geçmesi
  Safari'nin düzeldiğini kanıtlamaz**; gerçek iPhone/iPad denemesi gerekir.

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

## Üç tekrarlı ezber kayıtlarını ayetlere ayırma (`tool/ezber_split/split_ezber.py`)
Kaynak `H:\Music\sureler\tekrarli` (yalnız okunur). Kayıtta okumalar arasında aynı zil örneği var
(~789 Hz, ~0,92 sn, çevresi dijital sessizlik); zil bandı oranı + şablon korelasyonu (≥0,9) ile bulunur,
kesim zilin çevresindeki sessizlikte, konuşmadan 0,25 sn dışarıda. Ayet numarası zil sayısından değil:
her parça Kur'an tilavetiyle eğitilmiş `tarteel-ai/whisper-base-ar-quran` ile tanınıp
`tool/sources/diyanet_arabic_extract.json` metnine benzetilir; tekrarlar ayrıca DTW ile karşılaştırılır.
Kayıt yapısı (Asr'da doğrulandı): besmele (zilsiz, duraklamayla ayrılır) → her ayet 3 kez → sonda tam okuma.
Çıktı `tmp/ezber_split/<sure>/`: `parca_NN.mp3` (her tekrar), `00_besmele.mp3`, `NN_ayet.mp3`,
`tam_okuma.mp3`, `rapor.md/json` (şüpheliler: kenarda yüksek ses, zil kalıntısı, grup ≠ 3, sıra dışı).
Mono 32 kHz 48 kbps. Uygulamaya kendiliğinden girmez; dinlenip onaylanınca kopyalanır.
**Uygulamada: yalnız Asr** (`assets/audio/sureler/22_asr/`: besmele + 3 ayet, her ayetin en temiz tekrarı —
en az kırpma, en geniş sessizlik payı; −3 dB ile diğer surelerin seviyesine; parmak izleri
`tool/original_audio_fingerprints.json`'da; Asr'ın uzun tam kaydı kaldırıldı, Dinle ayet ayet çalar).
Test: `test/asr_ayet_audio_test.dart`. Diğer sureler kullanıcı Asr'ı onaylayınca.
`python tool/ezber_split/split_ezber.py "<dosya>"` veya `--batch` (gerekenler: numpy, scipy, torch, transformers).

## Bilinen sınırlar
- Tarayıcılar, kullanıcı ekrana dokunmadan sesi başlatmayı engeller (özellikle iOS Safari).
  Dinle ve Seç'te ilk soru sesi kendiliğinden çalmazsa çocuk Dinle butonuna dokunur.
- `yanlis.wav` (kullanılmayan, kullanıcının eklediği eski yanlış-cevap sesi) kullanıcı isteğiyle silindi;
  yanlış cevapta bilerek ses çalınmıyor.
