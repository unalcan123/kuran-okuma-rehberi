import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lays [count] square items out in centered rows, choosing the column
/// count that makes them as large as the available box allows (up to
/// [maxItemSize]). Everything always fits — the game never scrolls —
/// and small screens simply get smaller pieces.
class FitGrid extends StatelessWidget {
  const FitGrid({
    super.key,
    required this.count,
    required this.itemBuilder,
    this.maxItemSize = 150,
    this.minItemSize = 44,
    this.gap = 14,
  });

  final int count;
  final Widget Function(BuildContext context, int index, double size)
  itemBuilder;
  final double maxItemSize;
  final double minItemSize;
  final double gap;

  (int, double) _fit(Size area) {
    var bestColumns = 1;
    var bestSize = 0.0;
    for (var columns = 1; columns <= count; columns++) {
      final rows = (count / columns).ceil();
      final width = (area.width - gap * (columns - 1)) / columns;
      final height = (area.height - gap * (rows - 1)) / rows;
      final size = math.min(width, height);
      if (size > bestSize) {
        bestSize = size;
        bestColumns = columns;
      }
    }
    return (bestColumns, bestSize.clamp(minItemSize, maxItemSize));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final (columns, size) = _fit(constraints.biggest);
      final rows = <Widget>[];
      for (var start = 0; start < count; start += columns) {
        final end = math.min(start + columns, count);
        rows.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = start; i < end; i++) ...[
                if (i > start) SizedBox(width: gap),
                itemBuilder(context, i, size),
              ],
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              rows[i],
            ],
          ],
        ),
      );
    },
  );
}
