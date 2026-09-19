import 'package:flutter/widgets.dart';

import '../core/phone_zoom_detect.dart';

/// Shows the app at phone size when a phone's browser has laid the page
/// out far wider than the screen (see [detectPhoneZoom]). The app is
/// given a phone-sized canvas — so it picks its phone layout — and that
/// canvas is enlarged to fill the wide page, which the browser then shrinks
/// to the screen: the result looks like the installed phone app. When
/// nothing is off (zoom 1) this widget is invisible.
class PhoneZoomFix extends StatefulWidget {
  const PhoneZoomFix({
    super.key,
    required this.child,
    this.detect = detectPhoneZoom,
  });

  final Widget child;

  /// How much to enlarge; anything up to 1 means "leave it alone".
  final double Function() detect;

  @override
  State<PhoneZoomFix> createState() => _PhoneZoomFixState();
}

class _PhoneZoomFixState extends State<PhoneZoomFix>
    with WidgetsBindingObserver {
  late double _zoom = widget.detect();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final zoom = widget.detect();
    if (zoom != _zoom) setState(() => _zoom = zoom);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_zoom <= 1) return widget.child;
    final media = MediaQuery.of(context);
    final size = media.size / _zoom;
    // Align first: it frees the canvas from the page's tight constraints so
    // it can really be phone-sized.
    return Align(
      alignment: Alignment.topLeft,
      child: Transform.scale(
        scale: _zoom,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: MediaQuery(
            data: media.copyWith(
              size: size,
              padding: media.padding / _zoom,
              viewPadding: media.viewPadding / _zoom,
              viewInsets: media.viewInsets / _zoom,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
