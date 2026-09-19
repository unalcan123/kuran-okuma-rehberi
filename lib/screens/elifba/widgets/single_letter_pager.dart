import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/arabic_letter.dart';
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

  const SingleLetterPager({
    super.key,
    required this.letters,
    this.initialIndex = 0,
    this.onIndexChanged,
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
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goPrevious();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goNext();
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
        reverse: true,
        itemCount: letters.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          widget.onIndexChanged?.call(index);
        },
        itemBuilder:
            (context, index) => LetterPage(
              letter: letters[index],
              navigationControls: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NavArrowButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: _currentIndex < _lastIndex ? _goNext : null,
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
