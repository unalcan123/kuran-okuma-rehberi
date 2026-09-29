import 'package:flutter/material.dart';

import '../../../models/arabic_letter.dart';
import '../../../models/lesson_page_layout.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/book_pager.dart';
import 'all_letters_grid.dart';
import 'lesson_page_view.dart';
import 'letter_forms_table.dart';

/// The "Grid" view of a lesson with book pages: one grid per book page, with
/// the same page boundaries as the Sayfa view ([LessonPageLayout.itemsOf]),
/// turned like the book ([BookPager]). Items are the lesson's own [letters];
/// nothing is copied.
class LessonGridPager extends StatefulWidget {
  final List<ArabicLetter> letters;
  final LessonPageLayout layout;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<ArabicLetter> onTapLetter;

  /// Gets the item's index in [letters].
  final ValueChanged<int> onOpenLetter;

  /// Ders 2: each page as the "başta, ortada, sonda" table.
  final bool formsTable;

  const LessonGridPager({
    super.key,
    required this.letters,
    required this.layout,
    required this.onTapLetter,
    required this.onOpenLetter,
    this.initialPage = 0,
    this.onPageChanged,
    this.formsTable = false,
  });

  @override
  State<LessonGridPager> createState() => _LessonGridPagerState();
}

class _LessonGridPagerState extends State<LessonGridPager> {
  late final PageController _controller = PageController(
    initialPage: widget.initialPage,
  );
  late int _page = widget.initialPage;

  List<LessonBookPage> get _pages => widget.layout.pages;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _pages.length) return;
    BookPager.turnTo(_controller, page);
  }

  Widget _grid(int page) {
    final indices = widget.layout.itemsOf(page);
    if (indices.isEmpty) {
      return Center(
        key: ValueKey('grid-page-${_pages[page].bookPage}'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Bu sayfada okunacak harf yok.\nAçıklamayı 📖 Sayfa görünümünde oku.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    final items = [for (final i in indices) widget.letters[i]];
    void open(int local) => widget.onOpenLetter(indices[local]);
    return KeyedSubtree(
      key: ValueKey('grid-page-${_pages[page].bookPage}'),
      child:
          widget.formsTable
              ? LetterFormsTable(
                letters: items,
                onTapLetter: widget.onTapLetter,
                onOpenLetter: open,
              )
              : AllLettersGrid(
                letters: items,
                onTapLetter: widget.onTapLetter,
                onOpenLetter: open,
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BookPager(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (page) {
              setState(() => _page = page);
              widget.onPageChanged?.call(page);
            },
            itemBuilder: (context, page) => _grid(page),
          ),
        ),
        BookPageBar(
          page: _pages[_page],
          index: _page,
          count: _pages.length,
          onPrevious: _page > 0 ? () => _goTo(_page - 1) : null,
          onNext: _page < _pages.length - 1 ? () => _goTo(_page + 1) : null,
        ),
      ],
    );
  }
}
