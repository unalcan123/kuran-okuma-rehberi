# Mağaza teslimi (Google Play + App Store)

Son güncelleme: 2026-11-13. İlk sürüm **1.0.0 (derleme 1)**. Her iki mağazada da **yeni kayıt**
(Elif Be / com.fluttercan.elifbe'nin herkese açık kaydı yok: Play 404, App Store lookup 0 sonuç).

## Kimlikler (kalıcı, değişmez)
| | Değer |
|---|---|
| Android paket adı | `com.kuranokumarehberi.kuran_okuma_rehberi` |
| iOS Bundle ID | `com.kuranokumarehberi.kuranOkumaRehberi` |
| Görünen ad | Kur'an Okuma Rehberi (Android `@string/app_name`, iOS `CFBundleDisplayName`) |
| Firebase | `kuran-okuma-rehberi` projesinde bu iki kimlik kayıtlı (`lib/firebase_options.dart`) |
| Sürüm | `pubspec.yaml` `version: 1.0.0+1` → her yüklemede `+N` artmalı (Play versionCode / iOS build) |

## Android
- `compileSdk = 36`, `targetSdk = 36` (Play: 31 Ağu 2026'dan beri API 36 şart), `minSdk = 23`.
- Yükleme anahtarı: `C:\Users\unal_\keys\kuran_okuma_rehberi_upload.jks` (alias `upload`, PKCS12, 2054'e kadar).
  Şifre `android/key.properties`'te (git'e girmez). **Anahtarı ve şifreyi ikinci bir yerde yedekle**;
  Play App Signing açık olduğu için kaybolursa Play Console'dan yükleme anahtarı sıfırlanabilir.
  SHA-256: `4B:DC:20:31:05:B2:4F:60:6B:F1:92:AB:CE:51:5A:A4:75:38:13:54:09:E8:E2:BC:1D:53:12:48:DF:6A:C4:A3`
- `key.properties` yoksa yayın derlemesi debug anahtarıyla imzalanır (yalnız yerel deneme; Play kabul etmez).
- Derleme: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.

## iOS (macOS'ta yapılacak)
- Dağıtım hedefi **iOS 15.0** (Apple en az 13 ister; firebase_core 4.x / Firebase iOS SDK 12 en az 15 ister).
- `Info.plist`: ad "Kur'an Okuma Rehberi", `ITSAppUsesNonExemptEncryption = false` (yalnız HTTPS → ihracat
  sorusu çıkmaz), `LSApplicationQueriesSchemes = mailto` (Bize Ulaşın). İzin isteyen özellik yok
  (kamera/mikrofon/konum/fotoğraf kullanılmıyor) → izin açıklaması gerekmiyor.
- İkon: 1024×1024 RGB, saydamlık yok (App Store şartı) — tamam.
- Apple şartı (28 Nis 2026'dan beri): **Xcode 26+ ve iOS 26 SDK**. Depodaki Flutter 3.29.0 Xcode 26'dan
  önce çıktı; Mac'te Xcode 26 ile derleme sorun çıkarırsa Flutter'ı güncel kararlı sürüme yükselt
  (Windows'ta da aynı sürüme getir, `flutter analyze` + `flutter test` tekrar).
- Mac'te adımlar:
  1. `git pull`, `flutter pub get`, `cd ios && pod install` (Podfile ilk seferde oluşur; içinde
     `platform :ios, '15.0'` satırını aç).
  2. Xcode → Runner → Signing & Capabilities: Team seç, "Automatically manage signing" açık.
  3. App Store Connect'te kayıt: Bundle ID yukarıdaki, birincil dil Türkçe, SKU örn. `kuran-okuma-rehberi`.
  4. `flutter build ipa --release` → `build/ios/ipa/*.ipa`; ya da Xcode → Product → Archive.
  5. Doğrula: Xcode Organizer → **Validate App**; sonra Distribute (ya da Transporter ile yükle).
  6. TestFlight'ta iPhone + iPad'de ders akışı, ses, yazı boyutu, oyun sıralaması.

## Mağaza metinleri (Türkçe)

### Ad
- Play başlık (≤30): `Kur'an Okuma Rehberi: Elifba`
- App Store ad (≤30): `Kur'an Okuma Rehberi`
- App Store alt başlık (≤30): `Elifba, sure, dua ve oyunlar`

### Kısa tanıtım (Play, ≤80)
Elifba, namaz sureleri ve dualar: sesli dersler ve harf oyunlarıyla öğren.

### Tanıtım metni (App Store, ≤170)
Elif'ten başlayarak Kur'an okumayı adım adım öğrenin: sesli Elifba dersleri, namaz sureleri, dualar ve çocuklar için harf oyunları.

### Anahtar kelimeler (App Store, ≤100 bayt; Türkçe harf 2 bayt)
elifba,kuran,sure,dua,namaz,tecvid,arapca,harf,cocuk,ezber,elif,ayet,ezan,kamet,amentu

### Uzun açıklama (Play ve App Store, ≤4000)
Kur'an Okuma Rehberi, Kur'an-ı Kerim'i okumayı Elif'ten başlayarak adım adım öğreten bir eğitim uygulamasıdır. Çocuklar için sade ve sakin tasarlandı; büyükler de rahatça kullanabilir.

ELİFBA DERSLERİ
• 34 ders: harfler, harflerin başta, ortada ve sondaki biçimleri, üstün, esre, ötre, cezm, şedde, uzatma harfleri, tenvin, el takısı ve durak kuralları
• Her harfe ve kelimeye dokununca doğru telaffuzu dinleyin
• Harekeler ve kalın harfler kitaptaki gibi renkli gösterilir
• Kitap sayfası, ızgara ve tek tek büyük görünüm; sayfalar Arapça kitap gibi sağdan sola çevrilir
• Harflerin çıkış yerleri giriş bölümü

NAMAZ SURELERİ
• Namazda okunan kısa sureler (Fâtiha'dan Nâs'a)
• Amme cüzündeki aşirler ve namazlardan sonra okunan sureler: Âyetel Kürsî, Âmenerrasûlü, Hüvallâhüllezî ve daha fazlası
• Ayet ayet dinleme; "Dinle" ile baştan sona, "Ezberle" ile her ayeti istediğiniz kadar tekrar
• Okunan ayet ekranda işaretlenir; meal ve okunuş isteğe bağlı açılır

DUALAR
• Namazda okunan dualar: Sübhâneke, Ettehiyyâtü, Salli-Bârik, Rabbenâ, Kunut duaları
• Namazdan sonra okunan dualar, Âmentü, yemek duası, Tefriciye
• Ezan, kamet ve namaz lafızları

OYUNLAR
Harfleri oynayarak pekiştirin: Sürükle & Bırak, Dinle ve Seç, Hafıza, Bul & Patlat, Harf Arabaları, Harf Dedektifi, Harf Çiziyorum, Harf Treni ve Arapça Yazıyorum. İsteğe bağlı çevrimiçi sıralamada yalnız takma ad ve puan görünür.

KOLAY KULLANIM
• Yazı boyutu, okuma hızı ve tekrar sayısı ayarlanabilir
• Telefon ve tablet için uygun düzen
• Dersler, sureler, dualar ve sesler uygulamanın içinde; internet olmadan da çalışır
• Türkçe, İngilizce, Almanca, Fransızca, İspanyolca, Boşnakça ve Hollandaca arayüz
• Reklam yok, uygulama içi satın alma yok

Kur'an metinleri Diyanet İşleri Başkanlığı'nın yayımladığı metne göre hazırlanmıştır. İçerik kaynakları uygulamadaki Kaynaklar bölümündedir.

### Sürüm notları (1.0.0)
İlk sürüm: 34 Elifba dersi, namaz sureleri ve aşirler, dualar, ezan ve kamet; ayet ayet dinleme ve ezber modu; 9 harf oyunu ve isteğe bağlı çevrimiçi sıralama.

### Bağlantılar
- Gizlilik politikası: https://elifbe.nl/gizlilik.html (`web/gizlilik.html`; `main`'e push edilince yayınlanır)
- Destek: https://elifbe.nl/destek.html (`web/destek.html`)
- Pazarlama/web: https://elifbe.nl/
- İletişim e-postası: fluttercanpolat@gmail.com (uygulamadaki `kContactEmail` ile aynı)

## Veri güvenliği / Uygulama Gizliliği (taslak cevaplar)
İnceleme: `pubspec.yaml` (audioplayers, shared_preferences, url_launcher, google_fonts, provider, firebase_core,
firebase_auth, cloud_firestore), `docs/FIREBASE.md`, `firestore.rules`, Android birleşik manifest (izinler aşağıda).
Analytics, Crashlytics, reklam SDK'sı, konum, kamera, mikrofon, kişiler **yok**. google_fonts yalnız yazı tipi
indirir (kullanıcı verisi göndermez); Arapça yazı tipleri pakette.

### Google Play — Veri güvenliği
- Veri topluyor mu / paylaşıyor mu: **Toplanıyor: Evet. Paylaşılıyor: Hayır** (Firebase = hizmet sağlayıcı, paylaşım sayılmaz).
- Aktarımda şifreli: **Evet**. Kullanıcı silme isteyebilir: **Evet** (e-posta; gizlilik sayfasında anlatıldı).
- Toplanan veri türleri:
  | Kategori → tür | Neden | Zorunlu mu |
  |---|---|---|
  | Kişisel bilgiler → **Kullanıcı kimlikleri** (anonim Firebase UID) | Uygulama işlevselliği, sahtecilik önleme | Zorunlu (oyun sıralaması için arka planda) |
  | Kişisel bilgiler → **Diğer bilgiler** (takma ad) — ya da "Ad" olarak işaretle (takma ad çocuğun adı olabilir; daha güvenli seçim) | Uygulama işlevselliği | İsteğe bağlı |
  | Uygulama etkinliği → **Uygulama içi diğer etkinlikler** (oyun puanı, doğru/yanlış, harf ilerlemesi) | Uygulama işlevselliği | İsteğe bağlı |
- Hesap oluşturma: "Kullanıcı adı ve şifre gibi bir hesap yok" değil — anonim hesap var ama kullanıcı giriş yapmaz.
  Play "hesap silme" bölümünde: **Uygulama hesap oluşturmaya izin vermiyor** seçilebilir; yine de silme isteği
  e-postayla yapılabilir diye gizlilik sayfasında yazıyor. (Play inceleme isterse silme sayfası URL'si = gizlilik sayfası.)
- Hedef kitle ve içerik: hedef yaş grubu çocukları içeriyorsa **Aileler politikası** geçerli. Reklam yok;
  Firebase Auth/Firestore Aileler'de kullanılabilir. "Öğretmen Onaylı" programı isteğe bağlı.
- Reklam içeriyor: **Hayır**. Uygulama içi satın alma: **Hayır**. Haber uygulaması: Hayır. COVID/sağlık: Hayır.
- İçerik derecelendirmesi (IARC) anketi: şiddet/korku/cinsellik/kumar/küfür yok; **kullanıcılar etkileşime
  giriyor mu: Hayır** (sohbet yok); **kullanıcı içeriği paylaşılıyor mu:** takma ad sıralamada görünür → dürüst
  cevap "Evet, sınırlı (takma ad), filtreli". Beklenen sonuç: PEGI 3 / Herkes.

### App Store — Uygulama Gizliliği
- İzleme (tracking): **Hayır** → App Tracking Transparency gerekmez.
- Toplanan veriler (hepsi **kimliğe bağlı: Evet** (anonim UID ile), **izleme için: Hayır**, amaç: **Uygulama İşlevselliği**):
  - Tanımlayıcılar → **Kullanıcı Kimliği** (anonim UID)
  - Kullanım Verileri → **Ürün Etkileşimi** (oyun puanları, ilerleme)
  - Diğer Veriler → **Diğer Veri Türleri** (takma ad) — ya da İletişim Bilgileri → Ad (takma ad gerçek ad olabilir; temkinli seçim)
- Yaş derecelendirmesi (2026 yeni anket): şiddet/korku/cinsellik/kumar/alkol/ilaç/küfür: **Yok**;
  Kontrolsüz web erişimi: **Hayır**; Kullanıcı tarafından oluşturulan içerik: takma ad → **Evet** (filtreli);
  Mesajlaşma/sohbet: Hayır; Reklam: Hayır; Tıbbi: Hayır. Beklenen: **4+**.
- **Kids kategorisi seçme** (önerilmez): Kids'te "Bize Ulaşın" e-posta bağlantısı için ebeveyn kapısı ve
  üçüncü taraf hizmetler için ek şartlar gerekir. Kategori: **Eğitim** (ikincil: Başvuru Kaynakları).
- Fiyat: Ücretsiz. İhracat uyumluluğu: `ITSAppUsesNonExemptEncryption = false` ile otomatik.

## Ekran görüntüleri ve paketler (`store/`, git'e girmez)
- `store/kuran_okuma_rehberi-1.0.0+1.aab` — Play'e yüklenecek imzalı paket (147,6 MB; temel modül sınırı 200 MB).
- `store/kuran_okuma_rehberi-1.0.0+2-arm64-test.apk` — yalnız cihaz denemesi (güncelleme testi); mağazaya yüklenmez.
- `store/feature_graphic.png` — Play öne çıkan görsel 1024×500 (zorunlu).
- `store/screenshots/play_phone/` — 9 adet 1048×2092, **gerçek telefondan** (Samsung SM-S948B, Android 17;
  durum çubuğu/gezinme çubuğu/kenar paneli kırpıldı). Play telefon bölümüne.
- `store/screenshots/ios_iphone_6.9/` — 7 adet 1320×2868 (App Store 6.9" iPhone).
- `store/screenshots/ios_ipad_13/` — 6 adet 2064×2752 (App Store 13" iPad; Play 10" tablet için de kullanılabilir).
- iPhone/iPad görüntüleri aynı Flutter arayüzünün **web derlemesinden**, cihaz boyutunda Chrome ile alındı (Windows'ta
  iOS simülatörü yok). Mac'te gerçek simülatörden yenisini almak istersen: Xcode Simulator "iPhone 17 Pro Max" + "iPad Pro 13"
  → `xcrun simctl io booted screenshot x.png`.
- Paket derlemesi **HEAD (4c2ec75) + yayın ayarlarıyla** temiz bir kopyadan yapıldı; commit'lenmemiş Harf Yıldızları
  (yarım iş) pakette **yok**. Yeniden derlerken o işi ya bitirip commit'le ya da `git stash` ile dışarıda bırak.

## Test sonuçları (2026-11-13)
- `flutter analyze`: sorun yok. `flutter test`: 831 test geçti (yayın kopyasında).
- Android yayın APK'sı (aynı yükleme anahtarı, hedef API 36) gerçek telefonda: açılış, dil seçimi, Elifba → Ders 1,
  harfe dokununca ses (MediaPlayer + ses odağı alındığı `dumpsys audio` ile doğrulandı), Sureler → Fâtiha → Dinle
  (ayet ve kelime işaretleme), Dualar, Oyunlar, Hafıza oyunu. Çökme yok.
- **Güncelleme:** derleme 1 kurulu → derleme 2 üstüne kuruldu (`adb install -r`): seçilen dil (Türkçe, telefon Hollandaca)
  korundu = SharedPreferences verisi güncellemede kalıyor. Mağazada önceki sürüm olmadığı için "mağaza sürümünden
  güncelleme" testi yok; ikinci sürümde Play iç test kanalında tekrarla.
- **iOS cihaz testi yapılmadı** (Windows). Mac/TestFlight'ta: ders akışı, ses (sessiz mod anahtarı açıkken de çalıyor mu),
  iPad yatay/dikey, Bize Ulaşın (Mail uygulaması yoksa adres kopyalanıyor mu).
- Görülen küçük kusurlar (yayını engellemez): Oyunlar/Hafıza'da sol üstteki güneş süsü yazının ve "Puan" kutusunun
  arkasına biniyor; sure adlarında "Fatiha Sûresi" şapkalı, diğerleri "Suresi"; Ders 1'de "Kalın harfler şunlardır"
  satırındaki harf dizisinin yönü web'de iki çekim arasında farklı çıktı (ق…خ / خ…ق) — kontrol et.

## Mağaza hesabında kalan adımlar
**Google Play Console**
1. Uygulama oluştur: ad "Kur'an Okuma Rehberi: Elifba", varsayılan dil Türkçe, Uygulama, Ücretsiz.
2. Play App Signing'i kabul et (varsayılan), AAB'yi önce **iç test** kanalına yükle.
3. Kişisel geliştirici hesabıysa: üretime çıkmadan önce **kapalı test, en az 12 test kullanıcısı, 14 gün** şartı.
4. Uygulama içeriği: gizlilik politikası URL'si, reklam yok, uygulama erişimi (giriş gerekmez), içerik derecelendirmesi
   (IARC), hedef kitle (çocuklar dahilse Aileler politikası), Veri güvenliği (yukarıdaki taslak), devlet uygulaması değil,
   finans/sağlık değil.
5. Mağaza girişi: metinler + `feature_graphic.png` + `play_phone/` + (isteğe bağlı) tablet görüntüleri + 512×512 ikon
   (`assets/images/branding/app_icon.png`'den küçült).
**App Store Connect**
1. Apple Developer hesabında Bundle ID kaydı (`com.kuranokumarehberi.kuranOkumaRehberi`), uygulama kaydı.
2. Mac'te arşiv + Validate + yükleme (yukarıdaki iOS adımları), TestFlight.
3. Uygulama Gizliliği, yaş derecelendirmesi anketi, kategori Eğitim, fiyat Ücretsiz, metinler, iPhone + iPad görüntüleri,
   destek URL'si, gizlilik URL'si, inceleme notu ("Giriş gerekmez; sıralama için takma ad isteğe bağlıdır").
4. EU DSA tüccar durumu beyanı (AB'de yayın için).
**Her ikisinden önce:** `web/gizlilik.html` ve `web/destek.html` `main`'e push edilip https://elifbe.nl/gizlilik.html
açılıyor olmalı.
