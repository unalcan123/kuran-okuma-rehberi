import '../models/dua.dart';

// Imported verbatim from Elifbe2025 JSON and app_tr.arb. See docs/dualar_source.md.
const List<Dua> kDualar = [
  Dua(
    order: 1,
    id: "1_subhaneke_duasi",
    titleTr: "Sübhâneke",
    segments: [
      DuaSegment(
        id: 0,
        arabic: "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَِ",
        meaningTr:
            "Allah'ım! Seni her türlü eksiklikten tenzih ederim ve Sana hamd ederim.",
        audioAsset: "audio/dualar/01_subhaneke/subhaneke1.mp3",
      ),
      DuaSegment(
        id: 1,
        arabic: "وَتَبَارَكَ اسْمُكَ",
        meaningTr: "Senin ismin mübarektir.",
        audioAsset: "audio/dualar/01_subhaneke/subhaneke2.mp3",
      ),
      DuaSegment(
        id: 2,
        arabic: "وَتَعَالَى جَدُّكَ ",
        meaningTr: "Senin şanın yücedir.",
        audioAsset: "audio/dualar/01_subhaneke/subhaneke3.mp3",
      ),
      DuaSegment(
        id: 3,
        arabic: "وَلاَ إِلَهَ غَيْرُكَ",
        meaningTr: "Senden başka ilah yoktur.",
        audioAsset: "audio/dualar/01_subhaneke/subhaneke4.mp3",
      ),
    ],
  ),
  Dua(
    order: 2,
    id: "2_ettahiyatu_duasi",
    titleTr: "Ettehiyyâtü",
    segments: [
      DuaSegment(
        id: 0,
        arabic: "التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ",
        meaningTr:
            "Bütün tahiyyatlar, salavatlar ve güzel sözler Allah içindir.",
        audioAsset: "audio/dualar/02_ettahiyatu/etahiyyat-01.mp3",
      ),
      DuaSegment(
        id: 1,
        arabic:
            "السَّلامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ",
        meaningTr:
            "Ey Nebi! Allah'ın selamı, rahmeti ve bereketi senin üzerine olsun.",
        audioAsset: "audio/dualar/02_ettahiyatu/etahiyyat-02.mp3",
      ),
      DuaSegment(
        id: 2,
        arabic: " السَّلامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ",
        meaningTr:
            "Selam bizim üzerimize ve Allah'ın salih kullarının üzerine olsun.",
        audioAsset: "audio/dualar/02_ettahiyatu/etahiyyat-03.mp3",
      ),
      DuaSegment(
        id: 3,
        arabic: "أَشْهَدُ أَنْ لا إِلَهَ إِلا اللَّ",
        meaningTr: "Şahitlik ederim ki Allah'tan başka ilah yoktur.",
        audioAsset: "audio/dualar/02_ettahiyatu/etahiyyat-04.mp3",
      ),
      DuaSegment(
        id: 4,
        arabic: "وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ",
        meaningTr: "Yine şahitlik ederim ki Muhammed O'nun kulu ve resulüdür.",
        audioAsset: "audio/dualar/02_ettahiyatu/etahiyyat-05.mp3",
      ),
    ],
  ),
  Dua(
    order: 3,
    id: "3_salli_duasi",
    titleTr: "Allâhumme Salli",
    segments: [
      DuaSegment(
        id: 0,
        arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ ُ",
        meaningTr: "Allah'ım! Muhammed'e ve Muhammed'in aline rahmet eyle.",
        audioAsset: "audio/dualar/03_salli/salli-01.mp3",
      ),
      DuaSegment(
        id: 1,
        arabic: "كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمُ",
        meaningTr: "İbrahim'e ve İbrahim'in aline rahmet ettiğin gibi.",
        audioAsset: "audio/dualar/03_salli/salli-02.mp3",
      ),
      DuaSegment(
        id: 2,
        arabic: " إِنَّكَ حَمِيدٌ مَجِيدٌَ",
        meaningTr: "Şüphesiz Sen hamde layıksın, şanı yüce olansın.",
        audioAsset: "audio/dualar/03_salli/salli-03.mp3",
      ),
    ],
  ),
  Dua(
    order: 4,
    id: "4_barik_duasi",
    titleTr: "Allâhumme Barik",
    segments: [
      DuaSegment(
        id: 0,
        arabic: "اللَّهُمَّ بَارِكَ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ",
        meaningTr:
            "Allah'ım! Muhammed'e ve Muhammed'in aline bereket ihsan eyle.",
        audioAsset: "audio/dualar/04_barik/barik-01.mp3",
      ),
      DuaSegment(
        id: 1,
        arabic: "كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيم ",
        meaningTr: "İbrahim'e ve İbrahim'in aline bereket ihsan ettiğin gibi.",
        audioAsset: "audio/dualar/04_barik/barik-02.mp3",
      ),
      DuaSegment(
        id: 2,
        arabic: " إِنَّكَ حَمِيدٌ مَجِيدٌٌَ",
        meaningTr: "Şüphesiz Sen hamde layıksın, şanı yüce olansın.",
        audioAsset: "audio/dualar/04_barik/barik-03.mp3",
      ),
    ],
  ),
  Dua(
    order: 5,
    id: "5_atina_duasi",
    titleTr: "Rabbenâ âtinâ",
    segments: [
      DuaSegment(
        id: 0,
        arabic:
            "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةًٍ",
        meaningTr: "Rabbimiz! Bize dünyada iyilik, ahirette de iyilik ver.",
        audioAsset: "audio/dualar/05_atina/atina-01.mp3",
      ),
      DuaSegment(
        id: 1,
        arabic: " وَقِنَا عَذَابَ النَّارِ ",
        meaningTr: "Bizi cehennem azabından koru.",
        audioAsset: "audio/dualar/05_atina/atina-02.mp3",
      ),
    ],
  ),
  Dua(
    order: 6,
    id: "6_rabbenafirli_duasi",
    titleTr: "Rabbenâğfirli",
    segments: [
      DuaSegment(
        id: 0,
        arabic:
            "رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابًٍُ",
        meaningTr:
            "Rabbimiz! Hesabın görüleceği gün beni, ana babamı ve bütün müminleri bağışla.",
        audioAsset: "audio/dualar/06_rabbenafirli/5-RABBENAGFIRLI.mp3",
      ),
    ],
  ),
  Dua(
    order: 7,
    id: "7_kunut1_duasi",
    titleTr: "Kunut Duası 1",
    segments: [
      DuaSegment(
        id: 0,
        arabic:
            "اَللَّهُمَّ إِنَّا نَسْتَعِينُكَ وَ نَسْتَغْفِرُكَ وَ نَسْتَهْدِيكَ",
        meaningTr:
            "Allah'ım! Senden yardım isteriz, Senden bağışlanma dileriz ve Senden hidayet isteriz.",
        audioAsset: "audio/dualar/07_kunut1/kunut_1-01.mp3",
      ),
      DuaSegment(
        id: 1,
        arabic:
            " وَ نُؤْمِنُ بِكَ وَ نَتُوبُ اِلَيْكَ   وَ نَتَوَكَّلُ عَلَيْكَ ",
        meaningTr: "Sana iman eder, Sana tevbe eder ve Sana tevekkül ederiz.",
        audioAsset: "audio/dualar/07_kunut1/kunut_1-02.mp3",
      ),
      DuaSegment(
        id: 2,
        arabic: " وَنُثْنِى عَلَيْك اْلخَيْرَ كُلَّهُ ",
        meaningTr: "Seni hayırla överiz.",
        audioAsset: "audio/dualar/07_kunut1/kunut_1-03.mp3",
      ),
      DuaSegment(
        id: 3,
        arabic: "نَشْكُرُكَ وَ لاَ نَكْفُرُكَ ",
        meaningTr: "Sana şükreder, nankörlük etmeyiz.",
        audioAsset: "audio/dualar/07_kunut1/kunut_1-04.mp3",
      ),
      DuaSegment(
        id: 4,
        arabic: " وَ نَخْلَعُ وَ نَتْرُكُ مَنْ يَفْجُرُكَ",
        meaningTr: "Sana karşı gelenleri terk eder ve onlardan uzaklaşırız.",
        audioAsset: "audio/dualar/07_kunut1/kunut_1-05.mp3",
      ),
    ],
  ),
  Dua(
    order: 8,
    id: "8_kunut2_duasi",
    titleTr: "Kunut Duası 2",
    segments: [
      DuaSegment(
        id: 0,
        arabic: "اَللَّهُمَّ اِيَّاكَ نَعْبُدُ وَ لَكَ نُصَلِّى",
        meaningTr:
            "Allah'ım! Ancak Sana kulluk eder, Senin için namaz kılarız.",
        audioAsset: "audio/dualar/08_kunut2/kunut_2-01.mp3",
      ),
      DuaSegment(
        id: 1,
        arabic: "وَ نَسْجُدُ وَ اِلَيْكَ نَسعْىَ وَ نَحْفِدُ",
        meaningTr: "Sana secde eder, Sana yönelir ve Sana koşarız.",
        audioAsset: "audio/dualar/08_kunut2/kunut_2-02.mp3",
      ),
      DuaSegment(
        id: 2,
        arabic: " نَرْجُو رَحْمَتَكَ وَ نَخْشَى عَذَابَك",
        meaningTr: "Rahmetini umar, azabından korkarız.",
        audioAsset: "audio/dualar/08_kunut2/kunut_2-03.mp3",
      ),
      DuaSegment(
        id: 3,
        arabic: " اِنَّ عَذَابَكَ بِاْلكُفَّارِ مُلْحِقٌ",
        meaningTr: "Şüphesiz Senin azabın kafirlere ulaşacaktır.",
        audioAsset: "audio/dualar/08_kunut2/kunut_2-04.mp3",
      ),
    ],
  ),
  Dua(
    order: 9,
    id: "9_amentu_duasi",
    titleTr: "Amentü",
    segments: [
      DuaSegment(
        id: 0,
        arabic: "آمَنْتُ بِاللّٰهِ وَمَلٰائِكَتِهٖ وَكُتُبِهٖ وَرُسُلِهٖ",
        meaningTr:
            "Allah'a, meleklerine, kitaplarına ve peygamberlerine iman ettim.",
        audioAsset: "audio/dualar/09_amentu/amentu-01.mp3",
      ),
      DuaSegment(
        id: 1,
        arabic:
            " وَالْيَوْمِ الْاٰخِرِ وَبِالْقَدَرِ خَيْرِهٖ وَشَرِّهٖ مِنَ اللّٰهِ تَعٰالٰىُ",
        meaningTr:
            "Ahiret gününe, kadere; hayrın ve şerrin Allah'tan olduğuna iman ettim.",
        audioAsset: "audio/dualar/09_amentu/amentu-02.mp3",
      ),
      DuaSegment(
        id: 2,
        arabic: "وَالْبَعْثُ بَعْدَ الْمَوْتِ حَقٌّ",
        meaningTr: "Öldükten sonra dirilmek haktır.",
        audioAsset: "audio/dualar/09_amentu/amentu-03.mp3",
      ),
      DuaSegment(
        id: 3,
        arabic: "اَشْهَدُ اَنْ لٰا اِلٰهَ اِلَّا اللّٰهُ ",
        meaningTr: "Şahitlik ederim ki Allah'tan başka ilah yoktur.",
        audioAsset: "audio/dualar/09_amentu/amentu-04.mp3",
      ),
      DuaSegment(
        id: 4,
        arabic: "وَاَشْهَدُ اَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ ",
        meaningTr: "Yine şahitlik ederim ki Muhammed O'nun kulu ve resulüdür.",
        audioAsset: "audio/dualar/09_amentu/amentu-05.mp3",
      ),
    ],
  ),
];
