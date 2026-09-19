import 'package:flutter/widgets.dart';

/// Simple width-based breakpoints shared across the app so the same
/// codebase renders a real layout per device class instead of just
/// scaling the phone UI up.
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;
}

enum DeviceClass { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static DeviceClass deviceClassOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.tablet) return DeviceClass.desktop;
    if (width >= AppBreakpoints.mobile) return DeviceClass.tablet;
    return DeviceClass.mobile;
  }

  static bool isMobile(BuildContext context) =>
      deviceClassOf(context) == DeviceClass.mobile;

  static bool isTablet(BuildContext context) =>
      deviceClassOf(context) == DeviceClass.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceClassOf(context) == DeviceClass.desktop;

  /// Whether pointer-driven controls (visible arrows, keyboard hints)
  /// should be emphasized, i.e. non-touch-primary form factors.
  static bool prefersPointerControls(BuildContext context) =>
      !isMobile(context);
}
