import '../l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Replaces the baked title while retaining the original illustrated card.
class RecitationTitleOverlay extends StatelessWidget {
  const RecitationTitleOverlay({
    super.key,
    required this.title,
    required this.label,
    required this.prayer,
    this.showTitle = true,
  });
  final String title;
  final String label;
  final bool prayer;
  final bool showTitle;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return ExcludeSemantics(
        child: Stack(
          children: [
            Positioned(
              left: w * .045,
              top: h * .018,
              width: w * .24,
              height: h * .14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xffa2eba4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: FittedBox(
                    child: Text(
                      context.t(label),
                      style: const TextStyle(color: Color(0xff061b32)),
                    ),
                  ),
                ),
              ),
            ),
            if (showTitle)
              Positioned(
                left: w * .045,
                top: h * .165,
                width: w * .55,
                height: h * (prayer ? .25 : .20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xfffffbf0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.t(title),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff071653),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
