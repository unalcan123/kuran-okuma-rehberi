# Elifbe — düzeltme ve içerik raporu

28 Ekim 2026 · Yerel uygulama: `D:\Kuran Okuma Rehberi`

## Sonuç

Uygulamada 23 sure/ayet okuma kartı ve 14 dua bulunuyor. İstenen yeni sureler, Âyetel Kürsî ve referans sayfalarındaki beş dua grubu mevcut okuma ekranına eklendi. Türkçe sure mealleri Suat Yıldırım olarak güncellendi. Surelerin diğer altı dildeki mealleri yayımlanmış çevirilerden alındı; dini metinler tarafımdan çevrilmedi.

Verilen ses klasöründen 13 kayıt eşleştirildi. Kaynak dosyalar değiştirilmedi. Uygulamaya mono, 48 kbps kopyalar eklendi; kayıtların süreleri korundu. Uzun kayıtlar yalnızca Dinle'ye basıldığında yüklenir.

Bu çalışma yerelde hazırlandı; bu yeni paket henüz canlı siteye yayımlanmadı. Chrome önizlemesi: `http://127.0.0.1:8104/#/sureler`.

## Eklenen içerik

Namaz Sureleri sırası ve kart numaraları:

1. Fâtiha
2. Fil
3. Kureyş
4. Mâûn
5. Kevser
6. Kâfirûn
7. Nasr
8. Tebbet
9. İhlâs
10. Felâk
11. Nâs
12. Âyetel Kürsî — Bakara 255
13. Nebe — yalnız 31–40. ayetler
14. Duhâ
15. İnşirâh
16. Tîn
17. Kadir
18. Zilzâl
19. Âdiyât
20. Kâria
21. Tekâsür
22. Asr
23. Hümeze

Fâtiha'da besmele 1 numaralı ayettir; son iki kart, kullanıcının isteği doğrultusunda, aynı 7 numarasını ve aynı tam ayet mealini gösterir. Diğer surelerin besmelesi numarasızdır. Nasr'ın üçüncü ayeti mevcut ses kayıtlarında iki parçadır; iki kart da 3 numarasını ve üçüncü ayetin tam mealini gösterir. Ses dosyalarının eski kimlikleri korunmuştur.

Referans fotoğraflarından eklenenler:

- Ezan Duası
- Namazdaki Tekbir, Tahmid ve Tesbihler
- Namaz Tesbihatı
- Yemek Duası
- Salâten Tüncînâ Duası

Bu yeni duaların Türkçe ve Felemenkçe metinleri verilen kitap sayfalarından aktarıldı. Diğer beş dil için yeni dua çevirisi üretilmedi; bu sayfalarda kaynak bulunmayan anlamlar Türkçe olarak kalır. Mevcut dokuz dua korunmuştur. Yeni içeriklerde henüz özel resimli kapak olmadığından uygulamanın mevcut metin kartı kullanılır.

## Sesler

Eşleşen kayıtlar: Duhâ, İnşirâh, Tîn, Kadir, Zilzâl, Âdiyât, Kâria, Tekâsür, Asr, Hümeze, Âyetel Kürsî, Ezan Duası ve Yemek Duası.

Bu dosyalar bölümün tamamına ait öğretim kayıtlarıdır. Dinle ile tek kayıt olarak oynatılır; duraklatma, devam ve durdurma desteklenir. Ayet sınırları belirlenmeden ayetlere sahte ses eşleştirmesi yapılmadı. Yeni kayıtlar için ayet bazında dinleme ve Ezberle bu nedenle kapalıdır. Eski parçalara ayrılmış seslerin ezber sistemi korunmuştur.

Nebe 31–40, namaz tesbihleri, namaz tesbihatı ve Salâten Tüncînâ için kesin eşleşen ses yoktur. Klasördeki Tefriciye, Tüncînâ yerine kullanılmadı. Âmenerresûlü ve Hüvellezî kayıtları da bu istek kapsamında metin olarak eklenmedi. İsimsiz AVSEQ dosyaları kesin kimlik doğrulaması yapılmadan atanmadı.

Dosya eşleştirmeleri, süreler ve boyutlar: `tool/sources/audio_import_manifest.json`.

## UX incelemesindeki 18 madde

| No | Sonuç | Yapılan değişiklik / sınır |
|---|---|---|
| 1 | Düzeltildi | Besmele, ana düğmeler, numara rozetleri ve kırmızı Arapça vurgular koyulaştırıldı. Hedef metin renkleri için 4,5:1 üzeri kontrast testleri geçti. |
| 2 | Düzeltildi | Fâtiha besmelesinin sonundaki bağımsız kesre temizlendi. |
| 3 | Düzeltildi | Harf ve kelime ızgaralarına anlamlı sağdan sola erişilebilirlik sırası eklendi. Elif–Be–Te–Se sırası otomatik testle doğrulandı. |
| 4 | Düzeltildi | Erişilebilirlik katmanı uygulama açılışında etkinleşir. |
| 5 | Düzeltildi | Tarayıcı yakınlaştırma kısıtı kaldırıldı; uygulama içi %170, %180 ve %190 seçenekleri eklendi. |
| 6 | Düzeltildi | İncelemede belirtilen eksik arayüz çevirileri, dile göre meal anahtarı, Material geri düğmeleri, tarayıcı başlığı ve html dili güncellendi. Bu işlem bütün uygulamanın bağımsız dil editörlüğü denetimi değildir. |
| 7 | Düzeltildi | Açılış görseli 1.183.010 bayt PNG yerine 53.458 bayt WebP ile gösterilir: yaklaşık %95,5 küçülme. |
| 8 | Kısmen | Gereksiz ikonlar release derlemesinde ayıklanıyor; CanvasKit aynı siteden sunulacak şekilde ayarlandı. Arapça font alt kümelemesi uygulanmadı; tam font korunuyor. Yeni çeviriler nedeniyle ana JavaScript dosyası yaklaşık 4,81 MB oldu; JS küçüldü iddiası yoktur. |
| 9 | Korundu / sunucu sınırı | Mevcut service worker korunuyor. Ses önbelleği sürümü yenilendi. GitHub Pages'in HTTP cache-control politikası bu değişiklikle değişmedi. |
| 10 | Düzeltildi | robots.txt, sitemap.xml, canonical, tema rengi, sosyal paylaşım etiketleri ve noscript eklendi. Site haritası kök sayfayı listeler; hash bağlantıları ayrı indekslenebilir sayfa gibi sunulmaz. |
| 11 | Düzeltildi | Markalı, yedi dil destekli 404 sayfası eklendi. |
| 12 | Düzeltildi | Ortak düğme ve ikon hedefleri 48 px'e çıkarıldı; sayfa geçişleri dar ekranda küçülen yazılar yerine uygun ikonlarla sunulur. Kısa ekran kontrolleri geçti. |
| 13 | Düzeltildi | Dinleme etiketlerine ayet/bölüm numarası eklendi. |
| 14 | Düzeltildi | Kısa ekranlarda okuma üst görseli 88 px'e iner. |
| 15 | Kullanıcı tercihi korundu | Fâtiha son iki kartı aynı 7 numarasında ve aynı mealde bırakıldı. İncelemenin 7a/7b önerisi uygulanmadı. |
| 16 | İyileştirildi | Ortak kart oranı ve büyüklüğe bağlı başlık/rozet ölçüleri kullanılır. Türkçe resimli başlığın üstüne büyük beyaz alan eklenmez. Orijinal çizimlerin farklı iç oranları korunmuştur; yeni surelerde mevcut metin kartı vardır. |
| 17 | Düzeltildi | Ders, sure, dua, kaynaklar ve gizlilik için doğrudan hash bağlantıları eklendi. Örnek: /#/sure/fatiha ve /#/ders/1. |
| 18 | Düzeltildi | Açıklamalardaki Arapça harf grupları bölünmeyen bir parça olarak yerleştirildi. |

Ana ekrana Kaynaklar ve Gizlilik bağlantıları eklendi. Kaynak bilgileri öğrenme kartlarında tekrarlanmaz. Gizlilik metni yerel ayarları, Firebase anonim kimliğini ve takma ad/puan tablosunu açıklar; işletmeci kimliği ve saklama süreleri için ayrıca bilgi gerekir. Bu çalışma hukuki uygunluk belgesi değildir.

## Kaynaklar

- Arapça yeni sureler: [Diyanet Kur'an Platformu](https://kuran.diyanet.gov.tr/kuran?page=4) ve resmî Diyanet mushaf sayfaları. Ayet bazında alınan metinler ve kaynak adresleri `tool/sources/diyanet_arabic_extract.json` içinde saklandı.
- Türkçe sure mealleri: [Suat Yıldırım / Tanzil](https://tanzil.net/trans/tr.yildirim), kaynak sürümü 2010-09-14. Uygulamanın ücretsiz kullanımına ilişkin kaynak koşulları ve atıf korunur.
- Diğer diller: [QuranEnc](https://quranenc.com/) yayımlanmış çevirileri. İspanyolca García, Fransızca Rashid, Almanca Bubenheim/Elyas, İngilizce Saheeh International, Boşnakça Mihanovich ve Felemenkçe Rowwad Translation Center. Yayıncı, sürüm ve açıklamalar uygulamanın Kaynaklar sayfasında; metin ve dipnotlar kaynak kayıtlarında korunur.
- Dualar: kullanıcının `ref` klasörüne koyduğu kitap fotoğrafları, s. 37–41. Kaynak dosyalar değiştirilmedi.
- Sesler: kullanıcının `H:\Music\sureler` klasörü. Dışarıdan farklı okuyucu kaydı eklenmedi.

## Doğrulama

- Tam test çalışması: **805 test geçti** (`tmp/final-tests-verified.log`).
- On bir yeni sure dahil genişletilmiş telefon/yatay ekran ve %190 yazı kontrolü: **3 test geçti** (`tmp/new-content-layout.log`).
- Son analiz: **hata ve uyarı yok** (`tmp/final-analysis-verified.log`).
- Release web derlemesi: **başarılı** (`tmp/final-build-verified.log`).
- Yeni Arapça ayetler kayıtlı Diyanet metinleriyle, tüm sure mealleri seçilen dilin kaynak verisiyle karşılaştırıldı.
- Önizlemede Duhâ için Dinle → Duraklat → Durdur akışı ve yeni sıralama doğrulandı. Hoparlörden duyum veya yeni uzun seslerin her ayetinin insan tarafından dinlenmesi tamamlandı iddiası yoktur.
- Gerçek telefon, NVDA/VoiceOver oturumu ve soğuk ağ performans ölçümü yapılmadı. Test ortamı ve tarayıcı önizlemesi sonuçları raporlandı.

## Kalan işler

1. Eksik dört bölümün seslerini kesin metin eşleştirmesiyle tamamlamak.
2. Yeni uzun öğretim kayıtlarını ayetlere ayırmak istenirse, her sınırı dinleyerek doğrulamak; ardından ayet bazında Ezberle'yi açmak.
3. Yeni duaların kalan beş dilde yayımlanmış çevirilerini bulmak ve eklemek.
4. Yeni sure/dua kartlarına mevcut resim tarzında kapaklar hazırlamak.
5. İlk yükleme performansı, font alt kümelemesi ve barındırma önbelleğini ayrı ölçümle iyileştirmek.
6. Bu yerel paketi canlı siteye yayımlamak.
