import 'package:flutter/material.dart';

import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/book_pager.dart';
import 'letter_page.dart';
import 'nav_arrow_button.dart';

/// The "Tek Harf" (one letter at a time) study mode — ONE LETTER, ONE
/// SCREEN, ONE FOCUS. Pages turn right to left like the book ([BookPager]):
/// swipe left → right (or press ←) for the next item. Mouse/trackpad drag
/// works via [AppScrollBehavior] applied at the app level.
class SingleLetterPager extends StatefulWidget {
  final List<ArabicLetter> letters;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  /// "‹ Sonraki · 3 / 92 · Önceki ›" under the letter — the "Tekli / Büyük"
  /// view of a lesson with a book page. Otherwise: bare arrows.
  final bool showCounter;

  /// The book page item [index] is on (e.g. "Sayfa 15"), shown under the
  /// counter so the student knows when the next item is on the next page.
  final String? Function(int index)? pageLabelOf;

  const SingleLetterPager({
    super.key,
    required this.letters,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.showCounter = false,
    this.pageLabelOf,
  });

  @override
  State<SingleLetterPager> createState() => _SingleLetterPagerState();
}

class _SingleLetterPagerState extends State<SingleLetterPager> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _lastIndex => widget.letters.length - 1;

  void _goPrevious() {
    if (_currentIndex > 0) BookPager.turnTo(_controller, _currentIndex - 1);
  }

  void _goNext() {
    if (_currentIndex < _lastIndex) {
      BookPager.turnTo(_controller, _currentIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.letters;

    return BookPager(
      controller: _controller,
      itemCount: letters.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        widget.onIndexChanged?.call(index);
      },
      itemBuilder:
          (context, index) => LetterPage(
            letter: letters[index],
            navigationControls:
                widget.showCounter
                    ? _CounterControls(
                      index: _currentIndex,
                      count: letters.length,
                      pageLabel: widget.pageLabelOf?.call(_currentIndex),
                      onPrevious: _currentIndex > 0 ? _goPrevious : null,
                      onNext: _currentIndex < _lastIndex ? _goNext : null,
                    )
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        textDirection: TextDirection.ltr,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NavArrowButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed:
                                _currentIndex < _lastIndex ? _goNext : null,
                          ),
                          NavArrowButton(
                            icon: Icons.chevron_right_rounded,
                            onPressed: _currentIndex > 0 ? _goPrevious : null,
                          ),
                        ],
                      ),
                    ),
          ),
    );
  }
}

/// "‹ Sonraki   3 / 92   Önceki ›" (the next item is on the left, like the
/// book), with the item's book page under the count.
class _CounterControls extends StatelessWidget {
  final int index;
  final int count;
  final String? pageLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _CounterControls({
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
    this.pageLabel,
  });

  @override
  Widget build(BuildContext context) {
    final countStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // On a narrow phone (or with a large reading size) the row shrinks
      // rather than overflowing.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              key: const ValueKey('single-next'),
              onPressed: onNext,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Sonraki'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${index + 1} / $count',
                    key: const ValueKey('single-counter'),
                    style: countStyle,
                  ),
                  if (pageLabel != null)
                    Text(
                      pageLabel!,
                      key: const ValueKey('single-page-label'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('single-previous'),
              onPressed: onPrevious,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Önceki'),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
