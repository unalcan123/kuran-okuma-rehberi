# Ayet ayet sesler — iş sonu raporu

29 Ekim 2026 · Yerel uygulama: `D:\Kuran Okuma Rehberi` · Canlı siteye gönderilmedi.

## Sonuç

Asr Suresi'ndeki sistem diğer surelere uygulandı: her ayet ayrı kart, kartın her yerine dokununca
yalnız o ayet çalar, okunan kart yeşil ışıkla çevrilir, ses bitince vurgu kalkar, başka karta basınca
önceki ses durur, aynı karta basınca baştan çalar. Kart sistemi ortak olduğu için bu davranış ses
kaydı olan bütün sure ve dualarda geçerlidir (ilk 11 sure ve 9 dua öğretmenin mevcut kayıtlarıyla).

## Tamamlananlar

| Öğe | Ayet | Ses dosyası | Kaynak |
|---|---|---|---|
| Âyetel Kürsî | 1 (255) + besmele | 2 | `4/1-AYETUL KURSI.mp3` (sondaki tam okuma) |
| Duhâ | 11 + besmele | 12 | `tekrarli/duha.mp3` |
| İnşirâh | 8 + besmele | 9 | `tekrarli/insirah.mp3` |
| Tîn | 8 + besmele | 9 | `tekrarli/tin.mp3` |
| Zilzâl | 8 + besmele | 9 | `tekrarli/zilzal.mp3` |
| Âdiyât | 11 + besmele | 12 | `tekrarli/22.Adiyat Suresi.mp3` |
| Kâria | 11 + besmele | 12 | `tekrarli/garia.mp3` |
| Tekâsür | 8 + besmele | 9 | `tekrarli/tekasur.mp3` |
| Asr (önceden) | 3 + besmele | 4 | `tekrarli/asr.mp3` |
| Hümeze | 9 + besmele | 10 | `tekrarli/humeze.mp3` |

**Toplam 88 ses dosyası** (bu turda yeni 84; Asr'ın 4 dosyası onaylandığı gibi kaldı).
Bu öğelerin içinde zil sesi bulunan eski uzun kayıtları (9 dosya, ~28 MB) kaldırıldı; Dinle artık
ayet ayet çalar ve okunan kartı vurgular, Ezberle (tekrar sayısı ayarıyla) açıldı.

## Ses doğruluğu nasıl sağlandı

- Ayet numarası zil sayısından verilmedi: her tekrar Kur'an tilavetiyle eğitilmiş bir tanıma
  modeliyle okunup uygulamadaki Diyanet metnine benzetildi; tekrarlar sırayla gruplandı.
- Besmele, birinci ayetin ilk okunuşundan duraklamadan ayrıldı; besmeleli parça hiçbir ayete
  bağlanmadı (süresi grubundan %35 sapan tekrar kullanılmaz).
- Her ayetin üç tekrarından en temizi seçildi (en az kırpma, en geniş sessizlik payı).
- **Bağımsız doğrulama** (kurulan her dosya yeniden çözüldü): 88/88 dosya kendi ayetiyle
  eşleşti, hiçbirinde zil yok, hiçbirinin başı/sonu kesik değil (`tmp/ezber_split/dogrulama.md`).
- Çalışma sırasında bulunup düzeltilen hata: analizde zaman ölçeği %0,23 kayıyordu; uzun
  kayıtların sonlarına doğru ayet başları ~0,3–1 sn kesiliyordu (ör. Kâria 9–10). Düzeltmeden sonra
  her şey yeniden üretildi ve doğrulandı.

## Eksik veya şüpheli

| Öğe | Durum | Neden |
|---|---|---|
| Kadir | Kurulmadı (eski uzun kayıt kalır) | Kayıtta "selâm" 4. ayetin sonunda okunuyor, 5. ayet "hiye" ile başlıyor; 5. ayet kartında yazılanla duyulan uyuşmaz. Ya ayrı kayıt ya da tam okumadan elle kesim gerekir. |
| Nebe 31–40 | Ses yok | Kaynak klasörde kayıt yok. |
| Namaz Tesbihleri, Namaz Tesbihatı, Salâten Tüncînâ | Ses yok | Kaynak klasörde kayıt yok. |
| Ezan Duası | Kurulmadı (eski uzun kayıt kalır) | Kayıttaki tam okuma uygulamadaki metinle güvenilir biçimde örtüşmüyor (benzerlik 0,65). |
| Yemek Duası | Kurulmadı (eski uzun kayıt kalır) | Kayıtta metnin yalnız "elhamdülillâhillezî et'amenâ…" kısmı var; uygulamadaki metin çok daha uzun. |
| Kâria 9–10 | Kuruldu, dinleyerek kontrol önerilir | Tanıma ilk sesleri farklı duymuştu; zaman düzeltmesinden sonra tam kapsanıyor. |
| Zilzâl 2. ayet | Kuruldu | Kayıtta 5 kez okunmuş; en temizi seçildi. |
| Âyetel Kürsî | Kuruldu | Tek ayet, kayıtta çok yavaş okunuyor: kart sesi 139 sn. |

Kalan üç uzun kayıtta (Kadir, Ezan Duası, Yemek Duası) önceki gibi zil sesleri vardır.

## Değiştirilen dosyalar

- Ses: `assets/audio/sureler/{12_ayetel-kursi,14_duha,15_insirah,16_tin,18_zilzal,19_adiyat,20_karia,21_tekasur,23_humeze}/`
  (yeni); `assets/audio/full_readings/` altından 9 dosya silindi.
- Veri: `lib/data/supplementary_sureler_data.dart`, `lib/data/ayetel_kursi_data.dart`,
  `lib/data/full_reading_audio.dart`, `pubspec.yaml`, `lib/services/sound_cache.dart` (önbellek sürümü).
- Araçlar: `tool/ezber_split/split_ezber.py`, `install_clips.py` (yeni), `verify_clips.py` (yeni);
  `tool/original_audio_fingerprints.json`, `tool/sources/audio_import_manifest.json`.
- Testler: `test/verse_audio_all_test.dart` (yeni), `test/audio_assets_test.dart`,
  `test/expanded_readings_test.dart`.
- Belgeler: `docs/SES.md`, `CLAUDE.md`, bu rapor.

Tasarım, arka planlar, meal göster/gizle, okuma hızı, tekrar sayısı ayarları değişmedi.

## Test sonuçları

- `flutter analyze`: sorun yok.
- `flutter test`: **809 testin hepsi geçti**. Yeni test, sesli her surede bütün ayetlerin kendi
  dosyasına bağlı olduğunu, besmelenin 1. ayete atanmadığını ve karta dokununca o ayetin sesinin
  çaldığını denetler.
- Web release derlemesi başarılı; Duhâ ekranı Chrome'da açıldı (ses simgeleri, Dinle, Ezberle 3x).
- Gerçek telefonda ve hoparlörden insan kulağıyla dinleme yapılmadı; dinleyerek kontrol önerilir.
