import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/responsive.dart';

/// Decorative children (illustrations, `assets/images/kids/`) standing in the
/// empty margins left and right of a lesson's content — never on it.
///
/// A kid is drawn only in a margin wide enough for it: [contentMaxWidth] is
/// the widest the lesson's content gets, so the margin is
/// `(screen width - contentMaxWidth) / 2`. Desktop: one kid on each side;
/// tablet: one small kid on the right; phone: none. Without
/// [contentMaxWidth] (views that use the whole width) there are no kids.
///
/// Purely ornamental: never takes touches. A picture that is not in the app
/// yet is simply left out (see [LessonKids.available]), so the files can be
/// added one at a time.
class LessonKidsDecoration extends StatelessWidget {
  const LessonKidsDecoration({
    super.key,
    required this.child,
    required this.contentMaxWidth,
    this.lessonIndex = 0,
  });

  final Widget child;

  /// The widest the content gets (null: it fills the screen, no kids).
  final double? contentMaxWidth;

  /// Which pair of kids: lessons take turns, in order (not random).
  final int lessonIndex;

  /// Smallest kid worth drawing, and the largest.
  static const double minKidWidth = 110;
  static const double maxKidWidth = 220;
  static const double maxTabletKidWidth = 140;

  /// Space kept between a kid and the content / the screen edge.
  static const double gap = 12;

  @override
  Widget build(BuildContext context) {
    final maxContent = contentMaxWidth;
    if (maxContent == null) return child;
    LessonKids.ensureLoaded();
    final device = Responsive.deviceClassOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final margin = (constraints.maxWidth - maxContent) / 2;
        final width = switch (device) {
          DeviceClass.mobile => 0.0,
          DeviceClass.tablet => (margin - 2 * gap).clamp(
            0.0,
            maxTabletKidWidth,
          ),
          DeviceClass.desktop => (margin - 2 * gap).clamp(0.0, maxKidWidth),
        };
        if (width < minKidWidth) return child;
        final pair = LessonKids.pairFor(lessonIndex);
        return ValueListenableBuilder<Set<String>>(
          valueListenable: LessonKids.available,
          builder: (context, available, _) {
            Widget? kid(String asset, {required bool left}) {
              if (!available.contains(asset)) return null;
              return Positioned(
                left: left ? gap : null,
                right: left ? null : gap,
                bottom: gap,
                child: IgnorePointer(
                  child: SizedBox(
                    key: ValueKey('lesson-kid-${left ? 'left' : 'right'}'),
                    width: width,
                    height: width * LessonKids.heightRatio,
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            }

            final left =
                device == DeviceClass.desktop ? kid(pair.$1, left: true) : null;
            final right = kid(pair.$2, left: false);
            // Over the view (its own background fills the screen), but only
            // in the empty margins, so they never cover the content.
            return Stack(
              children: [
                Positioned.fill(child: child),
                if (left != null) left,
                if (right != null) right,
              ],
            );
          },
        );
      },
    );
  }
}

/// The kid illustrations and which of them the app has.
abstract final class LessonKids {
  /// Pictures are portrait, 2:3.
  static const double heightRatio = 1.5;

  /// (left, right) pairs; lessons take turns in this order.
  static const List<(String, String)> pairs = [
    (
      'assets/images/kids/kid_quran_rahle.webp',
      'assets/images/kids/kid_book.webp',
    ),
    (
      'assets/images/kids/kid_praying.webp',
      'assets/images/kids/kid_happy.webp',
    ),
  ];

  static (String, String) pairFor(int lessonIndex) =>
      pairs[lessonIndex.abs() % pairs.length];

  /// Kid pictures present in the app's assets.
  static final ValueNotifier<Set<String>> available = ValueNotifier(const {});

  static Future<void>? _loading;

  /// Reads the app's asset list once; safe to call from every build.
  static void ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      available.value = {
        for (final asset in manifest.listAssets())
          if (asset.startsWith('assets/images/kids/')) asset,
      };
    } catch (error) {
      debugPrint('LessonKids: görsel listesi okunamadı — $error');
    }
  }

  /// For tests: pretend exactly these pictures exist.
  @visibleForTesting
  static void debugSetAvailable(Set<String> assets) {
    _loading = Future.value();
    available.value = assets;
  }
}
