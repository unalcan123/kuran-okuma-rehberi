# Türkçe açıklama sesleri (🔊)

Kitap sayfalarındaki Türkçe açıklamalara ve konu başlıklarına dokununca Türkçe
seslendirmesi çalar. Metin ekranda gerçek Flutter metni olarak kalır (resim değil);
ses `assets/audio/tr/<id>.mp3`. Arapça harf/kelime sesleri ayrı sistemdir ve
değişmedi.

## Kaynak ve metin
- Kaynak: `assets/lazim/ELIF BA BASKI DENEME 2012.pdf`, s. 3–63 (git dışı).
- **Metin = ekrandaki metin = PDF metni.** Veri dosyaları PDF'ye göre düzeltildi
  (s. 6 "28/7/21", s. 24 "Hemze", s. 40 "Tenvin:" kırmızı ama tırnaksız; s. 57
  "işâretlerinde"). Tek bilinçli fark: s. 10 PDF'deki yazım hatası "bitiştiğinı" →
  "bitiştiğini".
- Kayıtların metni `tool/turkish_audio/manifest.json`'da. `test/turkish_audio_test.dart`
  manifest metninin ekrandakiyle **aynı** olduğunu denetler; ekrandaki metin
  değişirse test hangi kaydın metnini güncelleyeceğini söyler, üretici değişen
  metni (textHash) yeniden seslendirir.

## Kalıcı kimlik (ders numarasından bağımsız)
`sPPP_KK` = PDF sayfası PPP'nin KK. açıklaması; `sPPP_baslik_N` = o sayfanın N.
başlığı (sayfa başlığı, ara başlık, bölüm başlığı). Aynı sayfada iki ders olsa da
sıra sayfa içindedir (s. 39: `s039_01` Çeker Üstün, `s039_02` Çeker Esre; s. 55:
`s055_01–02` Zamir He, `s055_03` Uzun Med). Ders numarası kimlikte yoktur: dersler
birleşse/yeniden numaralansa da dosya adı değişmez. Manifest'te `lessonId`
(`Lesson.id`, kalıcı içerik kimliği) ayrıca tutulur. Güncel eşleme
(`kElifbaLessons`): 27 Zamir He (s. 54–55), 28 Uzun Med (s. 55 alt), 29 Kapalı Te
(s. 56), 30 Kelime Sonu (s. 57–59), 31–34 Alıştırmalar (s. 60–63).

## Gruplama
- Birlikte okunması gereken ardışık cümle/maddeler tek kayıt (ör. s. 39 Çeker
  Üstün'ün üç maddesi, s. 54 "He'den önce uzatma harflerinden…" iki satırı).
  Ayrı kurallar ayrı kayıt (s. 54'te her kural kendi örneklerinin üstünde).
- Tek maddelik ara başlık açıklamasıyla birlikte okunur ("5. GENİZ: Burun içi…",
  "Önemli Not: 1. Mahreçler…", "1. CEVF: …"); birden çok maddeye başlık olanlar
  ayrı başlık kaydıdır ("2. BOĞAZ:", "3. DİL VE AĞIZ İÇİ:", "4. DUDAK:").
- **Seslendirilmez:** "Örnekler:" (cümle içindeyse blokta durur ama okunmaz),
  "Yazılış durumları şöyledir:", "Örneklerle uygulamayı görelim:", "Diğer bazı
  örnekler:"; tekrar eden genel başlıklar ("ÖRNEKLER", "ALIŞTIRMALAR - 1…4"); tablo
  başlıkları; s. 8 satır etiketleri; s. 5 çizim etiketleri; s. 23 lejantı; s. 10
  tablo hücresi notu "(elif kelimenin başında bulunmaz…)"; s. 51/52'de uygulamanın
  kendi eklediği başlıklar (kitapta başlık yok).

## Sayılar
102 kayıt = 69 açıklama + 33 başlık (2026-09-29: Ders 2'den s. 9 ve s. 10
çıkarılınca `s009_baslik_1`, `s010_01`, `s010_02` manifest'ten ve paketten silindi; mp3'ler
git geçmişinde. `s010_baslik_1` s. 11'in başlığı olarak kaldı). Eski not: Envanter denetimi (2026-09-27): 53 mp3 =
53 `generated` kayıt; hepsi aynı ses/model, `textHash` güncel, ffprobe ile okunuyor
(mono 24 kHz), 0 bayt/sahipsiz/çift kimlik yok; 105 kimliğin hepsi uygulamada tam
bir kez bağlı.
- Güvenli (yalnız Türkçe): 53 = 35 açıklama + 18 başlık — **hepsi üretildi**
  (2026-09-27, `eleven_multilingual_v2`, tek ses; toplam ~2,0 MB).
- `needsPronunciationReview: true` (Arapça harf/kelime içeren): 52 = 36 açıklama +
  16 başlık. Bunlar varsayılan üretime girmez. Liste: `python
  tool/turkish_audio/generate_turkish_audio.py --dry-run --include-review`.
  İnceleme yolu: `ttsText`'e okunuşu yaz (ör. harf adları), dinle, onaylayınca
  `needsPronunciationReview: false` yap (test, gönderilen metinde Arapça harf
  kaldıkça bunu yasaklar).

## Uygulamada
- Veri: sayfa/bölüm `headingAudio`, `titleAudio`, `introAudio`/`outroAudio`
  (`{başlangıç paragrafı: TrAudio(id, paragraf sayısı)}`), `lib/models/turkish_audio.dart`.
  Ders 23–30 kitap sayfaları: `lesson_info_data.dart` içinde `_tr('s050_01', [...])`
  (`TrAudioSpan`), `BookPageBody` onları blok blok çizer; ⓘ penceresinde düz metin.
- Çizim: `lib/widgets/turkish_audio_block.dart` — küçük turkuaz 🔊 (çalarken dolu) +
  hafif zemin, bütün blok dokunulabilir (en az 40 px). Başlıkta ikon başlık satırının
  önünde.
- Çalma: `AudioService.playAsset('audio/tr/<id>.mp3')` — uygulamanın **tek**
  oynatıcısı; Türkçe sesi başlatmak Arapçayı keser, Arapça hücre Türkçeyi keser.
  Aynı bloğa tekrar dokunmak baştan çalar. Web'de görünen bloğun sesi önceden
  indirilir.
- Eksik ses: `TurkishAudioCatalog` AssetManifest'ten var olan dosyaları okur. Dosyası
  olmayan blokta ikon yok, dokunmak bir şey yapmaz, hata yok; dosya eklenince ikon
  kendiliğinden gelir.
- `pubspec.yaml`: `- assets/audio/tr/` (bir kez). Klasör boş kalamaz (Flutter
  derlemesi hata verir); bütün sesler silinirse geçici bir `.gitkeep` koy (parmak
  izi testi gizli dosyaları saymaz; ama `.gitkeep` web paketine de girer).

## Üretim (ElevenLabs, bir kez)
Uygulama ElevenLabs'e **hiç** bağlanmaz. Akış: manifest → üretici → mp3 →
`assets/audio/tr/` → `AudioService`.

```
python tool/turkish_audio/generate_turkish_audio.py --dry-run
python tool/turkish_audio/generate_turkish_audio.py --id s024_01 --voice <voice_id>
python tool/turkish_audio/generate_turkish_audio.py --all --voice <voice_id>
python tool/turkish_audio/generate_turkish_audio.py --id s024_01 --force
python tool/turkish_audio/generate_turkish_audio.py --id s050_01 --include-review
```
- Ses: `--voice`, yoksa `ELEVENLABS_VOICE_ID`, yoksa `defaults.voiceId`. Model:
  `defaults.model` (`eleven_multilingual_v2`), ayarlar `defaults.voiceSettings`.
- API anahtarı: `ELEVENLABS_API_KEY` ortam değişkeni, Windows kullanıcı değişkeni
  (`[Environment]::SetEnvironmentVariable('ELEVENLABS_API_KEY','…','User')`) ya da
  git dışı `.env`. Anahtar hiçbir çıktıya, manifest'e, koda girmez; test `lib/`,
  `web/` ve manifest'te anahtar/ElevenLabs izi olmadığını denetler.
- Manifest'te her kaydın `status` alanı: `generated` | `pending` | `pendingReview` |
  `failed` (üretici yazar). API hatası yalnız o kaydı `failed` yapar, diğerleri sürer.
  Test: `generated` ⇔ dosya var (boş değil), sahipsiz mp3 yok, uygulama paketi =
  üretilen kayıtlar. Üretici ses kimliğini ekrana yazmaz.
- Aynı metin + aynı ses + aynı model ile üretilmiş kayıt atlanır (`textHash`,
  `voiceId`, `model` manifest'e yazılır); `--force` yeniden üretir. Ses ayarı
  değişirse `--force` gerekir.
- Çıktı ElevenLabs'ten `mp3_44100_128` gelir, ffmpeg ile mono 24 kHz 40 kbps'e
  küçültülür (`defaults.transcode`): toplam ses bütçesi 30 MB (`audio_assets_test`),
  mevcut sesler ~22,8 MB. Kayıt başına < 240 KB.
- Ses ekleyince `flutter test` → yeni `kSoundCacheVersion` değerini söyler.

## Kalite kontrol ekranı (geliştirici aracı)
Üretilmiş seslerin hepsini PDF sırasıyla dinleyip işaretlemek için:
`lib/debug/turkish_audio_qc_screen.dart`. Her satır: PDF sayfası, kimlik, ekrandaki
metin, seslendirilen metin (`ttsText ?? text`), ▶ Dinle, durum (✓ İyi / ↻ Yeniden
üret / ✎ Metin/Telaffuz düzeltilecek; seçili duruma yeniden dokunmak kaldırır).
Filtreler: Tümü / Bakılmadı / İyi / Yeniden üretilecek / Metni düzeltilecek. Seçimler
cihazda (`shared_preferences`, `tr_ses_kontrol.v1`). Sağ üstteki paylaş düğmesi
raporu verir (`ID | PDF sayfası | text | ttsText | durum`, istenirse yalnız
yeniden üretilecek/düzeltilecek olanlar) → Kopyala.
- Açma: ayrı giriş noktası, uygulamanın hiçbir menüsünde (ana sayfa dahil) yok:
  `flutter run -d chrome -t lib/debug/turkish_audio_qc_main.dart`. Yayındaki
  uygulamaya/siteye girmez.
- Veri `lib/debug/turkish_audio_qc_data.dart`, manifest'ten üretilir:
  `python tool/turkish_audio/export_qc_data.py` (ses üretildikten/metin değiştikten
  sonra). `test/turkish_audio_qc_test.dart` manifest'le aynılığını denetler.
