import '../models/surah.dart';

class PublishedAyahMeaning {
  const PublishedAyahMeaning(
    this.text,
    this.footnotes,
    this.title,
    this.version,
    this.url,
    this.description,
  );
  final String text, footnotes, title, version, url, description;
  String get attribution => '$title · v$version · QuranEnc.com\n$url';
}

const kAyatelKursiMeanings = <String, PublishedAyahMeaning>{
  "tr": PublishedAyahMeaning(
    "Allah o İlâhtır ki Kendisinden başka ilâh yoktur. Haydır, kayyûmdur kendisini ne bir uyuklama, ne uyku tutamaz. Göklerde ve yerde ne varsa O'nundur. İzni olmadan huzurunda şefaat etmek kimin haddine? Yarattığı mahlûkların önünde ardında ne var, hepsini bilir. Mahlûklar ise O’nun dilediğinden başka, ilminden hiçbir şey kavrayamazlar. O’nun kürsüsü gökleri ve yeri kaplamıştır. Gökleri ve yeri koruyup gözetmek O’na ağır gelmez, O öyle ulu, öyle büyüktür. [19,93-95; 53,26; 21,28; 20,110] [KM, Tesniye 5,26; Tekvin 21,33; Çıkış 3,15]",
    "",
    "Turkish Translation - Dr. Ali Ozek and others",
    "1.0.0",
    "https://quranenc.com/en/browse/turkish_shahin/2#255",
    "Translated by Ali Ozek and others, developed under the supervision of Rowad Translation Center. The original translation is available for expressing opinion, evaluation, and continuous development.",
  ),
  "es": PublishedAyahMeaning(
    "255. ¡Dios! No existe nada ni nadie con derecho a ser adorado excepto Él, el Viviente [Eterno], el Sustentador [y Gobernador de toda la creación][1]. No Lo afectan somnolencia ni sueño. Suyo es cuanto hay en los cielos y la Tierra. ¿Quién podrá interceder ante Él si no es con Su permiso? Conoce el pasado y el futuro [lo manifiesto y lo oculto] y nadie abarca de Su conocimiento salvo lo que Él quiere. El escabel de Su Trono[2] abarca los cielos y la Tierra, y la custodia [y mantenimiento] de ambos no Lo agobia. Y Él es el Sublime, el Grandioso.",
    "[1] Este sublime nombre de Dios, Al-Qaium, indica que se basta a Sí mismo y sustenta a la creación; es decir, que Él no necesita de nadie, y todo necesita de Él.\n[2] Kursi كرسي, es el escabel del Trono, que no debe ser confundido con el ‘Arsh عرش, el Trono, que es inmensamente mayor.",
    "Spanish Translation - Isa Garcia",
    "1.0.2",
    "https://quranenc.com/en/browse/spanish_garcia/2#255",
    "Translated by Muhammad Isa Garcia",
  ),
  "fr": PublishedAyahMeaning(
    "Allah ! Il n’est de divinité digne d’être adorée que Lui, le Dieu Vivant et Eternel[156]. Il n’est gagné ni par le sommeil, ni même par la somnolence. Tout ce qui se trouve dans les cieux et sur la terre Lui appartient. Qui donc pourrait intercéder auprès de Lui sans Sa permission ? Il connaît leur avenir comme leur passé[157], tandis que les hommes n’embrassent de Sa science et de Ses mystères que ce qu’Il veut bien leur dévoiler. Son Koursi[158] embrasse les cieux et la terre dont Il assure la pérennité sans aucune difficulté. Il est le Très Haut, le Très Glorieux.",
    "[156]Qui règne en Maître absolu sur la Création et dont dépendent toutes les créatures qui ont besoin de Lui pour vivre et subsister, tandis que Lui-même peut se passer d’elles.\n[157] Littéralement : Il sait ce qui se trouve devant eux comme ce qui se trouve derrière eux.\n[158] Son Repose-Pied, selon nombre d’exégètes, Son Trône, selon d’autres.",
    "French Translation - Rachid Maach",
    "1.0.3",
    "https://quranenc.com/en/browse/french_rashid/2#255",
    "Translated by Rashid Ma’ash",
  ),
  "de": PublishedAyahMeaning(
    "Allah - es gibt keinen Gott außer Ihm, dem Lebendigen und Beständigen. Ihn überkommt weder Schlummer noch Schlaf. Ihm gehört (alles), was in den Himmeln und was auf der Erde ist. Wer ist es denn, der bei Ihm Fürsprache einlegen könnte - außer mit Seiner Erlaubnis? Er weiß, was vor ihnen und was hinter ihnen liegt, sie aber umfassen nichts von Seinem Wissen - außer, was Er will. Sein Thronschemel umfaßt die Himmel und die Erde, und ihre Behütung beschwert Ihn nicht. Er ist der Erhabene und Allgewaltige.",
    "",
    "German Translation - Frank Bubenheim",
    "1.1.4",
    "https://quranenc.com/en/browse/german_bubenheim/2#255",
    "Translated by ‘Abdullah as-Sāmit (Frank Bubenheim) and Dr. Nadim Elias.",
  ),
  "en": PublishedAyahMeaning(
    "Allāh - there is no deity except Him, the Ever-Living,[98] the Self-Sustaining.[99] Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them,[100] and they encompass not a thing of His knowledge except for what He wills. His Kursī[101] extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High,[102] the Most Great.[103]",
    "[98] Whose life is perfect, complete and eternal, without beginning or end, and through whom all created life originated and continues.\n[99] Dependent on none for His existence while being the sustainer and administrator of all created existence.\n[100] Allāh's knowledge encompasses every aspect of His creations in the past, present and future.\n[101] Chair or footstool. It is not to be confused with al-ʿArsh (the Throne) , which is infinitely higher and greater than al-Kursī.\n[102] Above all of His creations and superior to them in essence, rank and position.\n[103] Whose greatness is unlimited, beyond description or imagination.",
    "English Translation - Noor International Center",
    "1.1.2",
    "https://quranenc.com/en/browse/english_saheeh/2#255",
    "Issued by Noor International Center.",
  ),
  "bs": PublishedAyahMeaning(
    "Allah je, nema boga osim Njega, Živi i Samoopstojeći Održavatelj! Ne obuzima Ga ni drijemež ni san! Njegovo je ono što je na nebesima i na Zemlji! Ko se može pred Njim zauzimati bez Njegovog dopuštenja?! On zna šta je bilo prije i šta će biti poslije njih i oni ne mogu obuhvatiti od Njegovoga znanja osim koliko On želi. Njegova Kursija obuhvata i nebesa i Zemlju i Njemu nije teško održavati ih! On je Svevišnji i Veličanstveni! ",
    "",
    "Bosnian Translation - Muhammad Mahanovic",
    "1.1.0",
    "https://quranenc.com/en/browse/bosnian_mihanovich/2#255",
    "Translated by Muhammad Mahanovic, developed under the supervision of Rowwad Translation Center. The original translation is available for the purpose of expressing opinion, evaluation, and continuous development.",
  ),
  "nl": PublishedAyahMeaning(
    "Allah! Er is geen godheid dan Hij (die het recht heeft aanbeden te worden), de eeuwig Levende, de Zelfstandige. Sluimer noch slaap overmant Hem. Hij is de Bezitter van de hemelen en de aarde, en al wat er zich in bevindt. Wie kan bij Hem bemiddelen zonder Zijn toestemming? Hij is niet alleen op de hoogte van hun openlijke daden maar ook van hun stiekem gedrag. Zij kunnen niets van Zijn kennis onthullen, tenzij Hij dat wil. Zijn troon strekt zich uit (ver) over de hemelen en de aarde, (maar) het waken hierover vermoeit Hem helemaal niet. Hij is de meest Verhevene, de Almachtige.",
    "",
    "Dutch Translation - Rowwad Translation Center",
    "2.0.10",
    "https://quranenc.com/en/browse/dutch_center/2#255",
    "Issued by the Dutch Islamic Center and developed under the supervision of Rowwad Translation Center",
  ),
};

/// Bakara 255 in the nine phrases the recording reads one by one
/// ([Ayet.verse]). Arabic: the owner's Quran text (`kuran.docx`, Turkish
/// mushaf spelling; `tool/sources/kuran_docx_phrases.json`).
const kAyatelKursi = Surah(
  order: 12,
  id: 'ayetel-kursi',
  titleTr: 'Âyetel Kürsî',
  arabicName: 'آية الكرسي',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/12_ayetel-kursi/00_besmele.mp3',
  ayetler: [
    Ayet(
      number: 1,
      arabic: "اَللّٰهُ لَٓا اِلٰهَ اِلَّا هُوَۚ اَلْحَيُّ الْقَيُّومُۚ",
      meaningTr:
          "Allah o İlâhtır ki Kendisinden başka ilâh yoktur. Haydır, kayyûmdur.",
      audioAsset: 'audio/sureler/12_ayetel-kursi/01_ayet.mp3',
      verse: 255,
    ),
    Ayet(
      number: 2,
      arabic: "لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌۜ",
      meaningTr: "Kendisini ne bir uyuklama, ne uyku tutamaz.",
      audioAsset: 'audio/sureler/12_ayetel-kursi/02_ayet.mp3',
      verse: 255,
    ),
    Ayet(
      number: 3,
      arabic: "لَهُ مَا فِي السَّمٰوَاتِ وَمَا فِي الْاَرْضِۜ",
      meaningTr: "Göklerde ve yerde ne varsa O'nundur.",
      audioAsset: 'audio/sureler/12_ayetel-kursi/03_ayet.mp3',
      verse: 255,
    ),
    Ayet(
      number: 4,
      arabic: "مَنْ ذَا الَّذ۪ي يَشْفَعُ عِنْدَهُٓ اِلَّا بِاِذْنِه۪ۜ",
      meaningTr: "İzni olmadan huzurunda şefaat etmek kimin haddine?",
      audioAsset: 'audio/sureler/12_ayetel-kursi/04_ayet.mp3',
      verse: 255,
    ),
    Ayet(
      number: 5,
      arabic: "يَعْلَمُ مَا بَيْنَ اَيْد۪يهِمْ وَمَا خَلْفَهُمْۚ",
      meaningTr: "Yarattığı mahlûkların önünde ardında ne var, hepsini bilir.",
      audioAsset: 'audio/sureler/12_ayetel-kursi/05_ayet.mp3',
      verse: 255,
    ),
    Ayet(
      number: 6,
      arabic: "وَلَا يُح۪يطُونَ بِشَيْءٍ مِنْ عِلْمِه۪ٓ اِلَّا بِمَا شَٓاءَۚ",
      meaningTr:
          "Mahlûklar ise O’nun dilediğinden başka, ilminden hiçbir şey kavrayamazlar.",
      audioAsset: 'audio/sureler/12_ayetel-kursi/06_ayet.mp3',
      verse: 255,
    ),
    Ayet(
      number: 7,
      arabic: "وَسِعَ كُرْسِيُّهُ السَّمٰوَاتِ وَالْاَرْضَۚ",
      meaningTr: "O’nun kürsüsü gökleri ve yeri kaplamıştır.",
      audioAsset: 'audio/sureler/12_ayetel-kursi/07_ayet.mp3',
      verse: 255,
    ),
    Ayet(
      number: 8,
      arabic: "وَلَا يَؤُ۫دُهُ حِفْظُهُمَاۚ",
      meaningTr: "Gökleri ve yeri koruyup gözetmek O’na ağır gelmez,",
      audioAsset: 'audio/sureler/12_ayetel-kursi/08_ayet.mp3',
      verse: 255,
    ),
    Ayet(
      number: 9,
      arabic: "وَهُوَ الْعَلِيُّ الْعَظ۪يمُ",
      meaningTr: "O öyle ulu, öyle büyüktür.",
      audioAsset: 'audio/sureler/12_ayetel-kursi/09_ayet.mp3',
      verse: 255,
    ),
  ],
);

/// Bakara 285-286 ("Âmenerrasûlü") in the recording's 15 phrases
/// ([Ayet.verse]); Arabic from `kuran.docx` like [kAyatelKursi]. Listed
/// last (order 24) so the other surahs keep their numbers and folders.
const kAmenerrasulu = Surah(
  order: 24,
  id: 'amenerrasulu',
  titleTr: 'Âmenerrasûlü',
  arabicName: 'آمن الرسول',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/24_amenerrasulu/00_besmele.mp3',
  ayetler: [
    Ayet(
      number: 1,
      arabic:
          "اٰمَنَ الرَّسُولُ بِمَٓا اُنْزِلَ اِلَيْهِ مِنْ رَبِّه۪ وَالْمُؤْمِنُونَۜ",
      meaningTr:
          "Peygamber, Rabbi tarafından kendisine ne indirildi ise ona iman etti, müminler de!",
      audioAsset: 'audio/sureler/24_amenerrasulu/01_ayet.mp3',
      verse: 285,
    ),
    Ayet(
      number: 2,
      arabic: "كُلٌّ اٰمَنَ بِاللّٰهِ وَمَلٰٓئِكَتِه۪ وَكُتُبِه۪ وَرُسُلِه۪ۜ",
      meaningTr:
          "Onlardan her biri Allah'a, meleklerine, kitaplarına ve peygamberlerine iman etti.",
      audioAsset: 'audio/sureler/24_amenerrasulu/02_ayet.mp3',
      verse: 285,
    ),
    Ayet(
      number: 3,
      arabic: "لَا نُفَرِّقُ بَيْنَ اَحَدٍ مِنْ رُسُلِه۪۠",
      meaningTr:
          "“O’nun resullerinden hiç birini diğerinden ayırt etmeyiz.” dediler",
      audioAsset: 'audio/sureler/24_amenerrasulu/03_ayet.mp3',
      verse: 285,
    ),
    Ayet(
      number: 4,
      arabic: "وَقَالُوا سَمِعْنَا وَاَطَعْنَا",
      meaningTr: "ve eklediler: “İşittik ve itaat ettik.",
      audioAsset: 'audio/sureler/24_amenerrasulu/04_ayet.mp3',
      verse: 285,
    ),
    Ayet(
      number: 5,
      arabic: "غُفْرَانَكَ رَبَّنَا وَاِلَيْكَ الْمَص۪يرُ",
      meaningTr: "Ya Rabbenâ, affını dileriz, dönüşümüz Sanadır.”",
      audioAsset: 'audio/sureler/24_amenerrasulu/05_ayet.mp3',
      verse: 285,
    ),
    Ayet(
      number: 6,
      arabic: "لَا يُكَلِّفُ اللّٰهُ نَفْسًا اِلَّا وُسْعَهَاۜ",
      meaningTr:
          "Allah hiçbir kimseyi güç yetiremeyeceği bir şekilde yükümlü tutmaz.",
      audioAsset: 'audio/sureler/24_amenerrasulu/06_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 7,
      arabic: "لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْۜ",
      meaningTr:
          "Herkesin kazandığı iyilik kendi lehine, işlediği fenalık da kendi aleyhinedir.",
      audioAsset: 'audio/sureler/24_amenerrasulu/07_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 8,
      arabic: "رَبَّنَا لَا تُؤَاخِذْنَٓا اِنْ نَس۪ينَٓا اَوْ اَخْطَأْنَاۚ",
      meaningTr:
          "Ya Rabbenâ! Eğer unuttuk veya kasıtsız olarak yanlış yaptıysak bundan dolayı bizi sorumlu tutma!",
      audioAsset: 'audio/sureler/24_amenerrasulu/08_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 9,
      arabic: "رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَٓا اِصْرًا",
      meaningTr: "Ya Rabbenâ! Bize ağır yük yükleme,",
      audioAsset: 'audio/sureler/24_amenerrasulu/09_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 10,
      arabic: "كَمَا حَمَلْتَهُ عَلَى الَّذ۪ينَ مِنْ قَبْلِنَاۚ",
      meaningTr: "bizden öncekilere yüklediğin gibi!",
      audioAsset: 'audio/sureler/24_amenerrasulu/10_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 11,
      arabic: "رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِه۪ۚ",
      meaningTr:
          "Ya Rabbenâ! Takat getiremeyeceğimiz şeylerle bizi yükümlü tutma!",
      audioAsset: 'audio/sureler/24_amenerrasulu/11_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 12,
      arabic: "وَاعْفُ عَنَّا۠",
      meaningTr: "Affet bizi,",
      audioAsset: 'audio/sureler/24_amenerrasulu/12_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 13,
      arabic: "وَاغْفِرْ لَنَا۠",
      meaningTr: "lütfen bağışla kusurlarımızı,",
      audioAsset: 'audio/sureler/24_amenerrasulu/13_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 14,
      arabic: "وَارْحَمْنَا۠",
      meaningTr: "merhamet buyur bize!",
      audioAsset: 'audio/sureler/24_amenerrasulu/14_ayet.mp3',
      verse: 286,
    ),
    Ayet(
      number: 15,
      arabic: "اَنْتَ مَوْلٰينَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِر۪ينَ",
      meaningTr:
          "Sensin Mevlâmız, yardımcımız! Kâfir topluluklara karşı Sen yardım eyle bize!",
      audioAsset: 'audio/sureler/24_amenerrasulu/15_ayet.mp3',
      verse: 286,
    ),
  ],
);

/// Fetih 28-29 ("Hüvellezî ersele") in the 2011 recording's 13 phrases
/// (H:/Music/sureler/4/3-HUVELLEZI ERSELE.mp3, [Ayet.verse]); some phrases
/// restart with the previous one's last words, as read. Arabic from
/// `kuran.docx` (tool/sources/kuran_docx_fetih.json). Order 25: after
/// [kAmenerrasulu], so no folder or number moves.
const kHuvellezi = Surah(
  order: 25,
  id: 'huvellezi',
  titleTr: 'Hüvellezî Ersele (Fetih 28–29)',
  arabicName: 'هُوَ الَّذ۪ٓي اَرْسَلَ',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ',
  besmeleAudioAsset: 'audio/sureler/25_huvellezi/00_besmele.mp3',
  ayetler: [
    Ayet(
      number: 1,
      arabic:
          "هُوَ الَّذ۪ٓي اَرْسَلَ رَسُولَهُ بِالْهُدٰى وَد۪ينِ الْحَقِّ لِيُظْهِرَهُ",
      meaningTr: "Resulünü hidâyet ve hak dinle gönderen O'dur;",
      audioAsset: 'audio/sureler/25_huvellezi/01_ayet.mp3',
      verse: 28,
    ),
    Ayet(
      number: 2,
      arabic: "لِيُظْهِرَهُ عَلَى الدّ۪ينِ كُلِّه۪ۜ",
      meaningTr: "onu bütün dinlere üstün kılmak için.",
      audioAsset: 'audio/sureler/25_huvellezi/02_ayet.mp3',
      verse: 28,
    ),
    Ayet(
      number: 3,
      arabic: "وَكَفٰى بِاللّٰهِ شَه۪يدًاۜ",
      meaningTr: "Buna şahit olarak Allah yeter.",
      audioAsset: 'audio/sureler/25_huvellezi/03_ayet.mp3',
      verse: 28,
    ),
    Ayet(
      number: 4,
      arabic: "مُحَمَّدٌ رَسُولُ اللّٰهِۜ",
      meaningTr: "Muhammed Allah'ın resulüdür.",
      audioAsset: 'audio/sureler/25_huvellezi/04_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 5,
      arabic:
          "وَالَّذ۪ينَ مَعَهُٓ اَشِدَّٓاءُ عَلَى الْكُفَّارِ رُحَمَٓاءُ بَيْنَهُمْ",
      meaningTr:
          "Onun beraberindeki müminler de kâfirlere karşı şiddetli olup kendi aralarında şefkatlidirler.",
      audioAsset: 'audio/sureler/25_huvellezi/05_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 6,
      arabic: "تَرٰيهُمْ رُكَّعًا سُجَّدًا يَبْتَغُونَ فَضْلًا",
      meaningTr:
          "Sen onları rükû ederken, secde ederken, lütuf ararken görürsün;",
      audioAsset: 'audio/sureler/25_huvellezi/06_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 7,
      arabic: "يَبْتَغُونَ فَضْلًا مِنَ اللّٰهِ وَرِضْوَانًاۘ",
      meaningTr: "Allah’tan lütuf ve rıza ararken.",
      audioAsset: 'audio/sureler/25_huvellezi/07_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 8,
      arabic: "س۪يمَاهُمْ ف۪ي وُجُوهِهِمْ مِنْ اَثَرِ السُّجُودِۜ",
      meaningTr: "Onların alâmeti, yüzlerindeki secde izi, secde aydınlığıdır.",
      audioAsset: 'audio/sureler/25_huvellezi/08_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 9,
      arabic:
          "ذٰلِكَ مَثَلُهُمْ فِي التَّوْرٰيةِۚۛ وَمَثَلُهُمْ فِي الْاِنْج۪يلِ۠ۛ",
      meaningTr:
          "Bunlar, Tevrat’taki sıfatları olup İncîl’deki meselleri ise şöyledir:",
      audioAsset: 'audio/sureler/25_huvellezi/09_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 10,
      arabic:
          "كَزَرْعٍ اَخْرَجَ شَطْـَٔهُ۫ فَاٰزَرَهُ فَاسْتَغْلَظَ فَاسْتَوٰى",
      meaningTr:
          "Öyle bir ekin ki filizini çıkarmış, sonra da onu kuvvetlendirmiş, derken kalınlaşmış da",
      audioAsset: 'audio/sureler/25_huvellezi/10_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 11,
      arabic:
          "فَاسْتَوٰى عَلٰى سُوقِه۪ يُعْجِبُ الزُّرَّاعَ لِيَغ۪يظَ بِهِمُ الْكُفَّارَۜ",
      meaningTr:
          "artık gövdesi üzerinde doğrulmuş. Öyle ki ekicilerin hoşuna gider, kâfirleri de öfkelendirir.",
      audioAsset: 'audio/sureler/25_huvellezi/11_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 12,
      arabic:
          "وَعَدَ اللّٰهُ الَّذ۪ينَ اٰمَنُوا وَعَمِلُوا الصَّالِحَاتِ مِنْهُمْ",
      meaningTr:
          "İşte böylece Allah, onlar gibi iman edip makbul ve güzel işler yapanlara",
      audioAsset: 'audio/sureler/25_huvellezi/12_ayet.mp3',
      verse: 29,
    ),
    Ayet(
      number: 13,
      arabic: "مِنْهُمْ مَغْفِرَةً وَاَجْرًا عَظ۪يمًا",
      meaningTr:
          "mağfiret ve büyük bir mükâfat hazırlamıştır. [5,54] {KM, Vahiy 14,1; Matta 13, 31-32; Markos 4,26-27; Luka 13,18}",
      audioAsset: 'audio/sureler/25_huvellezi/13_ayet.mp3',
      verse: 29,
    ),
  ],
);

/// Haşr 22-24 ("Hüvallâhüllezî", read after the morning and evening
/// prayers) in the 10 phrases of the user's recording
/// (TransferXL/4-HUALLAHULLAVI.wav, split at its pauses; [Ayet.verse]);
/// "el-cebbâr" and "el-musavvir" are read twice, as recorded. Arabic from
/// `kuran.docx` (tool/sources/kuran_docx_hasr.json). Order 26.
const kHuvallahullezi = Surah(
  order: 26,
  id: 'huvallahullezi',
  titleTr: 'Hüvallâhüllezî (Haşr 22–24)',
  arabicName: 'هُوَ اللّٰهُ الَّذ۪ي',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ',
  besmeleAudioAsset: 'audio/sureler/26_huvallahullezi/00_besmele.mp3',
  ayetler: [
    Ayet(
      number: 1,
      arabic:
          "هُوَ اللّٰهُ الَّذ۪ي لَٓا اِلٰهَ اِلَّا هُوَۚ عَالِمُ الْغَيْبِ وَالشَّهَادَةِۚ",
      meaningTr:
          "Allah'tır gerçek İlah! O’ndan başka yoktur ilah. Görünmeyen ve görünen her şeyi bilir.",
      audioAsset: 'audio/sureler/26_huvallahullezi/01_ayet.mp3',
      verse: 22,
    ),
    Ayet(
      number: 2,
      arabic: "هُوَ الرَّحْمٰنُ الرَّح۪يمُ",
      meaningTr: "O rahmandır, rahîmdir. [1,3; 10,58; 7,156; 6,54]",
      audioAsset: 'audio/sureler/26_huvallahullezi/02_ayet.mp3',
      verse: 22,
    ),
    Ayet(
      number: 3,
      arabic: "هُوَ اللّٰهُ الَّذ۪ي لَٓا اِلٰهَ اِلَّا هُوَۚ",
      meaningTr: "Allah'tır gerçek İlah! O’ndan başka yoktur ilah!",
      audioAsset: 'audio/sureler/26_huvallahullezi/03_ayet.mp3',
      verse: 23,
    ),
    Ayet(
      number: 4,
      arabic:
          "اَلْمَلِكُ الْقُدُّوسُ السَّلَامُ الْمُؤْمِنُ الْمُهَيْمِنُ الْعَز۪يزُ الْجَبَّارُ",
      meaningTr:
          "O melik’tir, kuddûs’tür, selâm’dır, Mü’min’dir, müheymin’dir, aziz’dir, cebbar’dır,",
      audioAsset: 'audio/sureler/26_huvallahullezi/04_ayet.mp3',
      verse: 23,
    ),
    Ayet(
      number: 5,
      arabic: "الْجَبَّارُ الْمُتَكَبِّرُۜ",
      meaningTr: "cebbar’dır, mütekebbir’dir.",
      audioAsset: 'audio/sureler/26_huvallahullezi/05_ayet.mp3',
      verse: 23,
    ),
    Ayet(
      number: 6,
      arabic: "سُبْحَانَ اللّٰهِ عَمَّا يُشْرِكُونَ",
      meaningTr: "Allah, müşriklerin iddialarından münezzeh ve yücedir. [62,1]",
      audioAsset: 'audio/sureler/26_huvallahullezi/06_ayet.mp3',
      verse: 23,
    ),
    Ayet(
      number: 7,
      arabic: "هُوَ اللّٰهُ الْخَالِقُ الْبَارِئُ الْمُصَوِّرُ",
      meaningTr: "Allah o gerçek İlahtır ki halık'tır, bârî’dir, musavvir’dir.",
      audioAsset: 'audio/sureler/26_huvallahullezi/07_ayet.mp3',
      verse: 24,
    ),
    Ayet(
      number: 8,
      arabic: "الْمُصَوِّرُ لَهُ الْاَسْمَٓاءُ الْحُسْنٰىۜ",
      meaningTr: "Musavvir’dir; en güzel isimler ve vasıflar O’nundur.",
      audioAsset: 'audio/sureler/26_huvallahullezi/08_ayet.mp3',
      verse: 24,
    ),
    Ayet(
      number: 9,
      arabic: "يُسَبِّحُ لَهُ مَا فِي السَّمٰوَاتِ وَالْاَرْضِۚ",
      meaningTr:
          "Göklerde ne var, yerde ne varsa hepsi O’nu tesbih ve tenzih eder.",
      audioAsset: 'audio/sureler/26_huvallahullezi/09_ayet.mp3',
      verse: 24,
    ),
    Ayet(
      number: 10,
      arabic: "وَهُوَ الْعَز۪يزُ الْحَك۪يمُ",
      meaningTr: "O, azizdir, hakimdir. [17,44]",
      audioAsset: 'audio/sureler/26_huvallahullezi/10_ayet.mp3',
      verse: 24,
    ),
  ],
);

// A verse excerpt, listed after the 11 surahs without renumbering them.
const kNamazAyetleri = <Surah>[kAyatelKursi];
