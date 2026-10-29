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

const kAyatelKursi = Surah(
  order: 12,
  id: 'ayetel-kursi',
  titleTr: 'Âyetel Kürsî',
  arabicName: 'آية الكرسي',
  besmele: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحٖيمِ',
  besmeleAudioAsset: 'audio/sureler/12_ayetel-kursi/00_besmele.mp3',
  ayetler: [
    Ayet(
      number: 255,
      arabic:
          "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلۡأَرۡضِۗ مَن ذَا ٱلَّذِي يَشۡفَعُ عِندَهُۥٓ إِلَّا بِإِذۡنِهِۦۚ يَعۡلَمُ مَا بَيۡنَ أَيۡدِيهِمۡ وَمَا خَلۡفَهُمۡۖ وَلَا يُحِيطُونَ بِشَيۡءٖ مِّنۡ عِلۡمِهِۦٓ إِلَّا بِمَا شَآءَۚ وَسِعَ كُرۡسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۖ وَلَا يَـُٔودُهُۥ حِفۡظُهُمَاۚ وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ",
      meaningTr:
          "Allah o İlâhtır ki Kendisinden başka ilâh yoktur. Haydır, kayyûmdur kendisini ne bir uyuklama, ne uyku tutamaz. Göklerde ve yerde ne varsa O'nundur. İzni olmadan huzurunda şefaat etmek kimin haddine? Yarattığı mahlûkların önünde ardında ne var, hepsini bilir. Mahlûklar ise O’nun dilediğinden başka, ilminden hiçbir şey kavrayamazlar. O’nun kürsüsü gökleri ve yeri kaplamıştır. Gökleri ve yeri koruyup gözetmek O’na ağır gelmez, O öyle ulu, öyle büyüktür. [19,93-95; 53,26; 21,28; 20,110] [KM, Tesniye 5,26; Tekvin 21,33; Çıkış 3,15]",
      audioAsset: 'audio/sureler/12_ayetel-kursi/255_ayet.mp3',
    ),
  ],
);
// A verse excerpt, listed after the 11 surahs without renumbering them.
const kNamazAyetleri = <Surah>[kAyatelKursi];
