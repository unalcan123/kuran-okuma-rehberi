import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../widgets/reading_text_settings.dart';

import '../../../models/arabic_letter.dart';
import 'letter_card.dart';
import 'letter_page_background.dart';
import 'mahrec_banner.dart';

class _LetterGroup {
  final String? label;
  final int startIndex;
  final List<ArabicLetter> items;

  const _LetterGroup({
    required this.label,
    required this.startIndex,
    required this.items,
  });
}

/// Splits a lesson's letters into consecutive runs sharing the same
/// [ArabicLetter.groupLabel], so a lesson that mixes content types
/// (e.g. "Harf + Üstün" then "Kelime Okuma") still lays out as
/// separate grids per section. A lesson with no group labels (Ders 1,
/// 2) comes back as a single unlabeled group — identical to a plain
/// grid.
List<_LetterGroup> _groupConsecutive(List<ArabicLetter> letters) {
  final groups = <_LetterGroup>[];
  var i = 0;
  while (i < letters.length) {
    final label = letters[i].mahrec?.label ?? letters[i].groupLabel;
    final start = i;
    final items = <ArabicLetter>[];
    while (i < letters.length &&
        (letters[i].mahrec?.label ?? letters[i].groupLabel) == label) {
      items.add(letters[i]);
      i++;
    }
    groups.add(_LetterGroup(label: label, startIndex: start, items: items));
  }
  return groups;
}

/// The "Tüm Harfler" view: every letter of the lesson on one
/// scrollable grid.
///
/// Column count is driven purely by how much width each card actually
/// needs, not by how much screen is available: "does the screen have
/// room for one more card at its minimum width?" rather than "the
/// screen got wider, so add a column." A [LetterCard] showing
/// başta/ortada/sonda forms ([_minCardWidthPositionForms]) needs much
/// more room per card than a plain single-glyph card
/// ([_minCardWidthSimple]) — using the same target for both is what
/// let a "Harflerin Yazılışları"-style grid get squeezed to 6 narrow
/// columns and overflow on tablets.
class AllLettersGrid extends StatelessWidget {
  final List<ArabicLetter> letters;
  final ValueChanged<ArabicLetter> onTapLetter;
  final ValueChanged<int> onOpenLetter;

  /// Never let the whole grid area itself grow past this, even on an
  /// ultrawide desktop — keeps rows from stretching into a handful of
  /// oversized cards.
  static const double _maxContentWidth = 1100;

  /// Minimum comfortable width for a card that shows başta/ortada/
  /// sonda forms side by side (three sub-columns of short Turkish
  /// labels + an Arabic glyph + an example word). Below this the three
  /// sub-columns have to compress hard enough to clip or overflow.
  static const double _minCardWidthPositionForms = 320;

  /// Minimum width for a card that's just one big glyph — no internal
  /// columns, so it tolerates a much narrower cell.
  static const double _minCardWidthSimple = 150;

  const AllLettersGrid({
    super.key,
    required this.letters,
    required this.onTapLetter,
    required this.onOpenLetter,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _groupConsecutive(letters);
    final hasPositionForms = letters.any((letter) => letter.hasPositionForms);
    final minCardWidth =
        hasPositionForms ? _minCardWidthPositionForms : _minCardWidthSimple;
    final maxColumns = hasPositionForms ? 3 : 6;
    final readingScale = ReadingTextScale.factorOf(context);
    // Bigger letters need wider cards, so the columns thin out one at a
    // time as the reading size grows (5 -> 4 -> 3 -> ...) instead of
    // jumping to a single column.
    final cardGrowth = math.max(1.0, readingScale);

    return Stack(
      children: [
        const LetterPageBackground(),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = (hasPositionForms
                        ? (constraints.maxWidth - 40 + 16) /
                            (minCardWidth * cardGrowth + 16)
                        : constraints.maxWidth / (minCardWidth * cardGrowth))
                    .floor()
                    .clamp(1, maxColumns);
                // One wide column at an enlarged size: a short, wide card.
                final singleColumn = columns == 1 && readingScale > 1;

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: CustomScrollView(
                    slivers: [
                      for (final group in groups) ...[
                        if (group.items.first.mahrec case final mahrec?)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                              child: MahrecBanner(mahrec: mahrec),
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio:
                                      hasPositionForms ? 0.72 : 0.95,
                                  mainAxisExtent:
                                      hasPositionForms
                                          ? (((constraints.maxWidth -
                                                          40 -
                                                          (columns - 1) * 16) /
                                                      columns) *
                                                  1.2)
                                              .clamp(390.0, 560.0)
                                          : singleColumn
                                          ? 160 + (readingScale - 1) * 40
                                          : null,
                                ),
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final letter = group.items[i];
                              return LetterCard(
                                letter: letter,
                                onTap: () => onTapLetter(letter),
                                onOpenDetail:
                                    () => onOpenLetter(group.startIndex + i),
                              );
                            }, childCount: group.items.length),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
