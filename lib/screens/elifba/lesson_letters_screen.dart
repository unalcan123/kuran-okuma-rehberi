import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/book_highlights.dart';
import '../../data/letters_data.dart';
import '../../data/lesson_info_data.dart';
import '../../helpers/lesson_color_scope.dart';
import '../../models/arabic_letter.dart';
import '../../models/lesson.dart';
import '../../models/lesson_position.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/lesson_kids_decoration.dart';
import '../../widgets/reading_text_settings.dart';
import 'lesson_view_mode.dart';
import 'widgets/all_letters_grid.dart';
import 'widgets/book_page.dart';
import 'widgets/lesson_grid_pager.dart';
import 'widgets/lesson_mode_toggle.dart';
import 'widgets/lesson_page_view.dart';
import 'widgets/letter_forms_table.dart';
import 'widgets/letter_page.dart';
import 'widgets/single_letter_pager.dart';
import '../../widgets/arabic_scale.dart';
import '../../widgets/tablet_zoom.dart';

/// A lesson, in three views over the same [Lesson.letters]:
/// - "Sayfa" (default, every time the lesson opens): the lesson's pages as
///   in the book — [LessonPageView] from [Lesson.pageLayout], or for Ders
///   23-30 the explanation page [BookPage];
/// - "Grid": the classic cards ([AllLettersGrid]; Ders 2 its forms table),
///   book page by book page ([LessonGridPager]) when the lesson has pages;
/// - "Tekli / Büyük": one item at a time ([SingleLetterPager]).
/// All pages turn right to left like the book ([BookPager]). The three views
/// share one [LessonPosition] (active book page and item).
/// Colors come from the item's book page ([LessonColorScope]) in all three.
class LessonLettersScreen extends StatefulWidget {
  final Lesson lesson;
  final int initialIndex;

  const LessonLettersScreen({
    super.key,
    required this.lesson,
    this.initialIndex = 0,
  });

  @override
  State<LessonLettersScreen> createState() => _LessonLettersScreenState();
}

class _LessonLettersScreenState extends State<LessonLettersScreen> {
  final _textScale = ValueNotifier<double>(1);

  /// Ders 23-30: one explanation page in the book's layout.
  bool get _hasBookPage => kBookPageHeadings.containsKey(widget.lesson.id);

  LessonViewMode _mode = LessonViewMode.book;

  /// The active book page and item, shared by the three views (each view
  /// opens where the student was in the other).
  late final LessonPosition _position = LessonPosition(
    widget.lesson.pageLayout,
    item: widget.initialIndex == 0 ? null : widget.initialIndex,
  );

  @override
  void initState() {
    super.initState();
    // Fetch the whole lesson's sounds now so taps play without waiting.
    context.read<AudioService>().preload([
      ...widget.lesson.letters.map((letter) => letter.audioAsset),
      ...?widget.lesson.pageLayout?.extraAudioAssets,
    ]);
  }

  void _openSingleLetter(int index) {
    setState(() {
      _position.showItem(index);
      _mode = LessonViewMode.single;
    });
  }

  void _playLetterSound(ArabicLetter letter) {
    context.read<AudioService>().playLetter(letter);
  }

  @override
  void dispose() {
    _textScale.dispose();
    super.dispose();
  }

  /// The views read [_position] when they open, so switching keeps the
  /// book page (Sayfa <-> Grid) and the item (<-> Tekli / Büyük).
  void _changeMode(LessonViewMode mode) => setState(() => _mode = mode);

  bool get _isFormsTable => widget.lesson.id == 'harflerin-yazilislari';

  /// The widest each view's content gets (the kids stand outside it).
  double? _contentMaxWidth(LessonViewMode mode) => switch (mode) {
    LessonViewMode.book =>
      widget.lesson.pageLayout != null
          ? LessonPageView.maxSheetWidth
          : BookPage.maxContentWidth,
    LessonViewMode.grid =>
      _isFormsTable
          ? LetterFormsTable.maxContentWidth
          : AllLettersGrid.maxContentWidth,
    // The letter / word may grow to 85 % of the screen (LetterPage), as
    // laid out inside the body's TabletZoom.
    LessonViewMode.single =>
      MediaQuery.sizeOf(context).width /
          TabletZoom.zoomFor(MediaQuery.sizeOf(context)) *
          LetterPage.maxGlyphWidthFactor,
  };

  void _showLessonInfo(LessonInfo info) {
    showDialog<void>(
      context: context,
      builder: (context) => _LessonInfoDialog(info: info),
    );
  }

  Widget _pageView(LessonInfo? info) {
    final layout = widget.lesson.pageLayout;
    if (layout != null) {
      return LessonPageView(
        letters: widget.lesson.letters,
        layout: layout,
        initialPage: _position.page,
        onPageChanged: _position.showPage,
        onTapLetter: _playLetterSound,
        onOpenLetter: _openSingleLetter,
      );
    }
    return BookPage(
      info: info!,
      heading: kBookPageHeadings[widget.lesson.id]!,
      pages: kBookPageNumbers[widget.lesson.id],
    );
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.lesson.letters;
    final layout = widget.lesson.pageLayout;
    final info = kLessonInfo[widget.lesson.id];
    final hasPage = layout != null || (_hasBookPage && info != null);
    // The Giriş has pages only (nothing to list or show one by one).
    final pagesOnly = letters.isEmpty && hasPage;
    final mode =
        pagesOnly
            ? LessonViewMode.book
            : hasPage
            ? _mode
            : (_mode == LessonViewMode.book ? LessonViewMode.grid : _mode);

    final Widget view = switch (mode) {
      LessonViewMode.book => _pageView(info),
      LessonViewMode.single => SingleLetterPager(
        // Opened fresh from the other views; swiping must not rebuild it.
        key: const ValueKey('single'),
        letters: letters,
        initialIndex: _position.item,
        showCounter: true,
        pageLabelOf: _position.pageLabelOf,
        onIndexChanged: (index) => setState(() => _position.showItem(index)),
      ),
      LessonViewMode.grid when layout != null => LessonGridPager(
        letters: letters,
        layout: layout,
        initialPage: _position.page,
        onPageChanged: _position.showPage,
        formsTable: _isFormsTable,
        onTapLetter: _playLetterSound,
        onOpenLetter: _openSingleLetter,
      ),
      LessonViewMode.grid =>
        _isFormsTable
            ? LetterFormsTable(
              letters: letters,
              onTapLetter: _playLetterSound,
              onOpenLetter: _openSingleLetter,
            )
            : AllLettersGrid(
              letters: letters,
              onTapLetter: _playLetterSound,
              onOpenLetter: _openSingleLetter,
            ),
    };

    return Scaffold(
      // The title bar and the Sayfa / Grid / Tekli selector are part of the
      // scrolling content, not fixed: scrolling the page up moves them off
      // the screen (more room for the book); they come back only when the
      // page is scrolled back to its top.
      body: TabletZoom(child: NestedScrollView(
        key: const ValueKey('lesson-scroll'),
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: false,
                pinned: false,
                forceElevated: innerBoxIsScrolled,
                toolbarHeight: 48,
                leadingWidth: 48,
                titleSpacing: 4,
                centerTitle: false,
                title: Tooltip(
                  message: '${widget.lesson.label} · ${widget.lesson.title}',
                  child: Text(
                    '${widget.lesson.label} · ${widget.lesson.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                actions: [
                  ReadingTextSettingsButton(
                    showMeaningToggle: false,
                    controller: _textScale,
                  ),
                  if (info != null &&
                      !(_hasBookPage && mode == LessonViewMode.book))
                    IconButton(
                      tooltip: 'Ders açıklaması',
                      onPressed: () => _showLessonInfo(info),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                ],
              ),
              if (!pagesOnly)
                SliverToBoxAdapter(
                  key: const ValueKey('lesson-mode-header'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: LessonModeToggle(
                      mode: mode,
                      onChanged: _changeMode,
                      segments: {
                        if (hasPage) LessonViewMode.book: '📖 Sayfa',
                        LessonViewMode.grid: '▦ Grid',
                        LessonViewMode.single: '🔎 Tekli / Büyük',
                      },
                    ),
                  ),
                ),
            ],
        body: ReadingTextScale(
          controller: _textScale,
          // The lesson's Arabic ~30 % larger on tablets and desktops.
          child: ArabicScale(
            factor: ArabicScale.lessonFactorFor(MediaQuery.sizeOf(context)),
            child: LessonColorScope(
            lesson: widget.lesson,
            // Decorative kids in the side margins (desktop/tablet).
            child: LessonKidsDecoration(
              contentMaxWidth: _contentMaxWidth(mode),
              lessonIndex: kElifbaLessons.indexOf(widget.lesson),
              child: view,
            ),
          ),
          ),
        ),
      )),
    );
  }
}

class _LessonInfoDialog extends StatelessWidget {
  final LessonInfo info;

  const _LessonInfoDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.turquoiseSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.turquoise,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        info.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 3,
                  width: 58,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),
                // Long explanations (with tables) must scroll, most of all on
                // a phone held sideways.
                Flexible(
                  child: SingleChildScrollView(
                    child: Text.rich(
                      TextSpan(children: info.summary),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kapat'),
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
