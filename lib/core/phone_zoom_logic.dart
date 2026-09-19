import 'dart:math' as math;

/// How much smaller than the phone's own screen a browser is showing the
/// page — 1 when everything is normal.
///
/// A phone browser can lay the page out much wider than the screen (the
/// "desktop site" mode, some in-app browsers, an installed shortcut that
/// ignores the viewport tag) and then shrink it to fit; the app would take
/// that wide layout for a tablet and everything would look tiny.
///
/// The wide layout is recognised by the layout width being far beyond the
/// width the device really has *in the orientation it is held*. Some
/// browsers report `screen.width` unrotated (always the portrait width),
/// so the expected width is taken from the screen's short side when the
/// page is laid out in portrait and from its long side when in landscape —
/// never trusting which one `screen.width` happens to be.
///
/// Only phone-sized screens (short side under 600) are ever corrected.
double phoneZoomFor({
  required num layoutWidth,
  required num layoutHeight,
  required num screenWidth,
  required num screenHeight,
}) {
  final shortSide = math.min(screenWidth, screenHeight);
  final longSide = math.max(screenWidth, screenHeight);
  if (shortSide <= 0 || shortSide >= 600 || layoutWidth <= 0) return 1;
  final landscape = layoutWidth > layoutHeight;
  final expectedWidth = landscape ? longSide : shortSide;
  final ratio = layoutWidth / expectedWidth;
  return ratio > 1.25 ? ratio.toDouble() : 1;
}
