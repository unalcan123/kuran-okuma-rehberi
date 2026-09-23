/// Oyuncu takma adı kuralları. Hem yerel profil oluştururken hem çevrimiçi
/// sıralamaya yazmadan önce kullanılır; aynı kurallar `firestore.rules`
/// içinde de denetlenir (orada değişirse burada da değiştir).
///
///  * 2–16 karakter (harf sayısı, emoji/birleşik karakter değil),
///  * yalnızca harf (her alfabe: Türkçe, Arapça…), rakam, boşluk, `.`, `-`, `_`,
///  * baştaki/sondaki boşluk atılır, ardışık boşluklar teke iner,
///  * kontrol karakterleri ve `<`, `>`, `{`, `"` … gibi işaretler kabul edilmez
///    (HTML/script benzeri girişler böylece hiç yazılamaz),
///  * kısa bir uygunsuz kelime listesi (büyük bir filtre değil; ekleme yapılabilir).
class NicknamePolicy {
  const NicknamePolicy._();

  static const int minLength = 2;
  static const int maxLength = 16;

  static final RegExp _allowed = RegExp(
    r'^[\p{L}\p{M}\p{N} ._-]+$',
    unicode: true,
  );

  /// Küçük harfe çevrilmiş, harf dışı karakterleri atılmış adda aranır.
  /// Kasıtlı olarak kısa: yaygın kaba sözlerin kökleri.
  static const List<String> blockedWords = [
    'amk',
    'aq',
    'orospu',
    'pic',
    'sik',
    'yarrak',
    'got',
    'gavat',
    'ibne',
    'fuck',
    'shit',
    'bitch',
  ];

  /// Boşlukları sadeleştirir: baştaki/sondaki boşluk gider, ardışık boşluklar
  /// tek olur, kontrol karakterleri atılır.
  static String normalize(String raw) =>
      raw
          .replaceAll(
            RegExp(
              r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u2028-\u202E\u2066-\u2069\uFEFF]',
            ),
            '',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  /// Geçerliyse `null`, değilse hata nedeni. [raw] önce [normalize] edilir.
  static NicknameError? validate(String raw) {
    final name = normalize(raw);
    if (name.isEmpty) return NicknameError.empty;
    final length = name.runes.length;
    if (length < minLength) return NicknameError.tooShort;
    if (length > maxLength) return NicknameError.tooLong;
    if (!_allowed.hasMatch(name)) return NicknameError.invalidChars;
    if (_isBlocked(name)) return NicknameError.notAllowed;
    return null;
  }

  static bool isValid(String raw) => validate(raw) == null;

  static bool _isBlocked(String name) {
    final folded = _fold(name);
    final words = folded.split(' ');
    final joined = folded.replaceAll(' ', '');
    for (final w in blockedWords) {
      // Kısa kökler (≤3 harf) yalnızca tam kelime olarak; uzunlar her yerde.
      if (w.length <= 3
          ? words.contains(w) || joined == w
          : joined.contains(w)) {
        return true;
      }
    }
    return false;
  }

  /// Türkçe harfleri sadeleştirip küçük harfe çevirir ("Şİk" → "sik").
  static String _fold(String s) {
    const map = {
      'ç': 'c',
      'Ç': 'c',
      'ğ': 'g',
      'Ğ': 'g',
      'ı': 'i',
      'I': 'i',
      'İ': 'i',
      'ö': 'o',
      'Ö': 'o',
      'ş': 's',
      'Ş': 's',
      'ü': 'u',
      'Ü': 'u',
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
    };
    final b = StringBuffer();
    for (final ch in s.split('')) {
      b.write(map[ch] ?? ch.toLowerCase());
    }
    return b
        .toString()
        .replaceAll(RegExp(r'[._-]'), '')
        .replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
  }
}

enum NicknameError { empty, tooShort, tooLong, invalidChars, notAllowed }
