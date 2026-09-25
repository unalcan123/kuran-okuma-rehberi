import 'package:flutter/services.dart';

/// Arapça Yazıyorum'un metin işlemleri. Hepsi GERÇEK Unicode metin üzerinde
/// çalışır (TextEditingValue); harfler hiçbir zaman ters çevrilmez ya da
/// sunum biçimlerine (U+FE70…) dönüştürülmez: birleşmeyi metin motoru yapar.

/// Harekeler (klavyenin Harekeler bölümü): üstün, esre, ötre, cezm, şedde,
/// iki üstün, iki esre, iki ötre.
const String kFatha = 'َ';
const String kKasra = 'ِ';
const String kDamma = 'ُ';
const String kSukun = 'ْ';
const String kShadda = 'ّ';
const String kFathatan = 'ً';
const String kKasratan = 'ٍ';
const String kDammatan = 'ٌ';

/// Şedde dışındaki harekeler: bir harfte en çok bir tane olur.
const Set<String> kVowelMarks = {
  kFatha, kKasra, kDamma, kSukun, kFathatan, kKasratan, kDammatan, //
};

bool isArabicMark(int cu) =>
    (cu >= 0x064B && cu <= 0x065F) ||
    cu == 0x0670 ||
    (cu >= 0x06D6 && cu <= 0x06ED);

/// Hareke alabilen Arapça harf (temel harfler + ek harfler).
bool isArabicLetter(int cu) =>
    (cu >= 0x0621 && cu <= 0x063A) ||
    (cu >= 0x0641 && cu <= 0x064A) ||
    cu == 0x0671 ||
    cu == 0x06A9 ||
    cu == 0x06CC;

TextSelection _safeSelection(TextEditingValue v) {
  final s = v.selection;
  if (!s.isValid) return TextSelection.collapsed(offset: v.text.length);
  return TextSelection(
    baseOffset: s.baseOffset.clamp(0, v.text.length),
    extentOffset: s.extentOffset.clamp(0, v.text.length),
  );
}

/// İmleçteki yere yazar; seçili metin varsa onun yerine yazar. İmleç yeni
/// metnin sonuna gelir. [maxLength] aşılırsa değer değişmez (`null` döner).
TextEditingValue? insertAtCursor(
  TextEditingValue v,
  String text, {
  int? maxLength,
}) {
  final sel = _safeSelection(v);
  final start = sel.start;
  final end = sel.end;
  final next = v.text.replaceRange(start, end, text);
  if (maxLength != null && next.length > maxLength) return null;
  return TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: start + text.length),
  );
}

/// Geri silme. Seçim varsa seçimi siler. Yoksa imleçten önceki TEK kod
/// birimini siler: hareke varsa önce en son hareke, sonra harf gider
/// (ör. "بَّ" → "بّ" → "ب" → ""). Vekil çiftler (emoji vb.) bütün silinir.
TextEditingValue deleteBackward(TextEditingValue v) {
  final sel = _safeSelection(v);
  if (!sel.isCollapsed) {
    return TextEditingValue(
      text: v.text.replaceRange(sel.start, sel.end, ''),
      selection: TextSelection.collapsed(offset: sel.start),
    );
  }
  final at = sel.start;
  if (at == 0) return v.copyWith(selection: sel);
  var from = at - 1;
  final cu = v.text.codeUnitAt(from);
  if (cu >= 0xDC00 && cu <= 0xDFFF && from > 0) {
    final hi = v.text.codeUnitAt(from - 1);
    if (hi >= 0xD800 && hi <= 0xDBFF) from--;
  }
  return TextEditingValue(
    text: v.text.replaceRange(from, at, ''),
    selection: TextSelection.collapsed(offset: from),
  );
}

enum HarakaResult { applied, replaced, alreadyThere, noLetter }

/// Harekeyi imleçten önceki Arapça harfe uygular. Hareke asla boş yere ya da
/// boşluğa yazılmaz ([HarakaResult.noLetter]). Harfte başka bir hareke
/// varsa yenisiyle değiştirilir (şedde ayrıca durabilir); aynı hareke
/// ikinci kez eklenmez. Seçim varsa önce seçim silinmez: hareke yalnızca
/// imlecin hemen önündeki harfe uygulanır.
(TextEditingValue, HarakaResult) applyHaraka(TextEditingValue v, String mark) {
  final sel = _safeSelection(v);
  final at = sel.isCollapsed ? sel.start : sel.end;
  // İmleçten geriye: önce harfin mevcut harekeleri, sonra harfin kendisi.
  var i = at - 1;
  while (i >= 0 && isArabicMark(v.text.codeUnitAt(i))) {
    i--;
  }
  if (i < 0 || !isArabicLetter(v.text.codeUnitAt(i))) {
    return (v.copyWith(selection: sel), HarakaResult.noLetter);
  }
  final letterEnd = i + 1;
  final marks = v.text.substring(letterEnd, at);
  if (marks.contains(mark)) {
    return (
      v.copyWith(selection: TextSelection.collapsed(offset: at)),
      HarakaResult.alreadyThere,
    );
  }
  var newMarks = marks;
  var result = HarakaResult.applied;
  if (kVowelMarks.contains(mark)) {
    final kept = marks.split('').where((m) => !kVowelMarks.contains(m)).join();
    if (kept.length != marks.length) result = HarakaResult.replaced;
    newMarks = kept + mark;
  } else {
    newMarks = marks + mark;
  }
  // Tutarlı sıra: şedde önce (yaygın yazım); karşılaştırmada zaten
  // [normalizeArabic] kanonik sıraya dizer.
  if (newMarks.contains(kShadda)) {
    newMarks = kShadda + newMarks.replaceAll(kShadda, '');
  }
  final text = v.text.replaceRange(letterEnd, at, newMarks);
  final cursor = letterEnd + newMarks.length;
  return (
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    ),
    result,
  );
}

// ---------------------------------------------------------------------------
// Normalleştirme (karşılaştırma için)

/// Arapça için kanonik birleşik sınıflar (Unicode ccc).
const Map<int, int> _ccc = {
  0x064B: 27,
  0x064C: 28,
  0x064D: 29,
  0x064E: 30,
  0x064F: 31,
  0x0650: 32,
  0x0651: 33,
  0x0652: 34,
  0x0653: 230,
  0x0654: 230,
  0x0655: 220,
  0x0670: 35,
};

/// NFC'deki Arapça birleşimler: (temel, işaret) → birleşik harf.
const Map<(int, int), int> _compose = {
  (0x0627, 0x0653): 0x0622, // آ
  (0x0627, 0x0654): 0x0623, // أ
  (0x0648, 0x0654): 0x0624, // ؤ
  (0x0627, 0x0655): 0x0625, // إ
  (0x064A, 0x0654): 0x0626, // ئ
  (0x06D5, 0x0654): 0x06C0,
  (0x06C1, 0x0654): 0x06C2,
  (0x06D2, 0x0654): 0x06D3,
};

final Map<int, (int, int)> _decompose = {
  for (final e in _compose.entries) e.value: e.key,
};

/// Unicode NFC'nin Arapça kısmı: ayrışık yazılan hemzeli/medli harfleri
/// birleştirir (ا + ٔ → أ) ve harekeleri kanonik sıraya dizer (şedde +
/// üstün ile üstün + şedde aynı olur). FARKLI harfleri eşitlemez: ى ile ي,
/// ة ile ه, أ ile ا farklı kalır. Baştaki/sondaki boşluklar atılır.
String normalizeArabic(String s) {
  // 1) Ayrıştır.
  final cps = <int>[];
  for (final r in s.trim().runes) {
    final d = _decompose[r];
    if (d != null) {
      cps
        ..add(d.$1)
        ..add(d.$2);
    } else {
      cps.add(r);
    }
  }
  // 2) Birleşik işaret dizilerini ccc'ye göre (kararlı) sırala.
  var i = 0;
  while (i < cps.length) {
    if ((_ccc[cps[i]] ?? 0) == 0) {
      i++;
      continue;
    }
    var j = i;
    while (j < cps.length && (_ccc[cps[j]] ?? 0) != 0) {
      j++;
    }
    final run = cps.sublist(i, j);
    final indexed = [for (var k = 0; k < run.length; k++) (k, run[k])]
      ..sort((a, b) {
        final c = _ccc[a.$2]!.compareTo(_ccc[b.$2]!);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    cps.replaceRange(i, j, [for (final e in indexed) e.$2]);
    i = j;
  }
  // 3) Birleştir (araya aynı ya da daha yüksek sınıflı işaret girmediyse).
  final out = <int>[];
  var starter = -1;
  var lastCcc = 0;
  for (final cp in cps) {
    final c = _ccc[cp] ?? 0;
    if (starter >= 0 && c != 0 && lastCcc < c) {
      final composed = _compose[(out[starter], cp)];
      if (composed != null) {
        out[starter] = composed;
        continue;
      }
    }
    if (c == 0) {
      starter = out.length;
      lastCcc = 0;
    } else {
      lastCcc = c;
    }
    out.add(cp);
  }
  return String.fromCharCodes(out);
}

/// İki yazı aynı mı (normalleştirilmiş).
bool sameArabic(String a, String b) => normalizeArabic(a) == normalizeArabic(b);

/// Yazılan ile hedefin ortak başlangıcından sonraki ilk gereken karakter
/// (İpucu için). Yazılan hedefin başı değilse `null` + [wrongFrom] konumu.
({String? next, int? wrongFrom}) nextNeeded(String typed, String target) {
  final t = normalizeArabic(typed);
  final g = normalizeArabic(target);
  var k = 0;
  while (k < t.length && k < g.length && t[k] == g[k]) {
    k++;
  }
  if (k < t.length) return (next: null, wrongFrom: k);
  if (k >= g.length) return (next: null, wrongFrom: null);
  return (next: g[k], wrongFrom: null);
}
