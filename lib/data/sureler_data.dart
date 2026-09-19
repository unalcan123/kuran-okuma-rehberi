import '../models/surah.dart';

/// Source: the old Elifbe2025 project's `assets/jsondatalar/sureler/`
/// json files, transcribed as-is — Arabic text, Turkish meanings,
/// surah order and audio filenames all come from there. The Arabic
/// surah names are the standard Qur'an surah names (not present in
/// the old project's data, added as commonly-known facts).

const Surah kFatiha = Surah(
  order: 1,
  id: 'fatiha',
  titleTr: 'Fatiha Sûresi',
  arabicName: 'الفاتحة',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ ِ',
  besmeleAudioAsset: 'audio/sureler/01_fatiha/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'اَلْحَمْدُ لِلّٰهِ رَبِّ الْـعَالَمٖينَۙ', meaningTr: 'Bütün hamdler, övgüler âlemlerin Rabbi Allâh’adır.', audioAsset: 'audio/sureler/01_fatiha/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'اَلرَّحْمٰنِ الرَّحٖيمِۙ', meaningTr: 'O rahmândır, rahîmdir.', audioAsset: 'audio/sureler/01_fatiha/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'مَالِكِ يَوْمِ الدّٖينِؕ', meaningTr: 'Din gününün, hesap gününün tek hâkimidir.', audioAsset: 'audio/sureler/01_fatiha/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'اِيَّاكَ نَعْبُدُ وَاِيَّاكَ نَسْتَعٖينُؕ', meaningTr: '(Haydi öyleyse deyiniz): “Yalnız Sana ibadet eder, yalnız senden medet umarız.” [', audioAsset: 'audio/sureler/01_fatiha/04_ayet.mp3'),
    Ayet(number: 5, arabic: 'اِهْدِنَا الصِّرَاطَ الْمُسْتَقٖيمَۙ', meaningTr: 'Bizi doğru yola, Sana doğru varan yola ilet.', audioAsset: 'audio/sureler/01_fatiha/05_ayet.mp3'),
    Ayet(number: 6, arabic: 'صِرَاطَ الَّذٖينَ اَنْعَمْتَ عَلَيْهِمْۙ', meaningTr: 'Kendilerine nimet verdiğin kimselerin yoluna ilet, ”', audioAsset: 'audio/sureler/01_fatiha/06_ayet.mp3'),
    Ayet(number: 7, arabic: 'غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّٓالّٖينَ', meaningTr: 'gazaba uğrayanların ve sapıkların yoluna değil.', audioAsset: 'audio/sureler/01_fatiha/07_ayet.mp3'),
  ],
);

const Surah kFil = Surah(
  order: 2,
  id: 'fil',
  titleTr: 'Fil Suresi',
  arabicName: 'الفيل',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/02_fil/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'اَلَمْ تَرَ كَيْفَ فَعَلَ رَبُّكَ بِاَصْحَابِ الْفٖيلِؕ', meaningTr: '– Rabbinin Ashab-ı fil’e ettiklerini görmedin mi?', audioAsset: 'audio/sureler/02_fil/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'اَلَمْ يَجْعَلْ كَيْدَهُمْ فٖي تَضْلٖيلٍۙ', meaningTr: '– Onların hile ve düzenlerini boşa çıkarmadı mı?', audioAsset: 'audio/sureler/02_fil/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'وَاَرْسَلَ عَلَيْهِمْ طَيْراً اَبَابٖيلَۙ', meaningTr: 'Üzerlerine ebabili, sürü sürü kuşları salıverdi.', audioAsset: 'audio/sureler/02_fil/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'تَرْم۪يهِمْ بِحِجَارَةٍ مِنْ سِجّ۪يلٍۖۙ', meaningTr: '– Bunlar onlara pişkin tuğladan yapılmış taşlar atıyorlardı.', audioAsset: 'audio/sureler/02_fil/04_ayet.mp3'),
    Ayet(number: 5, arabic: 'فَجَعَلَهُمْ كَعَصْفٍ مَأْكُولٍ', meaningTr: 'Derken onları kurt yeniği ekin yaprağına çeviriverdi.', audioAsset: 'audio/sureler/02_fil/05_ayet.mp3'),
  ],
);

const Surah kKureysh = Surah(
  order: 3,
  id: 'kureysh',
  titleTr: 'Kureyş Suresi',
  arabicName: 'قريش',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/03_kureys/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'لِا۪يلَافِ قُرَيْشٍۙ', meaningTr: 'Kureyş’in güven ve barış anlaşmalarından faydalanmalarını sağlamak için,', audioAsset: 'audio/sureler/03_kureys/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'ا۪يلَافِهِمْ رِحْلَةَ الشِّتَٓاءِ وَالصَّيْفِۚ', meaningTr: 'Kış ve yaz seferlerinde faydalandıkları anlaşmaların kadrini bilmiş olmak için,', audioAsset: 'audio/sureler/03_kureys/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'فَلْيَعْبُدُوا رَبَّ هٰذَا الْبَيْتِۙ', meaningTr: 'Yalnız Bu Ev’in (Kâ’benin) Rabbine ibadet etsinler.', audioAsset: 'audio/sureler/03_kureys/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'اَلَّذ۪ٓي اَطْعَمَهُمْ مِنْ جُوعٍ وَاٰمَنَهُمْ مِنْ خَوْفٍ', meaningTr: 'Kendilerini açlıktan kurtarıp doyuran, korkudan emin kılan Rablerine kulluk etsinler.', audioAsset: 'audio/sureler/03_kureys/04_ayet.mp3'),
  ],
);

const Surah kMaun = Surah(
  order: 4,
  id: 'maun',
  titleTr: 'Mâun Suresi',
  arabicName: 'الماعون',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/04_maun/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'اَرَاَيْتَ الَّذٖي يُكَذِّبُ بِالدّٖينِؕ', meaningTr: 'Gördün mü dini yalan sayanı?', audioAsset: 'audio/sureler/04_maun/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'فَذٰلِكَ الَّذٖي يَدُعُّ الْيَتٖيمَۙ', meaningTr: 'İşte odur yetimi itip kakan;', audioAsset: 'audio/sureler/04_maun/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'وَلَا يَحُضُّ عَلٰى طَعَامِ الْمِسْك۪ينِۜ', meaningTr: 'Ve yoksula yedirmeyi özendirmeyen!', audioAsset: 'audio/sureler/04_maun/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'فَوَيْلٌ لِلْمُصَلّ۪ينَۙ', meaningTr: 'Vay haline o namaz kılanların ki,', audioAsset: 'audio/sureler/04_maun/04_ayet.mp3'),
    Ayet(number: 5, arabic: 'اَلَّذ۪ينَ هُمْ عَنْ صَلَاتِهِمْ سَاهُونَۙ', meaningTr: 'Onlar namazlarının özünden uzaktırlar.', audioAsset: 'audio/sureler/04_maun/05_ayet.mp3'),
    Ayet(number: 6, arabic: 'اَلَّذ۪ينَ هُمْ يُرَٓاؤُ۫نَۙ', meaningTr: 'Onlar halka gösteriş yaparlar.', audioAsset: 'audio/sureler/04_maun/06_ayet.mp3'),
    Ayet(number: 7, arabic: 'وَيَمْنَعُونَ الْمَاعُونَ', meaningTr: 'Hayra da engel olurlar.', audioAsset: 'audio/sureler/04_maun/07_ayet.mp3'),
  ],
);

const Surah kIhlas = Surah(
  order: 5,
  id: 'ihlas',
  titleTr: 'İhlas Suresi',
  arabicName: 'الإخلاص',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/05_ihlas/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'قُلْ هُوَ اللّٰهُ اَحَدٌۚ', meaningTr: 'De ki: O, Allah’tır, gerçek İlahtır ve Birdir.', audioAsset: 'audio/sureler/05_ihlas/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'اَللّٰهُ الصَّمَدُۚ', meaningTr: 'Allah Samed’dir.', audioAsset: 'audio/sureler/05_ihlas/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'لَمْ يَلِدْ وَلَمْ يُولَدْۙ', meaningTr: 'Ne doğurdu, ne de doğuruldu. [6,101; 19,88-90; 21, 26-27]', audioAsset: 'audio/sureler/05_ihlas/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'وَلَمْ يَكُنْ لَهُ كُفُواً اَحَدٌ', meaningTr: 'Ne de herhangi bir şey O’na denk oldu.', audioAsset: 'audio/sureler/05_ihlas/04_ayet.mp3'),
  ],
);

const Surah kKevser = Surah(
  order: 6,
  id: 'kevser',
  titleTr: 'Kevser Suresi',
  arabicName: 'الكوثر',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/06_kevser/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'اِنَّٓا اَعْطَيْنَاكَ الْكَوْثَرَؕ', meaningTr: 'Biz gerçekten sana verdik kevser.', audioAsset: 'audio/sureler/06_kevser/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'فَصَلِّ لِرَبِّكَ وَانْحَرْؕ', meaningTr: 'Sen de Rabbin için namaz kıl ve kurban kesiver.', audioAsset: 'audio/sureler/06_kevser/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'اِنَّ شَانِئَكَ هُوَ الْاَبْتَرُ', meaningTr: 'Doğrusu, seni kötüleyendir ebter!', audioAsset: 'audio/sureler/06_kevser/03_ayet.mp3'),
  ],
);

const Surah kNas = Surah(
  order: 7,
  id: 'nas',
  titleTr: 'Nas Suresi',
  arabicName: 'الناس',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/07_nas/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'قُلْ اَعُوذُ بِرَبِّ النَّاسِۙ', meaningTr: 'De ki: İnsanların Rabbine,', audioAsset: 'audio/sureler/07_nas/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'مَلِكِ النَّاسِۙ', meaningTr: 'İnsanların yegane Hükümdarına,', audioAsset: 'audio/sureler/07_nas/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'اِلٰهِ النَّاسِۙ', meaningTr: 'İnsanların İlahına sığınırım:', audioAsset: 'audio/sureler/07_nas/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِۙ', meaningTr: 'O sinsi şeytanın şerrinden', audioAsset: 'audio/sureler/07_nas/04_ayet.mp3'),
    Ayet(number: 5, arabic: 'اَلَّذٖي يُوَسْوِسُ فٖي صُدُورِ النَّاسِۙ', meaningTr: 'O ki insanların kalplerine vesvese verir,', audioAsset: 'audio/sureler/07_nas/05_ayet.mp3'),
    Ayet(number: 6, arabic: 'مِنَ الْجِنَّةِ وَالنَّاسِ', meaningTr: 'O şeytan, cinlerden de olur, insanlardan da olur. [6,112]', audioAsset: 'audio/sureler/07_nas/06_ayet.mp3'),
  ],
);

const Surah kFelak = Surah(
  order: 8,
  id: 'felak',
  titleTr: 'Felak Suresi',
  arabicName: 'الفلق',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/08_felak/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'قُلْ اَعُوذُ بِرَبِّ الْفَلَقِۙ', meaningTr: 'De ki: Sabahın Rabbine sığınırım:', audioAsset: 'audio/sureler/08_felak/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'مِنْ شَرِّ مَا خَلَقَۙ', meaningTr: 'Yarattığı şeylerin şerrinden,', audioAsset: 'audio/sureler/08_felak/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'وَمِنْ شَرِّ غَاسِقٍ اِذَا وَقَبَۙ', meaningTr: 'Karanlığı çöktüğü zaman gecenin şerrinden,', audioAsset: 'audio/sureler/08_felak/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِۙ', meaningTr: 'Düğümlere üfleyip büyü yapan büyücü kadınların şerrinden,', audioAsset: 'audio/sureler/08_felak/04_ayet.mp3'),
    Ayet(number: 5, arabic: 'وَمِنْ شَرِّ حَاسِدٍ اِذَا حَسَدَ', meaningTr: 'Ve hased ettiği zaman hasetçinin şerrinden.', audioAsset: 'audio/sureler/08_felak/05_ayet.mp3'),
  ],
);

const Surah kNasr = Surah(
  order: 9,
  id: 'nasr',
  titleTr: 'Nasr Suresi',
  arabicName: 'النصر',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/09_nasr/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'اِذَا جَٓاءَ نَصْرُ اللّٰهِ وَالْفَتْحُۙ', meaningTr: 'Allah’ın yardım ve zaferi geldiği zaman,', audioAsset: 'audio/sureler/09_nasr/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'وَرَاَيْتَ النَّاسَ يَدْخُلُونَ فٖي دٖينِ اللّٰهِ اَفْوَاجاًۙ', meaningTr: 'Ve insanların kafile kafile Allah’ın dinine girdiklerini gördüğün zaman,', audioAsset: 'audio/sureler/09_nasr/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'فَسَبِّـحْ بِحَمْدِ رَبِّكَ وَاسْتَغْفِرْهُؕ', meaningTr: 'Rabbine hamd ile tesbih et', audioAsset: 'audio/sureler/09_nasr/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'اِنَّهُ كَانَ تَـوَّاباً', meaningTr: 've O’ndan af dile.', audioAsset: 'audio/sureler/09_nasr/04_ayet.mp3'),
  ],
);

const Surah kTebbet = Surah(
  order: 10,
  id: 'tebbet',
  titleTr: 'Tebbet Suresi',
  arabicName: 'المسد',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/10_tebbet/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'تَبَّتْ يَدَٓا اَبٖي لَهَبٍ وَتَبَّؕ', meaningTr: 'Kurusun Ebû Leheb’in elleri. Zaten de kurudu!', audioAsset: 'audio/sureler/10_tebbet/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'مَٓا اَغْنٰى عَنْهُ مَالُهُ وَمَا كَسَبَؕ', meaningTr: 'O, alev alev yükselen ateşe girecek,', audioAsset: 'audio/sureler/10_tebbet/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'سَيَصْلٰى نَاراً ذَاتَ لَهَبٍۚ', meaningTr: 'Eşi de boynunda bükülmüş urgan olarak,\no ateşe odun taşıyacak.', audioAsset: 'audio/sureler/10_tebbet/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'وَامْرَاَتُهُؕ حَمَّالَةَ الْحَطَبِۚ', meaningTr: 'Eşi de boynunda bükülmüş urgan olarak,\no ateşe odun taşıyacak.', audioAsset: 'audio/sureler/10_tebbet/04_ayet.mp3'),
    Ayet(number: 5, arabic: 'فٖي جٖيدِهَا حَبْلٌ مِنْ مَسَدٍ', meaningTr: 'Eşi de boynunda bükülmüş urgan olarak,\no ateşe odun taşıyacak.', audioAsset: 'audio/sureler/10_tebbet/05_ayet.mp3'),
  ],
);

const Surah kKafirun = Surah(
  order: 11,
  id: 'kafirun',
  titleTr: 'Kâfirun Suresi',
  arabicName: 'الكافرون',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/11_kafirun/00_besmele.mp3',
  ayetler: [
    Ayet(number: 1, arabic: 'قُلْ يَٓا اَيُّهَا الْـكَافِرُونَۙ', meaningTr: 'De ki: Ey kâfirler!', audioAsset: 'audio/sureler/11_kafirun/01_ayet.mp3'),
    Ayet(number: 2, arabic: 'لَٓا اَعْبُدُ مَا تَعْبُدُونَۙ', meaningTr: 'Ben sizin ibadet ettiklerinize ibadet etmem.', audioAsset: 'audio/sureler/11_kafirun/02_ayet.mp3'),
    Ayet(number: 3, arabic: 'وَلَٓا اَنْتُمْ عَابِدُونَ مَٓا اَعْبُدُۚ', meaningTr: 'Siz de benim ibadet ettiğime ibadet etmiyorsunuz', audioAsset: 'audio/sureler/11_kafirun/03_ayet.mp3'),
    Ayet(number: 4, arabic: 'وَلَٓا اَنَا۬ عَابِدٌ مَا عَبَدْتُمْۙ', meaningTr: 'Ben sizin ibadet ettiklerinize asla ibadet edecek değilim.', audioAsset: 'audio/sureler/11_kafirun/04_ayet.mp3'),
    Ayet(number: 5, arabic: 'وَلَٓا اَنْتُمْ عَابِدُونَ مَٓا اَعْبُدُۜ', meaningTr: '– Siz de benim ibadet ettiğime ibadet etmezsiniz.', audioAsset: 'audio/sureler/11_kafirun/05_ayet.mp3'),
    Ayet(number: 6, arabic: 'لَـكُمْ د۪ينُكُمْ وَلِيَ د۪ينِ', meaningTr: 'O halde sizin dininiz size, benim dinim bana!', audioAsset: 'audio/sureler/11_kafirun/06_ayet.mp3'),
  ],
);

const List<Surah> kSureler = [
  kFatiha,
  kFil,
  kKureysh,
  kMaun,
  kIhlas,
  kKevser,
  kNas,
  kFelak,
  kNasr,
  kTebbet,
  kKafirun,
];
