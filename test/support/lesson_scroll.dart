import 'package:flutter_test/flutter_test.dart';

/// Scrolls a lesson screen with the finger until [target] is well on
/// screen. (`tester.ensureVisible` does not work there: the lesson's title
/// bar and view selector scroll away in a NestedScrollView, and revealing
/// through its outer part resets the inner page's scroll.)
Future<void> revealInLesson(WidgetTester tester, Finder target) async {
  final view = tester.view;
  final height = view.physicalSize.height / view.devicePixelRatio;
  final width = view.physicalSize.width / view.devicePixelRatio;
  for (var i = 0; i < 60; i++) {
    final rect = tester.getRect(target);
    // Room for the page bar at the bottom.
    if (rect.top >= 0 && rect.bottom <= height - 72) return;
    final dy = (rect.center.dy - height / 2).clamp(-240.0, 240.0);
    await tester.timedDragFrom(
      Offset(width / 2, height / 2),
      Offset(0, -dy),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();
  }
  fail('could not scroll $target into view');
}
