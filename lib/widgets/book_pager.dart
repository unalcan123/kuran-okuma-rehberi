import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Pages turned like the Arabic book: right to left. The next page lies to
/// the LEFT of the current one, so the child swipes LEFT → RIGHT for the
/// next page and RIGHT → LEFT for the previous one. Every paged lesson
/// view (Sayfa, Grid, Tekli / Büyük) uses this, so the direction is the
/// same everywhere.
///
/// Keys follow the same picture: ← (toward the next page) = next,
/// → = previous; Page Down / Page Up also work.
///
/// Turning a page: the upper page (the one with the higher index) slides
/// over the lower one, which stays in place and darkens a little — like a
/// book page laid down over the previous one. The motion follows the
/// finger (it is the [PageView]'s own scroll position); no 3D, no extra
/// packages.
class BookPager extends StatefulWidget {
  const BookPager({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
    this.pageColor = AppColors.background,
    this.pageBackground,
  });

  final PageController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;

  /// Every page is opaque (the upper page covers the lower one while
  /// turning): this color, and [pageBackground] over it.
  final Color pageColor;
  final Widget? pageBackground;

  /// How long a turn by button or key takes.
  static const Duration turnDuration = Duration(milliseconds: 320);

  /// Turns to [page] (by button or key).
  static Future<void> turnTo(PageController controller, int page) =>
      controller.animateToPage(
        page,
        duration: turnDuration,
        curve: Curves.easeOutCubic,
      );

  /// The page's paint for a turn [delta] pages away from the current
  /// position: positive = the upper page coming in (0 < delta < 1), negative
  /// = the lower page being covered (-1 < delta < 0). Pure, for tests.
  @visibleForTesting
  static ({double dx, double shade, double scale, double edgeShadow})
  turnEffect(double delta, double width) {
    if (delta <= -1 || delta >= 1 || delta == 0) {
      return (dx: 0, shade: 0, scale: 1, edgeShadow: 0);
    }
    if (delta < 0) {
      // Lower page: PageView would slide it right by -delta * width; hold
      // it still so the upper page is laid over it.
      final covered = -delta;
      return (
        dx: delta * width,
        shade: 0.14 * covered,
        scale: 1 - 0.02 * covered,
        edgeShadow: 0,
      );
    }
    // Upper page: slides in with PageView; a soft shadow on its leading
    // (right) edge, strongest mid-turn.
    return (
      dx: 0,
      shade: 0,
      scale: 1,
      edgeShadow: math.sin(delta * math.pi).clamp(0.0, 1.0),
    );
  }

  @override
  State<BookPager> createState() => _BookPagerState();
}

class _BookPagerState extends State<BookPager> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  int get _current {
    final controller = widget.controller;
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return controller.initialPage;
    }
    return (controller.page ?? controller.initialPage.toDouble()).round();
  }

  void _turn(int page) {
    if (page < 0 || page >= widget.itemCount) return;
    BookPager.turnTo(widget.controller, page);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageDown) {
      _turn(_current + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageUp) {
      _turn(_current - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  double _position() {
    final controller = widget.controller;
    if (controller.hasClients && controller.position.haveDimensions) {
      return controller.page ?? controller.initialPage.toDouble();
    }
    return controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: PageView.builder(
        controller: widget.controller,
        // Right to left, like the book: the next page is on the left.
        reverse: true,
        itemCount: widget.itemCount,
        onPageChanged: widget.onPageChanged,
        itemBuilder: (context, index) {
          final page = RepaintBoundary(
            child: ColoredBox(
              color: widget.pageColor,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.pageBackground != null) widget.pageBackground!,
                  widget.itemBuilder(context, index),
                ],
              ),
            ),
          );
          return LayoutBuilder(
            builder:
                (context, constraints) => AnimatedBuilder(
                  animation: widget.controller,
                  child: page,
                  builder: (context, child) {
                    final effect = BookPager.turnEffect(
                      index - _position(),
                      constraints.maxWidth,
                    );
                    if (effect.dx == 0 &&
                        effect.shade == 0 &&
                        effect.edgeShadow == 0) {
                      return child!;
                    }
                    return Transform.translate(
                      offset: Offset(effect.dx, 0),
                      child: Transform.scale(
                        scale: effect.scale,
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            child!,
                            if (effect.shade > 0)
                              IgnorePointer(
                                child: ColoredBox(
                                  color: AppColors.navy.withValues(
                                    alpha: effect.shade,
                                  ),
                                ),
                              ),
                            if (effect.edgeShadow > 0)
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: constraints.maxWidth,
                                width: 18,
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.navy.withValues(
                                            alpha: 0.22 * effect.edgeShadow,
                                          ),
                                          AppColors.navy.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          );
        },
      ),
    );
  }
}
