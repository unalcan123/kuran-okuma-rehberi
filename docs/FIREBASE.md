# Çevrimiçi sıralama (Firebase)

Son güncelleme: 2026-09-23. Bul & Patlat ve Harf Arabaları'nın oyun sonunda
"Genel Sıralama" (ilk 10 + kendi sıran + toplam oyuncu) gösterilir. Yerel skor /
profil sistemi aynen durur; Firebase onun üstünde bir katmandır.

## Proje
- Firebase projesi: **kuran-okuma-rehberi** (Spark / ücretsiz), hesap unalcanpolat@gmail.com.
  Console: https://console.firebase.google.com/project/kuran-okuma-rehberi
- Firestore: `(default)`, konum **eur3**. Authentication: yalnızca **Anonymous** açık.
- Uygulamalar: Android `com.kuranokumarehberi.kuran_okuma_rehberi`, iOS
  `com.kuranokumarehberi.kuranOkumaRehberi`, Web, Windows (web uygulaması olarak).
- `lib/firebase_options.dart`: `firebase apps:sdkconfig` çıktılarından üretildi (yeni
  proje o an `flutterfire configure` listesinde görünmüyordu). Yeniden üretmek:
  `flutterfire configure --project=kuran-okuma-rehberi`. Değerler gizli değildir;
  erişimi `firestore.rules` denetler.
- Cloud Functions, Analytics, Crashlytics, Storage **yok** (Spark'ta kalmak için).

## Şema
```
players/{playerId}                        playerId, ownerUid, nickname, createdAt, updatedAt
leaderboard_scores/{gameId}__{playerId}   playerId, ownerUid, nickname, gameId, bestScore,
                                          correctAnswers, wrongAnswers, missedTargets,
                                          totalItems, accuracy, bestAt, updatedAt
```
- `playerId = <anonim UID>_<yerel profil id>`: bir cihazda birden çok çocuk olabilir
  (mevcut profil sistemi); aynı adı taşıyan iki çocuk ayrı oyuncudur.
- Oyuncu başına oyun başına **tek** belge: yalnızca en iyi sonuç. Daha düşük skor yazılmaz
  (istemci işlemi + kural).
- Sıra: `gameId ==`, `bestScore` azalan, `bestAt` artan (eşit puanda önce ulaşan önde;
  `bestAt` sunucu zamanı). Kendi sıran = (daha yüksek puanlı sayısı + aynı puana daha
  önce ulaşan sayısı) + 1, sunucuda **count** ile; tüm koleksiyon indirilmez. Bir oyun
  sonu ≈ ilk 10 belge + kendi belgen + 2–3 sayım.
- Tutulmayan: e-posta, telefon, adres, doğum tarihi, fotoğraf, konum, cihaz kimliği.
- Bul & Patlat ve Harf Arabaları'nın 3 seviyesi **tek** sıralamada (seviye tutulmaz).

## Kod
- `lib/services/leaderboard/`: `nickname_policy.dart` (takma ad kuralları, yerel profil de
  kullanır), `leaderboard_models.dart`, `leaderboard_backend.dart` (arayüz),
  `firebase_leaderboard_backend.dart`, `leaderboard_service.dart` (kuyruk, zaman aşımı, sıra).
- `lib/main.dart`: Firebase arka planda başlar, uygulama beklemez; başlamazsa oyun yine oynanır.
- UI: `lib/screens/oyunlar/widgets/online_leaderboard_section.dart` → `GameResultPanel(online:)`.
- Oyun bağlantısı: `profil/record_result.dart` → `submitOnlineResult`.
- İnternet yoksa sonuç `SharedPreferences` (`leaderboard_pending_v1`) kuyruğunda bekler;
  sonraki oyun sonunda / açılışta / "Tekrar dene" ile gönderilir.
- Profil silinince çevrimiçi kaydı da silinir (internet varsa).

## Yeni oyunu bağlamak
1. `player_models.dart` → `GameIds` ve `kOnlineLeaderboardGames`'e sınırlarla ekle.
2. `firestore.rules` → `gameLimits()`'e aynı satır (test ikisini karşılaştırır).
3. Oyun sonunda `submitOnlineResult(context, OnlineScore(...))`, sonuç paneline
   `OnlineLeaderboardSection`. Puan kuralı farklıysa `OnlineScore.isPlausible` ve kuraldaki
   `validScore` tutarlılık şartlarını o oyuna göre ayır.
4. `firebase deploy --only firestore`.

## Sahte skor sınırları
Harf oyunlarının puan kuralı: doğru +10, ilk denemede +5, art arda 3. ilk-denemede +5 ⇒
`10·doğru ≤ puan`, `3·puan ≤ 50·doğru`, puan 5'in katı; doğru ≤ gelen öğe; Bul & Patlat'ta
kaçan ≤ 5. Oyun kodunda puan tavanı **yok**: her kareye dokunan bot Bul & Patlat'ta ~28 000
yapar. Mutlak tavan insan hızına göre: 120 sn × 2 doğru/sn = 240 doğru → **4000 puan**.
Hedefi duyduktan 0,5 sn sonra dokunan çok hızlı oyuncu: Bul & Patlat ~3700, Harf Arabaları
(seviye 3) ~2650 (test: `online_leaderboard_test.dart`). Bot yine 4000'e çıkabilir;
daha fazlası sunucu kodu (Functions, ücretli) ister.

## Komutlar / testler
```
firebase deploy --only firestore                 # kurallar + dizinler
cd tool/firestore_rules_test && npm install && npm test   # kurallar, emülatörde (hesap gerekmez)
flutter test test/online_leaderboard_test.dart    # servis, UI, oyun sonu (sahte arka uç)
```
- Android: Firebase Auth en az Kotlin 2.2 ister (`android/settings.gradle.kts` 2.2.20),
  `minSdk = 23`.
- Canlı kontrol (2026-09-23, web SDK ile): anonim giriş, Ahmed/Elif/Yusuf senaryosu,
  dizinli sorgular, başkasının kaydı / sahte skor reddi çalıştı; deneme verisi silindi.
