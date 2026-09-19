import 'dart:math' as math;

import 'package:web/web.dart' as web;

/// How much smaller than the phone's own screen the browser is showing
/// the page — 1 when everything is normal.
///
/// A phone browser can lay the page out much wider than the screen (the
/// "desktop site" mode, some in-app browsers, an installed shortcut that
/// ignores the viewport tag) and then shrink it to fit. The app would
/// take that wide layout for a tablet and everything would look tiny.
/// The wide layout is recognised by the browser's layout width being far
/// beyond the device's real screen width on a phone-sized screen.
double detectPhoneZoom() {
  try {
    final screen = web.window.screen;
    final shortSide = math.min(screen.width, screen.height);
    final layoutWidth = web.window.innerWidth;
    if (shortSide <= 0 || shortSide >= 600 || layoutWidth <= 0) return 1;
    final ratio = layoutWidth / screen.width;
    return ratio > 1.25 ? ratio : 1;
  } catch (_) {
    return 1;
  }
}
