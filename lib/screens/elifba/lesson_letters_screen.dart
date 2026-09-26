import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/book_highlights.dart';
import '../../data/lesson_info_data.dart';
import '../../helpers/lesson_color_scope.dart';
import '../../models/arabic_letter.dart';
import '../../models/lesson.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reading_text_settings.dart';
import 'lesson_view_mode.dart';
import 'widgets/all_letters_grid.dart';
import 'widgets/book_page.dart';
import 'widgets/lesson_mode_toggle.dart';
import 'widgets/lesson_page_view.dart';
import 'widgets/letter_forms_table.dart';
import 'widgets/single_letter_pager.dart';

/// A lesson, in three views over the same [Lesson.letters]:
/// - "Sayfa" (default, every time the lesson opens): the lesson's pages as
///   in the book — [LessonPageView] from [Lesson.pageLayout], or for Ders
///   23-30 the explanation page [BookPage];
/// - "Grid": the classic cards ([AllLettersGrid]; Ders 2 its forms table);
/// - "Tekli / Büyük": one item at a time ([SingleLetterPager]).
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
  late int _singleLetterIndex = widget.initialIndex;
  late int _currentPageIndex = widget.initialIndex;

  /// Book page shown in the "Sayfa" view (index in the lesson's pages).
  int _bookPage = 0;

  @override
  void initState() {
    super.initState();
    // Fetch the whole lesson's sounds now so taps play without waiting.
    context.read<AudioService>().preload(
      widget.lesson.letters.map((letter) => letter.audioAsset),
    );
  }

  void _openSingleLetter(int index) {
    setState(() {
      _singleLetterIndex = index;
      _currentPageIndex = index;
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

  void _changeMode(LessonViewMode mode) {
    setState(() {
      // "Tekli / Büyük" opens where the student last was.
      if (mode == LessonViewMode.single) _singleLetterIndex = _currentPageIndex;
      // Back on "Sayfa": the page with the item the student was looking at.
      final layout = widget.lesson.pageLayout;
      if (mode == LessonViewMode.book &&
          layout != null &&
          _mode == LessonViewMode.single) {
        _bookPage = layout.pageIndexOf(_currentPageIndex);
      }
      _mode = mode;
    });
  }

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
        initialPage: _bookPage,
        onPageChanged: (page) {
          // Tekli / Büyük opens on this page.
          _bookPage = page;
          _currentPageIndex = layout.firstItemOf(page);
        },
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
    final info = kLessonInfo[widget.lesson.id];
    final hasPage =
        widget.lesson.pageLayout != null || (_hasBookPage && info != null);
    final mode =
        hasPage
            ? _mode
            : (_mode == LessonViewMode.book ? LessonViewMode.grid : _mode);

    final Widget view = switch (mode) {
      LessonViewMode.book => _pageView(info),
      LessonViewMode.single => SingleLetterPager(
        key: ValueKey('single-$_singleLetterIndex'),
        letters: letters,
        initialIndex: _singleLetterIndex,
        showCounter: true,
        onIndexChanged: (index) => setState(() => _currentPageIndex = index),
      ),
      LessonViewMode.grid =>
        widget.lesson.id == 'harflerin-yazilislari'
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
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
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
            ],
        body: ReadingTextScale(
          controller: _textScale,
          child: LessonColorScope(
            lesson: widget.lesson,
            child: Column(
              children: [
                Padding(
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
                Expanded(child: view),
              ],
            ),
          ),
        ),
      ),
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
                      TextSpan(children: info.body),
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
