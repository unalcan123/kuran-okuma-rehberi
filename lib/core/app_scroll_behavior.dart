import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Allows swipe-style dragging (PageView, ListView, ...) with mouse
/// and trackpad input in addition to touch, so desktop/web users get
/// the same natural swipe gesture mobile users get.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
