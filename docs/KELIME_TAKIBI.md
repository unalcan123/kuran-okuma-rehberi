# Sure ve dua kelime takibi

30 Ekim 2026. Okunan Arapça kelime altın zemin ve koyu yeşil yazıyla belirtilir.
Dinle, tek bölüm ve Ezberle aynı kelime takibini kullanır. Metni gizle ayarı
korunur. Uzun metinde okunan kelime görünür alandan çıkarsa sayfa kaydırılır.

Zaman, webde HTMLAudioElement.currentTime'dan; yerel uygulamada audioplayers
konum olaylarından gelir. Hız, yükleme ve duraklama için duvar saatiyle tahmin
yapılmaz. İlk ses konumu gelmeden, beklemede ve duraklamada kelime vurgusu
gösterilmez. Ses/metin zamanları olmayan bölümde mevcut ayet/kart vurgusu sürer.

Zamanlar mevcut özgün kayıtlar ile ekrandaki Arapçanın Whisper çapraz dikkat
matrisinden dinamik zaman bükmesiyle çevrimdışı eşlenmesiyle oluşturuldu.
Model: tarteel-ai/whisper-base-ar-quran, snapshot
5c3c53fdf9272c4f6ee0bee09a1e5a4a615ee25c. Belirsiz token sınırlarında
kelime düzeyinde monoton dikkat eşlemesi uygulanır. Baş/son sessizlikler
ses enerjisinden ölçülür. Kelimelere eşit süre dağıtılmaz. Bu otomatik
hizalamadır; bütün kelimeler insan tarafından dinlenerek doğrulanmış değildir.

Kaynak veri: tool/sources/reading_word_timings.json. Her kaydın metni, süreleri
ve SHA-256 ses parmak izi saklanır. Çalışma zamanı tam ses yolu + tam Arapça
metinle eşleştirir. Ses dosyası aynı adla değişirse zamanları yeniden üretmek
gerekir. Sesler ve kaynak Arapça değiştirilmedi. Yeni ağ isteği, mikrofon izni
veya konuşma servisi gerektirmez; eşleme modeli uygulamaya paketlenmez.

Yöntem kaynağı: https://huggingface.co/docs/transformers/model_doc/whisper
Kelime sürelerinin kullanımı: https://github.com/openai/whisper/blob/main/whisper/timing.py

Kontroller: gerçek medya konumuyla kelime ilerleme, duraklat/devam, hız,
yeniden başlatma/durdurma, Arapça metnin korunması, uzun metinde kaydırma,
zaman aralıklarının sırası, mevcut sure/dua ekranları ve web ses motoru.
