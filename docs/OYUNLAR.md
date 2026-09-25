# Oyunlar bölümü — yapılanlar ve nasıl çalıştığı

Son güncelleme: 2026-09-25. Bu belge, oyunlar üzerinde yapılan işin hafızasıdır:
yeni bir konuşmada (ya da yarın) buradan devam edilir. Ana sayfadaki **Oyunlar**
kartı `OyunlarScreen`'i açar.

Kodun büyük kısmı `lib/screens/oyunlar/` altında. Çalıştırma ve doğrulama komutları
en altta.

## 1. Şu an var olanlar

| Oyun | Ne yapar | Nerede |
|---|---|---|
| **Sürükle & Bırak** | Küçük oyunlar listesi: Oyun 1–7 (eski uygulamanın 7 harf grubu) ve **Karışık** (her oynayışta 29 harften rastgele 5 harf). Ses kartına dokun, dinle, doğru harfi karta sürükle. | `drag_drop/` |
| **Dinle ve Seç** | Önce ders seçilir (37 ders). 5 soru: ses otomatik çalar, 4 şıktan doğrusu seçilir. | `listen_pick/` |
| **Hafıza** | Aynı harfli kartları bul (eski Elifba'nın 3. oyunu). Kolay / Zor / Çok Zor, 9 seviye. Kartlar çevrilince harfin sesi çalar. | `memory/` |
| **Bul & Patlat / Harf Arabaları** | Sesi dinle, doğru harfli balonu/arabayı bul (120 sn). İkisinde de 3 seviye (1 Yavaş, 2 Biraz Hızlı, 3 Hızlı; cihazda hatırlanır). Harf Arabaları'nda seviye 2 ilk sürümün hızıdır ve "Sonuçlarım" anahtarı eskisi gibi `harf_arabalari`; diğerleri `.l1` / `.l3`. Oyun sonunda çevrimiçi sıralama (`docs/FIREBASE.md`). | `harf_oyunlari/` |
| **Harf Dedektifi** | 3 mod: Şekilleri Tanı, Benzer Harfler, Kelime Dedektifi. 5 kısa tur, süre yok; bir turda birden çok doğru örnek bulunur. | `harf_dedektifi/` |
| **Sonuçlarım** | Oynanan her oyunun kaç kez oynandığı, ortalaması, en iyisi, son 5 puanı. Üst çubukta "Sonuçları sıfırla" (onaylı). | `results/` |

### Sürükle & Bırak
- Bir küçük oyun tek turdur. Son harf yerleşince ~0,8 sn sonra sonuç sayfası açılır
  (çocuk son harfin oturduğunu görsün diye). Sonuç sayfası kendiliğinden kapanmaz.
- Doğru yer: harf karta oturur, 3 küçük müzik notası yükselip kaybolur, önce
  `dogru.mp3` sonra harfin kendi sesi çalar (tek player, üst üste binmez).
- Yanlış yer: kart hafifçe sallanır, harf başlangıç yerine süzülerek döner. Kırmızı,
  ceza, ses yok. Boş yere ya da dolu karta bırakma da sadece geri döner.
- Harfin dokunma alanı = tüm hücre (çizilen daire hücrenin %84'ü); sürüklenen harf
  hedefi tamamen örtmesin diye.
- Yerleşim `FitGrid` ile: parçalar mevcut alana sığacak en büyük boyutta, kaydırma yok.
  Telefon dikeyde ekran altta harfler / üstte kartlar; yatayda yan yana.
- Seviyeler `lib/data/drag_drop_game_data.dart` → `kDragDropLevels`. Anahtar:
  `drag_drop.1` … `drag_drop.7`, `drag_drop.random`.

### Hafıza
- Seviyeler `lib/data/memory_game_data.dart` → `kMemoryLevels` (eski oyunun harf grupları aynen):
  **Kolay** 1–3 (4, 4, 5 çift), **Zor** 1–4 (6, 7, 7, 7 çift; benzer harfler ض ط ظ ع غ …),
  **Çok Zor** 1–2 (10 çift). Eski oyunda "Orta 1" ve "Orta 2" aynı harflerdi; tek seviyeye indirildi.
  Kullanıcının tanımı: "kolay, zor, çok zor" — bu adlar kullanıldı. Anahtar: `memory.easy1`…
  `memory.hardN`, `memory.veryHardN`.
- Akış: önce tüm kartlar **açık** gösterilir (2 + çift sayısı saniye; "Hazırım" ile erken başlanır,
  bu sırada dokununca harfin sesi çalar), sonra kartlar kapanır. Ekranda geri sayım yok.
- Kart çevrilince o **harfin sesi** çalar (öğretici kısım; eskisinde hiç ses yoktu). Çift bulununca
  `dogru.mp3` + harfin sesi, kartlar yeşile döner ve **Türkçe adını** yazar ("Elif", "Be" …).
  Yanlış tahminde ikinci kartın sesi çalar (hangi harf olduğunu duyar), kartlar hafifçe sallanır,
  ~1,1 sn sonra kapanır; bu sırada başka karta dokunulursa hemen kapanır (bekletmez).
- Puan `GameScorer`, öğe = çift. Bir çift, yanlış bir tahminde yer almadan bulunursa "ilk deneme"
  sayılır; yanlış tahmin puan düşürmez, sadece seriyi bozar ve o iki harfin ilk-deneme bonusunu alır.
  Çok Zor'da 3 yıldız bilerek zor. Ekranda "Deneme: n" sayacı var.
- Son çift bulununca 0,8 sn sonra sonuç sayfası; kendiliğinden yeniden başlamaz (eskisi 4 sn'de
  başlatıyordu). "Tekrar Oyna" kartları yeniden karıştırır ve ön izlemeyi baştan gösterir.
- Kartlar harf **resmi değil**, Hasenat metni; sırt yüzü müzik notası. `FitGrid` (ortak,
  `widgets/fit_grid.dart`) kartları alana sığdırır, ön izleme bitince boyut değişmez.

### Dinle ve Seç
- Sorular `kElifbaLessons` derslerinden üretilir (`listen_pick_questions.dart`). Eski
  uygulamanın JSON/ses dosyaları **taşınmadı**; yeni projedeki ders sesleri aynı kayıt.
- Soru içinde tekrar yok; şıklar aynı derse aittir; aynı yazılışlı iki şık çıkmaz.
- Yanlış seçim: kart soluklaşır ve devre dışı kalır, çocuk tekrar dener (ceza yok).
- Doğru seçim: kart yeşile döner, notalar çıkar, yalnızca `dogru.mp3` çalar, **2 sn sonra
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

### Harf Dedektifi (2026-09-25)
Başlangıç ekranında mod + harf grubu seçilir ("Tüm harfler" ya da Sürükle & Bırak'ın 7 grubu;
lam-elif alınmaz). Oturum **5 kısa tur**, süre yok. Her turda hedef harf büyük gösterilir
("ب harfini bul!" + doğrulanmış Türkçe ad), hoparlör düğmesi harfin **kendi** kaydını
(Ders 1) çalar, "Bulunan: 2 / 4" sayacı var. Tur bitince yıldızlı kısa kutlama + "Sonraki".
- **Şekilleri Tanı**: hedefin bağlantı biçimleri (tek başına / başta / ortada / sonda) kartlarda.
  Harf oturumda ilk kez gelince önce biçimler **adlarıyla** tanıtılır ("Aramaya Başla"),
  aramada kartlarda ad yok. Kart sayısı 6, 6, 8, 8, 9; ilk iki turda çeldiriciler gözle kolay
  ayrılan harflerden (`looksAlike` aileleri), sonra en çok 2 benzer harf.
- **Benzer Harfler**: gruplar ب ت ث, ج ح خ, د ذ, ر ز, س ش, ص ض, ط ظ, ع غ; gruptaki bütün harfler
  **aynı biçimlerde** yan yana (yalnızca noktalar farklı). Yanlışta seçilene göre ipucu
  ("Zı harfinin üstünde 1 nokta var. Tı harfinin hiç noktası yok.") + hedef ve seçilen yan yana
  büyütülmüş. Genel "noktalarına dikkat" cümlesi yok.
- **Kelime Dedektifi**: 2–3 gerçek kelime; çocuk kelimenin içindeki harfe dokunur. Aynı
  kelimede birden çok geçiş ayrı sayılır (ör. باب'da ب ×2).
- Puan: bulunan her **yeni** örnek **+10** (GameScorer kullanılmaz; ilk deneme/seri bonusu,
  hız bonusu yok). Aynı doğruya tekrar basmak puan vermez; yanlış turu bitirmez, puan silmez.
  Aynı yanlışa tekrar basmak istatistiğe sayılmaz. İki **farklı** yanlıştan sonra "İpucu"
  belirginleşir (öncesinde soluk durur); ipucu bulunmamış bir örneği büyüteçle/altın çerçeveyle gösterir.
- Değerlendirme: her bulunan örnek *ilk deneme* / *tekrar deneyerek* / *ipucuyla* sayılır.
  Sonuç: puan, yıldız (ilk deneme oranı), bulunan örnek, en çok 3 "Tekrar çalışalım" harf/biçim;
  düğmeler **Tekrar Oyna**, **Zorlandıklarımı Çalış** (turların ≥3'ü o harfler), **Oyunlara Dön**.
- Kalıcı zorluk: `harf_dedektifi.v1.<oyuncuId|cihaz>` → mod başına harf ağırlığı 0–5
  (zorlanılan tur +1, rahat tur −1). Hedef seçimi ağırlık `1 + min(ağırlık, 3)`; diğer harfler
  gelmeye devam eder. Bozuk kayıt → boş başlar. Ses tercihi `harf_dedektifi.ses_kapali`
  (üst çubukta hoparlör). `MediaQuery.disableAnimations` açıksa sallanma/yıldız animasyonu yok.
- Sonuçlarım anahtarları: `harf_dedektifi.sekiller|benzer|kelime` (mod başına ayrı). Oturum
  bir kez kaydedilir. **Çevrimiçi sıralamaya bağlanmadı**: turdaki örnek sayısı değişken (2–4),
  eşit soru sayılı oturumlar olmadığından karşılaştırma adil olmaz; ayrıca kural değişikliği
  `firebase deploy` ister. Gerekirse sabit örnek sayılı bir mod tasarlanıp `docs/FIREBASE.md`
  adımlarıyla eklenir.

**Arapça yazım kuralları (bozma):**
- Eşleştirme metinle değil **harf kimliğiyle** (`kArabicLetters` sırası 1–28). He verisi 'هـ'
  yazılır; kimlik temel 'ه'. Sunum biçimleri (U+FB50…) kullanılmaz.
- ا د ذ ر ز و sonraki harfe bağlanmaz → yalnızca iki görünüm (tek başına/başta, öncekine bağlı);
  yapay 4 biçim yok. Kaşide (ـ) yalnızca tek harf kartlarında bağlantıyı göstermek için; kelimelere
  asla eklenmez, harf sayılmaz. Bağlanan harflerin biçimleri Ders 2 verisiyle aynı (test).
- Hemzeli elif (أ إ), medli elif (آ), vasl (ٱ), hemze (ء ؤ ئ), elif maksura (ى), yuvarlak te (ة)
  **hiçbir harfe indirgenmez** (`letterIdOfChar` → null); içeren kelime havuza girmez. Lam-elif (لا)
  içeren kelime de girmez (tek glif, içindeki iki harfe ayrı dokunulamaz).
- Kelime havuzu yalnızca projedeki **Ders 2 örnek kelimeleri** (`positionExamples`, 67 kelime);
  yeni kelime uydurulmaz. Dışarıda kalanlar: أب، مرآة، مزرعة، حائط، لاعب، سلام، إلا.
- Harekeler önündeki harfle bir küme; ayrı dokunulmaz (havuzdaki kelimeler harekesiz).

**Kelime içinde dokunma** (`widgets/tappable_word.dart`): kelime tek metin olarak çizilir
(`TextPainter`, RTL); her harfin mantıksal aralığı için `getBoxesForSelection` kutusu alınır ve
dokunma alanı (`InkWell`, klavyeyle de seçilir) tam o kutuya yerleşir. Genişlikler eşit sayılmaz,
görsel sıra ölçümden gelir. Vurgu = arkaya boyanan zemin + harfin **rengi** (renk değişimi
şekillendirmeyi değiştirmez; testte kutu genişlikleri birebir aynı). Gerçek Hasenat ile ölçüldü:
67 kelimenin hepsinde her harfin ayrı, çakışmayan kutusu var (ligatür yok); piksel denetiminde her
harfin mürekkebinin ≥ %89'u kendi kutusunda (taşan kısım ر/و kuyrukları). Havuza yeni kelime
eklenince `harf_dedektifi_test.dart` bunu yeniden denetler; Hasenat'ın bitişik glif (ligatür)
yaptığı bir kelime testi kırar → o kelime alınmamalı.

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
- Puanlar cihaz bazlıdır. Cihaz başına tek oyuncu adı (Oyunlar'a ilk girişte sorulur);
  harf oyunlarında çevrimiçi "Genel Sıralama" var: `docs/FIREBASE.md`.

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
                           widgets: draggable_letter, sound_slot, fly_back
memory/                    memory_levels_screen (Kolay/Zor/Çok Zor listesi), memory_game_screen,
                           widgets: memory_card (dönen kart)
listen_pick/               listen_pick_lessons_screen (ders seçimi), listen_pick_screen,
                           listen_pick_questions (soru üretimi, LetterPosition),
                           widgets: option_card, options_grid, play_sound_button
harf_dedektifi/             harf_dedektifi_screen (mod + harf grubu), harf_dedektifi_game_screen
                           (turlar, geri bildirim, bitiş), dedektif_data (harf kimliği, biçimler,
                           benzer gruplar, nokta ipuçları, kelime havuzu), dedektif_engine (tur
                           üretimi + oturum/puan, saf Dart), dedektif_progress_store (zorluk, ses),
                           widgets: detective_card, tappable_word
results/game_results_screen.dart
widgets/                   Ortak parçalar: fit_grid, game_score_strip, game_result_summary,
                           game_finish_view, game_progress (GameStepPill, GameProgressBar),
                           music_note_burst, shake_on_trigger, game_colors
```
Diğer: `lib/models/game_score.dart`, `lib/services/game_score_store.dart`
(`main.dart`'ta `Provider<GameScoreStore>`), `lib/data/drag_drop_game_data.dart`,
ses: `assets/audio/oyunlar/dogru.mp3` (eski `assets_audio_win.wav`'ın sondaki sessizliği
kırpılmış, küçültülmüş hali; pubspec'te `assets/audio/oyunlar/`). Ses kayıtları/önbellek: `docs/SES.md`.

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
- **Eski `ikinci_oyun`** (şekil resimleriyle basit kart eşleştirme; harf öğretmiyor, Hafıza ile
  aynı türde): henüz **dokunulmadı**. Kullanıcı istemeden aktarma. (`ucuncu_oyun` = Hafıza, yapıldı.) Eski kod: `D:\Elifbe2025\lib\oyunlar\`, sesler `D:\Elifbe2025\assets\audio`
  (hayvan/şekil resimleri `assets/resim` — kopyalama).
- Tek oyuncu adı: `harf_oyunlari/profil/` (birden çok çocuk profili bilerek yok).
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
- Proje artık git deposu (GitHub'da); yayın bilgisi `CLAUDE.md`'de.
