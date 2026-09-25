# Kur'an Okuma Rehberi (Flutter)

Çocuklara Elifba, namaz sureleri ve namaz dualarını öğreten, Oyunlar bölümü olan
uygulama. Hedef: Android, iOS, Web, Windows; telefon / tablet / masaüstü responsive.
Kullanıcı Türkçe konuşur; yanıtlar ve arayüz metinleri Türkçe.

## Önce oku
- **Oyunlar bölümü** (sürükle-bırak, dinle ve seç, puanlama, sonuçlar): `docs/OYUNLAR.md`
  — ne yapıldı, kurallar, dosya haritası, yeni oyun ekleme, sırada ne var.
- **Ses** (kayıt formatı, web'de önbellek/ön yükleme, gecikme ölçümü): `docs/SES.md`.
  Ses dosyası ekleyince/değiştirince `kSoundCacheVersion`'ı güncelle (test söyler); kaynağı küçült.
- **Web/telefon görünümü** (tarayıcı sayfayı geniş yerleştirince her şey küçülüyordu; `PhoneZoomFix`): `docs/WEB.md`.
- **Çevrimiçi sıralama** (Firebase: anonim giriş + Firestore, Bul & Patlat / Harf Arabaları,
  kurallar, sahte skor sınırları, yeni oyun bağlama): `docs/FIREBASE.md`. Kural değişince
  `firebase deploy --only firestore` ve `tool/firestore_rules_test` (npm test).
- Dualar kaynağı: `docs/dualar_source.md`.

## Genel kurallar
- Ana ekranlar: `lib/screens/{home,elifba,sureler,dualar,oyunlar}`; veri `lib/data`,
  modeller `lib/models`, servisler `lib/services` (`AudioService` = tek ses player'ı; ekran açılınca `preload` çağır).
- Tema: `lib/theme` (`AppColors`: krem, turkuaz, adaçayı, lacivert, altın; Arapça için
  Hasenat fontu `AppTextTheme`), breakpoint'ler `lib/core/responsive.dart`.
- Sakin eğitim uygulaması: arcade/neon yok, çocuğu cezalandıran geri bildirim yok.
- Sağ üstteki yazı boyutu ayarı büyüdükçe harf/sure/dua ızgaralarında sütunlar **birer birer** azalır (kartın asgari genişliği yazı boyutuyla çarpılır; tek sütuna atlamaz). Test: `test/reading_columns_test.dart`.
- Elifba harf kartı: dokununca ses, **basılı tutunca** Tek Harf sayfası (çift dokunma yok; onDoubleTap tek dokunuşu geciktirir). Test: `test/letter_card_gesture_test.dart`.
- **Ders 23-33 kitap sayfası gibi açılır** (`BookPage`, `lib/screens/elifba/widgets/book_page.dart`; başlıklar `kBookPageHeadings`): kitaptaki açıklama metni + örnek tabloları, kelimeye dokununca ses. Metin `lib/data/lesson_info_data.dart` (ⓘ penceresi aynı içeriği gösterir); "Durulduğunda / Geçildiğinde" tabloları `WaqfExamplesTable` (Ders 32-33), kelime ızgaraları `WordGridTable` (Ders 23-31, kırmızı işaret kuralları `lib/models/word_highlight.dart`). Örnekler dersin **kendi kelime listesinden** gelir (Arapça tek yerde). Kaynak: `assets/lazim/ELIF BA BASKI DENEME 2012.pdf` s. 50-59 (PDF git'e girmez; sayfaları görmek için PyMuPDF ile PNG'ye çevir; Arapça harekeleri gözle doğrula). Sırada: Ders 1-22'nin kitap sayfaları ve kelime kontrolü (s. 2-49). Testler: `test/book_pages_test.dart`, `test/kelime_sonu_duraklar_test.dart`.
- Tuzak: `Table`'da tüm hücreler `TableCellVerticalAlignment.fill` ise satır yüksekliği 0 olur ve tablo kaybolur (testte "var" görünür) — widget testleri **boyutu** da denesin. Kaynak metinde harekelerin sırası (şedde/üstün) farklı yazılabilir; aynı kelimeyi iki yerde yazma.
- Eski uygulama `D:\Elifbe2025` **yalnızca okunur referans**; içeriği birebir kopyalama.

## Yayın (GitHub + web) — yapıldı, 2026-09-19
- Depo (herkese açık): https://github.com/unalcan123/kuran-okuma-rehberi (dal: `main`).
  Artık git deposu; değişiklikleri commit'le. Commit mesajı sonuna
  `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` ekle.
- Site: https://unalcan123.github.io/kuran-okuma-rehberi/ — `main`'e her push'ta
  `.github/workflows/deploy-web.yml` çalışır: `flutter analyze` → `flutter test` →
  `flutter build web` → GitHub Pages (~3 dk). Test/analiz kırılırsa **yayınlanmaz**.
  İlerleme: `gh run list`, `gh run watch <id>`.
- Web derlemesini yerelde dene: **PowerShell'de** `flutter build web --release --base-href /kuran-okuma-rehberi/`
  (Git Bash `/` ile başlayan yolu bozar).
- **Alan adı alınınca:** DNS'i Pages'e yönlendir, GitHub > Settings > Pages > Custom domain gir;
  ardından Settings > Secrets and variables > Actions > **Variables**'a `WEB_BASE_HREF` = `/` ekle
  (aksi halde site alt yol için derlenir), workflow'u yeniden çalıştır.
- Commit'lenmemesi gerekenler `.gitignore`'da: `*.apk` (kökteki test APK'sı 133 MB), `.claude/`,
  `build/`, `local.properties`. Anahtar/keystore dosyası ekleme (depo herkese açık).
- Depo herkese açık olduğu için ses kayıtları, Hasenat yazı tipi (`assets/fonts`, lisans bilgisi
  dosyada yok) ve görseller de görünür; hak/lisans durumu kullanıcının sorumluluğunda.
- Noto Naskh/Sans Arabic (Harf Treni) SIL OFL: `assets/fonts/OFL-NotoArabic.txt`. Kitabın font
  paketindeki ticari/"tüm hakları saklı" fontları depoya ekleme (ayrıntı `docs/OYUNLAR.md` Harf Treni).

## İş bitince
```
flutter analyze
flutter test
flutter build web --no-tree-shake-icons
```
Arayüz değişikliğini ekran boyutlarında (360×800, 800×1280, 1280×800, 800×360, 1920×1080)
test et; yöntem `docs/OYUNLAR.md` §7. Geçici `test/zz_*` dosyalarını sil.
