# Kur'an Okuma Rehberi (Flutter)

Çocuklara Elifba, namaz sureleri ve namaz dualarını öğreten, Oyunlar bölümü olan
uygulama. Hedef: Android, iOS, Web, Windows; telefon / tablet / masaüstü responsive.
Kullanıcı Türkçe konuşur; yanıtlar ve arayüz metinleri Türkçe.

## Önce oku
- **Oyunlar bölümü** (sürükle-bırak, dinle ve seç, puanlama, sonuçlar): `docs/OYUNLAR.md`
  — ne yapıldı, kurallar, dosya haritası, yeni oyun ekleme, sırada ne var.
- **Ses** (kayıt formatı, web'de önbellek/ön yükleme, gecikme ölçümü): `docs/SES.md`.
  Ses dosyası ekleyince/değiştirince `kSoundCacheVersion`'ı güncelle (test söyler); kaynağı küçült.
- Dualar kaynağı: `docs/dualar_source.md`.

## Genel kurallar
- Ana ekranlar: `lib/screens/{home,elifba,sureler,dualar,oyunlar}`; veri `lib/data`,
  modeller `lib/models`, servisler `lib/services` (`AudioService` = tek ses player'ı; ekran açılınca `preload` çağır).
- Tema: `lib/theme` (`AppColors`: krem, turkuaz, adaçayı, lacivert, altın; Arapça için
  Hasenat fontu `AppTextTheme`), breakpoint'ler `lib/core/responsive.dart`.
- Sakin eğitim uygulaması: arcade/neon yok, çocuğu cezalandıran geri bildirim yok.
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

## İş bitince
```
flutter analyze
flutter test
flutter build web --no-tree-shake-icons
```
Arayüz değişikliğini ekran boyutlarında (360×800, 800×1280, 1280×800, 800×360, 1920×1080)
test et; yöntem `docs/OYUNLAR.md` §7. Geçici `test/zz_*` dosyalarını sil.
