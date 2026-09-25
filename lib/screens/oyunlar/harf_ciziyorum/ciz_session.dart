import 'ciz_progress_store.dart';

/// Bir oturumdaki harf sayısı; çocuk isterse "5 harf daha" ile sürer.
const int kDrawSessionSize = 5;

const List<int> _allIds = [
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, //
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28,
];

/// "Sırayla Öğren": [startId]'den başlayarak Elifba sırasıyla 5 harf
/// (sonda başa döner).
List<int> lettersFrom(int startId, {int count = kDrawSessionSize}) {
  final start = _allIds.indexOf(startId);
  return [
    for (var i = 0; i < count; i++) _allIds[(start + i) % _allIds.length],
  ];
}

/// Oturumdan sonra "5 harf daha": son çalışılanın ardından gelen 5 harf.
List<int> nextLettersInOrder(
  int lastId,
  Map<int, LetterDrawProgress> progress, {
  int count = kDrawSessionSize,
}) => lettersFrom(
  _allIds[(_allIds.indexOf(lastId) + 1) % _allIds.length],
  count: count,
);

/// Başlangıç ekranında önerilen ilk harf: iki yıldızı olmayan ilk harf.
int suggestedStart(Map<int, LetterDrawProgress> progress) {
  for (final id in _allIds) {
    if ((progress[id]?.stars ?? 0) < 2) return id;
  }
  return 1;
}

/// "Zorlandıklarımı Çalış": önce zorlanma sayacı yüksek olanlar, sonra
/// kılavuzla yapılıp daha az yardımla henüz yapılamayanlar (en çok 5).
List<int> practiceLetters(
  Map<int, LetterDrawProgress> progress, {
  int count = kDrawSessionSize,
}) {
  final struggling = [
    for (final id in _allIds)
      if ((progress[id]?.struggle ?? 0) > 0) id,
  ]..sort((a, b) => progress[b]!.struggle.compareTo(progress[a]!.struggle));
  final halfDone = [
    for (final id in _allIds)
      if ((progress[id]?.guided ?? false) &&
          !(progress[id]?.lessHelp ?? false) &&
          !struggling.contains(id))
        id,
  ];
  return [...struggling, ...halfDone].take(count).toList();
}
