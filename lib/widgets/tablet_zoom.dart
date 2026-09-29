import 'package:flutter/widgets.dart';

import '../core/responsive.dart';

/// Shows [child] about 20 % larger on tablets and desktops: the child is
/// laid out on a canvas 1/[factor] the size of the space it gets and that
/// canvas is enlarged to fill it. Everything grows together — text, Arabic
/// letters and their marks, pictures, buttons — and a grid that counts how
/// many cards fit gets fewer columns by itself, so nothing overflows or is
/// cut. Phones (the screen's short side under [AppBreakpoints.mobile], a
/// phone turned sideways too) are left exactly as they are.
///
/// Used for the bodies of the lesson, surah and prayer screens (their app
/// bars stay as they are). Inside, [MediaQuery] reports the canvas size, so
/// breakpoints keep working on what is actually laid out.
class TabletZoom extends StatelessWidget {
  const TabletZoom({super.key, required this.child});

  final Widget child;

  /// How much larger on a tablet or a desktop.
  static const double factor = 1.2;

  /// The zoom for a screen of [screen] size: [factor], or 1 on a phone.
  static double zoomFor(Size screen) =>
      screen.shortestSide >= AppBreakpoints.mobile ? factor : 1;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final zoom = zoomFor(media.size);
    if (zoom == 1) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest / zoom;
        // Align first: it frees the canvas from the tight constraints so it
        // can really be smaller before it is enlarged.
        return ClipRect(
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scale: zoom,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: MediaQuery(
                  data: media.copyWith(
                    size: media.size / zoom,
                    padding: media.padding / zoom,
                    viewPadding: media.viewPadding / zoom,
                    viewInsets: media.viewInsets / zoom,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
