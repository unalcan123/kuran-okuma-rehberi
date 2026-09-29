import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../helpers/arabic_colorizer.dart';
import '../../../helpers/colored_arabic_text.dart';
import '../../../helpers/haraka_colors.dart';
import '../../../models/arabic_letter.dart';
import '../../../models/lesson_page_layout.dart';
import '../../../models/turkish_audio.dart';
import '../../../services/audio_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../../../widgets/book_pager.dart';
import '../../../widgets/turkish_audio_block.dart';
import 'letter_page_background.dart';
import '../../../widgets/arabic_scale.dart';

/// The "Sayfa Görünümü": the lesson's pages as printed in the book, one at
/// a time and in book order — heading, explanation, the items in the book's
/// table of dashed cells (read right to left) and the book's page number.
/// Move between pages with the bar at the bottom, a swipe (left → right =
/// next, like the Arabic book) or the ← → keys — see [BookPager].
///
/// Items are the lesson's own [letters] (the same list the Grid and
/// "Tekli / Büyük" views show); [layout] says which of them each page shows,
/// how, and in which colors. Tap a cell to hear it; long-press to open it in
/// the "Tekli / Büyük" view ([onOpenLetter] gets its index in [letters]).
class LessonPageView extends StatefulWidget {
  final List<ArabicLetter> letters;
  final LessonPageLayout layout;
  final ValueChanged<ArabicLetter> onTapLetter;
  final ValueChanged<int> onOpenLetter;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;

  const LessonPageView({
    super.key,
    required this.letters,
    required this.layout,
    required this.onTapLetter,
    required this.onOpenLetter,
    this.initialPage = 0,
    this.onPageChanged,
  });

  /// Widest a sheet gets — about a printed page on a desktop screen.
  static const double maxSheetWidth = 720;

  @override
  State<LessonPageView> createState() => _LessonPageViewState();
}

class _LessonPageViewState extends State<LessonPageView> {
  late final PageController _controller = PageController(
    initialPage: widget.initialPage,
  );
  late int _page = widget.initialPage;

  List<LessonBookPage> get _pages => widget.layout.pages;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _pages.length) return;
    BookPager.turnTo(_controller, page);
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.letters;
    return Column(
      children: [
        Expanded(
          child: BookPager(
            controller: _controller,
            itemCount: _pages.length,
            pageBackground: const LetterPageBackground(),
            onPageChanged: (page) {
              setState(() => _page = page);
              widget.onPageChanged?.call(page);
            },
            itemBuilder: (context, index) {
              final start = widget.layout.firstItemOf(index);
              final end = math.min(
                start + _pages[index].totalItems,
                letters.length,
              );
              return LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 480;
                  return SingleChildScrollView(
                    key: PageStorageKey('book-page-$index'),
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 8 : 20,
                      vertical: 12,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: LessonPageView.maxSheetWidth,
                        ),
                        child: _BookSheet(
                          page: _pages[index],
                          allLetters: letters,
                          items: letters.sublist(
                            math.min(start, letters.length),
                            end,
                          ),
                          firstIndex: start,
                          onTapLetter: widget.onTapLetter,
                          onOpenLetter: widget.onOpenLetter,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        BookPageBar(
          page: _pages[_page],
          index: _page,
          count: _pages.length,
          onPrevious: _page > 0 ? () => _goTo(_page - 1) : null,
          onNext: _page < _pages.length - 1 ? () => _goTo(_page + 1) : null,
        ),
      ],
    );
  }
}

/// The bar under a paged lesson view (Sayfa and Grid), laid out like the
/// book's direction — the next page is on the left:
/// "‹ Sonraki Sayfa   Sayfa 14 · Konu · 1 / 3   Önceki Sayfa ›".
class BookPageBar extends StatelessWidget {
  final LessonBookPage page;
  final int index;
  final int count;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const BookPageBar({
    super.key,
    required this.page,
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.96),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                TextButton.icon(
                  key: const ValueKey('page-next'),
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Sonraki Sayfa'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sayfa ${page.bookPage}',
                        key: const ValueKey('page-number'),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${page.type.label} · ${index + 1} / $count',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const ValueKey('page-previous'),
                  onPressed: onPrevious,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Önceki Sayfa'),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark red of the book's headings (read from the PDF).
const Color _bookHeadingColor = Color(0xFF932224);

/// One printed page: cream sheet with a gold frame, like the book.
class _BookSheet extends StatelessWidget {
  final LessonBookPage page;
  final List<ArabicLetter> items;
  final List<ArabicLetter> allLetters;
  final int firstIndex;
  final ValueChanged<ArabicLetter> onTapLetter;
  final ValueChanged<int> onOpenLetter;

  const _BookSheet({
    required this.page,
    required this.items,
    required this.allLetters,
    required this.firstIndex,
    required this.onTapLetter,
    required this.onOpenLetter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 480;
        final inner = narrow ? 8.0 : 18.0;
        final gap = SizedBox(height: narrow ? 12 : 16);
        final children = <Widget>[];
        if (page.heading != null || page.kicker != null) {
          children
            ..add(_SheetHeading(page: page))
            ..add(gap);
        }
        if (page.intro.isNotEmpty) {
          children
            ..add(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: narrow ? 4 : 8),
                child: _IntroText(page.intro, audio: page.introAudio),
              ),
            )
            ..add(gap);
        }
        if (page.figure != null) {
          children.add(
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Image.asset(
                  page.figure!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          );
          if (page.figureLegend.isNotEmpty) {
            children.add(
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    for (final item in page.figureLegend)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 16,
                            decoration: BoxDecoration(
                              color: item.color,
                              border: Border.all(color: AppColors.divider),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.label),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }
          children.add(gap);
        }
        var start = 0;
        for (final section in page.tables) {
          final end = math.min(start + section.itemCount, items.length);
          children
            ..add(
              _SectionView(
                section: section,
                page: page,
                allLetters: allLetters,
                items: items.sublist(math.min(start, items.length), end),
                firstIndex: firstIndex + start,
                onTapLetter: onTapLetter,
                onOpenLetter: onOpenLetter,
              ),
            )
            ..add(gap);
          start = end;
        }
        children.add(
          Center(
            child: Text(
              '${page.bookPage}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        return Container(
          key: ValueKey('book-sheet-${page.bookPage}'),
          padding: EdgeInsets.all(inner),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );
      },
    );
  }
}

/// The book's ornamental heading frame (supplied picture, kept whole: no
/// crop, no stretching), used at the top of every lesson page as in the
/// book.
const String kBookHeaderFrame =
    'assets/images/elifba/harflerin_cikis_yerleri_header.png';

/// A page heading as printed in the book: the ornamental frame with the
/// kicker, heading, Arabic name / mark and subheading in its plain middle
/// panel. [LessonBookPage.headerImage] can give another frame.
class _SheetHeading extends StatelessWidget {
  final LessonBookPage page;

  const _SheetHeading({required this.page});

  @override
  Widget build(BuildContext context) => BookFrameHeading(
    kicker: page.kicker,
    kickerColor: page.kickerColor,
    heading: page.heading,
    subheading: page.subheading,
    arabic: [
      if (page.arabicHeading != null) page.arabicHeading!,
      if (page.mark != null) page.mark!,
    ].join('   '),
    arabicColor: page.arabicHeadingColor,
    image: page.headerImage,
    audioId: page.headingAudio,
  );
}

/// The book's heading: the ornamental frame ([kBookHeaderFrame]) with the
/// lines of the heading in its plain middle panel.
class BookFrameHeading extends StatelessWidget {
  final String? kicker;
  final Color? kickerColor;
  final String? heading;
  final String? subheading;
  final String arabic;
  final Color? arabicColor;
  final String? image;

  /// Recording of the heading (see [TrAudio]): with it, tapping the
  /// heading plays it and a small speaker stands before the heading line.
  final String? audioId;

  const BookFrameHeading({
    super.key,
    this.kicker,
    this.kickerColor,
    this.heading,
    this.subheading,
    this.arabic = '',
    this.arabicColor,
    this.image,
    this.audioId,
  });

  static const double _aspect = 2168 / 725;

  @override
  Widget build(BuildContext context) => TurkishAudioTap(
    audioId: audioId,
    builder:
        (context, available, playing) =>
            _frame(available ? audioId : null, playing),
  );

  /// With [speaker], the heading line starts with that recording's icon.
  Widget _frame(String? speaker, bool playing) {
    const color = _bookHeadingColor;
    // The speaker goes on the first line only.
    Widget withSpeaker(Widget line, double size, {required bool first}) =>
        speaker == null || !first
            ? line
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TurkishAudioIcon(
                  audioId: speaker,
                  playing: playing,
                  size: size * 0.8,
                ),
                SizedBox(width: size * 0.3),
                line,
              ],
            );
    return Semantics(
      header: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AspectRatio(
            aspectRatio: _aspect,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final size = (w * 0.05).clamp(13.0, 26.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      image ?? kBookHeaderFrame,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder:
                          (context, error, stack) => DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                    ),
                    // The frame's plain middle panel.
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.21,
                        vertical: w * 0.075,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (kicker != null)
                                withSpeaker(
                                  Text(
                                    kicker!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: kickerColor ?? color,
                                      fontSize: size * 0.7,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  size * 0.7,
                                  first: true,
                                ),
                              if (heading != null)
                                withSpeaker(
                                  Text(
                                    heading!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: size,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                  size,
                                  first: kicker == null,
                                ),
                              if (subheading != null)
                                Text(
                                  subheading!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: size * 0.62,
                                  ),
                                ),
                              if (arabic.isNotEmpty)
                                Text(
                                  arabic,
                                  textDirection: TextDirection.rtl,
                                  style: AppTextTheme.arabicSmall(
                                    fontSize: size * 1.25,
                                  ).copyWith(
                                    color: arabicColor ?? color,
                                    height: 1.35,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Explanation text: “quoted” text is printed red, as in the book; Arabic
/// runs are set in the Arabic font; "- " / "* " paragraphs are bullets.
/// Paragraphs with a recording in [audio] are listenable, a rule's
/// paragraphs together as one block.
class _IntroText extends StatelessWidget {
  final List<String> paragraphs;
  final Map<int, TrAudio> audio;

  const _IntroText(this.paragraphs, {this.audio = const {}});

  static final _quoted = RegExp('“[^”]*”');
  static final _arabic = RegExp(r'[؀-ۿﹰ-﻿]+(?:[ ؀-ۿﹰ-﻿]*[؀-ۿﹰ-﻿])?');

  static List<InlineSpan> _arabicRuns(String text, TextStyle? style) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _arabic.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(last, match.start)));
      spans.add(
        TextSpan(
          text: match[0],
          style: AppTextTheme.arabicSmall(
            fontSize: (style?.fontSize ?? 16) * 1.6,
          ).copyWith(color: style?.color ?? arabicRed, height: 1.2),
        ),
      );
      last = match.end;
    }
    spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  /// ⟪…⟫ green, ⟦…⟧ blue, «…» red (without quotes), “…” red with quotes.
  static final _colored = RegExp('⟪([^⟫]*)⟫|⟦([^⟧]*)⟧|«([^»]*)»');

  static List<InlineSpan> spans(String text, TextStyle? base) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _colored.allMatches(text)) {
      spans.addAll(_redQuotes(text.substring(last, match.start), base));
      final color =
          match[1] != null
              ? arabicGreen
              : match[2] != null
              ? arabicBlue
              : arabicRed;
      final style = TextStyle(color: color, fontWeight: FontWeight.w700);
      spans.add(
        TextSpan(
          style: style,
          children: _arabicRuns(
            match[1] ?? match[2] ?? match[3]!,
            base?.merge(style) ?? style,
          ),
        ),
      );
      last = match.end;
    }
    spans.addAll(_redQuotes(text.substring(last), base));
    return spans;
  }

  static List<InlineSpan> _redQuotes(String text, TextStyle? base) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _quoted.allMatches(text)) {
      spans.addAll(_arabicRuns(text.substring(last, match.start), base));
      const red = TextStyle(color: arabicRed, fontWeight: FontWeight.w700);
      spans.add(
        TextSpan(
          style: red,
          children: _arabicRuns(match[0]!, base?.merge(red) ?? red),
        ),
      );
      last = match.end;
    }
    spans.addAll(_arabicRuns(text.substring(last), base));
    return spans;
  }

  static bool _isBullet(String p) => p.startsWith('- ') || p.startsWith('* ');

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(height: 1.45, color: AppColors.textPrimary);
    final blocks = <Widget>[];
    for (var i = 0; i < paragraphs.length;) {
      final recording = audio[i];
      final end = math.min(i + (recording?.paragraphs ?? 1), paragraphs.length);
      final group = [for (var j = i; j < end; j++) _paragraph(j, style)];
      blocks.add(
        recording == null
            ? group.single
            : TurkishAudioBlock(
              audioId: recording.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: group,
              ),
            ),
      );
      i = end;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _paragraph(int i, TextStyle? style) => Padding(
    // A new paragraph after the bullets gets a gap, as in the book.
    padding: EdgeInsets.only(
      top:
          i > 0 && !_isBullet(paragraphs[i]) && _isBullet(paragraphs[i - 1])
              ? 10
              : 2,
    ),
    child:
        _isBullet(paragraphs[i])
            ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paragraphs[i].startsWith('*') ? '* ' : '– ',
                  style: style?.copyWith(color: arabicRed),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: spans(paragraphs[i].substring(2), style),
                    ),
                    style: style,
                  ),
                ),
              ],
            )
            : Text.rich(
              TextSpan(children: spans(paragraphs[i], style)),
              style: style,
            ),
  );
}

/// One block of a page: its title and text, then its table.
class _SectionView extends StatelessWidget {
  final BookSection section;
  final LessonBookPage page;
  final List<ArabicLetter> items;
  final List<ArabicLetter> allLetters;
  final int firstIndex;
  final ValueChanged<ArabicLetter> onTapLetter;
  final ValueChanged<int> onOpenLetter;

  const _SectionView({
    required this.section,
    required this.page,
    required this.items,
    required this.allLetters,
    required this.firstIndex,
    required this.onTapLetter,
    required this.onOpenLetter,
  });

  @override
  Widget build(BuildContext context) {
    ArabicColorProfile profileOf(int i) =>
        section.itemProfiles[i] ?? section.colorProfile ?? page.colorProfile;
    Color? frameOf(int local) {
      var start = 0;
      for (final run in section.frames) {
        if (local < start + run.count) return run.color;
        start += run.count;
      }
      return null;
    }

    final cells = <_CellSpec>[];
    final refs = section.refs;
    final texts = section.texts;
    if (texts != null) {
      // Display-only cells, a Turkish label ending each row (s. 8).
      final labels = section.rowLabels;
      final perRow =
          labels == null ? texts.length : texts.length ~/ labels.length;
      for (var i = 0; i < texts.length; i++) {
        if (labels != null && i % perRow == 0) {
          cells.add(
            _CellSpec(
              text: '',
              label: labels[i ~/ perRow],
              profile: ArabicColorProfile.none,
            ),
          );
        }
        final item = section.textItems[i];
        cells.add(
          _CellSpec(
            // A cell's own recording (s. 8: each Lâm-Elif shape) wins over
            // the item's.
            letter:
                section.textAudio[i] ??
                (item == null ? null : allLetters[item]),
            index: item,
            key: 'book-text-cell-$i',
            text: texts[i],
            profile: profileOf(i),
          ),
        );
      }
    } else if (refs != null && section.kind == BookSectionKind.grid) {
      // Items shown again from elsewhere in the lesson (e.g. s. 41), each
      // followed by its derived form when the section has one.
      for (var i = 0; i < refs.length; i++) {
        final letter = allLetters[refs[i]];
        cells.add(
          _CellSpec(
            letter: letter,
            index: refs[i],
            text: section.refTexts?[i] ?? letter.isolatedForm,
            profile: profileOf(i),
          ),
        );
        final derive = section.derived;
        if (derive != null) {
          cells.add(
            _CellSpec(
              letter: section.derivedAudioItems?[i],
              text: derive.apply(letter.isolatedForm),
              profile: section.derivedProfile ?? page.colorProfile,
            ),
          );
        }
      }
    } else if (section.kind == BookSectionKind.grid) {
      for (var p = 0; p < items.length; p++) {
        final local =
            section.order != null && p < section.order!.length
                ? section.order![p]
                : p;
        cells.add(
          _CellSpec(
            letter: items[local],
            index: firstIndex + local,
            text: items[local].isolatedForm,
            profile: profileOf(local),
            frame: frameOf(local),
          ),
        );
      }
    }
    final formIndices =
        section.refs ?? [for (var i = 0; i < items.length; i++) firstIndex + i];
    Widget? table;
    if (cells.isNotEmpty ||
        (section.kind == BookSectionKind.forms && formIndices.isNotEmpty)) {
      table = switch (section.kind) {
        BookSectionKind.grid => _BookTable(
          section: section,
          cells: cells,
          onTapLetter: onTapLetter,
          onOpenLetter: onOpenLetter,
        ),
        BookSectionKind.forms => _FormsTable(
          rows: [
            for (var i = 0; i <= formIndices.length; i++) ...[
              if (section.extraRows[i] case final extra?)
                _FormRow(
                  extra,
                  null,
                  section.colorProfile ?? page.colorProfile,
                ),
              if (i < formIndices.length)
                _FormRow(
                  allLetters[formIndices[i]],
                  formIndices[i],
                  profileOf(i),
                ),
            ],
          ],
          onTapLetter: onTapLetter,
          onOpenLetter: onOpenLetter,
        ),
      };
      if (section.frameColor != null) {
        table = DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: section.frameColor!, width: 2),
          ),
          child: table,
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TurkishAudioTap(
              audioId: section.titleAudio,
              builder:
                  (context, available, playing) => Text.rich(
                    TextSpan(
                      children: [
                        if (available)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: TurkishAudioIcon(
                                audioId: section.titleAudio!,
                                playing: playing,
                              ),
                            ),
                          ),
                        ..._IntroText.spans(
                          section.title!,
                          const TextStyle(
                            color: arabicRed,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: arabicRed,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
          ),
        if (section.intro.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
            child: _IntroText(section.intro, audio: section.introAudio),
          ),
        if (table != null) table,
        if (section.frames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 6,
              children: [
                for (final run in section.frames)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 28, height: 3, color: run.color),
                      const SizedBox(width: 8),
                      Text(
                        run.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        if (section.label != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 3,
                  color: section.frameColor ?? AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  section.label!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (section.outro.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
            child: _IntroText(section.outro, audio: section.outroAudio),
          ),
      ],
    );
  }
}

double _fontFor(LessonItemKind kind, double cellWidth) => switch (kind) {
  LessonItemKind.letter => (cellWidth * 0.42).clamp(34.0, 56.0),
  LessonItemKind.word => (cellWidth * 0.28).clamp(28.0, 44.0),
  LessonItemKind.phrase => (cellWidth * 0.2).clamp(24.0, 36.0),
};

/// The book's table: rows of dashed cells, first item at the top right. On
/// a narrow screen (or with a large reading size) a column is dropped at a
/// time rather than shrinking the Arabic too much.
class _BookTable extends StatelessWidget {
  final BookSection section;
  final List<_CellSpec> cells;
  final ValueChanged<ArabicLetter> onTapLetter;
  final ValueChanged<int> onOpenLetter;

  const _BookTable({
    required this.section,
    required this.cells,
    required this.onTapLetter,
    required this.onOpenLetter,
  });

  /// Narrowest a cell may get (before the reading size) for its content.
  static double minCellWidth(LessonItemKind kind) => switch (kind) {
    LessonItemKind.letter => 64,
    LessonItemKind.word => 96,
    LessonItemKind.phrase => 140,
  };

  /// The widest kind of item in the section.
  LessonItemKind get _widestKind {
    final kinds = section.rowKinds ?? [section.itemKind];
    return kinds.reduce((a, b) => a.index >= b.index ? a : b);
  }

  /// Row sizes: the book's, or — when cells would get narrower than
  /// [minCellWidth] × the reading size — fewer columns, one at a time.
  List<int> _rows(double width, double textScale) {
    final book =
        section.rowColumns ??
        List.filled((cells.length / section.columns).ceil(), section.columns);
    final widest = book.reduce(math.max);
    var columns = widest;
    while (columns > 1 &&
        width / columns < minCellWidth(_widestKind) * textScale) {
      columns--;
    }
    if (columns == widest) {
      // Fill the book's rows (the last one may be short).
      final rows = <int>[];
      var left = cells.length;
      for (final n in book) {
        if (left <= 0) break;
        rows.add(math.min(n, left));
        left -= n;
      }
      while (left > 0) {
        rows.add(math.min(widest, left));
        left -= widest;
      }
      return rows;
    }
    return [
      for (var left = cells.length; left > 0; left -= columns)
        math.min(columns, left),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final textScale = ArabicScale.arabicFactorOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final rows = _rows(width, textScale);
        final bookLayout =
            rows.isEmpty ||
            rows.first == (section.rowColumns?.first ?? section.columns);
        final headers = bookLayout ? section.headers : null;
        final maxColumns = rows.isEmpty ? 1 : rows.reduce(math.max);
        final blocks = <Widget>[];
        var current = <Widget>[];
        var position = 0;
        for (var r = 0; r < rows.length; r++) {
          final n = rows[r];
          // In the book's layout each row fills the width; a reflowed last
          // row keeps the cell width of the others.
          final cellWidth = width / (bookLayout ? n : maxColumns);
          final kind =
              section.rowKinds == null
                  ? section.itemKind
                  : section.rowKinds![r % section.rowKinds!.length];
          final fontSize = _fontFor(kind, cellWidth);
          final rowStart = position;
          final rowHeight = math
              .max(
                cellWidth * (kind == LessonItemKind.letter ? 0.66 : 0.6),
                fontSize * textScale * 1.9,
              )
              .clamp(0.0, fontSize * textScale * 3.2);
          current.add(
            SizedBox(
              height: rowHeight,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  for (var c = 0; c < n; c++)
                    SizedBox(
                      width: cellWidth,
                      child: _BookCell(
                        spec: cells[rowStart + c],
                        fontSize: fontSize,
                        onTap: onTapLetter,
                        onOpen: onOpenLetter,
                      ),
                    ),
                ],
              ),
            ),
          );
          position += n;
          final endOfGroup =
              section.groupRows != null && (r + 1) % section.groupRows! == 0;
          if (endOfGroup || r == rows.length - 1) {
            blocks.add(
              _dashed(current, headers: blocks.isEmpty ? headers : null),
            );
            current = [];
          }
        }
        return Column(
          children: [
            for (var i = 0; i < blocks.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              blocks[i],
            ],
          ],
        );
      },
    );
  }

  Widget _dashed(List<Widget> rows, {List<String>? headers}) => Column(
    children: [
      if (headers != null)
        Container(
          color: const Color(0xFFF6D3B8),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              for (final header in headers)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        header,
                        style: const TextStyle(
                          color: arabicRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    ],
  );
}

/// One row of the forms table: a letter (an item of the lesson, or a row
/// the book adds, like s. 10's hemze row — then [index] is null).
class _FormRow {
  final ArabicLetter letter;
  final int? index;
  final ArabicColorProfile profile;

  const _FormRow(this.letter, this.index, this.profile);
}

/// "HARF | BAŞTA | ORTADA | SONDA" (s. 10-13): the letter, then the book's
/// example words ([ArabicLetter.formExamples]) with the letter at the
/// start, middle and end — the letters the book prints red, red.
class _FormsTable extends StatelessWidget {
  final List<_FormRow> rows;
  final ValueChanged<ArabicLetter> onTapLetter;
  final ValueChanged<int> onOpenLetter;

  const _FormsTable({
    required this.rows,
    required this.onTapLetter,
    required this.onOpenLetter,
  });

  static const _headers = ['HARF', 'BAŞTA', 'ORTADA', 'SONDA'];

  @override
  Widget build(BuildContext context) {
    final textScale = ArabicScale.arabicFactorOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 4;
        final fontSize = (cellWidth * 0.26).clamp(24.0, 40.0);
        Widget word(FormWord w) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ColoredArabicText(
              w.text,
              textDirection: TextDirection.rtl,
              profile: ArabicColorProfile.none.withClusterBodies({
                for (final i in w.red) i: arabicRed,
              }),
              style: AppTextTheme.arabicSmall(
                fontSize: fontSize,
              ).copyWith(color: AppColors.textPrimary, height: 1.45),
            ),
          ),
        );
        Widget column(List<FormWord> words, String? note) => _Dashed(
          width: cellWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final w in words) word(w),
                if (words.isEmpty && note != null) ...[
                  const Text(
                    'x',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      note,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: (cellWidth * 0.075).clamp(10.0, 13.0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
        return Column(
          children: [
            Container(
              color: const Color(0xFFF6D3B8),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  for (final header in _headers)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(
                            header,
                            style: const TextStyle(
                              color: arabicRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (final row in rows)
              IntrinsicHeight(
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: cellWidth,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: fontSize * textScale * 1.9,
                        ),
                        child: _BookCell(
                          spec: _CellSpec(
                            letter: row.index == null ? null : row.letter,
                            index: row.index,
                            text: row.letter.isolatedForm,
                            profile: row.profile,
                          ),
                          fontSize: fontSize * 1.15,
                          onTap: onTapLetter,
                          onOpen: onOpenLetter,
                        ),
                      ),
                    ),
                    for (var p = 0; p < 3; p++)
                      column(
                        (row.letter.formExamples != null &&
                                p < row.letter.formExamples!.length)
                            ? row.letter.formExamples![p]
                            : const [],
                        p == 0 ? row.letter.formNote : null,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// What one table cell shows: an item of the lesson (tap = its sound,
/// long-press = Tekli / Büyük), or display-only text derived from one.
class _CellSpec {
  final ArabicLetter? letter;
  final int? index;
  final String text;
  final ArabicColorProfile profile;
  final Color? frame;

  /// A Turkish label instead of Arabic (s. 8's last column).
  final String? label;

  /// Key of the cell's tap target when not the item's (`book-cell-<index>`).
  final String? key;

  const _CellSpec({
    this.letter,
    this.index,
    this.key,
    required this.text,
    required this.profile,
    this.frame,
    this.label,
  });
}

/// Cell of a book table.
class _BookCell extends StatelessWidget {
  final _CellSpec spec;
  final double fontSize;
  final ValueChanged<ArabicLetter> onTap;
  final ValueChanged<int> onOpen;

  const _BookCell({
    required this.spec,
    required this.fontSize,
    required this.onTap,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final letter = spec.letter;
    if (spec.label != null) {
      return _Dashed(
        solid: spec.frame,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              spec.label!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }
    final text = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ColoredArabicText(
            spec.text,
            textDirection: TextDirection.rtl,
            profile: spec.profile,
            style: AppTextTheme.arabicSmall(
              fontSize: fontSize,
            ).copyWith(color: AppColors.textPrimary, height: 1.5),
          ),
        ),
      ),
    );
    if (letter == null) return _Dashed(solid: spec.frame, child: text);
    final audio = context.watch<AudioService>();
    final playing = audio.isPlaying && audio.currentAsset == letter.audioAsset;
    return _Dashed(
      solid: spec.frame,
      child: Semantics(
        button: true,
        label: '${letter.turkishName ?? 'Kelime'}. Dinle',
        child: Material(
          color: playing ? AppColors.turquoiseSoft : Colors.transparent,
          child: InkWell(
            key: ValueKey(
              spec.key ??
                  (spec.index == null
                      ? 'book-derived-cell-${letter.audioAsset}'
                      : 'book-cell-${spec.index}'),
            ),
            onTap: () => onTap(letter),
            onLongPress: spec.index == null ? null : () => onOpen(spec.index!),
            splashColor: AppColors.turquoiseSoft,
            child: text,
          ),
        ),
      ),
    );
  }
}

/// A table cell with the book's dashed border.
class _Dashed extends StatelessWidget {
  final Widget child;
  final double? width;

  /// A solid colored frame instead (e.g. the mahreç groups of s. 23).
  final Color? solid;

  const _Dashed({required this.child, this.width, this.solid});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child:
        solid != null
            ? DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: solid!, width: 2),
              ),
              child: child,
            )
            : CustomPaint(
              foregroundPainter: _DashedRowsPainter(
                color: AppColors.gold.withValues(alpha: 0.7),
              ),
              child: child,
            ),
  );
}

/// Dashed border around one cell, like the tables in the book.
class _DashedRowsPainter extends CustomPainter {
  final Color color;

  const _DashedRowsPainter({required this.color});

  static const double _dash = 5, _gap = 4;

  static void line(Canvas canvas, Offset a, Offset b, Paint paint) {
    final length = (b - a).distance;
    if (length == 0) return;
    final dir = (b - a) / length;
    for (var d = 0.0; d < length; d += _dash + _gap) {
      canvas.drawLine(
        a + dir * d,
        a + dir * math.min(d + _dash, length),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;
    final w = size.width - 0.5, h = size.height - 0.5;
    line(canvas, Offset.zero, Offset(w, 0), paint);
    line(canvas, Offset(0, h), Offset(w, h), paint);
    line(canvas, Offset.zero, Offset(0, h), paint);
    line(canvas, Offset(w, 0), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRowsPainter old) => old.color != color;
}
