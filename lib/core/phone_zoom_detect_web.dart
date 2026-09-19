import 'package:web/web.dart' as web;

import 'phone_zoom_logic.dart';

/// Reads the browser's layout size and the device's screen size and asks
/// [phoneZoomFor] how much the page is being shrunk (1 = not at all).
double detectPhoneZoom() {
  try {
    final screen = web.window.screen;
    return phoneZoomFor(
      layoutWidth: web.window.innerWidth,
      layoutHeight: web.window.innerHeight,
      screenWidth: screen.width,
      screenHeight: screen.height,
    );
  } catch (_) {
    return 1;
  }
}
