# Kur'an Okuma Rehberi (Flutter)

Çocuklara Elifba, namaz sureleri ve namaz dualarını öğreten, Oyunlar bölümü olan
uygulama. Hedef: Android, iOS, Web, Windows; telefon / tablet / masaüstü responsive.
Kullanıcı Türkçe konuşur; yanıtlar ve arayüz metinleri Türkçe.

## Önce oku
- **Oyunlar bölümü** (sürükle-bırak, dinle ve seç, puanlama, sonuçlar): `docs/OYUNLAR.md`
  — ne yapıldı, kurallar, dosya haritası, yeni oyun ekleme, sırada ne var.
- Dualar kaynağı: `docs/dualar_source.md`.

## Genel kurallar
- Ana ekranlar: `lib/screens/{home,elifba,sureler,dualar,oyunlar}`; veri `lib/data`,
  modeller `lib/models`, servisler `lib/services` (`AudioService` = tek ses player'ı).
- Tema: `lib/theme` (`AppColors`: krem, turkuaz, adaçayı, lacivert, altın; Arapça için
  Hasenat fontu `AppTextTheme`), breakpoint'ler `lib/core/responsive.dart`.
- Sakin eğitim uygulaması: arcade/neon yok, çocuğu cezalandıran geri bildirim yok.
- Eski uygulama `D:\Elifbe2025` **yalnızca okunur referans**; içeriği birebir kopyalama.
- Bu klasör git deposu **değil**.

## Sırada: GitHub'a koy + web sürümünü yayınla (kullanıcı 2026-09-19'da "yarın" dedi)
Henüz yapılmadı; kullanıcı söylemeden başlama, başlarken onay al (repo adı, herkese açık/özel).
Hazırlık notları:
- Klasör git deposu değil → `git init`. `.gitignore` var (`/build/`, `.dart_tool/` dahil).
  Eklenmesi gerekenler: kökteki `Kuran-Okuma-Rehberi-Test.apk` (133 MB — GitHub'ın 100 MB
  dosya sınırını aşar, **commit'leme**), `flutter_01.log`, `.claude/`. `assets/` ~115 MB (çoğu ses).
- GitHub CLI (`gh`) kurulu ve `unalcan123` hesabıyla giriş yapılmış.
- Web: `flutter build web --no-tree-shake-icons` çalışıyor (`build/web`). GitHub Pages için
  `--base-href /<repo-adı>/` ile derle; `web/index.html` zaten `$FLUTTER_BASE_HREF` kullanıyor.
  Yayın: `gh-pages` dalı ya da GitHub Actions (Flutter derle → Pages'e yükle).
- Yayından önce web'de ses (audioplayers) ve `shared_preferences` çalışmasını tarayıcıda dene.

## İş bitince
```
flutter analyze
flutter test
flutter build web --no-tree-shake-icons
```
Arayüz değişikliğini ekran boyutlarında (360×800, 800×1280, 1280×800, 800×360, 1920×1080)
test et; yöntem `docs/OYUNLAR.md` §7. Geçici `test/zz_*` dosyalarını sil.
