# Diller (tr, es, fr, de, en, bs, nl)

Öncelikli diller: Türkçe, İspanyolca, Fransızca, İngilizce ve Hollandaca (nl, 12 Ekim 2026). Ders 1 ve sonrasındaki açıklama çevirileri ve sesleri bu dillerde uygulamaya bağlıdır. Almanca ve Boşnakça sonraki aşama için altyapıda tutulur; dil menüsünde sunulmaz. Oyunların ortak yönergeleri çevrilip seslendirilmiştir, ancak bazı oyun ekranlarının menü ve dinamik geri bildirim çevirileri henüz tamamlanmamıştır.

Arapça harf/kelime/ayet, sure ve dua metinleri ile orijinal tilavet kayıtları her dilde aynıdır.

## Dil tercihi
- `lib/l10n/`: `AppLanguage` (kod + kendi dilindeki ad), `LanguageController`
  (tek tercih; ilk açılışta cihaz dili uygunsa o, yoksa Türkçe; elle seçim
  `SharedPreferences` `app.language`'a yazılır ve sonra hep o kullanılır),
  `AppLanguageScope` (uygulamanın kökünde, `app.dart`).
- Seçim: ana sayfadaki 🌐 dil düğmesi (`LanguagePickerButton`).
- Dil değişince çalan açıklama sesi durur (`app.dart`); Arapça sesler etkilenmez.
- Kapsamı olmayan widget testleri Türkçe çalışır (eski testler değişmeden geçer).

## Metin yazma kuralı (geliştirici)
- Kodda metin **Türkçe** yazılır ve gösterilirken çevrilir:
  `Text(context.t('Sonraki Sayfa'))`, yer tutucu ile
  `context.t('Sayfa {n}', {'n': page})` (`$` ile birleştirme yok).
- Çeviriler `lib/l10n/strings/ui_*.dart`: `'Türkçe': ['es', 'fr', 'de', 'en', 'bs']`.
  **Hollandaca ayrı**: kaynak `tool/i18n/ui_nl.json` (arayüz + oyun yönergeleri) ve
  `tool/i18n/content_nl.json` (ders metinleri), `python tool/i18n/build_nl_strings.py`
  → `lib/l10n/strings/nl_strings.g.dart` (`kNlStrings`); `L10n.table` bunu her satıra
  6. sütun olarak ekler. Yeni Türkçe metin eklerken `ui_nl.json`'a da ekle ve betiği çalıştır
  (`test/l10n_test.dart` eksik nl'yi yakalar). Oyun yönergesinin Hollandacası
  `game_narration_ids.g.dart`'a da girer.
  Veri olarak tutulan Türkçe metin (ör. menü kartı başlığı) gösterilirken
  `context.t(item.title)`; bütün olası değerleri tabloya ekle.
- Çevrilmeyecek bir literal (Arapça, sembol, geliştirici aracı) satırına
  `// l10n-ignore` yaz.
- `test/l10n_test.dart`: tablolar aktif dillerde dolu ve yer tutucuları aynı; kodda
  `t('…')` ile istenen her metin tabloda; ekranda çevrilmeden kalan Türkçe
  literal yok (`Text('…')`, `tooltip:`, `Semantics(label:)` …).

## Üslup
- Çocuklara sakin, sade, sıcak dil; arcade/cezalandırıcı ton yok.
- es: "tú"; fr: "tu", `:` `?` `!` öncesi boşluk (ince bölünmez boşluk  );
  de: "du"; en: sade; bs: Latin, ijekavica, "ti"; nl: "je/jij", başlıklar cümle düzeninde
  (her kelime büyük harfle başlamaz).
- nl kaynağı: kitabın Hollandaca baskısı `assets/lazim/ELIF BA 2015_FS2.pdf` (65 s.; Türkçe
  baskıdan genelde **1 sayfa kaymış**: TR s. 14 = NL s. 15). Terimler oradan alındı (dikke/dunne
  letters, Fatha, Sukun, Shadda, verlengingsletters, tanwien, ta marboeta, bij stoppen / bij
  doorlezen) ama metni kopyalanmadı: yazım hataları ve düşmüş sayılar/harfler var. Türkçe ses
  tarifleri Hollandacaya uyarlandı: U → “oe”, Ü → “uu”, ı → doffe klank. Giriş (mahreç)
  metinleri yalnız nl'de çevrili (diğer dillerde Türkçe kalır); girişe ses yok.
- Tecvid terimleri ve harf adları `tool/i18n/glossary.json`'daki karşılıkla,
  her yerde aynı.

## Ders açıklamaları
Bkz. aşağıdaki "İçerik kataloğu" ve `docs/TURKCE_SES.md` (ses üretimi).

## Güncel seslendirme kapsamı (11 Ekim 2026)

Yeni seslendirmeler Ders 1’den itibaren hazırlanır. Giriş/mahreç bölümüne
ek kayıt üretilmez; mevcut giriş kayıtları korunur. Öncelik Türkçe eksikler,
Fransızca, İspanyolca ve İngilizcedir. Almanca ve Boşnakça sonraki aşamadadır.
Oyun açıklamaları kapsamda kalır. Makine tarafından okunabilir tercih:
`tool/i18n/narration_scope.json`.

## Yerel ses paketinin durumu

12 Ekim 2026: nl 207 ders + 17 oyun kaydı (8 MB; `tool/i18n/audio_nl.json`,
`game_audio_nl.json`, okunacak metin `seslendirme_metinleri_nl.txt`; ses fr/en/es ile aynı
ElevenLabs sesi, `languageCode: nl`, `eleven_flash_v2_5`). Üretim:
`python tool/turkish_audio/generate_turkish_audio.py --manifest tool/i18n/audio_nl.json --all`.

11 Ekim 2026: fr/es/en dil başına 207 ders kaydı ve 17 oyun kaydı; tr 102 mevcut ders kaydı, 130 ek açıklama ve 17 oyun kaydı. Girişe yeni kayıt eklenmedi. Sesler yalnız seçili dil için ihtiyaç oldukça indirilir. Aktif dil başına toplam ortak ve dil sesleri 30 MB sınırını geçmez.

İlgili 101 ders/ses/platform/oyuncu/ana ekran testi ve aktif çeviri tablosu kontrolü geçti. Oyun adları, zorluklar, puan/deneme/çift bilgileri, okuma ayarları, dua/sure kontrolleri ve iletişim formu aktif dillere bağlıdır. Tam l10n kontrolü geçti. Gerçek Safari cihaz ve insan telaffuz kontrolü ayrıca gerekir. Yerel ön izleme build/ses_deneme_web; Yayın GitHub Pages kontrol hattıyla yapılır.
