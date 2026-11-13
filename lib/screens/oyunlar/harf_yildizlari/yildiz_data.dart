import 'package:flutter/material.dart';

import '../../../data/drag_drop_game_data.dart';
import '../../../l10n/l10n.dart';
import '../../../models/arabic_letter.dart';
import '../drag_drop/learning/letter_learning.dart';

/// Harf Yıldızları'nın ders verisi. Harfler ve sırası Sürükle & Bırak'ın
/// 29 harflik listesinden gelir (`kDragDropAllLetters`: Elifba sırası, Lâm Elif
/// 24. sırada); ad ve ses kaydı da aynı yerden. Burada harf uydurulmaz.

/// Oyunun ana rengi.
const Color kYildizNavy = Color(0xFF0B2452);

/// Oyunun kimliği (Oyunlar menüsü).
const String kHarfYildizlariGameKey = 'harf_yildizlari';

/// Rehberdeki 29 harf, sırasıyla.
List<ArabicLetter> get kYildizLetters => kDragDropAllLetters;

/// Harfin kararlı anahtarı (kayıt ve eşleştirme için).
String yildizKey(ArabicLetter letter) => letterIdOf(letter);

ArabicLetter? yildizLetterByKey(String key) {
  for (final letter in kYildizLetters) {
    if (yildizKey(letter) == key) return letter;
  }
  return null;
}

enum YildizLessonKind { main, review }

class YildizLesson {
  const YildizLesson({
    required this.id,
    required this.title,
    required this.first,
    required this.last,
    required this.kind,
    required this.baseQuestions,
    this.requires = const [],
    this.badge,
    this.tourSize,
  });

  final String id;
  final String title;

  /// Rehber sırasında 1 tabanlı, ikisi de dahil.
  final int first;
  final int last;
  final YildizLessonKind kind;

  /// Ayarlanmadan önceki temel soru sayısı.
  final int baseQuestions;

  /// Bu ders açılmadan önce tamamlanması gereken derslerin kimlikleri.
  final List<String> requires;

  /// Dersi ilk kez bitirince kazanılan rozetin adı (yoksa null).
  final String? badge;

  /// Doluysa temel sorular bu uzunlukta turlara bölünür; tur arası devam
  /// olanağı verilir.
  final int? tourSize;

  bool get isReview => kind == YildizLessonKind.review;
  int get letterCount => last - first + 1;

  String get rangeLabel =>
      first == last ? '$first. harf' : '$first–$last. harfler';

  List<ArabicLetter> get letters => kYildizLetters.sublist(first - 1, last);
}

const List<String> _mainBadges = [
  'İlk 5 Harfim',
  'İkinci 5 Harfim',
  'Üçüncü 5 Harfim',
  'Dördüncü 5 Harfim',
  'Beşinci 5 Harfim',
  'Son 4 Harfim',
];

/// Altı ana ders (5+5+5+5+5+4) ve beş tekrar durağı. Aralıklar ve açılma
/// koşulları yalnızca bu listeden yönetilir; sıra haritadaki sıradır.
final List<YildizLesson> kYildizLessons = () {
  YildizLesson main(int n) => YildizLesson(
    id: 'g$n',
    title: '$n. Ders',
    first: (n - 1) * 5 + 1,
    last: n == 6 ? 29 : n * 5,
    kind: YildizLessonKind.main,
    baseQuestions: 8,
    requires: n == 1 ? const [] : ['g${n - 1}'],
    badge: _mainBadges[n - 1],
  );
  return [
    main(1),
    main(2),
    const YildizLesson(
      id: 'r10',
      title: 'İlk 10 Harf',
      first: 1,
      last: 10,
      kind: YildizLessonKind.review,
      baseQuestions: 12,
      requires: ['g1', 'g2'],
      badge: '10 Harf Bir Arada',
    ),
    main(3),
    const YildizLesson(
      id: 'r15',
      title: 'İlk 15 Harf',
      first: 1,
      last: 15,
      kind: YildizLessonKind.review,
      baseQuestions: 15,
      requires: ['g1', 'g2', 'g3'],
      badge: '15 Harf Bir Arada',
    ),
    main(4),
    const YildizLesson(
      id: 'r20',
      title: 'İkinci 10 Harf',
      first: 11,
      last: 20,
      kind: YildizLessonKind.review,
      baseQuestions: 12,
      requires: ['g4'],
    ),
    main(5),
    main(6),
    const YildizLesson(
      id: 'r14',
      title: 'Son 14 Harf',
      first: 16,
      last: 29,
      kind: YildizLessonKind.review,
      baseQuestions: 15,
      requires: ['g6'],
    ),
    const YildizLesson(
      id: 'r29',
      title: '29 Harf Bir Arada',
      first: 1,
      last: 29,
      kind: YildizLessonKind.review,
      baseQuestions: 29,
      requires: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6'],
      badge: '29 Harfle Tanıştım!',
      tourSize: 10,
    ),
  ];
}();

YildizLesson yildizLessonById(String id) =>
    kYildizLessons.firstWhere((lesson) => lesson.id == id);

/// Tek yerde tanımlı ödül kuralları.
abstract final class YildizRewards {
  /// Tamamlanan her temel alıştırma (destekle tamamlamak dahil); yeniden
  /// oynanan derslerde de verilir.
  static const int practiceXp = 5;

  /// Yalnızca dersin ilk tamamlanışında.
  static const int firstCompletionBonus = 20;

  /// Bu kadar yanlıştan sonra doğru cevap gösterilir ve soru destekle biter.
  static const int maxWrongBeforeGuide = 2;

  /// Bir harf için en çok bu kadar tekrar sorusu sorulur (sonsuz döngü yok).
  static const int maxRetriesPerLetter = 2;

  /// Tekrar sorusu, hata yapılan sorudan en az bu kadar temel soru sonra gelir.
  static const int retryGap = 2;

  /// Anlamlı çalışma sayılması için tamamlanması gereken temel soru.
  static const int meaningfulQuestions = 5;
}

/// Veri ve motorun oluşturduğu dinamik metinleri seçili dilde gösterir.
/// Sayılı metinler L10n tablosundaki yer tutuculu şablonlarla eşleşir.
String yt(BuildContext context, String text) => context.t(text);
