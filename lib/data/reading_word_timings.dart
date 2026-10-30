import '../models/reading_segment.dart';

class ReadingWordTiming {
  const ReadingWordTiming(this.start, this.end, this.startMs, this.endMs);
  final int start, end, startMs, endMs;
}

// Keyed by the exact displayed Arabic AND recording to prevent stale timings
// from being applied after a text/audio mapping changes.
List<ReadingWordTiming> readingWordTimings(ReadingSegment segment) =>
    kReadingWordTimings['${segment.audioAsset}|${segment.arabic}'] ?? const [];

int? wordIndexAt(List<ReadingWordTiming> words, int milliseconds) {
  for (var i = 0; i < words.length; i++) {
    if (milliseconds >= words[i].startMs && milliseconds < words[i].endMs) {
      return i;
    }
  }
  return null;
}

// Offline Whisper cross-attention alignment of the owner's existing clips.
// No uniform word-duration estimates. Source: tool/sources/reading_word_timings.json.
const kReadingWordTimings = <String, List<ReadingWordTiming>>{
  "audio/sureler/01_fatiha/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 300),
        ReadingWordTiming(7, 14, 300, 580),
        ReadingWordTiming(15, 26, 580, 2240),
        ReadingWordTiming(27, 37, 2240, 5560),
      ],
  "audio/sureler/01_fatiha/01_ayet.mp3|اَلْحَمْدُ لِلّٰهِ رَبِّ الْـعَالَم۪ينَۙ":
      [
        ReadingWordTiming(0, 10, 0, 1020),
        ReadingWordTiming(11, 18, 1020, 2340),
        ReadingWordTiming(19, 24, 2340, 2940),
        ReadingWordTiming(25, 40, 2940, 6070),
      ],
  "audio/sureler/01_fatiha/02_ayet.mp3|اَلرَّحْمٰنِ الرَّح۪يمِۙ": [
    ReadingWordTiming(0, 12, 0, 980),
    ReadingWordTiming(13, 24, 980, 3980),
  ],
  "audio/sureler/01_fatiha/03_ayet.mp3|مَالِكِ يَوْمِ الدّ۪ينِ": [
    ReadingWordTiming(0, 7, 0, 860),
    ReadingWordTiming(8, 14, 860, 1520),
    ReadingWordTiming(15, 23, 1520, 4170),
  ],
  "audio/sureler/01_fatiha/04_ayet.mp3|اِيَّاكَ نَعْبُدُ وَاِيَّاكَ نَسْتَع۪ينُ":
      [
        ReadingWordTiming(0, 8, 0, 940),
        ReadingWordTiming(9, 17, 940, 1640),
        ReadingWordTiming(18, 28, 1640, 2380),
        ReadingWordTiming(29, 40, 2380, 6230),
      ],
  "audio/sureler/01_fatiha/05_ayet.mp3|اِهْدِنَا الصِّرَاطَ الْمُسْتَق۪يمَۙ": [
    ReadingWordTiming(0, 9, 0, 620),
    ReadingWordTiming(10, 20, 620, 1620),
    ReadingWordTiming(21, 36, 1620, 5400),
  ],
  "audio/sureler/01_fatiha/06_ayet.mp3|صِرَاطَ الَّذ۪ينَ اَنْعَمْتَ عَلَيْهِمْۙ":
      [
        ReadingWordTiming(0, 7, 0, 920),
        ReadingWordTiming(8, 17, 920, 1760),
        ReadingWordTiming(18, 28, 1760, 3380),
        ReadingWordTiming(29, 40, 3380, 5350),
      ],
  "audio/sureler/01_fatiha/07_ayet.mp3|غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّٓالّ۪ينَ":
      [
        ReadingWordTiming(0, 6, 0, 600),
        ReadingWordTiming(7, 19, 600, 1980),
        ReadingWordTiming(20, 30, 1980, 2440),
        ReadingWordTiming(31, 36, 2440, 2580),
        ReadingWordTiming(37, 50, 2580, 10600),
      ],
  "audio/sureler/02_fil/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ": [
    ReadingWordTiming(0, 6, 0, 240),
    ReadingWordTiming(7, 14, 240, 400),
    ReadingWordTiming(15, 26, 400, 1860),
    ReadingWordTiming(27, 37, 1860, 4680),
  ],
  "audio/sureler/02_fil/01_ayet.mp3|اَلَمْ تَرَ كَيْفَ فَعَلَ رَبُّكَ بِاَصْحَابِ الْف۪يلِ":
      [
        ReadingWordTiming(0, 6, 0, 280),
        ReadingWordTiming(7, 11, 280, 980),
        ReadingWordTiming(12, 18, 980, 1660),
        ReadingWordTiming(19, 25, 1660, 2200),
        ReadingWordTiming(26, 33, 2200, 3540),
        ReadingWordTiming(34, 45, 3540, 5440),
        ReadingWordTiming(46, 54, 5440, 8250),
      ],
  "audio/sureler/02_fil/02_ayet.mp3|اَلَمْ يَجْعَلْ كَيْدَهُمْ ف۪ي تَضْل۪يلٍۙ":
      [
        ReadingWordTiming(0, 6, 0, 300),
        ReadingWordTiming(7, 15, 300, 1240),
        ReadingWordTiming(16, 26, 1240, 2540),
        ReadingWordTiming(27, 30, 2540, 3220),
        ReadingWordTiming(31, 41, 3220, 6760),
      ],
  "audio/sureler/02_fil/03_ayet.mp3|وَاَرْسَلَ عَلَيْهِمْ طَيْراً اَبَاب۪يلَۙ":
      [
        ReadingWordTiming(0, 10, 0, 980),
        ReadingWordTiming(11, 21, 980, 2200),
        ReadingWordTiming(22, 29, 2200, 3400),
        ReadingWordTiming(30, 41, 3400, 6680),
      ],
  "audio/sureler/02_fil/04_ayet.mp3|تَرْم۪يهِمْ بِحِجَارَةٍ مِنْ سِجّ۪يلٍۖۙ": [
    ReadingWordTiming(0, 11, 0, 1060),
    ReadingWordTiming(12, 23, 1060, 3540),
    ReadingWordTiming(24, 28, 3540, 3860),
    ReadingWordTiming(29, 39, 3860, 8770),
  ],
  "audio/sureler/02_fil/05_ayet.mp3|فَجَعَلَهُمْ كَعَصْفٍ مَأْكُولٍ": [
    ReadingWordTiming(0, 12, 0, 980),
    ReadingWordTiming(13, 21, 980, 2560),
    ReadingWordTiming(22, 31, 2560, 7340),
  ],
  "audio/sureler/03_kureys/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 280),
        ReadingWordTiming(7, 14, 280, 560),
        ReadingWordTiming(15, 26, 560, 2080),
        ReadingWordTiming(27, 37, 2080, 5610),
      ],
  "audio/sureler/03_kureys/01_ayet.mp3|لِا۪يلَافِ قُرَيْشٍۙ": [
    ReadingWordTiming(0, 10, 40, 1740),
    ReadingWordTiming(11, 20, 1740, 4460),
  ],
  "audio/sureler/03_kureys/02_ayet.mp3|ا۪يلَافِهِمْ رِحْلَةَ الشِّتَٓاءِ وَالصَّيْفِۚ":
      [
        ReadingWordTiming(0, 12, 0, 1460),
        ReadingWordTiming(13, 21, 1460, 2440),
        ReadingWordTiming(22, 33, 2440, 4200),
        ReadingWordTiming(34, 46, 4200, 8150),
      ],
  "audio/sureler/03_kureys/03_ayet.mp3|فَلْيَعْبُدُوا رَبَّ هٰذَا الْبَيْتِۙ": [
    ReadingWordTiming(0, 14, 0, 1560),
    ReadingWordTiming(15, 20, 1560, 2300),
    ReadingWordTiming(21, 26, 2300, 2440),
    ReadingWordTiming(27, 37, 2440, 6400),
  ],
  "audio/sureler/03_kureys/04_ayet.mp3|اَلَّذ۪ٓي اَطْعَمَهُمْ مِنْ جُوعٍ وَاٰمَنَهُمْ مِنْ خَوْفٍ":
      [
        ReadingWordTiming(0, 9, 0, 780),
        ReadingWordTiming(10, 22, 780, 3020),
        ReadingWordTiming(23, 27, 3020, 3220),
        ReadingWordTiming(28, 33, 3220, 6080),
        ReadingWordTiming(34, 46, 6080, 8740),
        ReadingWordTiming(47, 51, 8740, 11280),
        ReadingWordTiming(52, 58, 11280, 17020),
      ],
  "audio/sureler/04_maun/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 280),
        ReadingWordTiming(7, 14, 280, 520),
        ReadingWordTiming(15, 26, 520, 2020),
        ReadingWordTiming(27, 37, 2020, 5860),
      ],
  "audio/sureler/04_maun/01_ayet.mp3|اَرَاَيْتَ الَّذ۪ي يُكَذِّبُ بِالدّ۪ينِ": [
    ReadingWordTiming(0, 10, 0, 900),
    ReadingWordTiming(11, 18, 900, 1220),
    ReadingWordTiming(19, 28, 1220, 3480),
    ReadingWordTiming(29, 39, 3480, 7290),
  ],
  "audio/sureler/04_maun/02_ayet.mp3|فَذٰلِكَ الَّذ۪ي يَدُعُّ الْيَت۪يمَۙ": [
    ReadingWordTiming(0, 8, 0, 800),
    ReadingWordTiming(9, 16, 800, 1760),
    ReadingWordTiming(17, 24, 1760, 3000),
    ReadingWordTiming(25, 36, 3000, 6580),
  ],
  "audio/sureler/04_maun/03_ayet.mp3|وَلَا يَحُضُّ عَلٰى طَعَامِ الْمِسْك۪ينِۜ":
      [
        ReadingWordTiming(0, 5, 0, 340),
        ReadingWordTiming(6, 13, 340, 1620),
        ReadingWordTiming(14, 19, 1620, 1840),
        ReadingWordTiming(20, 27, 1840, 4100),
        ReadingWordTiming(28, 41, 4100, 7810),
      ],
  "audio/sureler/04_maun/04_ayet.mp3|فَوَيْلٌ لِلْمُصَلّ۪ينَۙ": [
    ReadingWordTiming(0, 8, 0, 820),
    ReadingWordTiming(9, 24, 820, 5690),
  ],
  "audio/sureler/04_maun/05_ayet.mp3|اَلَّذ۪ينَ هُمْ عَنْ صَلَاتِهِمْ سَاهُونَۙ":
      [
        ReadingWordTiming(0, 10, 0, 960),
        ReadingWordTiming(11, 15, 960, 1920),
        ReadingWordTiming(16, 20, 1920, 2160),
        ReadingWordTiming(21, 32, 2160, 5240),
        ReadingWordTiming(33, 42, 5240, 8880),
      ],
  "audio/sureler/04_maun/06_ayet.mp3|اَلَّذ۪ينَ هُمْ يُرَٓاؤُ۫نَۙ": [
    ReadingWordTiming(0, 10, 0, 1020),
    ReadingWordTiming(11, 15, 1020, 1980),
    ReadingWordTiming(16, 28, 1980, 8290),
  ],
  "audio/sureler/04_maun/07_ayet.mp3|وَيَمْنَعُونَ الْمَاعُونَ": [
    ReadingWordTiming(0, 13, 0, 1860),
    ReadingWordTiming(14, 25, 1860, 5810),
  ],
  "audio/sureler/06_kevser/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 260),
        ReadingWordTiming(7, 14, 260, 480),
        ReadingWordTiming(15, 26, 480, 1900),
        ReadingWordTiming(27, 37, 1900, 5450),
      ],
  "audio/sureler/06_kevser/01_ayet.mp3|اِنَّٓا اَعْطَيْنَاكَ الْكَوْثَرَ": [
    ReadingWordTiming(0, 7, 0, 1340),
    ReadingWordTiming(8, 21, 1340, 4640),
    ReadingWordTiming(22, 33, 4640, 6900),
  ],
  "audio/sureler/06_kevser/02_ayet.mp3|فَصَلِّ لِرَبِّكَ وَانْحَرْ": [
    ReadingWordTiming(0, 7, 0, 380),
    ReadingWordTiming(8, 17, 380, 2260),
    ReadingWordTiming(18, 27, 2260, 4080),
  ],
  "audio/sureler/06_kevser/03_ayet.mp3|اِنَّ شَانِئَكَ هُوَ الْاَبْتَرُ": [
    ReadingWordTiming(0, 5, 0, 400),
    ReadingWordTiming(6, 15, 400, 2600),
    ReadingWordTiming(16, 20, 2600, 3220),
    ReadingWordTiming(21, 32, 3220, 5810),
  ],
  "audio/sureler/11_kafirun/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 220),
        ReadingWordTiming(7, 14, 220, 420),
        ReadingWordTiming(15, 26, 420, 1860),
        ReadingWordTiming(27, 37, 1860, 5090),
      ],
  "audio/sureler/11_kafirun/01_ayet.mp3|قُلْ يَٓا اَيُّهَا الْـكَافِرُونَۙ": [
    ReadingWordTiming(0, 4, 0, 360),
    ReadingWordTiming(5, 9, 360, 560),
    ReadingWordTiming(10, 18, 560, 2680),
    ReadingWordTiming(19, 34, 2680, 6700),
  ],
  "audio/sureler/11_kafirun/02_ayet.mp3|لَٓا اَعْبُدُ مَا تَعْبُدُونَۙ": [
    ReadingWordTiming(0, 4, 0, 320),
    ReadingWordTiming(5, 13, 320, 2540),
    ReadingWordTiming(14, 17, 2540, 3060),
    ReadingWordTiming(18, 30, 3060, 7110),
  ],
  "audio/sureler/11_kafirun/03_ayet.mp3|وَلَٓا اَنْتُمْ عَابِدُونَ مَٓا اَعْبُدُۚ":
      [
        ReadingWordTiming(0, 6, 0, 900),
        ReadingWordTiming(7, 15, 900, 3100),
        ReadingWordTiming(16, 26, 3100, 4880),
        ReadingWordTiming(27, 31, 4880, 5340),
        ReadingWordTiming(32, 41, 5340, 8800),
      ],
  "audio/sureler/11_kafirun/04_ayet.mp3|وَلَٓا اَنَا۬ عَابِدٌ مَا عَبَدْتُمْۙ":
      [
        ReadingWordTiming(0, 6, 0, 1360),
        ReadingWordTiming(7, 13, 1360, 2260),
        ReadingWordTiming(14, 21, 2260, 3460),
        ReadingWordTiming(22, 25, 3460, 3780),
        ReadingWordTiming(26, 37, 3780, 7350),
      ],
  "audio/sureler/11_kafirun/05_ayet.mp3|وَلَٓا اَنْتُمْ عَابِدُونَ مَٓا اَعْبُدُۜ":
      [
        ReadingWordTiming(0, 6, 0, 880),
        ReadingWordTiming(7, 15, 880, 3500),
        ReadingWordTiming(16, 26, 3500, 5340),
        ReadingWordTiming(27, 31, 5340, 5800),
        ReadingWordTiming(32, 41, 5800, 9090),
      ],
  "audio/sureler/11_kafirun/06_ayet.mp3|لَـكُمْ د۪ينُكُمْ وَلِيَ د۪ينِ": [
    ReadingWordTiming(0, 7, 0, 560),
    ReadingWordTiming(8, 17, 560, 1780),
    ReadingWordTiming(18, 24, 1780, 2660),
    ReadingWordTiming(25, 30, 2660, 5570),
  ],
  "audio/sureler/09_nasr/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 200),
        ReadingWordTiming(7, 14, 200, 420),
        ReadingWordTiming(15, 26, 420, 1780),
        ReadingWordTiming(27, 37, 1780, 4920),
      ],
  "audio/sureler/09_nasr/01_ayet.mp3|اِذَا جَٓاءَ نَصْرُ اللّٰهِ وَالْفَتْحُۙ":
      [
        ReadingWordTiming(0, 5, 0, 680),
        ReadingWordTiming(6, 12, 680, 2240),
        ReadingWordTiming(13, 19, 2240, 3340),
        ReadingWordTiming(20, 27, 3340, 3580),
        ReadingWordTiming(28, 40, 3580, 6380),
      ],
  "audio/sureler/09_nasr/02_ayet.mp3|وَرَاَيْتَ النَّاسَ يَدْخُلُونَ ف۪ي د۪ينِ اللّٰهِ اَفْوَاجاًۙ":
      [
        ReadingWordTiming(0, 10, 0, 1020),
        ReadingWordTiming(11, 19, 1020, 3060),
        ReadingWordTiming(20, 31, 3060, 4700),
        ReadingWordTiming(32, 35, 4700, 5240),
        ReadingWordTiming(36, 41, 5240, 6340),
        ReadingWordTiming(42, 49, 6340, 6980),
        ReadingWordTiming(50, 61, 6980, 10460),
      ],
  "audio/sureler/09_nasr/03_ayet.mp3|فَسَبِّـحْ بِحَمْدِ رَبِّكَ وَاسْتَغْفِرْهُ":
      [
        ReadingWordTiming(0, 10, 0, 980),
        ReadingWordTiming(11, 19, 980, 2260),
        ReadingWordTiming(20, 27, 2260, 3240),
        ReadingWordTiming(28, 43, 3240, 5760),
      ],
  "audio/sureler/09_nasr/04_ayet.mp3|اِنَّهُ كَانَ تَـوَّاباً": [
    ReadingWordTiming(0, 7, 0, 1580),
    ReadingWordTiming(8, 13, 1580, 2480),
    ReadingWordTiming(14, 24, 2480, 6460),
  ],
  "audio/sureler/10_tebbet/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 220),
        ReadingWordTiming(7, 14, 220, 480),
        ReadingWordTiming(15, 26, 480, 1840),
        ReadingWordTiming(27, 37, 1840, 5560),
      ],
  "audio/sureler/10_tebbet/01_ayet.mp3|تَبَّتْ يَدَٓا اَب۪ي لَهَبٍ وَتَبَّ": [
    ReadingWordTiming(0, 7, 0, 520),
    ReadingWordTiming(8, 14, 520, 1520),
    ReadingWordTiming(15, 20, 1520, 3260),
    ReadingWordTiming(21, 27, 3260, 3300),
    ReadingWordTiming(28, 35, 3300, 6740),
  ],
  "audio/sureler/10_tebbet/02_ayet.mp3|مَٓا اَغْنٰى عَنْهُ مَالُهُ وَمَا كَسَبَ":
      [
        ReadingWordTiming(0, 4, 0, 400),
        ReadingWordTiming(5, 12, 400, 2480),
        ReadingWordTiming(13, 19, 2480, 3420),
        ReadingWordTiming(20, 27, 3420, 4480),
        ReadingWordTiming(28, 33, 4480, 5480),
        ReadingWordTiming(34, 40, 5480, 7380),
      ],
  "audio/sureler/10_tebbet/03_ayet.mp3|سَيَصْلٰى نَاراً ذَاتَ لَهَبٍۚ": [
    ReadingWordTiming(0, 9, 0, 900),
    ReadingWordTiming(10, 16, 900, 2340),
    ReadingWordTiming(17, 22, 2340, 4060),
    ReadingWordTiming(23, 30, 4060, 5690),
  ],
  "audio/sureler/10_tebbet/04_ayet.mp3|وَامْرَاَتُهُ حَمَّالَةَ الْحَطَبِۚ": [
    ReadingWordTiming(0, 13, 0, 1060),
    ReadingWordTiming(14, 24, 1060, 4000),
    ReadingWordTiming(25, 35, 4000, 5940),
  ],
  "audio/sureler/10_tebbet/05_ayet.mp3|ف۪ي ج۪يدِهَا حَبْلٌ مِنْ مَسَدٍ": [
    ReadingWordTiming(0, 3, 0, 260),
    ReadingWordTiming(4, 12, 260, 1480),
    ReadingWordTiming(13, 19, 1480, 2440),
    ReadingWordTiming(20, 24, 2440, 2800),
    ReadingWordTiming(25, 31, 2800, 6410),
  ],
  "audio/sureler/05_ihlas/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 220),
        ReadingWordTiming(7, 14, 220, 640),
        ReadingWordTiming(15, 26, 640, 1820),
        ReadingWordTiming(27, 37, 1820, 5360),
      ],
  "audio/sureler/05_ihlas/01_ayet.mp3|قُلْ هُوَ اللّٰهُ اَحَدٌۚ": [
    ReadingWordTiming(0, 4, 0, 420),
    ReadingWordTiming(5, 9, 420, 480),
    ReadingWordTiming(10, 17, 480, 840),
    ReadingWordTiming(18, 25, 840, 3480),
  ],
  "audio/sureler/05_ihlas/02_ayet.mp3|اَللّٰهُ الصَّمَدُۚ": [
    ReadingWordTiming(0, 8, 0, 740),
    ReadingWordTiming(9, 19, 740, 3140),
  ],
  "audio/sureler/05_ihlas/03_ayet.mp3|لَمْ يَلِدْ وَلَمْ يُولَدْۙ": [
    ReadingWordTiming(0, 4, 0, 200),
    ReadingWordTiming(5, 11, 200, 980),
    ReadingWordTiming(12, 18, 980, 1560),
    ReadingWordTiming(19, 27, 1560, 3770),
  ],
  "audio/sureler/05_ihlas/04_ayet.mp3|وَلَمْ يَكُنْ لَهُ كُفُواً اَحَدٌ": [
    ReadingWordTiming(0, 6, 0, 480),
    ReadingWordTiming(7, 13, 480, 1180),
    ReadingWordTiming(14, 18, 1180, 1760),
    ReadingWordTiming(19, 26, 1760, 3260),
    ReadingWordTiming(27, 33, 3260, 5160),
  ],
  "audio/sureler/08_felak/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 0, 220),
        ReadingWordTiming(7, 14, 220, 440),
        ReadingWordTiming(15, 26, 440, 1880),
        ReadingWordTiming(27, 37, 1880, 5590),
      ],
  "audio/sureler/08_felak/01_ayet.mp3|قُلْ اَعُوذُ بِرَبِّ الْفَلَقِۙ": [
    ReadingWordTiming(0, 4, 0, 200),
    ReadingWordTiming(5, 12, 200, 1460),
    ReadingWordTiming(13, 20, 1460, 2100),
    ReadingWordTiming(21, 31, 2100, 4300),
  ],
  "audio/sureler/08_felak/02_ayet.mp3|مِنْ شَرِّ مَا خَلَقَۙ": [
    ReadingWordTiming(0, 4, 0, 320),
    ReadingWordTiming(5, 10, 320, 1520),
    ReadingWordTiming(11, 14, 1520, 1800),
    ReadingWordTiming(15, 22, 1800, 3940),
  ],
  "audio/sureler/08_felak/03_ayet.mp3|وَمِنْ شَرِّ غَاسِقٍ اِذَا وَقَبَۙ": [
    ReadingWordTiming(0, 6, 0, 540),
    ReadingWordTiming(7, 12, 540, 1660),
    ReadingWordTiming(13, 20, 1660, 3120),
    ReadingWordTiming(21, 26, 3120, 4000),
    ReadingWordTiming(27, 34, 4000, 5940),
  ],
  "audio/sureler/08_felak/04_ayet.mp3|وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِۙ":
      [
        ReadingWordTiming(0, 6, 0, 560),
        ReadingWordTiming(7, 12, 560, 1760),
        ReadingWordTiming(13, 27, 1760, 5360),
        ReadingWordTiming(28, 31, 5360, 5740),
        ReadingWordTiming(32, 42, 5740, 7770),
      ],
  "audio/sureler/08_felak/05_ayet.mp3|وَمِنْ شَرِّ حَاسِدٍ اِذَا حَسَدَ": [
    ReadingWordTiming(0, 6, 0, 560),
    ReadingWordTiming(7, 12, 560, 1620),
    ReadingWordTiming(13, 20, 1620, 3100),
    ReadingWordTiming(21, 26, 3100, 3960),
    ReadingWordTiming(27, 33, 3960, 5980),
  ],
  "audio/sureler/07_nas/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ": [
    ReadingWordTiming(0, 6, 0, 240),
    ReadingWordTiming(7, 14, 240, 480),
    ReadingWordTiming(15, 26, 480, 1840),
    ReadingWordTiming(27, 37, 1840, 5461),
  ],
  "audio/sureler/07_nas/01_ayet.mp3|قُلْ اَعُوذُ بِرَبِّ النَّاسِۙ": [
    ReadingWordTiming(0, 4, 0, 200),
    ReadingWordTiming(5, 12, 200, 1520),
    ReadingWordTiming(13, 20, 1520, 2180),
    ReadingWordTiming(21, 30, 2180, 6620),
  ],
  "audio/sureler/07_nas/02_ayet.mp3|مَلِكِ النَّاسِۙ": [
    ReadingWordTiming(0, 6, 0, 400),
    ReadingWordTiming(7, 16, 400, 4660),
  ],
  "audio/sureler/07_nas/03_ayet.mp3|اِلٰهِ النَّاسِۙ": [
    ReadingWordTiming(0, 6, 0, 580),
    ReadingWordTiming(7, 16, 580, 5100),
  ],
  "audio/sureler/07_nas/04_ayet.mp3|مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِۙ": [
    ReadingWordTiming(0, 4, 0, 260),
    ReadingWordTiming(5, 10, 260, 1480),
    ReadingWordTiming(11, 23, 1480, 3000),
    ReadingWordTiming(24, 36, 3000, 7240),
  ],
  "audio/sureler/07_nas/05_ayet.mp3|اَلَّذ۪ي يُوَسْوِسُ ف۪ي صُدُورِ النَّاسِۙ":
      [
        ReadingWordTiming(0, 8, 0, 720),
        ReadingWordTiming(9, 19, 720, 1800),
        ReadingWordTiming(20, 23, 1800, 2060),
        ReadingWordTiming(24, 31, 2060, 3880),
        ReadingWordTiming(32, 41, 3880, 7720),
      ],
  "audio/sureler/07_nas/06_ayet.mp3|مِنَ الْجِنَّةِ وَالنَّاسِ": [
    ReadingWordTiming(0, 4, 0, 280),
    ReadingWordTiming(5, 15, 280, 2540),
    ReadingWordTiming(16, 26, 2540, 6090),
  ],
  "audio/sureler/12_ayetel-kursi/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 120, 380),
        ReadingWordTiming(7, 14, 380, 800),
        ReadingWordTiming(15, 26, 800, 2040),
        ReadingWordTiming(27, 37, 2040, 5880),
      ],
  "audio/sureler/12_ayetel-kursi/02_ayet.mp3|لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌۜ":
      [
        ReadingWordTiming(0, 3, 360, 620),
        ReadingWordTiming(4, 14, 620, 1480),
        ReadingWordTiming(15, 21, 1480, 2820),
        ReadingWordTiming(22, 27, 2820, 3960),
        ReadingWordTiming(28, 35, 3960, 6830),
      ],
  "audio/sureler/12_ayetel-kursi/03_ayet.mp3|لَهُ مَا فِي السَّمٰوَاتِ وَمَا فِي الْاَرْضِۜ":
      [
        ReadingWordTiming(0, 4, 200, 420),
        ReadingWordTiming(5, 8, 420, 1100),
        ReadingWordTiming(9, 12, 1100, 1800),
        ReadingWordTiming(13, 25, 1800, 3580),
        ReadingWordTiming(26, 31, 3580, 4320),
        ReadingWordTiming(32, 35, 4320, 4860),
        ReadingWordTiming(36, 46, 4860, 6640),
      ],
  "audio/sureler/12_ayetel-kursi/04_ayet.mp3|مَنْ ذَا الَّذ۪ي يَشْفَعُ عِنْدَهُٓ اِلَّا بِاِذْنِه۪ۜ":
      [
        ReadingWordTiming(0, 4, 160, 400),
        ReadingWordTiming(5, 8, 400, 1400),
        ReadingWordTiming(9, 16, 1400, 1820),
        ReadingWordTiming(17, 25, 1820, 3260),
        ReadingWordTiming(26, 35, 3260, 3620),
        ReadingWordTiming(36, 42, 3620, 5780),
        ReadingWordTiming(43, 54, 5780, 9200),
      ],
  "audio/sureler/12_ayetel-kursi/05_ayet.mp3|يَعْلَمُ مَا بَيْنَ اَيْد۪يهِمْ وَمَا خَلْفَهُمْۚ":
      [
        ReadingWordTiming(0, 8, 300, 840),
        ReadingWordTiming(9, 12, 840, 1180),
        ReadingWordTiming(13, 19, 1180, 1940),
        ReadingWordTiming(20, 31, 1940, 3920),
        ReadingWordTiming(32, 37, 3920, 4440),
        ReadingWordTiming(38, 49, 4440, 6660),
      ],
  "audio/sureler/12_ayetel-kursi/06_ayet.mp3|وَلَا يُح۪يطُونَ بِشَيْءٍ مِنْ عِلْمِه۪ٓ اِلَّا بِمَا شَٓاءَۚ":
      [
        ReadingWordTiming(0, 5, 420, 880),
        ReadingWordTiming(6, 16, 880, 2540),
        ReadingWordTiming(17, 25, 2540, 3820),
        ReadingWordTiming(26, 30, 3820, 3940),
        ReadingWordTiming(31, 40, 3940, 5640),
        ReadingWordTiming(41, 47, 5640, 6100),
        ReadingWordTiming(48, 53, 6100, 8440),
        ReadingWordTiming(54, 61, 8440, 11020),
      ],
  "audio/sureler/12_ayetel-kursi/07_ayet.mp3|وَسِعَ كُرْسِيُّهُ السَّمٰوَاتِ وَالْاَرْضَۚ":
      [
        ReadingWordTiming(0, 6, 320, 840),
        ReadingWordTiming(7, 18, 840, 2200),
        ReadingWordTiming(19, 31, 2200, 4440),
        ReadingWordTiming(32, 44, 4440, 6420),
      ],
  "audio/sureler/12_ayetel-kursi/08_ayet.mp3|وَلَا يَؤُ۫دُهُ حِفْظُهُمَاۚ": [
    ReadingWordTiming(0, 5, 460, 1060),
    ReadingWordTiming(6, 15, 1060, 2400),
    ReadingWordTiming(16, 28, 2400, 5182),
  ],
  "audio/sureler/12_ayetel-kursi/09_ayet.mp3|وَهُوَ الْعَلِيُّ الْعَظ۪يمُ": [
    ReadingWordTiming(0, 6, 0, 860),
    ReadingWordTiming(7, 17, 860, 1780),
    ReadingWordTiming(18, 28, 1780, 6200),
  ],
  "audio/sureler/14_duha/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 260, 540),
        ReadingWordTiming(7, 14, 540, 760),
        ReadingWordTiming(15, 26, 760, 2220),
        ReadingWordTiming(27, 37, 2220, 4640),
      ],
  "audio/sureler/14_duha/01_ayet.mp3|وَالضُّحٰىۙ": [
    ReadingWordTiming(0, 11, 440, 2443),
  ],
  "audio/sureler/14_duha/02_ayet.mp3|وَالَّيْلِ اِذَا سَجٰىۙ": [
    ReadingWordTiming(0, 10, 240, 700),
    ReadingWordTiming(11, 16, 700, 1000),
    ReadingWordTiming(17, 23, 1000, 3674),
  ],
  "audio/sureler/14_duha/03_ayet.mp3|مَا وَدَّعَكَ رَبُّكَ وَمَا قَلٰى": [
    ReadingWordTiming(0, 3, 20, 1000),
    ReadingWordTiming(4, 13, 1000, 2240),
    ReadingWordTiming(14, 21, 2240, 3100),
    ReadingWordTiming(22, 27, 3100, 3740),
    ReadingWordTiming(28, 33, 3740, 5853),
  ],
  "audio/sureler/14_duha/04_ayet.mp3|وَلَلْاٰخِرَةُ خَيْرٌ لَكَ مِنَ الْاُو۫لٰى":
      [
        ReadingWordTiming(0, 14, 380, 1300),
        ReadingWordTiming(15, 21, 1300, 2920),
        ReadingWordTiming(22, 26, 2920, 3540),
        ReadingWordTiming(27, 31, 3540, 3880),
        ReadingWordTiming(32, 42, 3880, 6113),
      ],
  "audio/sureler/14_duha/05_ayet.mp3|وَلَسَوْفَ يُعْط۪يكَ رَبُّكَ فَتَـرْضٰى": [
    ReadingWordTiming(0, 10, 220, 1180),
    ReadingWordTiming(11, 20, 1180, 2700),
    ReadingWordTiming(21, 28, 2700, 3420),
    ReadingWordTiming(29, 39, 3420, 6103),
  ],
  "audio/sureler/14_duha/07_ayet.mp3|وَوَجَدَكَ ضَٓالًّا فَهَدٰىۖ": [
    ReadingWordTiming(0, 10, 0, 1700),
    ReadingWordTiming(11, 19, 1700, 5560),
    ReadingWordTiming(20, 28, 5560, 8833),
  ],
  "audio/sureler/14_duha/08_ayet.mp3|وَوَجَدَكَ عَٓائِلًا فَاَغْنٰىۜ": [
    ReadingWordTiming(0, 10, 220, 1320),
    ReadingWordTiming(11, 20, 1320, 3860),
    ReadingWordTiming(21, 31, 3860, 7153),
  ],
  "audio/sureler/14_duha/09_ayet.mp3|فَاَمَّا الْيَت۪يمَ فَلَا تَقْهَرْ": [
    ReadingWordTiming(0, 8, 20, 2540),
    ReadingWordTiming(9, 19, 2540, 3840),
    ReadingWordTiming(20, 25, 3840, 4220),
    ReadingWordTiming(26, 34, 4220, 6263),
  ],
  "audio/sureler/14_duha/10_ayet.mp3|وَاَمَّا السَّٓائِلَ فَلَا تَنْهَرْ": [
    ReadingWordTiming(0, 8, 20, 1900),
    ReadingWordTiming(9, 20, 1900, 4720),
    ReadingWordTiming(21, 26, 4720, 5300),
    ReadingWordTiming(27, 35, 5300, 7443),
  ],
  "audio/sureler/14_duha/11_ayet.mp3|وَاَمَّا بِنِعْمَةِ رَبِّكَ فَحَدِّثْ": [
    ReadingWordTiming(0, 8, 220, 2100),
    ReadingWordTiming(9, 19, 2100, 3680),
    ReadingWordTiming(20, 27, 3680, 4700),
    ReadingWordTiming(28, 37, 4700, 7673),
  ],
  "audio/sureler/15_insirah/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 280, 560),
        ReadingWordTiming(7, 14, 560, 760),
        ReadingWordTiming(15, 26, 760, 2260),
        ReadingWordTiming(27, 37, 2260, 4640),
      ],
  "audio/sureler/15_insirah/02_ayet.mp3|وَوَضَعْنَا عَنْكَ وِزْرَكَۙ": [
    ReadingWordTiming(0, 11, 0, 1660),
    ReadingWordTiming(12, 18, 1660, 3080),
    ReadingWordTiming(19, 28, 3080, 4843),
  ],
  "audio/sureler/15_insirah/03_ayet.mp3|اَلَّـذ۪ٓي اَنْقَضَ ظَهْرَكَۙ": [
    ReadingWordTiming(0, 10, 240, 1120),
    ReadingWordTiming(11, 19, 1120, 3920),
    ReadingWordTiming(20, 29, 3920, 5693),
  ],
  "audio/sureler/15_insirah/04_ayet.mp3|وَرَفَعْنَا لَكَ ذِكْرَكَ": [
    ReadingWordTiming(0, 11, 240, 1320),
    ReadingWordTiming(12, 16, 1320, 1980),
    ReadingWordTiming(17, 25, 1980, 4023),
  ],
  "audio/sureler/15_insirah/05_ayet.mp3|فَاِنَّ مَعَ الْعُسْرِ يُسْرًاۙ": [
    ReadingWordTiming(0, 7, 280, 700),
    ReadingWordTiming(8, 12, 700, 2400),
    ReadingWordTiming(13, 22, 2400, 3600),
    ReadingWordTiming(23, 31, 3600, 5613),
  ],
  "audio/sureler/15_insirah/06_ayet.mp3|اِنَّ مَعَ الْعُسْرِ يُسْرًاۜ": [
    ReadingWordTiming(0, 5, 0, 700),
    ReadingWordTiming(6, 10, 700, 1900),
    ReadingWordTiming(11, 20, 1900, 3220),
    ReadingWordTiming(21, 29, 3220, 5403),
  ],
  "audio/sureler/15_insirah/07_ayet.mp3|فَاِذَا فَرَغْتَ فَانْصَبْۙ": [
    ReadingWordTiming(0, 7, 0, 1380),
    ReadingWordTiming(8, 16, 1380, 2360),
    ReadingWordTiming(17, 27, 2360, 4633),
  ],
  "audio/sureler/15_insirah/08_ayet.mp3|وَاِلٰى رَبِّكَ فَارْغَبْ": [
    ReadingWordTiming(0, 7, 20, 1320),
    ReadingWordTiming(8, 15, 1320, 1940),
    ReadingWordTiming(16, 25, 1940, 4993),
  ],
  "audio/sureler/16_tin/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ": [
    ReadingWordTiming(0, 6, 280, 540),
    ReadingWordTiming(7, 14, 540, 760),
    ReadingWordTiming(15, 26, 760, 2240),
    ReadingWordTiming(27, 37, 2240, 4640),
  ],
  "audio/sureler/16_tin/01_ayet.mp3|وَالتّ۪ينِ وَالزَّيْتُونِۙ": [
    ReadingWordTiming(0, 10, 240, 980),
    ReadingWordTiming(11, 26, 980, 3880),
  ],
  "audio/sureler/16_tin/02_ayet.mp3|وَطُورِ س۪ين۪ينَۙ": [
    ReadingWordTiming(0, 7, 20, 1020),
    ReadingWordTiming(8, 17, 1020, 3400),
  ],
  "audio/sureler/16_tin/03_ayet.mp3|وَهٰذَا الْبَلَدِ الْاَم۪ينِۙ": [
    ReadingWordTiming(0, 7, 240, 900),
    ReadingWordTiming(8, 17, 900, 1980),
    ReadingWordTiming(18, 29, 1980, 4060),
  ],
  "audio/sureler/16_tin/04_ayet.mp3|لَقَدْ خَلَقْنَا الْاِنْسَانَ ف۪ٓي اَحْسَنِ تَقْو۪يمٍ":
      [
        ReadingWordTiming(0, 6, 240, 600),
        ReadingWordTiming(7, 16, 600, 1780),
        ReadingWordTiming(17, 29, 1780, 3420),
        ReadingWordTiming(30, 34, 3420, 3980),
        ReadingWordTiming(35, 43, 3980, 6320),
        ReadingWordTiming(44, 53, 6320, 8480),
      ],
  "audio/sureler/16_tin/05_ayet.mp3|ثُمَّ رَدَدْنَاهُ اَسْفَلَ سَافِل۪ينَۙ": [
    ReadingWordTiming(0, 5, 380, 760),
    ReadingWordTiming(6, 17, 760, 3440),
    ReadingWordTiming(18, 26, 3440, 4420),
    ReadingWordTiming(27, 38, 4420, 8113),
  ],
  "audio/sureler/16_tin/06_ayet.mp3|اِلَّا الَّذ۪ينَ اٰمَنُوا وَعَمِلُوا الصَّالِحَاتِ فَلَهُمْ اَجْرٌ غَيْرُ مَمْنُونٍ":
      [
        ReadingWordTiming(0, 6, 220, 580),
        ReadingWordTiming(7, 16, 580, 1160),
        ReadingWordTiming(17, 25, 1160, 2540),
        ReadingWordTiming(26, 36, 2540, 3500),
        ReadingWordTiming(37, 50, 3500, 5080),
        ReadingWordTiming(51, 59, 5080, 5880),
        ReadingWordTiming(60, 66, 5880, 6740),
        ReadingWordTiming(67, 73, 6740, 7680),
        ReadingWordTiming(74, 83, 7680, 10080),
      ],
  "audio/sureler/16_tin/07_ayet.mp3|فَمَا يُكَذِّبُكَ بَعْدُ بِالدّ۪ينِ": [
    ReadingWordTiming(0, 5, 300, 480),
    ReadingWordTiming(6, 17, 480, 2180),
    ReadingWordTiming(18, 24, 2180, 2640),
    ReadingWordTiming(25, 35, 2640, 5440),
  ],
  "audio/sureler/16_tin/08_ayet.mp3|اَلَيْسَ اللّٰهُ بِاَحْكَمِ الْحَاكِم۪ينَ":
      [
        ReadingWordTiming(0, 8, 20, 1260),
        ReadingWordTiming(9, 16, 1260, 1380),
        ReadingWordTiming(17, 27, 1380, 3400),
        ReadingWordTiming(28, 41, 3400, 6360),
      ],
  "audio/sureler/17_kadir/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 280, 560),
        ReadingWordTiming(7, 14, 560, 1080),
        ReadingWordTiming(15, 26, 1080, 2260),
        ReadingWordTiming(27, 37, 2260, 4640),
      ],
  "audio/sureler/17_kadir/01_ayet.mp3|اِنَّٓا اَنْزَلْنَاهُ ف۪ي لَيْلَةِ الْقَدْرِۚ":
      [
        ReadingWordTiming(0, 7, 240, 1840),
        ReadingWordTiming(8, 21, 1840, 5480),
        ReadingWordTiming(22, 25, 5480, 5740),
        ReadingWordTiming(26, 34, 5740, 6720),
        ReadingWordTiming(35, 45, 6720, 8593),
      ],
  "audio/sureler/17_kadir/02_ayet.mp3|وَمَٓا اَدْرٰيكَ مَا لَيْلَةُ الْقَدْرِ":
      [
        ReadingWordTiming(0, 6, 240, 520),
        ReadingWordTiming(7, 16, 520, 3660),
        ReadingWordTiming(17, 20, 3660, 3840),
        ReadingWordTiming(21, 29, 3840, 5060),
        ReadingWordTiming(30, 39, 5060, 7083),
      ],
  "audio/sureler/17_kadir/03_ayet.mp3|لَيْلَةُ الْقَدْرِ خَيْرٌ مِنْ اَلْفِ شَهْرٍ":
      [
        ReadingWordTiming(0, 8, 0, 1300),
        ReadingWordTiming(9, 18, 1300, 2380),
        ReadingWordTiming(19, 25, 2380, 3100),
        ReadingWordTiming(26, 30, 3100, 3320),
        ReadingWordTiming(31, 37, 3320, 4420),
        ReadingWordTiming(38, 44, 4420, 7213),
      ],
  "audio/sureler/17_kadir/04_ayet.mp3|تَنَزَّلُ الْمَلٰٓئِكَةُ وَالرُّوحُ ف۪يهَا بِاِذْنِ رَبِّهِمْۚ مِنْ كُلِّ اَمْرٍۙۛ":
      [
        ReadingWordTiming(0, 9, 20, 1500),
        ReadingWordTiming(10, 24, 1500, 4760),
        ReadingWordTiming(25, 35, 4760, 6000),
        ReadingWordTiming(36, 42, 6000, 6820),
        ReadingWordTiming(43, 51, 6820, 7960),
        ReadingWordTiming(52, 62, 7960, 8700),
        ReadingWordTiming(63, 67, 8700, 10180),
        ReadingWordTiming(68, 73, 10180, 11000),
        ReadingWordTiming(74, 82, 11000, 13080),
      ],
  "audio/sureler/17_kadir/05_ayet.mp3|سَلَامٌۛ هِيَ حَتّٰى مَطْلَعِ الْفَجْرِ":
      [
        ReadingWordTiming(0, 8, 0, 680),
        ReadingWordTiming(9, 13, 680, 3040),
        ReadingWordTiming(14, 20, 3040, 3680),
        ReadingWordTiming(21, 29, 3680, 4920),
        ReadingWordTiming(30, 39, 4920, 7074),
      ],
  "audio/sureler/18_zilzal/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 280, 560),
        ReadingWordTiming(7, 14, 560, 760),
        ReadingWordTiming(15, 26, 760, 2240),
        ReadingWordTiming(27, 37, 2240, 4640),
      ],
  "audio/sureler/18_zilzal/01_ayet.mp3|اِذَا زُلْزِلَتِ الْاَرْضُ زِلْزَالَهَاۙ":
      [
        ReadingWordTiming(0, 5, 20, 1020),
        ReadingWordTiming(6, 16, 1020, 2240),
        ReadingWordTiming(17, 26, 2240, 3180),
        ReadingWordTiming(27, 40, 3180, 5863),
      ],
  "audio/sureler/18_zilzal/02_ayet.mp3|وَاَخْرَجَتِ الْاَرْضُ اَثْقَالَهَاۙ": [
    ReadingWordTiming(0, 12, 240, 1480),
    ReadingWordTiming(13, 22, 1480, 2400),
    ReadingWordTiming(23, 36, 2400, 5283),
  ],
  "audio/sureler/18_zilzal/03_ayet.mp3|وَقَالَ الْاِنْسَانُ مَا لَهَاۚ": [
    ReadingWordTiming(0, 7, 20, 980),
    ReadingWordTiming(8, 20, 980, 3280),
    ReadingWordTiming(21, 24, 3280, 3640),
    ReadingWordTiming(25, 31, 3640, 6123),
  ],
  "audio/sureler/18_zilzal/04_ayet.mp3|يَوْمَئِذٍ تُحَدِّثُ اَخْبَارَهَاۙ": [
    ReadingWordTiming(0, 10, 240, 1180),
    ReadingWordTiming(11, 20, 1180, 2820),
    ReadingWordTiming(21, 34, 2820, 6433),
  ],
  "audio/sureler/18_zilzal/05_ayet.mp3|بِاَنَّ رَبَّكَ اَوْحٰى لَهَا": [
    ReadingWordTiming(0, 7, 260, 700),
    ReadingWordTiming(8, 15, 700, 3220),
    ReadingWordTiming(16, 23, 3220, 4320),
    ReadingWordTiming(24, 29, 4320, 6433),
  ],
  "audio/sureler/18_zilzal/06_ayet.mp3|يَوْمَئِذٍ يَصْدُرُ النَّاسُ اَشْتَاتًا لِيُرَوْا اَعْمَالَهُمْۜ":
      [
        ReadingWordTiming(0, 10, 320, 1220),
        ReadingWordTiming(11, 19, 1220, 2780),
        ReadingWordTiming(20, 28, 2780, 4300),
        ReadingWordTiming(29, 39, 4300, 5620),
        ReadingWordTiming(40, 49, 5620, 6260),
        ReadingWordTiming(50, 64, 6260, 9493),
      ],
  "audio/sureler/18_zilzal/07_ayet.mp3|فَمَنْ يَعْمَلْ مِثْقَالَ ذَرَّةٍ خَيْرًا يَرَهُۜ":
      [
        ReadingWordTiming(0, 6, 20, 820),
        ReadingWordTiming(7, 15, 820, 2140),
        ReadingWordTiming(16, 25, 2140, 3340),
        ReadingWordTiming(26, 33, 3340, 3900),
        ReadingWordTiming(34, 41, 3900, 5620),
        ReadingWordTiming(42, 49, 5620, 7613),
      ],
  "audio/sureler/18_zilzal/08_ayet.mp3|وَمَنْ يَعْمَلْ مِثْقَالَ ذَرَّةٍ شَرًّا يَرَهُ":
      [
        ReadingWordTiming(0, 6, 240, 680),
        ReadingWordTiming(7, 15, 680, 2060),
        ReadingWordTiming(16, 25, 2060, 3340),
        ReadingWordTiming(26, 33, 3340, 3800),
        ReadingWordTiming(34, 40, 3800, 5760),
        ReadingWordTiming(41, 47, 5760, 8363),
      ],
  "audio/sureler/19_adiyat/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 280, 560),
        ReadingWordTiming(7, 14, 560, 1080),
        ReadingWordTiming(15, 26, 1080, 2260),
        ReadingWordTiming(27, 37, 2260, 4660),
      ],
  "audio/sureler/19_adiyat/01_ayet.mp3|وَالْعَادِيَاتِ ضَبْحًاۙ": [
    ReadingWordTiming(0, 15, 780, 2200),
    ReadingWordTiming(16, 24, 2200, 4093),
  ],
  "audio/sureler/19_adiyat/02_ayet.mp3|فَالْمُورِيَاتِ قَدْحًاۙ": [
    ReadingWordTiming(0, 15, 20, 2200),
    ReadingWordTiming(16, 24, 2200, 3943),
  ],
  "audio/sureler/19_adiyat/03_ayet.mp3|فَالْمُغ۪يرَاتِ صُبْحًاۙ": [
    ReadingWordTiming(0, 15, 20, 2300),
    ReadingWordTiming(16, 24, 2300, 4253),
  ],
  "audio/sureler/19_adiyat/04_ayet.mp3|فَاَثَرْنَ بِه۪ نَقْعًاۙ": [
    ReadingWordTiming(0, 10, 340, 1320),
    ReadingWordTiming(11, 15, 1320, 1440),
    ReadingWordTiming(16, 24, 1440, 4073),
  ],
  "audio/sureler/19_adiyat/05_ayet.mp3|فَوَسَطْنَ بِه۪ جَمْعًاۙ": [
    ReadingWordTiming(0, 10, 0, 1560),
    ReadingWordTiming(11, 15, 1560, 1860),
    ReadingWordTiming(16, 24, 1860, 4603),
  ],
  "audio/sureler/19_adiyat/06_ayet.mp3|اِنَّ الْاِنْسَانَ لِرَبِّه۪ لَكَنُودٌۚ":
      [
        ReadingWordTiming(0, 5, 240, 660),
        ReadingWordTiming(6, 18, 660, 3480),
        ReadingWordTiming(19, 28, 3480, 4720),
        ReadingWordTiming(29, 39, 4720, 8233),
      ],
  "audio/sureler/19_adiyat/07_ayet.mp3|وَاِنَّهُ عَلٰى ذٰلِكَ لَشَه۪يدٌۚ": [
    ReadingWordTiming(0, 9, 240, 2460),
    ReadingWordTiming(10, 15, 2460, 3020),
    ReadingWordTiming(16, 22, 3020, 4500),
    ReadingWordTiming(23, 33, 4500, 7733),
  ],
  "audio/sureler/19_adiyat/08_ayet.mp3|وَاِنَّهُ لِحُبِّ الْخَيْرِ لَشَد۪يدٌ": [
    ReadingWordTiming(0, 9, 240, 2080),
    ReadingWordTiming(10, 17, 2080, 3160),
    ReadingWordTiming(18, 27, 3160, 4360),
    ReadingWordTiming(28, 37, 4360, 7503),
  ],
  "audio/sureler/19_adiyat/09_ayet.mp3|اَفَلَا يَعْلَمُ اِذَا بُعْثِرَ مَا فِي الْقُبُورِۙ":
      [
        ReadingWordTiming(0, 7, 20, 1100),
        ReadingWordTiming(8, 16, 1100, 2140),
        ReadingWordTiming(17, 22, 2140, 2780),
        ReadingWordTiming(23, 31, 2780, 3240),
        ReadingWordTiming(32, 35, 3240, 4220),
        ReadingWordTiming(36, 39, 4220, 4840),
        ReadingWordTiming(40, 51, 4840, 7523),
      ],
  "audio/sureler/19_adiyat/10_ayet.mp3|وَحُصِّلَ مَا فِي الصُّدُورِۙ": [
    ReadingWordTiming(0, 9, 520, 1160),
    ReadingWordTiming(10, 13, 1160, 1640),
    ReadingWordTiming(14, 17, 1640, 2260),
    ReadingWordTiming(18, 29, 2260, 5213),
  ],
  "audio/sureler/19_adiyat/11_ayet.mp3|اِنَّ رَبَّهُمْ بِهِمْ يَوْمَئِذٍ لَخَب۪يرٌ":
      [
        ReadingWordTiming(0, 5, 20, 860),
        ReadingWordTiming(6, 15, 860, 2640),
        ReadingWordTiming(16, 22, 2640, 4260),
        ReadingWordTiming(23, 33, 4260, 5660),
        ReadingWordTiming(34, 43, 5660, 10203),
      ],
  "audio/sureler/20_karia/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 280, 560),
        ReadingWordTiming(7, 14, 560, 1100),
        ReadingWordTiming(15, 26, 1100, 2260),
        ReadingWordTiming(27, 37, 2260, 4660),
      ],
  "audio/sureler/20_karia/01_ayet.mp3|اَلْقَارِعَةُۙ": [
    ReadingWordTiming(0, 14, 240, 2343),
  ],
  "audio/sureler/20_karia/02_ayet.mp3|مَا الْقَارِعَةُۚ": [
    ReadingWordTiming(0, 3, 20, 780),
    ReadingWordTiming(4, 17, 780, 2793),
  ],
  "audio/sureler/20_karia/03_ayet.mp3|وَمَٓا اَدْرٰيكَ مَا الْقَارِعَةُۜ": [
    ReadingWordTiming(0, 6, 20, 940),
    ReadingWordTiming(7, 16, 940, 3680),
    ReadingWordTiming(17, 20, 3680, 3900),
    ReadingWordTiming(21, 34, 3900, 6313),
  ],
  "audio/sureler/20_karia/04_ayet.mp3|يَوْمَ يَكُونُ النَّاسُ كَالْفَرَاشِ الْمَبْثُوثِۙ":
      [
        ReadingWordTiming(0, 6, 0, 900),
        ReadingWordTiming(7, 14, 900, 1620),
        ReadingWordTiming(15, 23, 1620, 3320),
        ReadingWordTiming(24, 36, 3320, 4820),
        ReadingWordTiming(37, 50, 4820, 8453),
      ],
  "audio/sureler/20_karia/05_ayet.mp3|وَتَكُونُ الْجِبَالُ كَالْعِهْنِ الْمَنْفُوشِۜ":
      [
        ReadingWordTiming(0, 9, 580, 1200),
        ReadingWordTiming(10, 20, 1200, 2700),
        ReadingWordTiming(21, 32, 2700, 3820),
        ReadingWordTiming(33, 46, 3820, 7793),
      ],
  "audio/sureler/20_karia/06_ayet.mp3|فَاَمَّا مَنْ ثَقُلَتْ مَوَاز۪ينُهُۙ": [
    ReadingWordTiming(0, 8, 0, 2240),
    ReadingWordTiming(9, 13, 2240, 2520),
    ReadingWordTiming(14, 22, 2520, 4420),
    ReadingWordTiming(23, 36, 4420, 7043),
  ],
  "audio/sureler/20_karia/07_ayet.mp3|فَهُوَ ف۪ي ع۪يشَةٍ رَاضِيَةٍ": [
    ReadingWordTiming(0, 6, 20, 1120),
    ReadingWordTiming(7, 10, 1120, 1200),
    ReadingWordTiming(11, 18, 1200, 2620),
    ReadingWordTiming(19, 28, 2620, 5123),
  ],
  "audio/sureler/20_karia/08_ayet.mp3|وَاَمَّا مَنْ خَفَّتْ مَوَاز۪ينُهُۙ": [
    ReadingWordTiming(0, 8, 20, 2360),
    ReadingWordTiming(9, 13, 2360, 2980),
    ReadingWordTiming(14, 21, 2980, 3960),
    ReadingWordTiming(22, 35, 3960, 6743),
  ],
  "audio/sureler/20_karia/09_ayet.mp3|فَاُمُّهُ هَاوِيَةٌ": [
    ReadingWordTiming(0, 9, 20, 2360),
    ReadingWordTiming(10, 19, 2360, 5153),
  ],
  "audio/sureler/20_karia/10_ayet.mp3|وَمَٓا اَدْرٰيكَ مَا هِيَهْ": [
    ReadingWordTiming(0, 6, 220, 500),
    ReadingWordTiming(7, 16, 500, 3440),
    ReadingWordTiming(17, 20, 3440, 3600),
    ReadingWordTiming(21, 27, 3600, 5503),
  ],
  "audio/sureler/20_karia/11_ayet.mp3|نَارٌ حَامِيَةٌ": [
    ReadingWordTiming(0, 5, 280, 1180),
    ReadingWordTiming(6, 15, 1180, 3563),
  ],
  "audio/sureler/21_tekasur/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 280, 560),
        ReadingWordTiming(7, 14, 560, 1080),
        ReadingWordTiming(15, 26, 1080, 2260),
        ReadingWordTiming(27, 37, 2260, 4660),
      ],
  "audio/sureler/21_tekasur/01_ayet.mp3|اَلْهٰيكُمُ التَّكَاثُرُۙ": [
    ReadingWordTiming(0, 11, 20, 1300),
    ReadingWordTiming(12, 25, 1300, 3473),
  ],
  "audio/sureler/21_tekasur/02_ayet.mp3|حَتّٰى زُرْتُمُ الْمَقَابِرَ": [
    ReadingWordTiming(0, 6, 20, 1300),
    ReadingWordTiming(7, 15, 1300, 2140),
    ReadingWordTiming(16, 28, 2140, 4574),
  ],
  "audio/sureler/21_tekasur/03_ayet.mp3|كَلَّا سَوْفَ تَعْلَمُونَۙ": [
    ReadingWordTiming(0, 6, 240, 420),
    ReadingWordTiming(7, 13, 420, 1580),
    ReadingWordTiming(14, 26, 1580, 4723),
  ],
  "audio/sureler/21_tekasur/04_ayet.mp3|ثُمَّ كَلَّا سَوْفَ تَعْلَمُونَ": [
    ReadingWordTiming(0, 5, 20, 1000),
    ReadingWordTiming(6, 12, 1000, 2320),
    ReadingWordTiming(13, 19, 2320, 3480),
    ReadingWordTiming(20, 31, 3480, 6853),
  ],
  "audio/sureler/21_tekasur/05_ayet.mp3|كَلَّا لَوْ تَعْلَمُونَ عِلْمَ الْيَق۪ينِ":
      [
        ReadingWordTiming(0, 6, 20, 1060),
        ReadingWordTiming(7, 11, 1060, 1520),
        ReadingWordTiming(12, 23, 1520, 3480),
        ReadingWordTiming(24, 30, 3480, 4220),
        ReadingWordTiming(31, 41, 4220, 7133),
      ],
  "audio/sureler/21_tekasur/06_ayet.mp3|لَتَرَوُنَّ الْجَح۪يمَۙ": [
    ReadingWordTiming(0, 11, 40, 1880),
    ReadingWordTiming(12, 23, 1880, 6323),
  ],
  "audio/sureler/21_tekasur/07_ayet.mp3|ثُمَّ لَتَرَوُنَّهَا عَيْنَ الْيَق۪ينِۙ":
      [
        ReadingWordTiming(0, 5, 20, 1120),
        ReadingWordTiming(6, 20, 1120, 2880),
        ReadingWordTiming(21, 27, 2880, 5040),
        ReadingWordTiming(28, 39, 5040, 8203),
      ],
  "audio/sureler/21_tekasur/08_ayet.mp3|ثُمَّ لَتُسْـَٔلُنَّ يَوْمَئِذٍ عَنِ النَّع۪يمِ":
      [
        ReadingWordTiming(0, 5, 0, 980),
        ReadingWordTiming(6, 20, 980, 3220),
        ReadingWordTiming(21, 31, 3220, 5940),
        ReadingWordTiming(32, 36, 5940, 6320),
        ReadingWordTiming(37, 47, 6320, 11153),
      ],
  "audio/sureler/22_asr/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ": [
    ReadingWordTiming(0, 6, 280, 560),
    ReadingWordTiming(7, 14, 560, 1080),
    ReadingWordTiming(15, 26, 1080, 2260),
    ReadingWordTiming(27, 37, 2260, 4660),
  ],
  "audio/sureler/22_asr/01_ayet.mp3|وَالْعَصْرِۙ": [
    ReadingWordTiming(0, 12, 220, 1260),
  ],
  "audio/sureler/22_asr/02_ayet.mp3|اِنَّ الْاِنْسَانَ لَف۪ي خُسْرٍۙ": [
    ReadingWordTiming(0, 5, 20, 840),
    ReadingWordTiming(6, 18, 840, 3720),
    ReadingWordTiming(19, 24, 3720, 4220),
    ReadingWordTiming(25, 32, 4220, 5440),
  ],
  "audio/sureler/22_asr/03_ayet.mp3|اِلَّا الَّذ۪ينَ اٰمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ":
      [
        ReadingWordTiming(0, 6, 140, 500),
        ReadingWordTiming(7, 16, 500, 1120),
        ReadingWordTiming(17, 25, 1120, 2300),
        ReadingWordTiming(26, 36, 2300, 3220),
        ReadingWordTiming(37, 50, 3220, 4600),
        ReadingWordTiming(51, 63, 4600, 6120),
        ReadingWordTiming(64, 74, 6120, 7120),
        ReadingWordTiming(75, 87, 7120, 8760),
        ReadingWordTiming(88, 99, 8760, 9860),
      ],
  "audio/sureler/23_humeze/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 280, 560),
        ReadingWordTiming(7, 14, 560, 1080),
        ReadingWordTiming(15, 26, 1080, 2260),
        ReadingWordTiming(27, 37, 2260, 4640),
      ],
  "audio/sureler/23_humeze/01_ayet.mp3|وَيْلٌ لِكُلِّ هُمَزَةٍ لُمَزَةٍۙ": [
    ReadingWordTiming(0, 6, 0, 820),
    ReadingWordTiming(7, 14, 820, 1580),
    ReadingWordTiming(15, 23, 1580, 2860),
    ReadingWordTiming(24, 33, 2860, 5043),
  ],
  "audio/sureler/23_humeze/02_ayet.mp3|اَلَّذ۪ى جَمَعَ مَالًا وَعَدَّدَهُۙ": [
    ReadingWordTiming(0, 8, 240, 700),
    ReadingWordTiming(9, 15, 700, 1700),
    ReadingWordTiming(16, 22, 1700, 2440),
    ReadingWordTiming(23, 35, 2440, 5333),
  ],
  "audio/sureler/23_humeze/03_ayet.mp3|يَحْسَبُ اَنَّ مَالَـهُٓ اَخْلَدَهُۚ": [
    ReadingWordTiming(0, 8, 240, 820),
    ReadingWordTiming(9, 14, 820, 1360),
    ReadingWordTiming(15, 24, 1360, 3360),
    ReadingWordTiming(25, 36, 3360, 7253),
  ],
  "audio/sureler/23_humeze/04_ayet.mp3|كَلَّا لَيُنْبَذَنَّ فِي الْحُطَمَةِ": [
    ReadingWordTiming(0, 6, 0, 860),
    ReadingWordTiming(7, 20, 860, 3360),
    ReadingWordTiming(21, 24, 3360, 4420),
    ReadingWordTiming(25, 36, 4420, 6663),
  ],
  "audio/sureler/23_humeze/05_ayet.mp3|وَمَٓا اَدْرٰيكَ مَا الْحُطَمَةُ": [
    ReadingWordTiming(0, 6, 240, 500),
    ReadingWordTiming(7, 16, 500, 3580),
    ReadingWordTiming(17, 20, 3580, 3740),
    ReadingWordTiming(21, 32, 3740, 5834),
  ],
  "audio/sureler/23_humeze/06_ayet.mp3|نَارُ اللّٰهِ الْمُوقَدَةُۙ": [
    ReadingWordTiming(0, 5, 300, 1020),
    ReadingWordTiming(6, 13, 1020, 1120),
    ReadingWordTiming(14, 27, 1120, 4673),
  ],
  "audio/sureler/23_humeze/07_ayet.mp3|اَلَّت۪ي تَطَّلِعُ عَلَى الْاَفْـِٔدَةِ":
      [
        ReadingWordTiming(0, 8, 20, 1060),
        ReadingWordTiming(9, 18, 1060, 2340),
        ReadingWordTiming(19, 24, 2340, 2560),
        ReadingWordTiming(25, 39, 2560, 5173),
      ],
  "audio/sureler/23_humeze/08_ayet.mp3|اِنَّهَا عَلَيْهِمْ مُؤْصَدَةٌۙ": [
    ReadingWordTiming(0, 8, 20, 2240),
    ReadingWordTiming(9, 19, 2240, 3900),
    ReadingWordTiming(20, 31, 3900, 6953),
  ],
  "audio/sureler/23_humeze/09_ayet.mp3|ف۪ي عَمَدٍ مُمَدَّدَةٍ": [
    ReadingWordTiming(0, 3, 0, 820),
    ReadingWordTiming(4, 10, 820, 1560),
    ReadingWordTiming(11, 22, 1560, 4813),
  ],
  "audio/sureler/24_amenerrasulu/00_besmele.mp3|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ":
      [
        ReadingWordTiming(0, 6, 20, 260),
        ReadingWordTiming(7, 14, 260, 500),
        ReadingWordTiming(15, 26, 500, 1920),
        ReadingWordTiming(27, 37, 1920, 5150),
      ],
  "audio/sureler/24_amenerrasulu/01_ayet.mp3|اٰمَنَ الرَّسُولُ بِمَٓا اُنْزِلَ اِلَيْهِ مِنْ رَبِّه۪ وَالْمُؤْمِنُونَۜ":
      [
        ReadingWordTiming(0, 6, 20, 760),
        ReadingWordTiming(7, 17, 760, 2000),
        ReadingWordTiming(18, 24, 2000, 2540),
        ReadingWordTiming(25, 33, 2540, 5700),
        ReadingWordTiming(34, 42, 5700, 6540),
        ReadingWordTiming(43, 47, 6540, 7080),
        ReadingWordTiming(48, 55, 7080, 8180),
        ReadingWordTiming(56, 73, 8180, 11810),
      ],
  "audio/sureler/24_amenerrasulu/02_ayet.mp3|كُلٌّ اٰمَنَ بِاللّٰهِ وَمَلٰٓئِكَتِه۪ وَكُتُبِه۪ وَرُسُلِه۪ۜ":
      [
        ReadingWordTiming(0, 5, 20, 200),
        ReadingWordTiming(6, 12, 200, 700),
        ReadingWordTiming(13, 22, 700, 2720),
        ReadingWordTiming(23, 38, 2720, 5560),
        ReadingWordTiming(39, 49, 5560, 7760),
        ReadingWordTiming(50, 61, 7760, 9610),
      ],
  "audio/sureler/24_amenerrasulu/03_ayet.mp3|لَا نُفَرِّقُ بَيْنَ اَحَدٍ مِنْ رُسُلِه۪۠":
      [
        ReadingWordTiming(0, 3, 20, 240),
        ReadingWordTiming(4, 13, 240, 1440),
        ReadingWordTiming(14, 20, 1440, 1760),
        ReadingWordTiming(21, 27, 1760, 3100),
        ReadingWordTiming(28, 32, 3100, 4820),
        ReadingWordTiming(33, 42, 4820, 6360),
      ],
  "audio/sureler/24_amenerrasulu/04_ayet.mp3|وَقَالُوا سَمِعْنَا وَاَطَعْنَا": [
    ReadingWordTiming(0, 9, 20, 1360),
    ReadingWordTiming(10, 19, 1360, 2480),
    ReadingWordTiming(20, 31, 2480, 4640),
  ],
  "audio/sureler/24_amenerrasulu/05_ayet.mp3|غُفْرَانَكَ رَبَّنَا وَاِلَيْكَ الْمَص۪يرُ":
      [
        ReadingWordTiming(0, 11, 20, 1400),
        ReadingWordTiming(12, 20, 1400, 2400),
        ReadingWordTiming(21, 31, 2400, 4200),
        ReadingWordTiming(32, 42, 4200, 6970),
      ],
  "audio/sureler/24_amenerrasulu/06_ayet.mp3|لَا يُكَلِّفُ اللّٰهُ نَفْسًا اِلَّا وُسْعَهَاۜ":
      [
        ReadingWordTiming(0, 3, 20, 240),
        ReadingWordTiming(4, 13, 240, 1540),
        ReadingWordTiming(14, 21, 1540, 1780),
        ReadingWordTiming(22, 29, 1780, 3720),
        ReadingWordTiming(30, 36, 3720, 4140),
        ReadingWordTiming(37, 47, 4140, 6700),
      ],
  "audio/sureler/24_amenerrasulu/07_ayet.mp3|لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْۜ":
      [
        ReadingWordTiming(0, 5, 20, 460),
        ReadingWordTiming(6, 9, 460, 1080),
        ReadingWordTiming(10, 18, 1080, 2420),
        ReadingWordTiming(19, 30, 2420, 3760),
        ReadingWordTiming(31, 34, 3760, 4280),
        ReadingWordTiming(35, 47, 4280, 5720),
      ],
  "audio/sureler/24_amenerrasulu/08_ayet.mp3|رَبَّنَا لَا تُؤَاخِذْنَٓا اِنْ نَس۪ينَٓا اَوْ اَخْطَأْنَاۚ":
      [
        ReadingWordTiming(0, 8, 20, 200),
        ReadingWordTiming(9, 12, 200, 780),
        ReadingWordTiming(13, 26, 780, 2980),
        ReadingWordTiming(27, 31, 2980, 4660),
        ReadingWordTiming(32, 41, 4660, 6820),
        ReadingWordTiming(42, 46, 6820, 9000),
        ReadingWordTiming(47, 59, 9000, 10840),
      ],
  "audio/sureler/24_amenerrasulu/09_ayet.mp3|رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَٓا اِصْرًا":
      [
        ReadingWordTiming(0, 8, 20, 200),
        ReadingWordTiming(9, 14, 200, 620),
        ReadingWordTiming(15, 23, 620, 2380),
        ReadingWordTiming(24, 34, 2380, 2640),
        ReadingWordTiming(35, 42, 2640, 7080),
      ],
  "audio/sureler/24_amenerrasulu/10_ayet.mp3|كَمَا حَمَلْتَهُ عَلَى الَّذ۪ينَ مِنْ قَبْلِنَاۚ":
      [
        ReadingWordTiming(0, 5, 20, 300),
        ReadingWordTiming(6, 16, 300, 1640),
        ReadingWordTiming(17, 22, 1640, 1900),
        ReadingWordTiming(23, 32, 1900, 4040),
        ReadingWordTiming(33, 37, 4040, 4320),
        ReadingWordTiming(38, 48, 4320, 6930),
      ],
  "audio/sureler/24_amenerrasulu/11_ayet.mp3|رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِه۪ۚ":
      [
        ReadingWordTiming(0, 8, 20, 200),
        ReadingWordTiming(9, 14, 200, 620),
        ReadingWordTiming(15, 27, 620, 3940),
        ReadingWordTiming(28, 31, 3940, 4580),
        ReadingWordTiming(32, 35, 4580, 5300),
        ReadingWordTiming(36, 43, 5300, 6360),
        ReadingWordTiming(44, 49, 6360, 7120),
        ReadingWordTiming(50, 55, 7120, 8460),
      ],
  "audio/sureler/24_amenerrasulu/12_ayet.mp3|وَاعْفُ عَنَّا۠": [
    ReadingWordTiming(0, 7, 180, 880),
    ReadingWordTiming(8, 15, 880, 3623),
  ],
  "audio/sureler/24_amenerrasulu/13_ayet.mp3|وَاغْفِرْ لَنَا۠": [
    ReadingWordTiming(0, 9, 100, 1020),
    ReadingWordTiming(10, 16, 1020, 2438),
  ],
  "audio/sureler/24_amenerrasulu/14_ayet.mp3|وَارْحَمْنَا۠": [
    ReadingWordTiming(0, 13, 0, 2415),
  ],
  "audio/sureler/24_amenerrasulu/15_ayet.mp3|اَنْتَ مَوْلٰينَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِر۪ينَ":
      [
        ReadingWordTiming(0, 6, 340, 1820),
        ReadingWordTiming(7, 17, 1820, 3400),
        ReadingWordTiming(18, 30, 3400, 6260),
        ReadingWordTiming(31, 36, 6260, 6800),
        ReadingWordTiming(37, 46, 6800, 7980),
        ReadingWordTiming(47, 60, 7980, 11160),
      ],
  "audio/dualar/01_subhaneke/subhaneke1.mp3|سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَِ":
      [
        ReadingWordTiming(0, 11, 60, 800),
        ReadingWordTiming(12, 22, 800, 1320),
        ReadingWordTiming(23, 36, 1320, 3560),
      ],
  "audio/dualar/01_subhaneke/subhaneke2.mp3|وَتَبَارَكَ اسْمُكَ": [
    ReadingWordTiming(0, 11, 20, 1100),
    ReadingWordTiming(12, 19, 1100, 1652),
  ],
  "audio/dualar/01_subhaneke/subhaneke3.mp3|وَتَعَالَى جَدُّكَ ": [
    ReadingWordTiming(0, 10, 0, 740),
    ReadingWordTiming(11, 18, 740, 1818),
  ],
  "audio/dualar/01_subhaneke/subhaneke4.mp3|وَلاَ إِلَهَ غَيْرُكَ": [
    ReadingWordTiming(0, 5, 40, 760),
    ReadingWordTiming(6, 12, 760, 1400),
    ReadingWordTiming(13, 21, 1400, 2919),
  ],
  "audio/dualar/02_ettahiyatu/etahiyyat-02.mp3|السَّلامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ":
      [
        ReadingWordTiming(0, 9, 0, 520),
        ReadingWordTiming(10, 18, 520, 1400),
        ReadingWordTiming(19, 27, 1400, 2040),
        ReadingWordTiming(28, 38, 2040, 2760),
        ReadingWordTiming(39, 49, 2760, 4060),
        ReadingWordTiming(50, 57, 4060, 4140),
        ReadingWordTiming(58, 71, 4140, 6720),
      ],
  "audio/dualar/02_ettahiyatu/etahiyyat-04.mp3|أَشْهَدُ أَنْ لا إِلَهَ إِلا اللَّ":
      [
        ReadingWordTiming(0, 8, 0, 420),
        ReadingWordTiming(9, 13, 420, 620),
        ReadingWordTiming(14, 16, 620, 1100),
        ReadingWordTiming(17, 23, 1100, 1880),
        ReadingWordTiming(24, 28, 1880, 1920),
        ReadingWordTiming(29, 34, 1920, 4290),
      ],
  "audio/dualar/02_ettahiyatu/etahiyyat-05.mp3|وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ":
      [
        ReadingWordTiming(0, 10, 0, 560),
        ReadingWordTiming(11, 16, 560, 920),
        ReadingWordTiming(17, 27, 920, 2260),
        ReadingWordTiming(28, 36, 2260, 3300),
        ReadingWordTiming(37, 48, 3300, 5000),
      ],
  "audio/dualar/03_salli/salli-01.mp3|اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ ُ":
      [
        ReadingWordTiming(0, 10, 220, 700),
        ReadingWordTiming(11, 16, 700, 1660),
        ReadingWordTiming(17, 22, 1660, 1680),
        ReadingWordTiming(23, 32, 1680, 3020),
        ReadingWordTiming(33, 40, 3020, 3800),
        ReadingWordTiming(41, 44, 3800, 4800),
        ReadingWordTiming(45, 54, 4800, 5640),
        ReadingWordTiming(55, 56, 5640, 6020),
      ],
  "audio/dualar/03_salli/salli-02.mp3|كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمُ":
      [
        ReadingWordTiming(0, 5, 80, 440),
        ReadingWordTiming(6, 15, 440, 1200),
        ReadingWordTiming(16, 21, 1200, 1320),
        ReadingWordTiming(22, 34, 1320, 2660),
        ReadingWordTiming(35, 42, 2660, 3220),
        ReadingWordTiming(43, 46, 3220, 3240),
        ReadingWordTiming(47, 59, 3240, 5280),
      ],
  "audio/dualar/03_salli/salli-03.mp3| إِنَّكَ حَمِيدٌ مَجِيدٌَ": [
    ReadingWordTiming(1, 8, 80, 900),
    ReadingWordTiming(9, 16, 900, 1800),
    ReadingWordTiming(17, 25, 1800, 4320),
  ],
  "audio/dualar/04_barik/barik-02.mp3|كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيم ":
      [
        ReadingWordTiming(0, 5, 140, 420),
        ReadingWordTiming(6, 15, 420, 1320),
        ReadingWordTiming(16, 21, 1320, 1460),
        ReadingWordTiming(22, 34, 1460, 2940),
        ReadingWordTiming(35, 42, 2940, 3560),
        ReadingWordTiming(43, 46, 3560, 3620),
        ReadingWordTiming(47, 58, 3620, 5740),
      ],
  "audio/dualar/04_barik/barik-03.mp3| إِنَّكَ حَمِيدٌ مَجِيدٌٌَ": [
    ReadingWordTiming(1, 8, 80, 1360),
    ReadingWordTiming(9, 16, 1360, 2260),
    ReadingWordTiming(17, 26, 2260, 4660),
  ],
  "audio/dualar/05_atina/atina-01.mp3|رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةًٍ":
      [
        ReadingWordTiming(0, 8, 360, 520),
        ReadingWordTiming(9, 15, 520, 1780),
        ReadingWordTiming(16, 19, 1780, 2140),
        ReadingWordTiming(20, 30, 2140, 3260),
        ReadingWordTiming(31, 39, 3260, 4040),
        ReadingWordTiming(40, 45, 4040, 4860),
        ReadingWordTiming(46, 55, 4860, 5680),
        ReadingWordTiming(56, 65, 5680, 6860),
      ],
  "audio/dualar/05_atina/atina-02.mp3| وَقِنَا عَذَابَ النَّارِ ": [
    ReadingWordTiming(1, 8, 100, 740),
    ReadingWordTiming(9, 16, 740, 1840),
    ReadingWordTiming(17, 25, 1840, 3980),
  ],
  "audio/dualar/06_rabbenafirli/5-RABBENAGFIRLI.mp3|رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابًٍُ":
      [
        ReadingWordTiming(0, 8, 480, 640),
        ReadingWordTiming(9, 16, 640, 1500),
        ReadingWordTiming(17, 20, 1500, 1780),
        ReadingWordTiming(21, 35, 1780, 3060),
        ReadingWordTiming(36, 53, 3060, 4780),
        ReadingWordTiming(54, 60, 4780, 5440),
        ReadingWordTiming(61, 68, 5440, 6340),
        ReadingWordTiming(69, 81, 6340, 8900),
      ],
  "audio/dualar/07_kunut1/kunut_1-01.mp3|اَللَّهُمَّ إِنَّا نَسْتَعِينُكَ وَ نَسْتَغْفِرُكَ وَ نَسْتَهْدِيكَ":
      [
        ReadingWordTiming(0, 11, 0, 420),
        ReadingWordTiming(12, 18, 420, 1360),
        ReadingWordTiming(19, 32, 1360, 3160),
        ReadingWordTiming(33, 35, 3160, 3320),
        ReadingWordTiming(36, 50, 3320, 4320),
        ReadingWordTiming(51, 53, 4320, 4800),
        ReadingWordTiming(54, 67, 4800, 6640),
      ],
  "audio/dualar/07_kunut1/kunut_1-02.mp3| وَ نُؤْمِنُ بِكَ وَ نَتُوبُ اِلَيْكَ   وَ نَتَوَكَّلُ عَلَيْكَ ":
      [
        ReadingWordTiming(1, 3, 0, 120),
        ReadingWordTiming(4, 12, 120, 620),
        ReadingWordTiming(13, 17, 620, 1060),
        ReadingWordTiming(18, 20, 1060, 1260),
        ReadingWordTiming(21, 28, 1260, 1880),
        ReadingWordTiming(29, 37, 1880, 2660),
        ReadingWordTiming(40, 42, 2660, 2820),
        ReadingWordTiming(43, 54, 2820, 3360),
        ReadingWordTiming(55, 63, 3360, 5380),
      ],
  "audio/dualar/07_kunut1/kunut_1-03.mp3| وَنُثْنِى عَلَيْك اْلخَيْرَ كُلَّهُ ":
      [
        ReadingWordTiming(1, 10, 0, 760),
        ReadingWordTiming(11, 18, 760, 1400),
        ReadingWordTiming(19, 28, 1400, 1980),
        ReadingWordTiming(29, 36, 1980, 3630),
      ],
  "audio/dualar/07_kunut1/kunut_1-04.mp3|نَشْكُرُكَ وَ لاَ نَكْفُرُكَ ": [
    ReadingWordTiming(0, 10, 0, 540),
    ReadingWordTiming(11, 13, 540, 840),
    ReadingWordTiming(14, 17, 840, 1000),
    ReadingWordTiming(18, 28, 1000, 2540),
  ],
  "audio/dualar/07_kunut1/kunut_1-05.mp3| وَ نَخْلَعُ وَ نَتْرُكُ مَنْ يَفْجُرُكَ":
      [
        ReadingWordTiming(1, 3, 0, 120),
        ReadingWordTiming(4, 12, 120, 680),
        ReadingWordTiming(13, 15, 680, 900),
        ReadingWordTiming(16, 24, 900, 1380),
        ReadingWordTiming(25, 29, 1380, 1680),
        ReadingWordTiming(30, 40, 1680, 3470),
      ],
  "audio/dualar/08_kunut2/kunut_2-01.mp3|اَللَّهُمَّ اِيَّاكَ نَعْبُدُ وَ لَكَ نُصَلِّى":
      [
        ReadingWordTiming(0, 11, 0, 360),
        ReadingWordTiming(12, 20, 360, 1740),
        ReadingWordTiming(21, 29, 1740, 2240),
        ReadingWordTiming(30, 32, 2240, 2600),
        ReadingWordTiming(33, 37, 2600, 2960),
        ReadingWordTiming(38, 46, 2960, 4740),
      ],
  "audio/dualar/08_kunut2/kunut_2-02.mp3|وَ نَسْجُدُ وَ اِلَيْكَ نَسعْىَ وَ نَحْفِدُ":
      [
        ReadingWordTiming(0, 2, 0, 160),
        ReadingWordTiming(3, 11, 160, 740),
        ReadingWordTiming(12, 14, 740, 980),
        ReadingWordTiming(15, 23, 980, 1460),
        ReadingWordTiming(24, 31, 1460, 2440),
        ReadingWordTiming(32, 34, 2440, 2620),
        ReadingWordTiming(35, 43, 2620, 4160),
      ],
  "audio/dualar/08_kunut2/kunut_2-03.mp3| نَرْجُو رَحْمَتَكَ وَ نَخْشَى عَذَابَك":
      [
        ReadingWordTiming(1, 8, 0, 560),
        ReadingWordTiming(9, 19, 560, 1460),
        ReadingWordTiming(20, 22, 1460, 1680),
        ReadingWordTiming(23, 30, 1680, 2320),
        ReadingWordTiming(31, 39, 2320, 3760),
      ],
  "audio/dualar/08_kunut2/kunut_2-04.mp3| اِنَّ عَذَابَكَ بِاْلكُفَّارِ مُلْحِقٌ":
      [
        ReadingWordTiming(1, 6, 0, 300),
        ReadingWordTiming(7, 16, 300, 1700),
        ReadingWordTiming(17, 30, 1700, 2900),
        ReadingWordTiming(31, 39, 2900, 4480),
      ],
  "audio/dualar/09_amentu/amentu-01.mp3|آمَنْتُ بِاللّٰهِ وَمَلٰائِكَتِهٖ وَكُتُبِهٖ وَرُسُلِهٖ":
      [
        ReadingWordTiming(0, 7, 480, 1020),
        ReadingWordTiming(8, 17, 1020, 1640),
        ReadingWordTiming(18, 33, 1640, 3140),
        ReadingWordTiming(34, 44, 3140, 4580),
        ReadingWordTiming(45, 55, 4580, 5660),
      ],
  "audio/dualar/09_amentu/amentu-02.mp3| وَالْيَوْمِ الْاٰخِرِ وَبِالْقَدَرِ خَيْرِهٖ وَشَرِّهٖ مِنَ اللّٰهِ تَعٰالٰىُ":
      [
        ReadingWordTiming(1, 12, 240, 900),
        ReadingWordTiming(13, 22, 900, 1720),
        ReadingWordTiming(23, 36, 1720, 2760),
        ReadingWordTiming(37, 45, 2760, 3460),
        ReadingWordTiming(46, 55, 3460, 4460),
        ReadingWordTiming(56, 60, 4460, 4660),
        ReadingWordTiming(61, 68, 4660, 5100),
        ReadingWordTiming(69, 78, 5100, 6420),
      ],
  "audio/dualar/09_amentu/amentu-03.mp3|وَالْبَعْثُ بَعْدَ الْمَوْتِ حَقٌّ": [
    ReadingWordTiming(0, 11, 240, 1080),
    ReadingWordTiming(12, 18, 1080, 1300),
    ReadingWordTiming(19, 28, 1300, 2100),
    ReadingWordTiming(29, 34, 2100, 2780),
  ],
  "audio/dualar/09_amentu/amentu-04.mp3|اَشْهَدُ اَنْ لٰا اِلٰهَ اِلَّا اللّٰهُ ":
      [
        ReadingWordTiming(0, 8, 340, 820),
        ReadingWordTiming(9, 13, 820, 1040),
        ReadingWordTiming(14, 17, 1040, 1460),
        ReadingWordTiming(18, 24, 1460, 1740),
        ReadingWordTiming(25, 31, 1740, 1880),
        ReadingWordTiming(32, 39, 1880, 3400),
      ],
  "audio/dualar/09_amentu/amentu-05.mp3|وَاَشْهَدُ اَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ ":
      [
        ReadingWordTiming(0, 10, 300, 920),
        ReadingWordTiming(11, 16, 920, 1200),
        ReadingWordTiming(17, 27, 1200, 2240),
        ReadingWordTiming(28, 36, 2240, 3260),
        ReadingWordTiming(37, 48, 3260, 4480),
      ],
  "audio/dualar/10_ezan_duasi/ezan-01.mp3|اَللّٰهُمَّ رَبَّ هٰذِهِ الدَّعْوَةِ التَّامَّةِ":
      [
        ReadingWordTiming(0, 11, 440, 1180),
        ReadingWordTiming(12, 17, 1180, 1860),
        ReadingWordTiming(18, 24, 1860, 2220),
        ReadingWordTiming(25, 36, 2220, 3340),
        ReadingWordTiming(37, 48, 3340, 4970),
      ],
  "audio/dualar/10_ezan_duasi/ezan-02.mp3|وَالصَّلٰوةِ الْقَائِمَةِ": [
    ReadingWordTiming(0, 12, 0, 1040),
    ReadingWordTiming(13, 25, 1040, 2670),
  ],
  "audio/dualar/10_ezan_duasi/ezan-03.mp3|آتِ مُحَمَّدًا الْوَسٖيلَةَ وَالْفَضٖيلَةَ":
      [
        ReadingWordTiming(0, 3, 0, 500),
        ReadingWordTiming(4, 14, 500, 1480),
        ReadingWordTiming(15, 27, 1480, 2580),
        ReadingWordTiming(28, 42, 2580, 3970),
      ],
  "audio/dualar/10_ezan_duasi/ezan-04.mp3|وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذٖي وَعَدْتَهُ":
      [
        ReadingWordTiming(0, 11, 180, 860),
        ReadingWordTiming(12, 20, 860, 1520),
        ReadingWordTiming(21, 31, 1520, 2700),
        ReadingWordTiming(32, 39, 2700, 2840),
        ReadingWordTiming(40, 50, 2840, 4580),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_01.mp3|اَللّٰهُ أَكْبَرُ": [
    ReadingWordTiming(0, 8, 0, 580),
    ReadingWordTiming(9, 17, 580, 2340),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_02.mp3|سُبْحَانَ رَبِّيَ الْعَظٖيمِ": [
    ReadingWordTiming(0, 9, 0, 700),
    ReadingWordTiming(10, 17, 700, 1260),
    ReadingWordTiming(18, 28, 1260, 3530),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_05.mp3|سُبْحَانَ رَبِّيَ الْأَعْلٰى": [
    ReadingWordTiming(0, 9, 0, 700),
    ReadingWordTiming(10, 17, 700, 1260),
    ReadingWordTiming(18, 28, 1260, 3560),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_03.mp3|سَمِعَ اللّٰهُ لِمَنْ حَمِدَهُ": [
    ReadingWordTiming(0, 6, 0, 500),
    ReadingWordTiming(7, 14, 500, 660),
    ReadingWordTiming(15, 21, 660, 1960),
    ReadingWordTiming(22, 30, 1960, 3450),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_04.mp3|رَبَّنَا وَلَكَ الْحَمْدُ": [
    ReadingWordTiming(0, 8, 0, 140),
    ReadingWordTiming(9, 15, 140, 1360),
    ReadingWordTiming(16, 25, 1360, 3060),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_06.mp3|اَلسَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ":
      [
        ReadingWordTiming(0, 11, 0, 560),
        ReadingWordTiming(12, 22, 560, 1760),
        ReadingWordTiming(23, 33, 1760, 2860),
        ReadingWordTiming(34, 41, 2860, 4570),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_07.mp3|اَلسَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ":
      [
        ReadingWordTiming(0, 11, 0, 600),
        ReadingWordTiming(12, 22, 600, 1020),
        ReadingWordTiming(23, 33, 1020, 2920),
        ReadingWordTiming(34, 41, 2920, 4930),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_08.mp3|اَللّٰهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ":
      [
        ReadingWordTiming(0, 11, 0, 460),
        ReadingWordTiming(12, 18, 460, 1600),
        ReadingWordTiming(19, 29, 1600, 2860),
        ReadingWordTiming(30, 38, 2860, 4660),
        ReadingWordTiming(39, 49, 4660, 5700),
        ReadingWordTiming(50, 61, 5700, 7680),
        ReadingWordTiming(62, 65, 7680, 7940),
        ReadingWordTiming(66, 69, 7940, 8340),
        ReadingWordTiming(70, 80, 8340, 9280),
        ReadingWordTiming(81, 95, 9280, 11900),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_09.mp3|عَلٰى رَسُولِنَا صَلَوَاتٌ": [
    ReadingWordTiming(0, 5, 0, 280),
    ReadingWordTiming(6, 16, 280, 1640),
    ReadingWordTiming(17, 26, 1640, 4030),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_10.mp3|اَللّٰهُمَّ صَلِّ عَلٰى سَيِّدِنَا مُحَمَّدٍ وَعَلٰى آلِ سَيِّدِنَا مُحَمَّدٍ":
      [
        ReadingWordTiming(0, 11, 120, 600),
        ReadingWordTiming(12, 17, 600, 1200),
        ReadingWordTiming(18, 23, 1200, 1220),
        ReadingWordTiming(24, 34, 1220, 2380),
        ReadingWordTiming(35, 44, 2380, 3520),
        ReadingWordTiming(45, 52, 3520, 4220),
        ReadingWordTiming(53, 56, 4220, 4380),
        ReadingWordTiming(57, 67, 4380, 5760),
        ReadingWordTiming(68, 77, 5760, 7720),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_20.mp3|وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ الْعَلِيِّ الْعَظٖيمِ":
      [
        ReadingWordTiming(0, 5, 280, 700),
        ReadingWordTiming(6, 12, 700, 1320),
        ReadingWordTiming(13, 18, 1320, 1560),
        ReadingWordTiming(19, 26, 1560, 2780),
        ReadingWordTiming(27, 33, 2780, 3000),
        ReadingWordTiming(34, 43, 3000, 4440),
        ReadingWordTiming(44, 54, 4440, 5240),
        ReadingWordTiming(55, 65, 5240, 8080),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_21.mp3|سُبْحَانَ اللّٰهِ بُكْرَةً وَأَصٖيلًا":
      [
        ReadingWordTiming(0, 9, 0, 680),
        ReadingWordTiming(10, 17, 680, 820),
        ReadingWordTiming(18, 26, 820, 2100),
        ReadingWordTiming(27, 37, 2100, 5110),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_22.mp3|اَلْحَمْدُ لِلّٰهِ حَمْدًا كَثٖيرًا":
      [
        ReadingWordTiming(0, 10, 0, 640),
        ReadingWordTiming(11, 18, 640, 1440),
        ReadingWordTiming(19, 26, 1440, 2120),
        ReadingWordTiming(27, 35, 2120, 4080),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_23.mp3|اَللّٰهُ أَكْبَرُ كَبٖيرًا": [
    ReadingWordTiming(0, 8, 280, 740),
    ReadingWordTiming(9, 17, 740, 1660),
    ReadingWordTiming(18, 26, 1660, 3900),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_24.mp3|لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرٖيكَ لَهُ":
      [
        ReadingWordTiming(0, 3, 140, 380),
        ReadingWordTiming(4, 10, 380, 1240),
        ReadingWordTiming(11, 17, 1240, 1460),
        ReadingWordTiming(18, 25, 1460, 1860),
        ReadingWordTiming(26, 34, 1860, 3880),
        ReadingWordTiming(35, 38, 3880, 4220),
        ReadingWordTiming(39, 46, 4220, 5380),
        ReadingWordTiming(47, 51, 5380, 6036),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_25.mp3|لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ يُحْيٖي وَيُمٖيتُ":
      [
        ReadingWordTiming(0, 4, 60, 480),
        ReadingWordTiming(5, 14, 480, 1220),
        ReadingWordTiming(15, 21, 1220, 1980),
        ReadingWordTiming(22, 31, 1980, 2820),
        ReadingWordTiming(32, 39, 2820, 3560),
        ReadingWordTiming(40, 49, 3560, 5399),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_26.mp3|وَهُوَ حَيٌّ لَا يَمُوتُ": [
    ReadingWordTiming(0, 6, 0, 760),
    ReadingWordTiming(7, 12, 760, 1340),
    ReadingWordTiming(13, 16, 1340, 1480),
    ReadingWordTiming(17, 24, 1480, 3789),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_27.mp3|بِيَدِهِ الْخَيْرُ": [
    ReadingWordTiming(0, 8, 40, 900),
    ReadingWordTiming(9, 18, 900, 2932),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_28.mp3|وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدٖيرٌ":
      [
        ReadingWordTiming(0, 6, 0, 640),
        ReadingWordTiming(7, 12, 640, 780),
        ReadingWordTiming(13, 18, 780, 1420),
        ReadingWordTiming(19, 25, 1420, 2580),
        ReadingWordTiming(26, 33, 2580, 5420),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_29.mp3|وَإِلَيْهِ الْمَصٖيرُ": [
    ReadingWordTiming(0, 10, 0, 1040),
    ReadingWordTiming(11, 21, 1040, 3951),
  ],
  "audio/dualar/13_yemek_duasi/yemek-01.mp3|اَلْحَمْدُ لِلّٰهِ الَّذٖي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمٖينَ":
      [
        ReadingWordTiming(0, 10, 120, 660),
        ReadingWordTiming(11, 18, 660, 1360),
        ReadingWordTiming(19, 26, 1360, 1580),
        ReadingWordTiming(27, 38, 1580, 3000),
        ReadingWordTiming(39, 49, 3000, 4320),
        ReadingWordTiming(50, 61, 4320, 5160),
        ReadingWordTiming(62, 73, 5160, 7660),
      ],
  "audio/dualar/13_yemek_duasi/yemek-02.mp3|اَللّٰهُمَّ أَطْعِمْ مَنْ أَطْعَمَنَا":
      [
        ReadingWordTiming(0, 11, 120, 760),
        ReadingWordTiming(12, 20, 760, 2040),
        ReadingWordTiming(21, 25, 2040, 2540),
        ReadingWordTiming(26, 37, 2540, 4300),
      ],
  "audio/dualar/13_yemek_duasi/yemek-03.mp3|وَاسْقِ مَنْ سَقَانَا": [
    ReadingWordTiming(0, 7, 160, 660),
    ReadingWordTiming(8, 12, 660, 880),
    ReadingWordTiming(13, 21, 880, 2780),
  ],
  "audio/dualar/13_yemek_duasi/yemek-04.mp3|اَللّٰهُمَّ بَارِكْ لَهُمْ فٖيمَا رَزَقْتَهُمْ":
      [
        ReadingWordTiming(0, 11, 180, 580),
        ReadingWordTiming(12, 19, 580, 1700),
        ReadingWordTiming(20, 26, 1700, 2060),
        ReadingWordTiming(27, 33, 2060, 2720),
        ReadingWordTiming(34, 46, 2720, 4490),
      ],
  "audio/dualar/13_yemek_duasi/yemek-05.mp3|وَاغْفِرْ لَهُمْ وَارْحَمْهُمْ": [
    ReadingWordTiming(0, 9, 300, 900),
    ReadingWordTiming(10, 16, 900, 1340),
    ReadingWordTiming(17, 30, 1340, 3320),
  ],
  "audio/dualar/13_yemek_duasi/yemek-06.mp3|أَفْطَرَ عِنْدَكُمُ الصَّائِمُونَ":
      [
        ReadingWordTiming(0, 8, 120, 620),
        ReadingWordTiming(9, 19, 620, 1300),
        ReadingWordTiming(20, 33, 1300, 3410),
      ],
  "audio/dualar/13_yemek_duasi/yemek-07.mp3|وَأَكَلَ طَعَامَكُمُ الْأَبْرَارُ":
      [
        ReadingWordTiming(0, 8, 60, 460),
        ReadingWordTiming(9, 20, 460, 1860),
        ReadingWordTiming(21, 33, 1860, 3790),
      ],
  "audio/dualar/13_yemek_duasi/yemek-08.mp3|وَصَلَّتْ عَلَيْكُمُ الْمَلَائِكَةُ":
      [
        ReadingWordTiming(0, 9, 200, 940),
        ReadingWordTiming(10, 20, 940, 1760),
        ReadingWordTiming(21, 35, 1760, 4060),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_11.mp3|صَلَاةً تُنْجٖينَا بِهَا مِنْ جَمٖيعِ الْأَهْوَالِ وَالْآفَاتِ":
      [
        ReadingWordTiming(0, 7, 300, 960),
        ReadingWordTiming(8, 18, 960, 2060),
        ReadingWordTiming(19, 24, 2060, 2660),
        ReadingWordTiming(25, 29, 2660, 3020),
        ReadingWordTiming(30, 37, 3020, 3600),
        ReadingWordTiming(38, 50, 3600, 4640),
        ReadingWordTiming(51, 62, 4640, 6344),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_12.mp3|وَتَقْضٖي لَنَا بِهَا جَمٖيعَ الْحَاجَاتِ":
      [
        ReadingWordTiming(0, 9, 20, 980),
        ReadingWordTiming(10, 15, 980, 1360),
        ReadingWordTiming(16, 21, 1360, 1940),
        ReadingWordTiming(22, 29, 1940, 2720),
        ReadingWordTiming(30, 41, 2720, 4411),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_13.mp3|وَتُطَهِّرُنَا بِهَا مِنْ جَمٖيعِ السَّيِّئَاتِ":
      [
        ReadingWordTiming(0, 14, 240, 1520),
        ReadingWordTiming(15, 20, 1520, 2080),
        ReadingWordTiming(21, 25, 2080, 2440),
        ReadingWordTiming(26, 33, 2440, 3120),
        ReadingWordTiming(34, 47, 3120, 4799),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_14.mp3|وَتَرْفَعُنَا بِهَا عِنْدَكَ أَعْلَى الدَّرَجَاتِ":
      [
        ReadingWordTiming(0, 13, 0, 1640),
        ReadingWordTiming(14, 19, 1640, 2180),
        ReadingWordTiming(20, 28, 2180, 3060),
        ReadingWordTiming(29, 36, 3060, 3540),
        ReadingWordTiming(37, 49, 3540, 5360),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_15.mp3|وَتُبَلِّغُنَا بِهَا أَقْصَى الْغَايَاتِ":
      [
        ReadingWordTiming(0, 14, 300, 1560),
        ReadingWordTiming(15, 20, 1560, 2140),
        ReadingWordTiming(21, 28, 2140, 3060),
        ReadingWordTiming(29, 40, 3060, 5200),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_16.mp3|مِنْ جَمٖيعِ الْخَيْرَاتِ فِي الْحَيَاةِ وَبَعْدَ الْمَمَاتِ":
      [
        ReadingWordTiming(0, 4, 0, 420),
        ReadingWordTiming(5, 12, 420, 1020),
        ReadingWordTiming(13, 25, 1020, 2180),
        ReadingWordTiming(26, 29, 2180, 2400),
        ReadingWordTiming(30, 40, 2400, 3400),
        ReadingWordTiming(41, 49, 3400, 3980),
        ReadingWordTiming(50, 60, 3980, 5940),
      ],
  "audio/dualar/namaz_lafizlari/lafiz_17.mp3|آمٖينَ يَا مُجٖيبَ الدَّعَوَاتِ": [
    ReadingWordTiming(0, 6, 260, 1420),
    ReadingWordTiming(7, 10, 1420, 1580),
    ReadingWordTiming(11, 18, 1580, 2620),
    ReadingWordTiming(19, 31, 2620, 4578),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_18.mp3|وَالْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمٖينَ":
      [
        ReadingWordTiming(0, 11, 0, 900),
        ReadingWordTiming(12, 19, 900, 1600),
        ReadingWordTiming(20, 25, 1600, 2120),
        ReadingWordTiming(26, 39, 2120, 5210),
      ],
  "audio/dualar/15_tefriciye/tefriciye-01.mp3|اَللّٰهُمَّ صَلِّ صَلَاةً كَامِلَةً وَسَلِّمْ سَلَامًا تَامًّا عَلٰى سَيِّدِنَا مُحَمَّدٍ":
      [
        ReadingWordTiming(0, 11, 120, 600),
        ReadingWordTiming(12, 17, 600, 1560),
        ReadingWordTiming(18, 25, 1560, 2340),
        ReadingWordTiming(26, 35, 2340, 3220),
        ReadingWordTiming(36, 45, 3220, 3640),
        ReadingWordTiming(46, 54, 3640, 4960),
        ReadingWordTiming(55, 62, 4960, 6140),
        ReadingWordTiming(63, 68, 6140, 6380),
        ReadingWordTiming(69, 79, 6380, 7340),
        ReadingWordTiming(80, 89, 7340, 9100),
      ],
  "audio/dualar/15_tefriciye/tefriciye-02.mp3|الَّذٖي تَنْحَلُّ بِهِ الْعُقَدُ":
      [
        ReadingWordTiming(0, 7, 120, 580),
        ReadingWordTiming(8, 17, 580, 1240),
        ReadingWordTiming(18, 22, 1240, 1340),
        ReadingWordTiming(23, 32, 1340, 2840),
      ],
  "audio/dualar/15_tefriciye/tefriciye-03.mp3|وَتَنْفَرِجُ بِهِ الْكُرَبُ": [
    ReadingWordTiming(0, 12, 120, 880),
    ReadingWordTiming(13, 17, 880, 1180),
    ReadingWordTiming(18, 27, 1180, 3040),
  ],
  "audio/dualar/15_tefriciye/tefriciye-04.mp3|وَتُقْضٰى بِهِ الْحَوَائِجُ": [
    ReadingWordTiming(0, 9, 120, 920),
    ReadingWordTiming(10, 14, 920, 1140),
    ReadingWordTiming(15, 27, 1140, 2900),
  ],
  "audio/dualar/15_tefriciye/tefriciye-05.mp3|وَتُنَالُ بِهِ الرَّغَائِبُ وَحُسْنُ الْخَوَاتٖيمِ":
      [
        ReadingWordTiming(0, 9, 120, 780),
        ReadingWordTiming(10, 14, 780, 1020),
        ReadingWordTiming(15, 27, 1020, 2500),
        ReadingWordTiming(28, 36, 2500, 3200),
        ReadingWordTiming(37, 50, 3200, 5120),
      ],
  "audio/dualar/15_tefriciye/tefriciye-06.mp3|وَيُسْتَسْقَى الْغَمَامُ بِوَجْهِهِ الْكَرٖيمِ":
      [
        ReadingWordTiming(0, 13, 120, 1100),
        ReadingWordTiming(14, 24, 1100, 1680),
        ReadingWordTiming(25, 35, 1680, 2600),
        ReadingWordTiming(36, 46, 2600, 4000),
      ],
  "audio/dualar/15_tefriciye/tefriciye-07.mp3|وَعَلٰى آلِهٖ وَصَحْبِهٖ": [
    ReadingWordTiming(0, 7, 120, 480),
    ReadingWordTiming(8, 13, 480, 860),
    ReadingWordTiming(14, 24, 860, 2330),
  ],
  "audio/dualar/15_tefriciye/tefriciye-08.mp3|فٖي كُلِّ لَمْحَةٍ وَنَفَسٍ بِعَدَدِ كُلِّ مَعْلُومٍ لَكَ":
      [
        ReadingWordTiming(0, 3, 140, 300),
        ReadingWordTiming(4, 9, 300, 500),
        ReadingWordTiming(10, 18, 500, 1300),
        ReadingWordTiming(19, 27, 1300, 2120),
        ReadingWordTiming(28, 36, 2120, 2600),
        ReadingWordTiming(37, 42, 2600, 3220),
        ReadingWordTiming(43, 52, 3220, 4220),
        ReadingWordTiming(53, 57, 4220, 5640),
      ],
  "audio/sureler/12_ayetel-kursi/01_ayet.mp3|اَللّٰهُ لَٓا اِلٰهَ اِلَّا هُوَۚ اَلْحَيُّ الْقَيُّومُۚ":
      [
        ReadingWordTiming(0, 8, 120, 740),
        ReadingWordTiming(9, 13, 740, 1460),
        ReadingWordTiming(14, 20, 1460, 1720),
        ReadingWordTiming(21, 27, 1720, 3180),
        ReadingWordTiming(28, 33, 3180, 3400),
        ReadingWordTiming(34, 43, 3400, 6060),
        ReadingWordTiming(44, 56, 6060, 9620),
      ],
  "audio/sureler/14_duha/06_ayet.mp3|اَلَمْ يَجِدْكَ يَت۪يمًا فَاٰوٰىۖ": [
    ReadingWordTiming(0, 6, 220, 380),
    ReadingWordTiming(7, 15, 380, 1200),
    ReadingWordTiming(16, 24, 1200, 2680),
    ReadingWordTiming(25, 33, 2680, 5973),
  ],
  "audio/dualar/02_ettahiyatu/etahiyyat-01.mp3|التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ":
      [
        ReadingWordTiming(0, 13, 0, 920),
        ReadingWordTiming(14, 21, 920, 1360),
        ReadingWordTiming(22, 36, 1360, 2720),
        ReadingWordTiming(37, 52, 2720, 5960),
      ],
  "audio/dualar/02_ettahiyatu/etahiyyat-03.mp3| السَّلامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ":
      [
        ReadingWordTiming(1, 10, 0, 480),
        ReadingWordTiming(11, 20, 480, 860),
        ReadingWordTiming(21, 28, 860, 1960),
        ReadingWordTiming(29, 36, 1960, 2800),
        ReadingWordTiming(37, 44, 2800, 3240),
        ReadingWordTiming(45, 58, 3240, 5810),
      ],
  "audio/dualar/04_barik/barik-01.mp3|اللَّهُمَّ بَارِكَ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ":
      [
        ReadingWordTiming(0, 10, 340, 780),
        ReadingWordTiming(11, 18, 780, 1980),
        ReadingWordTiming(19, 24, 1980, 2420),
        ReadingWordTiming(25, 34, 2420, 3500),
        ReadingWordTiming(35, 42, 3500, 4220),
        ReadingWordTiming(43, 46, 4220, 5400),
        ReadingWordTiming(47, 56, 5400, 6780),
      ],
  "audio/sureler/15_insirah/01_ayet.mp3|اَلَمْ نَشْرَحْ لَكَ صَدْرَكَۙ": [
    ReadingWordTiming(0, 6, 0, 60),
    ReadingWordTiming(7, 15, 60, 1820),
    ReadingWordTiming(16, 20, 1820, 2320),
    ReadingWordTiming(21, 30, 2320, 3828),
  ],
  "audio/dualar/namaz_lafizlari/lafiz_19.mp3|سُبْحَانَ اللّٰهِ وَالْحَمْدُ لِلّٰهِ وَلَا إِلٰهَ إِلَّا اللّٰهُ وَاللّٰهُ أَكْبَرُ":
      [
        ReadingWordTiming(0, 9, 0, 560),
        ReadingWordTiming(10, 17, 560, 880),
        ReadingWordTiming(18, 29, 880, 1420),
        ReadingWordTiming(30, 37, 1420, 1480),
        ReadingWordTiming(38, 43, 1480, 1800),
        ReadingWordTiming(44, 50, 1800, 2040),
        ReadingWordTiming(51, 57, 2040, 3580),
        ReadingWordTiming(58, 65, 3580, 3640),
        ReadingWordTiming(66, 75, 3640, 3700),
        ReadingWordTiming(76, 84, 3700, 8477),
      ],
};
