import '../../../data/drag_drop_game_data.dart';
import '../../../data/letter_forms_data.dart';
import '../../../data/letters_data.dart';
import '../../../models/arabic_letter.dart';

/// Harf Dedektifi'nin harf ve kelime verisi.
///
/// Harf kimliği = [kArabicLetters] sırası (1–28). Eşleştirme hiçbir zaman
/// ekrandaki metinle (bağlantı çizgili biçimler, Hasenat glifleri) yapılmaz;
/// her kart ve kelimedeki her harf bu kararlı kimliği taşır. Metinde normal
/// Arapça Unicode harfleri tutulur, sunum biçimleri (U+FE70…) kullanılmaz.

/// Kaşide (ـ). Tek harf kartlarında yalnızca bağlantıyı göstermek için
/// eklenir; harf sayılmaz. Kelimelere asla eklenmez.
const String kTatweel = 'ـ';

/// Kendinden sonraki harfe bağlanmayan harfler (kimlik): ا د ذ ر ز و.
/// Bunların yalnızca iki görünümü vardır (tek başına / önceki harfe bağlı);
/// yapay "başta / ortada" biçimleri üretilmez.
const Set<int> kNonJoiningLetterIds = {1, 8, 9, 10, 11, 26};

/// Harfin kartta gösterilen bağlantı biçimi (kelimedeki konum değil).
enum LetterForm {
  isolated('Tek başına'),
  initial('Başta'),
  medial('Ortada'),
  finalForm('Sonda');

  const LetterForm(this.label);
  final String label;
}

class DetectiveLetter {
  const DetectiveLetter({
    required this.id,
    required this.char,
    required this.name,
    required this.audio,
  });

  /// Kararlı kimlik: [kArabicLetters] sırası.
  final int id;

  /// Temel Unicode harfi (kaşidesiz; ör. He için 'ه').
  final String char;

  /// Projede zaten doğrulanmış Türkçe adı (Ders 1 verisi).
  final String name;

  /// Harfin kendi ses kaydı (Ders 1: harfin adı okunur). Kelime sesi değil.
  final String? audio;

  bool get joinsNext => !kNonJoiningLetterIds.contains(id);

  /// Bu harfin gerçekten var olan bağlantı biçimleri.
  List<LetterForm> get forms =>
      joinsNext
          ? LetterForm.values
          : const [LetterForm.isolated, LetterForm.finalForm];

  /// Kartta gösterilecek metin. Kaşide yalnızca bağlantı yönünü gösterir.
  String display(LetterForm form) => switch (form) {
    LetterForm.isolated => char,
    LetterForm.initial => '$char$kTatweel',
    LetterForm.medial => '$kTatweel$char$kTatweel',
    LetterForm.finalForm => '$kTatweel$char',
  };

  /// Biçimin çocuğa gösterilen adı. Bağlanmayan harflerde "başta" ile
  /// "tek başına" aynı görünür; "ortada / sonda" ise yalnızca öncekine bağlıdır.
  String formLabel(LetterForm form) {
    if (joinsNext) return form.label;
    return form == LetterForm.isolated ? 'Tek başına / Başta' : 'Öncekine bağlı';
  }
}

/// 28 harf, [kArabicLetters]'tan türetilir (ad ve ses tek kaynaktan gelir).
final List<DetectiveLetter> kDetectiveLetters = [
  for (final letter in kArabicLetters)
    DetectiveLetter(
      id: letter.order,
      char: letter.isolatedForm.replaceAll(kTatweel, ''),
      name: letter.turkishName ?? '',
      audio: letter.audioAsset,
    ),
];

final Map<int, DetectiveLetter> _byId = {
  for (final letter in kDetectiveLetters) letter.id: letter,
};

final Map<String, int> _idByChar = {
  for (final letter in kDetectiveLetters) letter.char: letter.id,
};

DetectiveLetter letterById(int id) => _byId[id]!;

/// Temel Unicode harfinin kimliği; tanınmayan karakterde `null`.
///
/// Açık kural: hemzeli elif (أ إ), medli elif (آ), vasl elifi (ٱ), hemze (ء),
/// hemzeli vav/ye (ؤ ئ), elif maksura (ى) ve yuvarlak te (ة) hiçbir harfe
/// sessizce indirgenmez → `null`. Bu karakterleri içeren kelimeler havuza
/// girmez. Kitap bunları ayrı derslerde öğretir; eklenmek istenirse burada
/// açık bir eşleştirme yazılmalıdır.
int? letterIdOfChar(String char) => _idByChar[char];

/// Hareke ve diğer birleştirici işaretler: ayrı harf sayılmaz, dokunulamaz.
bool isArabicCombiningMark(int codeUnit) =>
    (codeUnit >= 0x064B && codeUnit <= 0x065F) ||
    codeUnit == 0x0670 ||
    (codeUnit >= 0x06D6 && codeUnit <= 0x06ED);

// ---------------------------------------------------------------------------
// Benzer harfler

/// Nokta sayısı ve yeriyle ayrılan harf grupları (Benzer Harfler modu).
const List<List<int>> kSimilarGroups = [
  [2, 3, 4], // ب ت ث
  [5, 6, 7], // ج ح خ
  [8, 9], // د ذ
  [10, 11], // ر ز
  [12, 13], // س ش
  [14, 15], // ص ض
  [16, 17], // ط ظ
  [18, 19], // ع غ
];

List<int>? similarGroupOf(int id) {
  for (final group in kSimilarGroups) {
    if (group.contains(id)) return group;
  }
  return null;
}

/// Noktaların sayısı ve yeri, harfin kendi adıyla anlatılır.
const Map<int, String> _dotText = {
  2: 'altında 1 nokta var',
  3: 'üstünde 2 nokta var',
  4: 'üstünde 3 nokta var',
  5: 'altında 1 nokta var',
  6: 'hiç noktası yok',
  7: 'üstünde 1 nokta var',
  8: 'hiç noktası yok',
  9: 'üstünde 1 nokta var',
  10: 'hiç noktası yok',
  11: 'üstünde 1 nokta var',
  12: 'hiç noktası yok',
  13: 'üstünde 3 nokta var',
  14: 'hiç noktası yok',
  15: 'üstünde 1 nokta var',
  16: 'hiç noktası yok',
  17: 'üstünde 1 nokta var',
  18: 'hiç noktası yok',
  19: 'üstünde 1 nokta var',
};

/// "Te harfinin üstünde 2 nokta var." — yalnızca nokta farkıyla ayrılan
/// harfler için; diğerlerinde `null` (genel "noktalarına dikkat" denmez).
String? dotDescription(int id) {
  final text = _dotText[id];
  if (text == null) return null;
  return '${letterById(id).name} harfinin $text.';
}

/// Şekilleri Tanı modunda ilk turlarda çeldirici seçilmeyecek, birbirine
/// çok benzeyen harf aileleri (baş/orta biçimde ب ت ث ن ي aynı dişlidir).
const List<Set<int>> _lookAlikeFamilies = [
  {2, 3, 4, 25, 28},
  {5, 6, 7},
  {8, 9},
  {10, 11},
  {12, 13},
  {14, 15},
  {16, 17},
  {18, 19},
  {20, 21},
];

bool looksAlike(int a, int b) {
  if (a == b) return true;
  for (final family in _lookAlikeFamilies) {
    if (family.contains(a) && family.contains(b)) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Harf seçimi

class LetterChoice {
  const LetterChoice({required this.id, required this.title, this.letterIds});

  final String id;
  final String title;

  /// `null` = tüm harfler.
  final List<int>? letterIds;

  List<int> get ids => letterIds ?? [for (final l in kDetectiveLetters) l.id];
}

/// "Tüm harfler" + Sürükle & Bırak'taki 7 harf grubu (aynı öğrenme sırası).
/// Lam-elif harf değil bitişik yazılış olduğu için bu oyuna alınmaz.
final List<LetterChoice> kLetterChoices = [
  const LetterChoice(id: 'all', title: 'Tüm harfler'),
  for (var i = 0; i < kDragDropGroups.length; i++)
    LetterChoice(
      id: 'g${i + 1}',
      title: 'Grup ${i + 1}',
      letterIds: [
        for (final letter in kDragDropGroups[i])
          if (detectiveIdOf(letter) case final id?) id,
      ],
    ),
];

// ---------------------------------------------------------------------------
// Kelimeler

/// Kelimedeki tek bir harf: kimliği ve metindeki aralığı (harekeleri dahil).
class WordLetter {
  const WordLetter({
    required this.letterId,
    required this.start,
    required this.end,
  });

  final int letterId;
  final int start;
  final int end;
}

class DetectiveWord {
  DetectiveWord._(this.text, this.letters);

  final String text;

  /// Mantıksal (okuma) sırasıyla harfler; görsel sıra ölçümden gelir.
  final List<WordLetter> letters;

  /// Kelimeyi harflere ayırır; tanınmayan bir karakter ya da lam-elif
  /// birleşimi varsa `null` (kelime havuza alınmaz).
  static DetectiveWord? tryParse(String text) {
    final letters = <WordLetter>[];
    var i = 0;
    while (i < text.length) {
      final id = letterIdOfChar(text[i]);
      if (id == null) return null;
      var end = i + 1;
      while (end < text.length && isArabicCombiningMark(text.codeUnitAt(end))) {
        end++;
      }
      letters.add(WordLetter(letterId: id, start: i, end: end));
      i = end;
    }
    if (letters.isEmpty) return null;
    for (var k = 0; k + 1 < letters.length; k++) {
      // لا tek glif (bitişik) çizilir; içindeki iki harfe ayrı dokunulamaz.
      if (letters[k].letterId == 23 && letters[k + 1].letterId == 1) {
        return null;
      }
    }
    return DetectiveWord._(text, letters);
  }

  /// Hedef harfin bu kelimedeki bütün geçişleri (her biri ayrı sayılır).
  List<int> occurrencesOf(int letterId) => [
    for (var k = 0; k < letters.length; k++)
      if (letters[k].letterId == letterId) k,
  ];
}

/// Kelime havuzu: YALNIZCA projede zaten bulunan, Ders 2'nin ("Harflerin
/// Yazılışları") örnek kelimeleri. Yeni kelime uydurulmaz; hemzeli, yuvarlak
/// te'li ve lam-elifli olanlar ([DetectiveWord.tryParse]) dışarıda kalır.
final List<DetectiveWord> kDetectiveWords = () {
  final seen = <String>{};
  final words = <DetectiveWord>[];
  for (final letter in kLetterFormLetters) {
    for (final text in letter.positionExamples ?? const <String>[]) {
      if (!seen.add(text)) continue;
      final word = DetectiveWord.tryParse(text);
      if (word != null) words.add(word);
    }
  }
  return words;
}();

List<DetectiveWord> wordsContaining(int letterId) => [
  for (final word in kDetectiveWords)
    if (word.occurrencesOf(letterId).isNotEmpty) word,
];

/// Kelime modunda hedef olabilecek harfler (en az 2 kelimede geçenler).
List<int> wordModeLetterIds() => [
  for (final letter in kDetectiveLetters)
    if (wordsContaining(letter.id).length >= 2) letter.id,
];

/// Başka ekranlar için: [ArabicLetter]'ın dedektif kimliği.
int? detectiveIdOf(ArabicLetter letter) =>
    letterIdOfChar(letter.isolatedForm.replaceAll(kTatweel, ''));
