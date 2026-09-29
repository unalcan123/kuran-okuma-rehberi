import 'dart:ui' show Color;

import '../helpers/arabic_colorizer.dart';
import 'arabic_letter.dart';
import 'turkish_audio.dart';

/// A lesson's pages in the printed book (`ELIF BA BASKI DENEME 2012.pdf`),
/// in book order — the "Sayfa Görünümü" shows them one by one.
///
/// The items themselves stay in [Lesson.letters], the single source the
/// Sayfa, Grid and Tekli/Büyük views all read. A page only says which of
/// them it shows and how: page 1 takes the first [LessonBookPage.totalItems]
/// items, page 2 the next ones, and so on; within a page, each
/// [BookSection] takes the next [BookSection.itemCount] items. A section can
/// instead name items by index ([BookSection.refs]) when the book shows
/// them in another order or again (e.g. s. 9 "Sırasız yazılan harfler").
class LessonPageLayout {
  final List<LessonBookPage> pages;

  const LessonPageLayout(this.pages);

  /// Items taken in order by all pages.
  int get itemCount => pages.fold(0, (sum, page) => sum + page.totalItems);

  /// Every item index some page shows (in order or by reference).
  Set<int> get shownItems {
    final shown = <int>{};
    var start = 0;
    for (final page in pages) {
      for (final section in page.tables) {
        for (var i = 0; i < section.itemCount; i++) {
          shown.add(start + i);
        }
        start += section.itemCount;
        shown.addAll(section.refs ?? const []);
        shown.addAll(section.textItems.values);
      }
    }
    return shown;
  }

  /// Where item [itemIndex] is first shown: (page, section, position in
  /// the section), or null.
  (int, BookSection, int)? _find(int itemIndex) {
    var start = 0;
    for (var p = 0; p < pages.length; p++) {
      for (final section in pages[p].tables) {
        if (itemIndex >= start && itemIndex < start + section.itemCount) {
          return (p, section, itemIndex - start);
        }
        start += section.itemCount;
        final at = section.refs?.indexOf(itemIndex) ?? -1;
        if (at >= 0) return (p, section, at);
        for (final entry in section.textItems.entries) {
          if (entry.value == itemIndex) return (p, section, entry.key);
        }
      }
    }
    return null;
  }

  /// Index in [pages] of the page showing item [itemIndex].
  int pageIndexOf(int itemIndex) => _find(itemIndex)?.$1 ?? 0;

  /// The lesson items page [pageIndex] shows, in the page's order and
  /// once each: its run of items, then items shown by reference. The Grid
  /// view shows a page with exactly these (the same page boundaries as the
  /// Sayfa view); empty for an explanation page.
  List<int> itemsOf(int pageIndex) {
    final items = <int>[];
    var start = 0;
    for (var p = 0; p < pages.length; p++) {
      for (final section in pages[p].tables) {
        if (p == pageIndex) {
          for (var i = 0; i < section.itemCount; i++) {
            items.add(start + i);
          }
          items.addAll(section.refs ?? const []);
          final texts = section.textItems.keys.toList()..sort();
          items.addAll([for (final t in texts) section.textItems[t]!]);
        }
        start += section.itemCount;
      }
      if (p == pageIndex) break;
    }
    final seen = <int>{};
    return [for (final i in items) if (seen.add(i)) i];
  }

  /// Page to show for item [itemIndex] when the student was on page
  /// [currentPage]: that page if it shows the item (an item can be on
  /// more than one page, e.g. s. 6 and s. 7), else the item's first page.
  int pageShowing(int itemIndex, int currentPage) =>
      currentPage >= 0 &&
              currentPage < pages.length &&
              itemsOf(currentPage).contains(itemIndex)
          ? currentPage
          : pageIndexOf(itemIndex);

  /// Recordings the pages play besides the lesson's items (e.g. s. 8's
  /// Lâm-Elif shapes), for preloading.
  Iterable<String> get extraAudioAssets sync* {
    for (final page in pages) {
      for (final section in page.tables) {
        for (final item in [
          ...section.textAudio.values,
          ...?section.derivedAudioItems,
        ]) {
          if (item.audioAsset case final asset?) yield asset;
        }
      }
    }
  }

  /// Index in the lesson's items of the first item on page [pageIndex]
  /// (0 for a page without items).
  int firstItemOf(int pageIndex) {
    var start = 0;
    for (var p = 0; p < pages.length; p++) {
      for (final section in pages[p].tables) {
        if (p == pageIndex) {
          if (section.itemCount > 0) return start;
          final refs = section.refs;
          if (refs != null && refs.isNotEmpty) return refs.first;
        }
        start += section.itemCount;
      }
    }
    return 0;
  }

  /// The colors item [itemIndex] is printed with in the book (where it is
  /// first shown): the item's own override, else its section's profile,
  /// else its page's.
  ArabicColorProfile colorProfileOf(int itemIndex) {
    final found = _find(itemIndex);
    if (found == null) return ArabicColorProfile.standard;
    final (page, section, position) = found;
    return section.itemProfiles[position] ??
        section.colorProfile ??
        pages[page].colorProfile;
  }
}

/// What a book page is for.
enum LessonPageType {
  /// Teaches the topic (e.g. s. 14 "HAREKELER – ÜSTÜN").
  lesson('Konu'),

  /// "ÖRNEKLER": words to read with what was just taught.
  examples('Örnekler'),

  /// "ALIŞTIRMALAR" or a practice table (e.g. s. 9, s. 23, s. 60-63).
  exercise('Alıştırma'),

  /// Explanation without items to read (e.g. s. 3-5, çıkış yerleri).
  info('Bilgi');

  const LessonPageType(this.label);
  final String label;
}

/// What an item on a book page is — decides its size in a cell.
enum LessonItemKind {
  /// One letter with its mark(s): large, like the book's letter tables.
  letter,

  /// A word: smaller, so a whole word fits in the same cell.
  word,

  /// Several words / a phrase: smaller still.
  phrase,
}

/// How a section's items are laid out.
enum BookSectionKind {
  /// The book's table of dashed cells, read right to left.
  grid,

  /// "HARF | BAŞTA | ORTADA | SONDA" rows (s. 10-13): each item is one
  /// letter with its written forms and example words.
  forms,
}

/// One table (or explanation block) on a book page.
class BookSection {
  /// Heading of this block on the page (e.g. "ÇEKER ESRE").
  final String? title;

  /// Recording of [title] (see [TrAudio]).
  final String? titleAudio;

  /// Explanation paragraphs before the table; a paragraph starting with
  /// "- " or "* " is a bullet. Text inside “…” is printed red, as in the
  /// book; Arabic text is set in the Arabic font.
  final List<String> intro;

  /// Recordings of [intro]: paragraph index where each one starts → it.
  final Map<int, TrAudio> introAudio;

  final int itemCount;
  final BookSectionKind kind;

  /// Columns of the table (the book's count; fewer on a narrow screen).
  final int columns;

  /// Columns row by row when the rows differ (e.g. s. 39: 2, 4, 4);
  /// overrides [columns].
  final List<int>? rowColumns;

  final LessonItemKind itemKind;

  /// Item size row by row, repeating (e.g. s. 28: small pairs row, big row).
  final List<LessonItemKind>? rowKinds;

  /// A gap is left after every [groupRows] rows (e.g. s. 28: blocks of 2).
  final int? groupRows;

  /// Column headers, right to left (e.g. s. 41 "Durulduğunda").
  final List<String>? headers;

  /// Display order: position `i` of the table shows item `order[i]` of the
  /// section (indices relative to the section), when the book's layout
  /// differs from the data order.
  final List<int>? order;

  /// Colored frame and legend label around the whole table.
  final Color? frameColor;
  final String? label;

  /// Consecutive runs of items framed in a color, with a legend below the
  /// table (e.g. s. 23: 6 Boğaz red, 18 Dil blue, 4 Dudak green).
  final List<FrameRun> frames;

  /// The section's colors when they differ from the page's.
  final ArabicColorProfile? colorProfile;

  /// Colors of single items (index relative to the section) that differ
  /// from the section/page — e.g. s. 41's "Durulduğunda" column.
  final Map<int, ArabicColorProfile> itemProfiles;

  /// Items shown by index (lesson item indices) instead of taking the next
  /// [itemCount] items — when the book shows them again or in another order
  /// (e.g. s. 41 repeats the letters of s. 40). The same item and recording;
  /// nothing is copied.
  final List<int>? refs;

  /// With [refs]: the text each cell shows instead of the item's own (e.g.
  /// s. 7 the letters' names أَلِفْ بَا …; tapping still plays the item,
  /// which says that name).
  final List<String>? refTexts;

  /// Display-only cells (no item, no recording) — e.g. s. 8's Lâm-Elif
  /// shapes. With [rowLabels] a Turkish label ends each row.
  final List<String>? texts;
  final List<String>? rowLabels;

  /// Cells of [texts] that are items after all (position → lesson item
  /// index): tapping plays the item (e.g. s. 8's لا).
  final Map<int, int> textItems;

  /// Cells of [texts] with their own recording that are not lesson items
  /// (position → the recording; e.g. s. 8's لآ لأ لإ, each read
  /// differently). Tapping plays it; a cell also in [textItems] still
  /// opens that item on long-press.
  final Map<int, ArabicLetter> textAudio;

  /// For [BookSectionKind.forms]: rows the book adds between the items'
  /// rows, keyed by the position they come before (e.g. s. 10: the hemze
  /// row after elif). Display only.
  final Map<int, ArabicLetter> extraRows;

  /// With [refs]: each item is followed by this form of it (e.g. s. 41
  /// "Durulduğunda"). Audio can reuse existing items via [derivedAudioItems].
  final DerivedForm? derived;
  final ArabicColorProfile? derivedProfile;

  /// Existing audio source items, in the same order as [refs], for the
  /// derived cells. Does not change their displayed text or lesson indices.
  final List<ArabicLetter>? derivedAudioItems;

  /// Paragraphs after the table.
  final List<String> outro;

  /// Recordings of [outro], like [introAudio].
  final Map<int, TrAudio> outroAudio;

  const BookSection({
    this.title,
    this.titleAudio,
    this.intro = const [],
    this.introAudio = const {},
    this.itemCount = 0,
    this.kind = BookSectionKind.grid,
    this.columns = 4,
    this.rowColumns,
    this.itemKind = LessonItemKind.letter,
    this.rowKinds,
    this.groupRows,
    this.headers,
    this.order,
    this.frameColor,
    this.label,
    this.frames = const [],
    this.colorProfile,
    this.itemProfiles = const {},
    this.refs,
    this.refTexts,
    this.texts,
    this.rowLabels,
    this.textItems = const {},
    this.textAudio = const {},
    this.extraRows = const {},
    this.derived,
    this.derivedProfile,
    this.derivedAudioItems,
    this.outro = const [],
    this.outroAudio = const {},
  });
}

/// A form of an item the book prints next to it.
enum DerivedForm {
  /// Stopping on a letter with iki üstün: the tenvin is read as one üstün
  /// and the elif lengthens it (s. 41 "Durulduğunda": بًا → بَا).
  waqfOnFathatan;

  String apply(String text) => switch (this) {
    DerivedForm.waqfOnFathatan => '${text.replaceAll(RegExp('[ًاـ]'), '')}َا',
  };
}

/// [count] consecutive items of a section framed in [color] ([label] in
/// the legend).
class FrameRun {
  final int count;
  final Color color;
  final String label;

  const FrameRun(this.count, this.color, this.label);
}

/// One printed page: an optional heading, explanation lines, and one or
/// more [BookSection]s. A page with a single table can give its table
/// directly with [itemCount] / [columns] / [itemKind].
class LessonBookPage {
  /// Page number printed in the book — shown on the page so a teacher's
  /// "open page 15" works in the app too.
  final int bookPage;

  final LessonPageType type;

  /// Small line above the heading (e.g. "HAREKELER").
  final String? kicker;

  /// Heading (e.g. "ÜSTÜN", "ÖRNEKLER"); a page without one continues the
  /// previous page's table.
  final String? heading;

  /// Line under the heading (e.g. "(Çıkış Yerleri Sırasına Göre)").
  final String? subheading;

  /// Arabic name printed beside the heading (e.g. فَتْحَةٌ).
  final String? arabicHeading;

  /// The mark the page teaches, drawn on a tatweel (e.g. "ـَـ").
  final String? mark;

  /// Color of [arabicHeading] / [mark] when the book prints them in the
  /// taught color (e.g. s. 34 "YÂ ( ى )" blue); else the heading color.
  final Color? arabicHeadingColor;

  /// Color of [kicker] when not the heading color (e.g. s. 38 green).
  final Color? kickerColor;

  /// A ready-made heading picture used instead of the drawn heading.
  final String? headerImage;

  /// Recording of the heading (see [TrAudio]); none for a repeated
  /// general heading such as "ÖRNEKLER".
  final String? headingAudio;

  /// Explanation paragraphs (see [BookSection.intro]).
  final List<String> intro;

  /// Recordings of [intro] (see [BookSection.introAudio]).
  final Map<int, TrAudio> introAudio;

  /// A picture from the book (e.g. s. 5 mahreç drawing) and its legend.
  final String? figure;
  final List<FrameRun> figureLegend;

  final int itemCount;
  final int columns;
  final LessonItemKind itemKind;
  final List<BookSection> sections;

  /// Which parts the book prints in color on this page (read from the
  /// PDF's own text colors). The same item is drawn with these colors in
  /// every view.
  final ArabicColorProfile colorProfile;

  const LessonBookPage({
    required this.bookPage,
    required this.type,
    this.kicker,
    this.heading,
    this.subheading,
    this.arabicHeading,
    this.mark,
    this.arabicHeadingColor,
    this.kickerColor,
    this.headerImage,
    this.headingAudio,
    this.intro = const [],
    this.introAudio = const {},
    this.figure,
    this.figureLegend = const [],
    this.itemCount = 0,
    this.columns = 4,
    this.itemKind = LessonItemKind.letter,
    this.sections = const [],
    this.colorProfile = ArabicColorProfile.none,
  });

  /// The page's tables, in order.
  List<BookSection> get tables =>
      sections.isNotEmpty
          ? sections
          : [
            BookSection(
              itemCount: itemCount,
              columns: columns,
              itemKind: itemKind,
            ),
          ];

  /// Items on the page.
  int get totalItems =>
      sections.isNotEmpty
          ? sections.fold(0, (sum, s) => sum + s.itemCount)
          : itemCount;
}
