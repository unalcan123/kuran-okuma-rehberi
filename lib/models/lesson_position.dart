import 'lesson_page_layout.dart';

/// Where the student is in a lesson — the one state the Sayfa, Grid and
/// Tekli / Büyük views share: the active book page (index in the layout's
/// pages; Sayfa and Grid show it) and the active item (index in
/// `Lesson.letters`; Tekli / Büyük shows it). Changing one keeps the other
/// on the same book page.
class LessonPosition {
  /// Opens on the first book page, or on the page of [item] when given.
  LessonPosition(this.layout, {int? item}) {
    if (item != null) {
      showItem(item);
    } else {
      showPage(0);
    }
  }

  /// Null for a lesson without book pages (only [item] matters then).
  final LessonPageLayout? layout;

  int _page = 0;
  int _item = 0;

  int get page => _page;
  int get item => _item;

  /// The student turned to book page [page] (Sayfa or Grid). The item stays
  /// if the page shows it, else it becomes the page's first item.
  void showPage(int page) {
    _page = page;
    final items = layout?.itemsOf(page) ?? const <int>[];
    if (items.isNotEmpty && !items.contains(_item)) _item = items.first;
  }

  /// The student moved to item [item] (Tekli / Büyük, or a long-press). The
  /// page stays if it shows the item, else it becomes the item's page.
  void showItem(int item) {
    _item = item;
    final layout = this.layout;
    if (layout != null) _page = layout.pageShowing(item, _page);
  }

  /// "Sayfa 15": the book page item [item] is on, seen from the active page.
  String? pageLabelOf(int item) {
    final layout = this.layout;
    if (layout == null || layout.pages.isEmpty) return null;
    return 'Sayfa ${layout.pages[layout.pageShowing(item, _page)].bookPage}';
  }
}
