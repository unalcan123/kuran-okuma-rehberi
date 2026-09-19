# Oyunlar bölümü — yapılanlar ve nasıl çalıştığı

Son güncelleme: 2026-09-19. Bu belge, oyunlar üzerinde yapılan işin hafızasıdır:
yeni bir konuşmada (ya da yarın) buradan devam edilir. Ana sayfadaki **Oyunlar**
kartı `OyunlarScreen`'i açar.

Kodun büyük kısmı `lib/screens/oyunlar/` altında. Çalıştırma ve doğrulama komutları
en altta.

## 1. Şu an var olanlar

| Oyun | Ne yapar | Nerede |
|---|---|---|
| **Sürükle & Bırak** | Küçük oyunlar listesi: Oyun 1–7 (eski uygulamanın 7 harf grubu) ve **Karışık** (her oynayışta 29 harften rastgele 5 harf). Ses kartına dokun, dinle, doğru harfi karta sürükle. | `drag_drop/` |
| **Dinle ve Seç** | Önce ders seçilir (37 ders). 5 soru: ses otomatik çalar, 4 şıktan doğrusu seçilir. | `listen_pick/` |
| **Sonuçlarım** | Oynanan her oyunun kaç kez oynandığı, ortalaması, en iyisi, son 5 puanı. Üst çubukta "Sonuçları sıfırla" (onaylı). | `results/` |

### Sürükle & Bırak
- Bir küçük oyun tek turdur. Son harf yerleşince ~0,8 sn sonra sonuç sayfası açılır
  (çocuk son harfin oturduğunu görsün diye). Sonuç sayfası kendiliğinden kapanmaz.
- Doğru yer: harf karta oturur, 3 küçük müzik notası yükselip kaybolur, önce
  `dogru.wav` sonra harfin kendi sesi çalar (tek player, üst üste binmez).
- Yanlış yer: kart hafifçe sallanır, harf başlangıç yerine süzülerek döner. Kırmızı,
  ceza, ses yok. Boş yere ya da dolu karta bırakma da sadece geri döner.
- Harfin dokunma alanı = tüm hücre (çizilen daire hücrenin %84'ü); sürüklenen harf
  hedefi tamamen örtmesin diye.
- Yerleşim `FitGrid` ile: parçalar mevcut alana sığacak en büyük boyutta, kaydırma yok.
  Telefon dikeyde ekran altta harfler / üstte kartlar; yatayda yan yana.
- Seviyeler `lib/data/drag_drop_game_data.dart` → `kDragDropLevels`. Anahtar:
  `drag_drop.1` … `drag_drop.7`, `drag_drop.random`.

### Dinle ve Seç
- Sorular `kElifbaLessons` derslerinden üretilir (`listen_pick_questions.dart`). Eski
  uygulamanın JSON/ses dosyaları **taşınmadı**; yeni projedeki ders sesleri aynı kayıt.
- Soru içinde tekrar yok; şıklar aynı derse aittir; aynı yazılışlı iki şık çıkmaz.
- Yanlış seçim: kart soluklaşır ve devre dışı kalır, çocuk tekrar dener (ceza yok).
- Doğru seçim: kart yeşile döner, notalar çıkar, yalnızca `dogru.wav` çalar, **2 sn sonra
  kendiliğinden sonraki soruya geçilir** ("Sonraki" butonu yok). **Son soruda hemen**
  sonuç sayfası açılır; çocuk "Tekrar Oyna" / "Derslere Dön" ile kendisi seçer.
- **Ders 2 (Harflerin Yazılışları)** özel: harflerin *başta / ortada / sonda* yazılışı
  sorulur. Şıklar sorulan konumdaki biçimleri gösterir; konum hem yönergede hem
  Dinle butonunun altındaki etikette yazar ("Başta" vb.). 5 soruda üç konum da çıkar.
  Tek başına (boşta) biçim **kasıtlı eklenmedi** (Ders 1'e benzer); istenirse
  `LetterPosition` enum'una eklenir.
- Şık yerleşimi (`options_grid.dart`): en uzun şıkkın en büyük yazılabildiği düzen
  seçilir (2×2, tek sütun ya da tek satır). Uzun kelime/cümleler alt alta geniş kart olur.
- Anahtar: her ders ayrı oyundur → `listen_pick.<lessonId>`.

## 2. Puanlama (tüm oyunlar için ortak)

Kod: `lib/models/game_score.dart` (`GameScorer`), depolama:
`lib/services/game_score_store.dart` (`shared_preferences`).

- Doğru cevap **+10**; ilk denemede doğruysa **+5** ek; üst üste her **3.** ilk-deneme
  doğruda **+5** ek (seri turlar/sorular arasında sürer).
- Yanlış cevap: **puan düşmez**, puan asla negatif olmaz. Sadece o öğe "ilk deneme"
  sayılmaz ve seri sıfırlanır. Zamanlayıcı / hız bonusu **yok** (bilerek).
- Yıldız (1–3): oyunu bitirmek = en az 1. İlk denemede doğru oranı ≥ %50 → 2,
  ≥ %80 → 3. Ham puana bakılmaz.
- Örnek toplamlar: 4 harflik oyun hepsi ilk denemede = 65; 5 soru/harf = 80;
  29 öğe olsaydı 480.
- Ekranda: üstte `Puan N` + ilerleme (`GameStepPill`); cevaptan sonra kısa süre `+15`,
  seride ayrıca "Güzel gidiyorsun! +5". Şerit **sabit yükseklikte** (oyun alanı
  kaymasın diye). Bitişte puan, "x / y İlk Denemede Doğru", yıldızlar, "En İyi" veya
  "Yeni rekor!".
- **Her ayrı oyunun kendi kaydı vardır**: aynı oyunun son 5 puanı ve ortalaması, başka
  oyunla karışmaz (kullanıcı özellikle istedi).
- Kayıt anahtarları (prefs): `game_score.<oyunAnahtarı>.best_score|best_stars`,
  `game_history.<oyunAnahtarı>.plays|total|top|recent` (recent = son 5, eskiden yeniye).
  Yalnızca **bitirilen** oyunlar sayılır. `clearAll()` yalnızca bu iki öneki siler.
- Puanlar cihaz bazlıdır; çocuk profili **yok**.

### Eski uygulamada puanlama nasıldı (okunup bilerek değiştirildi)
- Sürükle-bırak: +10 / −5 (negatife inebiliyordu). Dinle-seç: +20 × 5 soru, yanlışta
  düşme yok. Hafıza: +10 / −2 (0'ın altına inmez). Süre, yıldız, seri, rekor yoktu;
  tek kalıcı şey oyun/ders adına göre puan ortalamasıydı (`ScoreProvider`).
- Eski sonuç sayfası ortalamayı yüzdeyle ve "Çok düşük, daha fazla çalışmalısın!" gibi
  cesaret kırıcı mesajlarla gösteriyordu → **taşınmadı**.

## 3. Dosya haritası (`lib/screens/oyunlar/`)

```
oyunlar_screen.dart        Menü: kGames kartları + "Sonuçlarım"
games.dart                 kGames: GameEntry + GameVariant (menü VE sonuçlar buradan beslenir)
drag_drop/                 drag_drop_levels_screen (seçim), drag_drop_game_screen,
                           widgets: draggable_letter, sound_slot, fit_grid, fly_back
listen_pick/               listen_pick_lessons_screen (ders seçimi), listen_pick_screen,
                           listen_pick_questions (soru üretimi, LetterPosition),
                           widgets: option_card, options_grid, play_sound_button
results/game_results_screen.dart
widgets/                   Ortak parçalar: game_score_strip, game_result_summary,
                           game_finish_view, game_progress (GameStepPill, GameProgressBar),
                           music_note_burst, shake_on_trigger, game_colors
```
Diğer: `lib/models/game_score.dart`, `lib/services/game_score_store.dart`
(`main.dart`'ta `Provider<GameScoreStore>`), `lib/data/drag_drop_game_data.dart`,
ses: `assets/audio/oyunlar/dogru.wav` (eski `assets_audio_win.wav`'ın sondaki sessizliği
kırpılmış hali; pubspec'te `assets/audio/oyunlar/`).

Yeniden kullanılan mevcut parçalar: `AudioService` (tek player; `playLetter`,
`playPlaylist`), `kArabicLetters` / `kLetterFormLetters` / `kElifbaLessons`,
`LessonCard`, `HomeMenuCard`, `AppColors`, `Responsive`, Hasenat fontu.

## 4. Yeni oyun eklemek (kontrol listesi)
1. Ekranı `lib/screens/oyunlar/<oyun>/` altına yaz; puan için `GameScorer(total: …)`
   (`recordCorrect(firstTry: …)` / `recordMiss()`), üstte `GameScoreStrip`, bitişte
   `GameFinishView(summary: GameResultSummary(...))`.
2. Bitişte `GameScoreStore.submit('<oyunAnahtarı>', result)`.
3. `games.dart` → `kGames`'e `GameEntry` ekle (`variants`: sonuçlarda ayrı ayrı görünecek
   oyunlar). Menü ve Sonuçlarım otomatik güncellenir.
4. Ses çalarken tek `AudioService` kullan (üst üste binmesin); `dispose`'da
   `Future.microtask(_audio.stop)`.
5. Test yaz (aşağıda), 5 ekran boyutunda taşma olmadığını doğrula.

## 5. Kullanıcının koyduğu tasarım kuralları (bozma)
- Hayvan resmi **yok** (eski oyunlarda vardı, kopyalanmadı); tema müzik notası, Material
  ikonlarıyla (`music_note_rounded`, `audiotrack_rounded`); resim asset'i eklenmez.
- Sakin, eğitim odaklı: krem / turkuaz / adaçayı / lacivert / altın. Arcade, neon,
  "COMBO!" yok. Yanlış cevap ceza gibi hissettirmez (kırmızı, alarm, puan kaybı yok).
- 6–15 yaş; çok bebeksi değil. Dokunma alanları büyük; oyun alanında dikey kaydırma yok;
  tablet ekranı gerçekten kullanır (telefon UI'ı ortada küçük kalmaz); masaüstünde
  max genişlik.
- Akışı kesen diyalog yok (tek istisna: sonuçları sıfırlama onayı).
- Eski oyunları **birebir kopyalama**; mantığı incele, modern/responsive yeniden yaz.

## 6. Yapılmadı / sırada
- **Eski `ikinci_oyun`** (kart eşleştirme, şekil resimleriyle) ve **`ucuncu_oyun`**
  (hafıza oyunu, easy/medium/hard): henüz **dokunulmadı**. Kullanıcı onayı olmadan
  aktarma. Eski kod: `D:\Elifbe2025\lib\oyunlar\`, sesler `D:\Elifbe2025\assets\audio`
  (hayvan/şekil resimleri `assets/resim` — kopyalama).
- Çocuk profili (birden fazla öğrenci) yok.
- Oyunlar menüsü kartlarında en iyi yıldız/puan gösterilmiyor (sadece sürükle-bırak
  seçim listesinde yıldız var).
- Ders 2'ye tek başına (boşta) biçim eklemek istenirse: `LetterPosition`'a ekle.

## 7. Doğrulama
```
flutter analyze
flutter test                      # ~92 test
flutter build web --no-tree-shake-icons
```
Testler: `test/drag_drop_game_test.dart`, `listen_pick_game_test.dart`,
`game_score_test.dart`, `game_results_test.dart` (sürükle-bırak gerçek `TestGesture` ile
yapılır; 7 ekran boyutunda sığma denenir).

Görsel kontrol yöntemi (gerçek cihaz yokken): geçici bir widget testi yazıp
`RepaintBoundary.toImage` ile PNG'ye çevirmek, fontları elle yüklemek
(`FontLoader`: Hasenat, `roboto-regular.ttf`, `materialicons-regular.otf` — Flutter
cache'inde `D:\src\flutter\bin\cache\artifacts\material_fonts\`), sonra PNG'yi okumak.
Geçici dosyayı işi bitirince sil (`test/zz_*`).

### Öğrenilen tuzaklar
- `setState(() => _x = asyncFn())` Future döndürür ve hata verir → blok gövde kullan.
- Bir widget'ın ilk render nesnesi `Transform` ise `tester.tap(finder)` sahte "hit
  test" uyarısı verir → asıl `InkWell` descendant'ına dokun.
- Animasyon testinde `tap` sonrası önce `pump()`, sonra süre ver (animasyon ilk
  karede başlar).
- Testte tanımsız font `Ahem` (kare) olur; uzun metinler gerçekte sığsa da testte
  taşabilir → uzun metinleri `FittedBox`/`Flexible` ile taşmaya dayanıklı yaz.
- Bildirim çıkıp kaybolurken yükseklik değişirse oyun alanı kayar → `GameScoreStrip`
  sabit yükseklik.
- Bu klasör **git deposu değil** (sürüm geçmişi yok); önemli işlerden önce yedek al.
