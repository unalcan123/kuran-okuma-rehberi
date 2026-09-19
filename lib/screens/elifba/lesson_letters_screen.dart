import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/lesson_info_data.dart';
import '../../models/arabic_letter.dart';
import '../../models/lesson.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reading_text_settings.dart';
import 'lesson_view_mode.dart';
import 'widgets/all_letters_grid.dart';
import 'widgets/letter_forms_table.dart';

import 'widgets/single_letter_pager.dart';
import 'widgets/lesson_one_book.dart';

/// Entry point for a lesson's letters. Offers two study modes backed
/// by the same [Lesson.letters] data:
/// - "Tüm Harfler": every letter on one scrollable grid (default).
/// - "Tek Harf": the existing one-letter-per-screen pager.
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
  // Keep the experimental preference while the app is running.
  static LessonViewMode _lastLessonOneMode = LessonViewMode.grid;
  bool get _supportsBook => widget.lesson.id == 'harfleri-taniyalim';
  late LessonViewMode _mode =
      _supportsBook ? _lastLessonOneMode : LessonViewMode.grid;
  late int _singleLetterIndex = widget.initialIndex;
  late int _currentPageIndex = widget.initialIndex;

  void _openSingleLetter(int index) {
    setState(() {
      _singleLetterIndex = index;
      _currentPageIndex = index;
      _mode = LessonViewMode.single;
      if (_supportsBook) _lastLessonOneMode = _mode;
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
      _mode = mode;
      if (_supportsBook) _lastLessonOneMode = mode;
    });
  }

  void _showLessonInfo(LessonInfo info) {
    showDialog<void>(
      context: context,
      builder: (context) => _LessonInfoDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.lesson.letters;
    final isSingleMode = _mode == LessonViewMode.single;
    final info = kLessonInfo[widget.lesson.id];

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
                  PopupMenuButton<LessonViewMode>(
                    tooltip: 'Görünüm seç',
                    initialValue: _mode,
                    onSelected: _changeMode,
                    icon: Icon(switch (_mode) {
                      LessonViewMode.grid => Icons.grid_view_rounded,
                      LessonViewMode.single => Icons.view_carousel_outlined,
                      LessonViewMode.book => Icons.menu_book_rounded,
                    }, size: 21),
                    itemBuilder:
                        (context) => [
                          for (final entry
                              in {
                                LessonViewMode.grid: 'Tüm Harfler',
                                LessonViewMode.single: 'Tek Harf',
                                if (_supportsBook)
                                  LessonViewMode.book: 'Kitap Modu',
                              }.entries)
                            CheckedPopupMenuItem(
                              value: entry.key,
                              checked: _mode == entry.key,
                              child: Text(entry.value),
                            ),
                        ],
                  ),
                  if (info != null)
                    IconButton(
                      tooltip: 'Ders açıklaması',
                      onPressed: () => _showLessonInfo(info),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  if (isSingleMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        child: Text(
                          '${_currentPageIndex + 1} / ${letters.length}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
        body: ReadingTextScale(
          controller: _textScale,
          child:
              _supportsBook && _mode == LessonViewMode.book
                  ? LessonOneBook(
                    letters: letters,
                    onTapLetter: _playLetterSound,
                  )
                  : isSingleMode
                  ? SingleLetterPager(
                    letters: letters,
                    initialIndex: _singleLetterIndex,
                    onIndexChanged:
                        (index) => setState(() => _currentPageIndex = index),
                  )
                  : widget.lesson.id == 'harflerin-yazilislari'
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
                Text.rich(
                  TextSpan(children: info.body),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
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
