import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/arabic_letter.dart';
import '../../../theme/app_colors.dart';
import 'letter_page.dart';
import 'nav_arrow_button.dart';

/// The "Tek Harf" (one letter at a time) study mode — ONE LETTER, ONE
/// SCREEN, ONE FOCUS. Supports touch swipe, mouse/trackpad drag (via
/// [AppScrollBehavior] applied at the app level), keyboard left/right
/// arrows, and visible previous/next controls.
class SingleLetterPager extends StatefulWidget {
  final List<ArabicLetter> letters;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  /// "Önceki · 3 / 92 · Sonraki" under the letter, pages ordered left to
  /// right (swipe left or press → for the next one) — the "Tekli / Büyük"
  /// view of a lesson with a book page. Otherwise: bare arrows, pages
  /// ordered right to left like the book.
  final bool showCounter;

  const SingleLetterPager({
    super.key,
    required this.letters,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.showCounter = false,
  });

  @override
  State<SingleLetterPager> createState() => _SingleLetterPagerState();
}

class _SingleLetterPagerState extends State<SingleLetterPager> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _lastIndex => widget.letters.length - 1;

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goPrevious() {
    if (_currentIndex > 0) _goTo(_currentIndex - 1);
  }

  void _goNext() {
    if (_currentIndex < _lastIndex) _goTo(_currentIndex + 1);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final ltr = widget.showCounter;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      ltr ? _goNext() : _goPrevious();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      ltr ? _goPrevious() : _goNext();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.letters;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: PageView.builder(
        controller: _controller,
        reverse: !widget.showCounter,
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
      ),
    );
  }
}

/// "‹ Önceki   3 / 92   Sonraki ›".
class _CounterControls extends StatelessWidget {
  final int index;
  final int count;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _CounterControls({
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
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
              key: const ValueKey('single-previous'),
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Önceki'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${index + 1} / $count',
                key: const ValueKey('single-counter'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('single-next'),
              onPressed: onNext,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sonraki'),
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
