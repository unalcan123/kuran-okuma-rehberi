import 'package:flutter/widgets.dart';

import 'reading_text_settings.dart';
import 'tablet_zoom.dart';

/// How much larger a lesson's Arabic reading content is drawn than its
/// normal size: letters and examples with every mark (harekeler, cezm,
/// şedde, med). Only the Arabic grows — titles, menus and Turkish text do
/// not — and only on tablets and desktops; phones keep their look.
///
/// [ColoredArabicText] applies it to its font size; layouts that size cells
/// for Arabic count it like the reading text size ([arabicFactorOf]), so a
/// row takes fewer examples instead of shrinking the letters.
class ArabicScale extends InheritedWidget {
  const ArabicScale({super.key, required this.factor, required super.child});

  final double factor;

  /// Total enlargement of a lesson's Arabic on a tablet or a desktop,
  /// together with the screen's [TabletZoom].
  static const double lessonTotal = 1.3;

  /// The factor for a lesson screen of [screen] size: what is left of
  /// [lessonTotal] after the screen's [TabletZoom]; 1 on a phone.
  static double lessonFactorFor(Size screen) {
    final zoom = TabletZoom.zoomFor(screen);
    return zoom == 1 ? 1 : lessonTotal / zoom;
  }

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ArabicScale>()?.factor ?? 1;

  /// The reading text size ([ReadingTextScale]) times [of]: how much larger
  /// than normal the Arabic of a lesson is drawn.
  static double arabicFactorOf(BuildContext context) =>
      ReadingTextScale.factorOf(context) * of(context);

  @override
  bool updateShouldNotify(ArabicScale oldWidget) => oldWidget.factor != factor;
}
