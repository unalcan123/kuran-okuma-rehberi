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

## Üç tekrarlı ezber kayıtlarını ayetlere ayırma (`tool/ezber_split/`)
Kaynak `H:\Music\sureler\tekrarli` (yalnız okunur). Okumalar arasında aynı zil örneği
(~789 Hz, ~0,92 sn; çevresi dijital sessizlik, dönüşte 30 ms'lik "tık"). Kayıt yapısı: besmele
(zilsiz, kısa duraklamayla) → her ayet 3 kez (Zilzâl 2. ayet 5 kez) → sonda tam okuma. Üç tekrar
çoğu kayıtta birebir aynı ses (kopyalanmış).
- `split_ezber.py`: zil = bant oranı + şablon korelasyonu; konuşma 150–5000 Hz bandında, taban +14 dB,
  yumuşak baş/son taban +6 dB'ye kadar uzatılır (zil çınlaması ve zilden sonraki 0,6 sn hariç);
  kesim konuşmadan 0,25 sn dışarıda. Ayet numarası zil sayısından değil: her parça
  `tarteel-ai/whisper-base-ar-quran` ile tanınıp uygulamanın ayetleriyle sınırlı Diyanet metnine
  benzetilir (`diyanet_arabic_extract.json`'da surelerin sonunda başka surelere ait yanlış satırlar var).
  Besmele, ilk parçadaki duraklamalardan en iyi okunanından ayrılır. Grubun süre ortancasından %35 sapan
  tekrar kullanılmaz. Her ayetin en temiz tekrarı (en az kırpma, en geniş sessizlik) −3 dB, mono 32 kHz 48 kbps.
  `--single`: Âyetel Kürsî gibi tek kartlık öğede sondaki tam okuma (besmele ayrılır).
- **Tuzaklar:** analiz 22 000 Hz (22 050'de 220 örneklik kare 9,977 ms → zaman %0,23 kayıyordu: 156. sn'de
  0,35 sn, ayet başları kesiliyordu); Whisper sıcaklık geri dönüşü kapalı + jeton sınırı (yoksa parça başına
  dakikalar); iki tanıma işini aynı anda çalıştırma (CPU boğulur).
- `verify_clips.py`: kurulan her klibi bağımsız doğrular (doğru ayet, zil yok, kenar sessiz) →
  `tmp/ezber_split/dogrulama.md`. `install_clips.py`: klasör, veri yolları, pubspec, parmak izi; bütün
  bölümlerin sesi varsa uzun zilli tam kayıt (`full_readings/`) silinir, Dinle ayet ayet çalar.
- **Uygulamada (2026-10-29):** Âyetel Kürsî (besmele + 139 sn'lik tek ayet; boyut testinde süreye göre
  istisna), Duhâ, İnşirâh, Tîn, Zilzâl, Âdiyât, Kâria, Tekâsür, Asr, Hümeze — 88 klip, hepsi doğrulandı.
  **Kadir (sonradan kuruldu):** kayıtta "selâm" 4. ayetin klibinin sonunda okunuyordu; 13,08 sn'den kesilip kısa bir
  duraklamayla 5. ayetin başına eklendi (tanıma: "…min kulli emr" / "selâmun hiye hattâ…"), uzun zilli kayıt silindi.
  **Kurulmadı:** Nebe 31–40 (kayıt yok). Tesbihat, Tüncînâ, Ezan ve Yemek Duası sonradan kullanıcının bölüm bölüm
  kayıtlarıyla kuruldu (aşağıda); artık uzun/zilli kayıt yok. Test: `test/verse_audio_all_test.dart`,
  `test/asr_ayet_audio_test.dart`.
- **Bölüm bölüm hazır gelen dua kayıtları** (kullanıcı Audacity'de ayırır, `ref/<dua>/NN-*.mp3`): her parça
  Whisper ile tanınıp kartla eşleştirilir, mono 44,1 kHz 80 kbps + 8 ms / 40 ms yumuşatma, `register()` ile
  pubspec/parmak izi. **Tefriciye** (2026-10-29, 15. dua, kitapta yok): 8 parça; 8. parça "fî külli lemhatin
  ve nefes" ile başladığı için 7. parça 2,62 sn'de kesildi (okuyucu ifadeyi iki kez okumuş; ikinci, boşluklu kayıtta da aynı); baştan 0,15 sn, sondan 0,3 sn sessizlik bırakılır. **Ezan Duası**
  4 parça geldi ama "ve'd-derecete'r-refî'a" ve "inneke lâ tuhlifu'l-mîâd" okunmuyor → kullanıcı yeniden
  kaydedecek, kurulmadı. **Yemek Duası** `ref/yemekduasi`: üç parça da aynı ilk cümle (tekrarlı kayıt) →
  duanın tamamı kaydedilince 3 karta bölünecek.
- **Bölüm bölüm kayıtlar (2026-10-29, kullanıcı Audacity'de kesti):** hepsi Whisper ile tanınıp bölüme eşlendi,
  mono 32 kHz 48 kbps (36 MB toplam bütçesi için). **Namazla ilgili lafızlar** (`ref/NAMAZLA ILGILI LAFIZLAR`, 29 klip
  → `dualar/namaz_lafizlari/lafiz_NN.mp3`): Dua 11 (tekbirler, iki selam), 12 (tesbihat; istiğfar ve 33'lükler kayıtsız,
  "Allâhu ekber 33" lafiz_01'i paylaşır), 14 (Salâten Tüncînâ 9 bölüm). Kullanıcı kararıyla metin kayda uyduruldu
  ("kayda göre" işaretli): "Rabbenâ **ve** leke'l-hamd", "Elhamdülillâhi **hamden** kesîrâ", Tüncînâ sonu "âmîn yâ
  mucîbe'd-de'avât, ve'l-hamdü lillâhi…", uzun tevhid (yuhyî ve yümît … ve ileyhi'l-masîr). Belirsiz kelimede iki metni
  modele puanlat (`score`: kayıp düşük olan okunuyor). Kaydı olmayan bölüm sessiz: Dinle/Ezberle en az bir klip varsa açık,
  oynatıcı sessiz bölümü atlar. **Âyetel Kürsî** 9 bölüm (`Ayet.verse` = 255, dosya 01-09_ayet) + yeni besmele; eski 139 sn'lik
  `255_ayet.mp3` silindi. **Âmenerrasûlü** (Bakara 285-286) yeni, 24. öğe (`kAmenerrasulu`, sona; numaralar/klasörler
  kaymasın), 15 bölüm; 05 ve 10'un sonundaki tekrar ("gufrâneke rabbenâ", "kemâ hameltehû") kesildi. Âyetel Kürsî ve
  Âmenerrasûlü Arapçası kullanıcının `kuran.docx`'inden (Türkiye mushaf yazımı; `tool/sources/kuran_docx_*.json`), mealler
  Suat Yıldırım + QuranEnc (`amenerrasulu_published.json`).
- **Ezan ve Yemek Duası (2026-10-29):** cümle cümle kartlar; zilli uzun kayıtlar silindi (`kFullReadingAudio` artık boş,
  `full_readings/` klasörü yok). Ezan: 4 cümle kullanıcının zilsiz parçalarından (`dualar/10_ezan_duasi/`), "ve'd-derecete'r-refî'a"
  ve "inneke lâ tuhlifu'l-mîâd" kayıtsız/sessiz. Yemek: yalnız "Elhamdülillâhillezî et'amenâ…" sesli (`dualar/13_yemek_duasi/`),
  diğer cümleler kayıt gelene kadar sessiz. **Sonra:** kullanıcı 3 yeni kayıt verdi (`ref/9|10|11-YEMEK DUASI N.wav`); Yemek
  Duası kayda göre yeniden yazıldı (Eûzü-Besmele sessiz + "…ve cealenâ müslimîn" (puanlamayla, "mine'l-" yok), "Allâhümme et'im men
  et'amenâ…", "Eftara indekümü's-sâimûn…"; kitabın kayıtta olmayan kısımları çıkarıldı). 2. ve 3. kayıt duraklamalarından
  (enerji < tepe−28 dB) 4 + 3 ifadeye kesildi, her parça tanıtıldı → 10 kart, `yemek-01..08.mp3`.
- Çalıştırma: `python tool/ezber_split/split_ezber.py --batch` ve `--single`, ardından
  `install_clips.py <id...>`, `verify_clips.py <id...>` (gerekenler: numpy, scipy, torch, transformers).

## Bilinen sınırlar
- Tarayıcılar, kullanıcı ekrana dokunmadan sesi başlatmayı engeller (özellikle iOS Safari).
  Dinle ve Seç'te ilk soru sesi kendiliğinden çalmazsa çocuk Dinle butonuna dokunur.
- `yanlis.wav` (kullanılmayan, kullanıcının eklediği eski yanlış-cevap sesi) kullanıcı isteğiyle silindi;
  yanlış cevapta bilerek ses çalınmıyor.
