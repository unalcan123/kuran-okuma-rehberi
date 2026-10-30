import '../models/dua.dart';
import 'dualar_data.dart';

// Transcribed from user-supplied ref photographs, pages 37–41.
// 11, 12, 14: split and worded as the owner's recordings read them
// (ref/NAMAZLA ILGILI LAFIZLAR, one clip per part; "kayda göre" marks a
// part that differs from the book). A part without a recording is silent.
const kAdditionalDualar = <Dua>[
  // One sentence per card; the owner's recording (ref/ezanduasi) has no
  // "ve'd-derecete'r-refî'a" nor "inneke lâ tuhlifu'l-mîâd": those two stay
  // silent until they are recorded (the old long recording had bells).
  Dua(
    order: 10,
    id: "10_ezan_duasi",
    titleTr: "Ezan Duası",
    segments: [
      DuaSegment(
        id: 1,
        arabic: "اَللّٰهُمَّ رَبَّ هٰذِهِ الدَّعْوَةِ التَّامَّةِ",
        meaningTr: "Ey şu eksiksiz davetin",
        meanings: {
          "es": "Oh Allah, Señor de esta llamada perfecta",
          "fr": "Ô Allah, Seigneur de cet appel parfait",
          "de": "O Allah, Herr dieses vollkommenen Rufes",
          "en": "O Allah, Lord of this perfect call",
          "bs": "Allahu, Gospodaru ovog potpunog poziva",
          "nl": "O Allah, Heer van deze volmaakte oproep (tot gebed)",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/10_ezan_duasi/ezan-01.mp3',
      ),
      DuaSegment(
        id: 2,
        arabic: "وَالصَّلٰوةِ الْقَائِمَةِ",
        meaningTr: "ve kılınacak namazın Rabbi olan Allah'ım!",
        meanings: {
          "es": "y de la oración que se va a establecer,",
          "fr": "et de la prière qui va être accomplie,",
          "de": "und des bevorstehenden Gebets,",
          "en": "and of the prayer about to be established,",
          "bs": "i namaza koji će se obaviti,",
          "nl": "en van het gebed dat op het punt staat te worden verricht.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/10_ezan_duasi/ezan-02.mp3',
      ),
      DuaSegment(
        id: 3,
        arabic: "آتِ مُحَمَّدًا الْوَسٖيلَةَ وَالْفَضٖيلَةَ",
        meaningTr: "Muhammed'e (sav) vesîleyi ve fazîleti ver,",
        meanings: {
          "es": "concede a Muhammad la wasila y la excelencia,",
          "fr": "accorde à Muhammad la wasila et l'excellence,",
          "de": "gewähre Muhammad die Wasila und die Vorzüglichkeit,",
          "en": "grant Muhammad al-wasilah and excellence,",
          "bs": "podari Muhammedu vesilu i odlikovanost,",
          "nl":
              "Schenk onze meester Mohammed het recht van voorbede en de rang over de rest van de schepping,",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/10_ezan_duasi/ezan-03.mp3',
      ),
      DuaSegment(
        id: 4,
        arabic: "وَالدَّرَجَةَ الرَّفٖيعَةَ",
        meaningTr: "yüksek dereceyi de ver.",
        meanings: {
          "es": "y el grado elevado.",
          "fr": "ainsi que le rang élevé.",
          "de": "und den hohen Rang.",
          "en": "and the elevated rank.",
          "bs": "i visoki stepen.",
          "nl": "en de verheven graad.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: '',
      ),
      DuaSegment(
        id: 5,
        arabic: "وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذٖي وَعَدْتَهُ",
        meaningTr: "Onu, kendisine vaadettiğin makâm-ı mahmûda ulaştır.",
        meanings: {
          "es":
              "Y elévalo a la posición digna de alabanza que le has prometido.",
          "fr": "Et élève-le à la station louée que Tu lui as promise.",
          "de":
              "Und erwecke ihn zur lobenswerten Stellung, die Du ihm versprochen hast.",
          "en":
              "And raise him to the praiseworthy station You have promised him.",
          "bs": "I postavi ga na hvale dostojno mjesto koje si mu obećao.",
          "nl": "Verhef hem tot de geëerde positie die U hem hebt beloofd.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/10_ezan_duasi/ezan-04.mp3',
      ),
      DuaSegment(
        id: 6,
        arabic: "إِنَّكَ لَا تُخْلِفُ الْمٖيعَادَ",
        meaningTr: "Şüphesiz Sen vaadinden dönmezsin.",
        meanings: {
          "es": "Ciertamente, Tú no faltas a Tu promesa.",
          "fr": "Tu ne manques certes jamais à Ta promesse.",
          "de": "Du brichst wahrlich Dein Versprechen nicht.",
          "en": "Indeed, You never break Your promise.",
          "bs": "Ti, zaista, ne kršiš Svoje obećanje.",
          "nl": "Voorwaar, U faalt nooit in Uw Belofte.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: '',
      ),
    ],
  ),
  Dua(
    order: 11,
    id: "11_namaz_tekbir_tesbih",
    titleTr: "Namazdaki Tekbir, Tahmid ve Tesbihler",
    segments: [
      DuaSegment(
        id: 1,
        arabic: "اَللّٰهُ أَكْبَرُ",
        meaningTr: "Allah en büyük ve en yücedir.",
        meanings: {
          "es": "Allah es el más grande.",
          "fr": "Allah est le plus grand.",
          "de": "Allah ist am größten.",
          "en": "Allah is the greatest.",
          "bs": "Allah je najveći.",
          "nl": "Allah is de Almachtige.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_01.mp3',
      ),
      DuaSegment(
        id: 2,
        arabic: "سُبْحَانَ رَبِّيَ الْعَظٖيمِ",
        meaningTr:
            "Ey büyük Rabb'ım! Seni bütün noksan sıfatlardan tenzih ederim.",
        meanings: {
          "es":
              "Glorificado sea mi Señor, el Magnífico, libre de toda imperfección.",
          "fr":
              "Gloire à mon Seigneur, l'Immense, exempt de toute imperfection.",
          "de":
              "Gepriesen sei mein Herr, der Gewaltige, frei von jeder Unvollkommenheit.",
          "en":
              "Glory be to my Lord, the Magnificent, free from every imperfection.",
          "bs":
              "Slavljen neka je moj Gospodar Veličanstveni, čist od svakog nedostatka.",
          "nl": "Alglorieus is mijn Heer, de Almachtige.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_02.mp3',
      ),
      DuaSegment(
        id: 3,
        arabic: "سُبْحَانَ رَبِّيَ الْأَعْلٰى",
        meaningTr:
            "Ey Yüce Rabb'im! Seni bütün noksan sıfatlardan tenzih ederim.",
        meanings: {
          "es":
              "Glorificado sea mi Señor, el Altísimo, libre de toda imperfección.",
          "fr":
              "Gloire à mon Seigneur, le Très-Haut, exempt de toute imperfection.",
          "de":
              "Gepriesen sei mein Herr, der Allerhöchste, frei von jeder Unvollkommenheit.",
          "en":
              "Glory be to my Lord, the Most High, free from every imperfection.",
          "bs":
              "Slavljen neka je moj Gospodar Svevišnji, čist od svakog nedostatka.",
          "nl": "Alglorieus is mijn Heer, de Allerhoogste.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_05.mp3',
      ),
      DuaSegment(
        id: 4,
        arabic: "سَمِعَ اللّٰهُ لِمَنْ حَمِدَهُ",
        meaningTr: "Allah kendisine hamd edenleri işitti",
        meanings: {
          "es": "Allah escucha a quien Lo alaba.",
          "fr": "Allah entend celui qui Le loue.",
          "de": "Allah hört denjenigen, der Ihn lobt.",
          "en": "Allah hears the one who praises Him.",
          "bs": "Allah čuje onoga ko Ga hvali.",
          "nl": "Allah hoort hem die Hem prijst.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_03.mp3',
      ),
      DuaSegment(
        id: 5,
        arabic: "رَبَّنَا وَلَكَ الْحَمْدُ",
        meaningTr: "Ey Rabbimiz! Her çeşit hamd ancak sanadır.",
        meanings: {
          "es": "Señor nuestro, a Ti pertenece toda alabanza.",
          "fr": "Notre Seigneur, à Toi toute la louange.",
          "de": "Unser Herr, Dir gebührt alles Lob.",
          "en": "Our Lord, to You belongs all praise.",
          "bs": "Gospodaru naš, Tebi pripada sva hvala.",
          "nl": "Onze Heer, en aan U is de lof.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 38 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_04.mp3',
      ),
      DuaSegment(
        id: 6,
        arabic: "اَلسَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ",
        meaningTr: "Allah'ın selamı ve rahmeti üzerinize olsun.",
        meanings: {
          "es": "La paz y la misericordia de Allah sean con vosotros.",
          "fr": "Que la paix et la miséricorde d'Allah soient sur vous.",
          "de": "Allahs Friede und Barmherzigkeit seien mit euch.",
          "en": "May Allah's peace and mercy be upon you.",
          "bs": "Neka su na vas Allahov mir i milost.",
          "nl": "Vrede zij met u, en Allah’s Genade (zij met u).",
        },

        instruction: "Sağa",
        meaningSource: "Elifbe · ref · s. 38",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_06.mp3',
      ),
      DuaSegment(
        id: 7,
        arabic: "اَلسَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ",
        meaningTr: "Allah'ın selamı ve rahmeti üzerinize olsun.",
        meanings: {
          "es": "La paz y la misericordia de Allah sean con vosotros.",
          "fr": "Que la paix et la miséricorde d'Allah soient sur vous.",
          "de": "Allahs Friede und Barmherzigkeit seien mit euch.",
          "en": "May Allah's peace and mercy be upon you.",
          "bs": "Neka su na vas Allahov mir i milost.",
          "nl": "Vrede zij met u, en Allah’s Genade (zij met u).",
        },

        instruction: "Sola",
        meaningSource: "Elifbe · ref · s. 38 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_07.mp3',
      ),
    ],
  ),
  Dua(
    order: 12,
    id: "12_namaz_tesbihati",
    titleTr: "Namaz Tesbihatı",
    segments: [
      DuaSegment(
        id: 1,
        arabic:
            "أَسْتَغْفِرُ اللّٰهَ أَسْتَغْفِرُ اللّٰهَ أَسْتَغْفِرُ اللّٰهَ الْعَظٖيمَ الْكَرٖيمَ الَّذٖي لَا إِلٰهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ",
        meaningTr:
            "Allah’tan bağışlanma dilerim. Allah’tan bağışlanma dilerim. Kendisinden başka ilah olmayan, daima diri ve her şeyi ayakta tutan, yüce ve kerem sahibi Allah’tan bağışlanma diler, O’na tövbe ederim.",
        meanings: {
          "es":
              "Pido perdón a Allah. Pido perdón a Allah. Pido perdón a Allah, el Magnífico, el Generoso, fuera de Quien no hay divinidad, el Viviente, el Sustentador, y me arrepiento ante Él.",
          "fr":
              "Je demande pardon à Allah. Je demande pardon à Allah. Je demande pardon à Allah, l'Immense, le Généreux, en dehors de qui il n'y a de divinité, le Vivant, Celui qui subsiste par Lui-même, et je me repens à Lui.",
          "de":
              "Ich bitte Allah um Vergebung. Ich bitte Allah um Vergebung. Ich bitte Allah, den Gewaltigen, den Großzügigen, um Vergebung. Es gibt keine Gottheit außer Ihm, dem Lebendigen, dem Beständigen, und ich wende mich Ihm reumütig zu.",
          "en":
              "I ask Allah for forgiveness. I ask Allah for forgiveness. I ask Allah, the Magnificent, the Generous, for forgiveness; there is no deity except Him, the Ever-Living, the Sustainer, and I turn to Him in repentance.",
          "bs":
              "Molim Allaha za oprost. Molim Allaha za oprost. Molim Allaha Veličanstvenog, Plemenitog, osim Kojeg nema boga, Živog i Vječnog, za oprost i Njemu se kajem.",
          "nl":
              "Ik vraag Allah om vergeving. Ik vraag Allah om vergeving. Ik vraag Allah, de Geweldige, de Edelmoedige, om vergeving; er is geen god behalve Hij, de Levende, de Zelfstandige, en ik toon Hem berouw.",
        },

        instruction: "Namazın bitiminde selam verildikten sonra",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: '',
      ),
      DuaSegment(
        id: 2,
        arabic:
            "اَللّٰهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ",
        meaningTr:
            "Allah'ım! Sen kurtuluş merciisin. Esenlik ve güvenlik sendedir. Ey Azamet ve Kerem sahibi Allah'ım! Senin şanın çok yücedir.",
        meanings: {
          "es":
              "Oh Allah, Tú eres la Paz y de Ti procede la paz. Bendito eres, Dueño de la Majestad y la Generosidad.",
          "fr":
              "Ô Allah, Tu es la Paix et de Toi vient la paix. Béni sois-Tu, Détenteur de la majesté et de la générosité.",
          "de":
              "O Allah, Du bist der Friede und von Dir kommt der Friede. Gesegnet bist Du, Besitzer der Majestät und Ehre.",
          "en":
              "O Allah, You are Peace and from You comes peace. Blessed are You, Possessor of majesty and honour.",
          "bs":
              "Allahu, Ti si Mir i od Tebe dolazi mir. Blagoslovljen si, Posjedniče veličanstva i plemenitosti.",
          "nl":
              "O mijn Allah, U bent de Al Vredzame, en van U is alle Vrede. Jij bent de Algezegende en Ene die zegeningen schenkt, O een van Majesteit en Milddadigheid.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_08.mp3',
      ),
      DuaSegment(
        id: 3,
        arabic: "عَلٰى رَسُولِنَا صَلَوَاتٌ",
        meaningTr: "Salat Peygamberimiz Hz.Muhammed (s.a.v.)'in üzerine olsun.",
        meanings: {
          "es": "Que la gracia de Allah sea sobre nuestro Mensajero.",
          "fr": "Que la grâce d'Allah soit sur notre Messager.",
          "de": "Allahs Gnade sei auf unserem Gesandten.",
          "en": "May Allah's grace be upon our Messenger.",
          "bs": "Neka je Allahova milost na našem Poslaniku.",
          "nl":
              "Moge Allah’s vrede en zegeningen met onze Profeet Mohammed zijn",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_09.mp3',
      ),
      DuaSegment(
        id: 4,
        arabic:
            "اَللّٰهُمَّ صَلِّ عَلٰى سَيِّدِنَا مُحَمَّدٍ وَعَلٰى آلِ سَيِّدِنَا مُحَمَّدٍ",
        meaningTr:
            "Allah'ım Efendimiz Hz.Muhammed(sav)'e ve onun ailesine salat eyle",
        meanings: {
          "es":
              "Oh Allah, concede Tu gracia a nuestro señor Muhammad y a su familia.",
          "fr":
              "Ô Allah, accorde Ta grâce à notre maître Muhammad et à sa famille.",
          "de":
              "O Allah, schenke unserem Herrn Muhammad und seiner Familie Deine Gnade.",
          "en":
              "O Allah, bestow Your grace upon our master Muhammad and his family.",
          "bs":
              "Allahu, podari Svoju milost našem prvaku Muhammedu i njegovoj porodici.",
          "nl":
              "O Allah! Schenk Uw zegeningen en vrede aan onze meester Mohammed en zijn familie.",
        },

        instruction: "Salavat getirilir",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_10.mp3',
      ),
      DuaSegment(
        id: 5,
        arabic:
            "سُبْحَانَ اللّٰهِ وَالْحَمْدُ لِلّٰهِ وَلَا إِلٰهَ إِلَّا اللّٰهُ وَاللّٰهُ أَكْبَرُ",
        meaningTr:
            "Allah eksik sıfatlardan beridir. Hamd Allah'adır. Allah'tan başka ilah yoktur ve Allah en büyüktür.",
        meanings: {
          "es":
              "Glorificado sea Allah. Alabado sea Allah. No hay divinidad salvo Allah y Allah es el más grande.",
          "fr":
              "Gloire à Allah. Louange à Allah. Il n'y a de divinité qu'Allah et Allah est le plus grand.",
          "de":
              "Gepriesen sei Allah. Alles Lob gebührt Allah. Es gibt keine Gottheit außer Allah und Allah ist am größten.",
          "en":
              "Glory be to Allah. Praise be to Allah. There is no deity except Allah, and Allah is the greatest.",
          "bs":
              "Slavljen neka je Allah. Hvala Allahu. Nema boga osim Allaha i Allah je najveći.",
          "nl":
              "Glorie zij Allah, alle lof is aan Allah, er is geen godheid dan Allah, en Allah is de Grootste.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_19.mp3',
      ),
      DuaSegment(
        id: 6,
        arabic:
            "وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ الْعَلِيِّ الْعَظٖيمِ",
        meaningTr: "Allah'tan başkasında güç ve kudret yoktur.",
        meanings: {
          "es":
              "No hay fuerza ni poder sino en Allah, el Altísimo, el Magnífico.",
          "fr":
              "Il n'y a de force ni de puissance qu'en Allah, le Très-Haut, l'Immense.",
          "de":
              "Es gibt keine Kraft und keine Macht außer durch Allah, den Erhabenen, den Gewaltigen.",
          "en":
              "There is no might nor power except through Allah, the Most High, the Magnificent.",
          "bs": "Nema snage ni moći osim s Allahom, Uzvišenim, Veličanstvenim.",
          "nl":
              "Er is geen macht en geen kracht behalve bij Allah, de Verhevene, de Almachtige.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_20.mp3',
      ),
      DuaSegment(
        id: 7,
        arabic: "سُبْحَانَ اللّٰهِ بُكْرَةً وَأَصٖيلًا",
        meaningTr: "Sabah akşam her an tesbihimiz Allah'adır",
        meanings: {
          "es": "Glorificado sea Allah por la mañana y por la tarde.",
          "fr": "Gloire à Allah matin et soir.",
          "de": "Gepriesen sei Allah morgens und abends.",
          "en": "Glory be to Allah morning and evening.",
          "bs": "Slavljen neka je Allah jutrom i večeri.",
          "nl": "Wij verheerlijken Allah dag en nacht",
        },

        instruction: "Âyetel Kürsî’den sonra",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_21.mp3',
      ),
      DuaSegment(
        id: 8,
        arabic: "سُبْحَانَ اللّٰهِ",
        meaningTr: "Allah noksan sıfatlardan münezzehtir.",
        meanings: {
          "es": "Glorificado sea Allah, libre de toda imperfección.",
          "fr": "Gloire à Allah, exempt de toute imperfection.",
          "de": "Gepriesen sei Allah, frei von jeder Unvollkommenheit.",
          "en": "Glory be to Allah, free from every imperfection.",
          "bs": "Slavljen neka je Allah, čist od svakog nedostatka.",
          "nl": "Glorie zij Allah, Hij is vrij van alle gebreken",
        },

        instruction: "33 defa",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: '',
      ),
      DuaSegment(
        id: 9,
        arabic: "اَلْحَمْدُ لِلّٰهِ حَمْدًا كَثٖيرًا",
        meaningTr: "Allah'a olan hamdimiz çoktur",
        meanings: {
          "es": "Alabado sea Allah con abundantes alabanzas.",
          "fr": "Louange à Allah, une louange abondante.",
          "de": "Allah gebührt reichliches Lob.",
          "en": "Abundant praise be to Allah.",
          "bs": "Allahu pripada obilna hvala.",
          "nl": "We prijzen Allah en danken Hem in overvloed",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_22.mp3',
      ),
      DuaSegment(
        id: 10,
        arabic: "اَلْحَمْدُ لِلّٰهِ",
        meaningTr: "Hamd Allah'adır.",
        meanings: {
          "es": "Alabado sea Allah.",
          "fr": "Louange à Allah.",
          "de": "Alles Lob gebührt Allah.",
          "en": "Praise be to Allah.",
          "bs": "Hvala Allahu.",
          "nl": "Alle lof en dank zijn aan Allah",
        },

        instruction: "33 defa",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: '',
      ),
      DuaSegment(
        id: 11,
        arabic: "اَللّٰهُ أَكْبَرُ كَبٖيرًا",
        meaningTr: "Allah büyüklerin en büyüğüdür",
        meanings: {
          "es": "Allah es el más grande, inmensamente grande.",
          "fr": "Allah est le plus grand, infiniment grand.",
          "de": "Allah ist am größten, unermesslich groß.",
          "en": "Allah is the greatest, immeasurably great.",
          "bs": "Allah je najveći, neizmjerno velik.",
          "nl": "Allah is de Grootste van alle groten.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_23.mp3',
      ),
      DuaSegment(
        id: 12,
        arabic: "اَللّٰهُ أَكْبَرُ",
        meaningTr: "Allah en büyük ve en yücedir",
        meanings: {
          "es": "Allah es el más grande.",
          "fr": "Allah est le plus grand.",
          "de": "Allah ist am größten.",
          "en": "Allah is the greatest.",
          "bs": "Allah je najveći.",
          "nl": "Allah is de Grootste",
        },

        instruction: "33 defa",
        meaningSource: "Elifbe · ref · s. 39–40",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_01.mp3',
      ),
      DuaSegment(
        id: 13,
        arabic: "لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرٖيكَ لَهُ",
        meaningTr: "Eşsiz olan ve ortağı olmayan Allah'tan başka ilah yoktur.",
        meanings: {
          "es": "No hay divinidad salvo Allah, Único, sin asociado.",
          "fr": "Il n'y a de divinité qu'Allah, l'Unique, sans associé.",
          "de": "Es gibt keine Gottheit außer Allah allein, ohne Teilhaber.",
          "en": "There is no deity except Allah alone, with no partner.",
          "bs": "Nema boga osim Allaha, Jedinog, Koji nema sudruga.",
          "nl":
              "Er is geen godheid dan Allah, de Ene, Hij heeft geen deelgenoten.",
        },

        instruction: "Tesbihlerden sonra",
        meaningSource: "Elifbe · ref · s. 39–40 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_24.mp3',
      ),
      DuaSegment(
        id: 14,
        arabic: "لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ يُحْيٖي وَيُمٖيتُ",
        meaningTr: "Hükümranlık O'nundur, hamd O'nadır; O diriltir ve öldürür.",
        meanings: {
          "es":
              "Suyo es el dominio y Suya es la alabanza; Él da la vida y la muerte.",
          "fr": "À Lui la royauté et la louange ; Il donne la vie et la mort.",
          "de":
              "Ihm gehören die Herrschaft und das Lob; Er gibt Leben und Tod.",
          "en":
              "To Him belongs dominion and praise; He gives life and causes death.",
          "bs": "Njemu pripada vlast i hvala; On oživljava i usmrćuje.",
          "nl":
              "Aan Hem behoort de heerschappij en aan Hem de lof; Hij geeft leven en doet sterven.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_25.mp3',
      ),
      DuaSegment(
        id: 15,
        arabic: "وَهُوَ حَيٌّ لَا يَمُوتُ",
        meaningTr: "O diridir, hiç ölmez.",
        meanings: {
          "es": "Él está vivo y nunca muere.",
          "fr": "Il est vivant et ne meurt jamais.",
          "de": "Er lebt und stirbt niemals.",
          "en": "He is living and never dies.",
          "bs": "On je živ i nikada ne umire.",
          "nl": "Hij is de Levende, die nooit sterft.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_26.mp3',
      ),
      DuaSegment(
        id: 16,
        arabic: "بِيَدِهِ الْخَيْرُ",
        meaningTr: "Her hayır O'nun elindedir.",
        meanings: {
          "es": "En Su mano está todo bien.",
          "fr": "Tout bien est dans Sa main.",
          "de": "In Seiner Hand liegt alles Gute.",
          "en": "In His hand is all good.",
          "bs": "U Njegovoj ruci je svako dobro.",
          "nl": "In Zijn hand is al het goede.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_27.mp3',
      ),
      DuaSegment(
        id: 17,
        arabic: "وَهُوَ عَلٰى كُلِّ شَيْءٍ قَدٖيرٌ",
        meaningTr: "O her şeye güç yetirendir.",
        meanings: {
          "es": "Él tiene poder sobre todas las cosas.",
          "fr": "Il est capable de toute chose.",
          "de": "Er hat Macht über alle Dinge.",
          "en": "He has power over all things.",
          "bs": "On sve može.",
          "nl": "En Hij is tot alles in staat.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_28.mp3',
      ),
      DuaSegment(
        id: 18,
        arabic: "وَإِلَيْهِ الْمَصٖيرُ",
        meaningTr: "Dönüş de yalnız O'nadır.",
        meanings: {
          "es": "Y a Él es el retorno.",
          "fr": "Et c'est vers Lui que se fera le retour.",
          "de": "Und zu Ihm ist die Rückkehr.",
          "en": "And to Him is the return.",
          "bs": "I Njemu je povratak.",
          "nl": "En tot Hem is de terugkeer.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 39–40 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_29.mp3',
      ),
    ],
  ),
  // As the owner's three recordings read it (ref/*-YEMEK DUASI N.wav, in
  // their order; differs from the book's s. 37 text, "kayda göre"), the 2nd
  // and 3rd cut at their pauses into one phrase per card; the eûzü-besmele
  // before it has no recording.
  Dua(
    order: 13,
    id: "13_yemek_duasi",
    titleTr: "Yemek Duası",
    segments: [
      DuaSegment(
        id: 1,
        arabic: "أَعُوذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجٖيمِ",
        meaningTr: "Kovulmuş şeytandan Allah'a sığınırım.",
        meanings: {
          "es": "Me refugio en Allah del demonio expulsado.",
          "fr": "Je cherche refuge auprès d'Allah contre Satan le banni.",
          "de": "Ich suche Zuflucht bei Allah vor dem verstoßenen Satan.",
          "en": "I seek refuge in Allah from Satan, the outcast.",
          "bs": "Utječem se Allahu od prokletog šejtana.",
          "nl": "Ik zoek mijn toevlucht bij Allah tegen de vervloekte satan.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37",
        audioAsset: '',
      ),
      DuaSegment(
        id: 2,
        arabic: "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ",
        meaningTr: "Rahmân ve Rahîm olan Allah'ın adıyla.",
        meanings: {
          "es": "En el nombre de Allah, el Compasivo, el Misericordioso.",
          "fr":
              "Au nom d'Allah, le Tout Miséricordieux, le Très Miséricordieux.",
          "de": "Im Namen Allahs, des Allerbarmers, des Barmherzigen.",
          "en":
              "In the name of Allah, the Most Merciful, the Especially Merciful.",
          "bs": "U ime Allaha, Milostivog, Samilosnog.",
          "nl": "In de naam van Allah, de Barmhartige, de Genadevolle.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37",
        audioAsset: '',
      ),
      DuaSegment(
        id: 3,
        arabic:
            "اَلْحَمْدُ لِلّٰهِ الَّذٖي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمٖينَ",
        meaningTr:
            "Bizi yediren, içiren ve bizi müslüman kılan Allah'a hamdolsun.",
        meanings: {
          "es":
              "Alabado sea Allah, que nos ha dado de comer y beber y nos ha hecho musulmanes.",
          "fr":
              "Louange à Allah, qui nous a nourris, abreuvés et faits musulmans.",
          "de":
              "Alles Lob gebührt Allah, der uns gespeist, uns zu trinken gegeben und uns zu Muslimen gemacht hat.",
          "en":
              "Praise be to Allah, who has fed us, given us drink and made us Muslims.",
          "bs":
              "Hvala Allahu, Koji nas je nahranio, napojio i učinio muslimanima.",
          "nl":
              "Alle lof zij Allah, die ons te eten en te drinken heeft gegeven en ons moslim heeft gemaakt.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37 (kayda göre)",
        audioAsset: 'audio/dualar/13_yemek_duasi/yemek-01.mp3',
      ),
      DuaSegment(
        id: 4,
        arabic: "اَللّٰهُمَّ أَطْعِمْ مَنْ أَطْعَمَنَا",
        meaningTr: "Allah'ım! Bizi doyuranı Sen doyur,",
        meanings: {
          "es": "Oh Allah, alimenta a quien nos ha alimentado,",
          "fr": "Ô Allah, nourris celui qui nous a nourris,",
          "de": "O Allah, speise denjenigen, der uns gespeist hat,",
          "en": "O Allah, feed the one who has fed us,",
          "bs": "Allahu, nahrani onoga ko je nas nahranio,",
          "nl": "O Allah, geef te eten aan wie ons te eten gaf",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37 (kayda göre)",
        audioAsset: 'audio/dualar/13_yemek_duasi/yemek-02.mp3',
      ),
      DuaSegment(
        id: 5,
        arabic: "وَاسْقِ مَنْ سَقَانَا",
        meaningTr: "bize içireni Sen içir.",
        meanings: {
          "es": "y da de beber a quien nos ha dado de beber.",
          "fr": "et abreuve celui qui nous a abreuvés.",
          "de":
              "und gib demjenigen zu trinken, der uns zu trinken gegeben hat.",
          "en": "and give drink to the one who has given us drink.",
          "bs": "i napoji onoga ko je nas napojio.",
          "nl": "en te drinken aan wie ons te drinken gaf.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37 (kayda göre)",
        audioAsset: 'audio/dualar/13_yemek_duasi/yemek-03.mp3',
      ),
      DuaSegment(
        id: 6,
        arabic: "اَللّٰهُمَّ بَارِكْ لَهُمْ فٖيمَا رَزَقْتَهُمْ",
        meaningTr: "Allah'ım! Onlara verdiğin rızıkları bereketli kıl,",
        meanings: {
          "es": "Oh Allah, bendice el sustento que les has concedido,",
          "fr": "Ô Allah, bénis la subsistance que Tu leur as accordée,",
          "de":
              "O Allah, segne ihnen, was Du ihnen an Versorgung gegeben hast,",
          "en": "O Allah, bless the provision You have given them,",
          "bs": "Allahu, blagoslovi im ono čime si ih opskrbio,",
          "nl": "O Allah, zegen hen in wat U hun hebt gegeven,",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37 (kayda göre)",
        audioAsset: 'audio/dualar/13_yemek_duasi/yemek-04.mp3',
      ),
      DuaSegment(
        id: 7,
        arabic: "وَاغْفِرْ لَهُمْ وَارْحَمْهُمْ",
        meaningTr: "onları bağışla ve onlara merhamet eyle.",
        meanings: {
          "es": "perdónalos y ten misericordia de ellos.",
          "fr": "pardonne-leur et fais-leur miséricorde.",
          "de": "vergib ihnen und erbarme Dich ihrer.",
          "en": "forgive them and have mercy on them.",
          "bs": "oprosti im i smiluj im se.",
          "nl": "vergeef hen en wees hen genadig.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37 (kayda göre)",
        audioAsset: 'audio/dualar/13_yemek_duasi/yemek-05.mp3',
      ),
      DuaSegment(
        id: 8,
        arabic: "أَفْطَرَ عِنْدَكُمُ الصَّائِمُونَ",
        meaningTr: "Oruçlular sizin yanınızda iftar etsin,",
        meanings: {
          "es": "Que quienes ayunan rompan su ayuno con vosotros,",
          "fr": "Que les jeûneurs rompent leur jeûne chez vous,",
          "de": "Mögen die Fastenden bei euch ihr Fasten brechen,",
          "en": "May those who fast break their fast with you,",
          "bs": "Neka postači kod vas iftare,",
          "nl": "Mogen vastenden bij u hun vasten verbreken,",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37 (kayda göre)",
        audioAsset: 'audio/dualar/13_yemek_duasi/yemek-06.mp3',
      ),
      DuaSegment(
        id: 9,
        arabic: "وَأَكَلَ طَعَامَكُمُ الْأَبْرَارُ",
        meaningTr: "iyiler yemeğinizi yesin,",
        meanings: {
          "es": "que los rectos coman de vuestra comida,",
          "fr": "que les vertueux mangent de votre nourriture,",
          "de": "die Rechtschaffenen von eurem Essen essen,",
          "en": "may the righteous eat your food,",
          "bs": "neka dobri ljudi jedu vašu hranu,",
          "nl": "mogen de vromen van uw eten eten",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37 (kayda göre)",
        audioAsset: 'audio/dualar/13_yemek_duasi/yemek-07.mp3',
      ),
      DuaSegment(
        id: 10,
        arabic: "وَصَلَّتْ عَلَيْكُمُ الْمَلَائِكَةُ",
        meaningTr: "melekler size dua etsin.",
        meanings: {
          "es": "y que los ángeles rueguen por vosotros.",
          "fr": "et que les anges prient pour vous.",
          "de": "und die Engel für euch beten.",
          "en": "and may the angels pray for you.",
          "bs": "i neka meleki mole za vas.",
          "nl": "en mogen de engelen voor u bidden.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 37 (kayda göre)",
        audioAsset: 'audio/dualar/13_yemek_duasi/yemek-08.mp3',
      ),
    ],
  ),
  Dua(
    order: 14,
    id: "14_salaten_tuncina",
    titleTr: "Salâten Tüncînâ Duası",
    segments: [
      DuaSegment(
        id: 1,
        arabic:
            "اَللّٰهُمَّ صَلِّ عَلٰى سَيِّدِنَا مُحَمَّدٍ وَعَلٰى آلِ سَيِّدِنَا مُحَمَّدٍ",
        meaningTr:
            "Allah'ım! Efendimiz Muhammed'e (asm) ve onun Ehl-i beytine salât eyle.",
        meanings: {
          "es":
              "Oh Allah, concede Tu gracia a nuestro señor Muhammad y a su familia.",
          "fr":
              "Ô Allah, accorde Ta grâce à notre maître Muhammad et à sa famille.",
          "de":
              "O Allah, schenke unserem Herrn Muhammad und seiner Familie Deine Gnade.",
          "en":
              "O Allah, bestow Your grace upon our master Muhammad and his family.",
          "bs":
              "Allahu, podari Svoju milost našem prvaku Muhammedu i njegovoj porodici.",
          "nl":
              "O Allah! Schenk zegeningen en vrede aan onze meester Mohammed en zijn Familie.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_10.mp3',
      ),
      DuaSegment(
        id: 2,
        arabic:
            "صَلَاةً تُنْجٖينَا بِهَا مِنْ جَمٖيعِ الْأَهْوَالِ وَالْآفَاتِ",
        meaningTr:
            "Öyle bir salât ki onun hürmetine bizi bütün korku ve belalardan kurtarırsın,",
        meanings: {
          "es":
              "Una gracia por la que nos salves de todos los terrores y calamidades,",
          "fr":
              "Une grâce par laquelle Tu nous délivres de toutes les frayeurs et calamités,",
          "de":
              "Eine Gnade, durch die Du uns vor allen Schrecken und Plagen rettest,",
          "en":
              "A grace through which You save us from all terrors and calamities,",
          "bs": "Milost kojom ćeš nas spasiti od svih strahota i nevolja,",
          "nl": "Een zegen waardoor U ons redt van alle tegenslagen en rampen,",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_11.mp3',
      ),
      DuaSegment(
        id: 3,
        arabic: "وَتَقْضٖي لَنَا بِهَا جَمٖيعَ الْحَاجَاتِ",
        meaningTr: "bütün ihtiyaçlarımızı yerine getirirsin,",
        meanings: {
          "es": "satisfagas todas nuestras necesidades,",
          "fr": "combles tous nos besoins,",
          "de": "alle unsere Bedürfnisse erfüllst,",
          "en": "fulfil all our needs,",
          "bs": "ispuniti sve naše potrebe,",
          "nl": "waardoor U in al onze behoeften voorziet,",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_12.mp3',
      ),
      DuaSegment(
        id: 4,
        arabic: "وَتُطَهِّرُنَا بِهَا مِنْ جَمٖيعِ السَّيِّئَاتِ",
        meaningTr: "bizi bütün günahlardan temizlersin,",
        meanings: {
          "es": "nos purifiques de todos los pecados,",
          "fr": "nous purifies de tous les péchés,",
          "de": "uns von allen Sünden reinigst,",
          "en": "purify us from all sins,",
          "bs": "očistiti nas od svih grijeha,",
          "nl": "waardoor U ons reinigt van alle ondeugden,",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_13.mp3',
      ),
      DuaSegment(
        id: 5,
        arabic: "وَتَرْفَعُنَا بِهَا عِنْدَكَ أَعْلَى الدَّرَجَاتِ",
        meaningTr: "bizi katında derecelerin en yükseğine çıkarırsın,",
        meanings: {
          "es": "nos eleves ante Ti a los grados más altos,",
          "fr": "nous élèves auprès de Toi aux plus hauts rangs,",
          "de": "uns bei Dir zu den höchsten Rängen erhebst,",
          "en": "raise us to the highest ranks in Your presence,",
          "bs": "uzdići nas kod Sebe na najviše stepene,",
          "nl": "waardoor U ons verheft tot de hoogste rangen bij U,",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_14.mp3',
      ),
      DuaSegment(
        id: 6,
        arabic: "وَتُبَلِّغُنَا بِهَا أَقْصَى الْغَايَاتِ",
        meaningTr: "ve bizi gayelerin en sonuna ulaştırırsın,",
        meanings: {
          "es": "y nos hagas alcanzar las metas más elevadas,",
          "fr": "et nous fasses atteindre les buts les plus élevés,",
          "de": "und uns die höchsten Ziele erreichen lässt,",
          "en": "and bring us to the furthest goals,",
          "bs": "i dovesti nas do najviših ciljeva,",
          "nl": "en waardoor U ons de hoogste doelen laat bereiken",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_15.mp3',
      ),
      DuaSegment(
        id: 7,
        arabic: "مِنْ جَمٖيعِ الْخَيْرَاتِ فِي الْحَيَاةِ وَبَعْدَ الْمَمَاتِ",
        meaningTr: "hayatta ve öldükten sonra bütün hayırlarda.",
        meanings: {
          "es": "en todo bien, en esta vida y después de la muerte.",
          "fr": "en tout bien, dans la vie et après la mort.",
          "de": "in allem Guten, im Leben und nach dem Tod.",
          "en": "in all good things, in life and after death.",
          "bs": "u svakom dobru, za života i poslije smrti.",
          "nl": "van alle soorten goedheid, in dit leven en na de dood.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_16.mp3',
      ),
      DuaSegment(
        id: 8,
        arabic: "آمٖينَ يَا مُجٖيبَ الدَّعَوَاتِ",
        meaningTr: "Âmin, ey duaları kabul eden!",
        meanings: {
          "es": "Amén, Tú que respondes a las súplicas.",
          "fr": "Amen, Toi qui exauces les invocations.",
          "de": "Amen, o Du, der die Bittgebete erhört.",
          "en": "Amen, O Answerer of prayers.",
          "bs": "Amin, Ti Koji uslišavaš dove.",
          "nl": "Amen, o Verhoorder van de gebeden!",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_17.mp3',
      ),
      DuaSegment(
        id: 9,
        arabic: "وَالْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمٖينَ",
        meaningTr: "Hamd, âlemlerin Rabbi olan Allah'adır.",
        meanings: {
          "es": "Alabado sea Allah, Señor de todos los mundos.",
          "fr": "Louange à Allah, Seigneur des mondes.",
          "de": "Alles Lob gebührt Allah, dem Herrn der Welten.",
          "en": "Praise be to Allah, Lord of all worlds.",
          "bs": "Hvala Allahu, Gospodaru svjetova.",
          "nl": "En alle lof is aan Allah, de Heer der werelden.",
        },

        instruction: "",
        meaningSource: "Elifbe · ref · s. 41 (kayda göre)",
        audioAsset: 'audio/dualar/namaz_lafizlari/lafiz_18.mp3',
      ),
    ],
  ),
  Dua(
    order: 15,
    id: "15_tefriciye",
    titleTr: "Tefriciye Duası",
    segments: [
      DuaSegment(
        id: 1,
        arabic:
            "اَللّٰهُمَّ صَلِّ صَلَاةً كَامِلَةً وَسَلِّمْ سَلَامًا تَامًّا عَلٰى سَيِّدِنَا مُحَمَّدٍ",
        meaningTr:
            "Allah'ım! Efendimiz Muhammed'e (sav) tam bir salât ve eksiksiz bir selâm eyle.",
        meanings: {
          "es":
              "Oh Allah, concede una gracia perfecta y una paz completa a nuestro señor Muhammad.",
          "fr":
              "Ô Allah, accorde une grâce parfaite et une paix complète à notre maître Muhammad.",
          "de":
              "O Allah, schenke unserem Herrn Muhammad vollkommene Gnade und vollständigen Frieden.",
          "en":
              "O Allah, bestow perfect grace and complete peace upon our master Muhammad.",
          "bs":
              "Allahu, podari potpunu milost i savršen mir našem prvaku Muhammedu.",
          "nl":
              "O Allah, schenk volmaakte zegeningen en volledige vrede aan onze meester Mohammed,",
        },

        meaningSource: "Tefriciye · kitapta yok",
        audioAsset: 'audio/dualar/15_tefriciye/tefriciye-01.mp3',
      ),
      DuaSegment(
        id: 2,
        arabic: "الَّذٖي تَنْحَلُّ بِهِ الْعُقَدُ",
        meaningTr: "Onun hürmetine düğümler çözülür,",
        meanings: {
          "es": "Por consideración a él se desatan los nudos,",
          "fr": "Par égard pour lui, les nœuds se dénouent,",
          "de": "Um seinetwillen lösen sich die Knoten,",
          "en": "For his sake, knots are untied,",
          "bs": "Radi njega se čvorovi razrješavaju,",
          "nl": "door wie knopen worden ontward,",
        },

        meaningSource: "Tefriciye · kitapta yok",
        audioAsset: 'audio/dualar/15_tefriciye/tefriciye-02.mp3',
      ),
      DuaSegment(
        id: 3,
        arabic: "وَتَنْفَرِجُ بِهِ الْكُرَبُ",
        meaningTr: "sıkıntılar giderilir,",
        meanings: {
          "es": "se alivian las angustias,",
          "fr": "les détresses se dissipent,",
          "de": "werden Bedrängnisse gelindert,",
          "en": "distresses are relieved,",
          "bs": "nevolje otklanjaju,",
          "nl": "zorgen worden weggenomen,",
        },

        meaningSource: "Tefriciye · kitapta yok",
        audioAsset: 'audio/dualar/15_tefriciye/tefriciye-03.mp3',
      ),
      DuaSegment(
        id: 4,
        arabic: "وَتُقْضٰى بِهِ الْحَوَائِجُ",
        meaningTr: "ihtiyaçlar karşılanır,",
        meanings: {
          "es": "se satisfacen las necesidades,",
          "fr": "les besoins sont comblés,",
          "de": "werden Bedürfnisse erfüllt,",
          "en": "needs are fulfilled,",
          "bs": "potrebe ispunjavaju,",
          "nl": "noden worden vervuld,",
        },

        meaningSource: "Tefriciye · kitapta yok",
        audioAsset: 'audio/dualar/15_tefriciye/tefriciye-04.mp3',
      ),
      DuaSegment(
        id: 5,
        arabic: "وَتُنَالُ بِهِ الرَّغَائِبُ وَحُسْنُ الْخَوَاتٖيمِ",
        meaningTr: "dileklere ve güzel bir sona ulaşılır,",
        meanings: {
          "es": "y se alcanzan los deseos y un buen final.",
          "fr": "les souhaits se réalisent et une bonne fin est obtenue.",
          "de": "gehen Wünsche in Erfüllung und wird ein gutes Ende erreicht.",
          "en": "wishes and a good ending are attained,",
          "bs": "želje ostvaruju i postiže lijep završetak,",
          "nl": "wensen en een goed einde worden bereikt,",
        },

        meaningSource: "Tefriciye · kitapta yok",
        audioAsset: 'audio/dualar/15_tefriciye/tefriciye-05.mp3',
      ),
      DuaSegment(
        id: 6,
        arabic: "وَيُسْتَسْقَى الْغَمَامُ بِوَجْهِهِ الْكَرٖيمِ",
        meaningTr: "onun mübarek yüzü hürmetine bulutlardan yağmur istenir.",
        meanings: {
          "es": "Y por su noble rostro se pide a las nubes que traigan lluvia.",
          "fr":
              "Et par égard pour son noble visage, on implore la pluie des nuages.",
          "de":
              "Und um seines edlen Angesichts willen wird aus den Wolken Regen erbeten.",
          "en":
              "And for the sake of his noble countenance, rain is sought from the clouds.",
          "bs": "I radi njegovog plemenitog lica moli se za kišu iz oblaka.",
          "nl":
              "en om wiens edele gelaat om regen uit de wolken wordt gevraagd.",
        },

        meaningSource: "Tefriciye · kitapta yok",
        audioAsset: 'audio/dualar/15_tefriciye/tefriciye-06.mp3',
      ),
      DuaSegment(
        id: 7,
        arabic: "وَعَلٰى آلِهٖ وَصَحْبِهٖ",
        meaningTr: "Onun ailesine ve ashabına da (salât ve selâm eyle);",
        meanings: {
          "es": "Y también a su familia y a sus compañeros,",
          "fr": "Ainsi qu'à sa famille et à ses compagnons,",
          "de": "Und auch seiner Familie und seinen Gefährten,",
          "en": "And upon his family and companions too,",
          "bs": "I njegovoj porodici i ashabima,",
          "nl": "En ook aan zijn familie en metgezellen,",
        },

        meaningSource: "Tefriciye · kitapta yok",
        audioAsset: 'audio/dualar/15_tefriciye/tefriciye-07.mp3',
      ),
      DuaSegment(
        id: 8,
        arabic: "فٖي كُلِّ لَمْحَةٍ وَنَفَسٍ بِعَدَدِ كُلِّ مَعْلُومٍ لَكَ",
        meaningTr: "her bakışta ve her nefeste, bildiğin her şeyin sayısınca.",
        meanings: {
          "es":
              "en cada instante y en cada aliento, tantas veces como todo lo que Tú conoces.",
          "fr":
              "à chaque instant et à chaque souffle, autant de fois que tout ce que Tu connais.",
          "de":
              "in jedem Augenblick und bei jedem Atemzug, so oft wie die Zahl aller Dinge, die Du kennst.",
          "en":
              "at every moment and with every breath, as many times as all that You know.",
          "bs":
              "u svakom trenutku i sa svakim dahom, onoliko puta koliko je svega što Ti znaš.",
          "nl":
              "bij elke oogopslag en elke ademhaling, zo talrijk als alles wat U bekend is.",
        },

        meaningSource: "Tefriciye · kitapta yok",
        audioAsset: 'audio/dualar/15_tefriciye/tefriciye-08.mp3',
      ),
    ],
  ),
];
const kAllDualar = <Dua>[...kDualar, ...kAdditionalDualar];
