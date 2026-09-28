import 'package:flutter/material.dart';

import '../../../data/lesson_info_data.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/turkish_audio_block.dart';
import 'lesson_page_view.dart' show BookFrameHeading;
import 'letter_page_background.dart';

/// The heading printed on a book page: up to three lines of Turkish and
/// an optional Arabic line.
class BookPageHeading {
  final String? top;
  final String main;
  final String? bottom;
  final String? arabic;

  /// Recording of the heading (see [TrAudio]); null where the book prints
  /// no heading of its own (s. 51, s. 52).
  final String? audio;

  const BookPageHeading({
    this.top,
    required this.main,
    this.bottom,
    this.arabic,
    this.audio,
  });
}

BookPageHeading _zamirHe(String main) =>
    BookPageHeading(top: 'ZAMİR “HE”’NİN', main: main, arabic: 'هـ ه');

/// Lessons shown as a book page (pages 50-59 of the book), by lesson id.
final Map<String, BookPageHeading> kBookPageHeadings = {
  'el-takisi-okunan': BookPageHeading(
    main: 'ELİF - LÂM',
    audio: 's050_baslik_1',
  ),
  'el-takisi-okunmayan': BookPageHeading(main: 'ELİF - LÂM'),
  'el-takisi-hemze': BookPageHeading(main: 'EL TAKISI’NDAKİ HEMZE'),
  'el-takisi-hemze-vasil': BookPageHeading(
    main: 'OKUNMAYAN HEMZE',
    bottom: '(Vasıl Hemzesi)',
    arabic: 'ٱ',
    audio: 's053_baslik_1',
  ),
  'zamir-he-uzatilmasi': _zamirHe('UZATILMASI'),
  'zamir-he-uzatma-med': BookPageHeading(
    main: 'UZUN MED İŞARETİ',
    arabic: 'ـٓـ',
    audio: 's055_baslik_1',
  ),
  'zamir-he-uzatma-yok': _zamirHe('UZATILMAMASI'),
  'zamir-he-uzatma-yok-cezimli': _zamirHe('UZATILMAMASI'),
  'zamir-he-uzatma-yok-cezimli-seddeli': _zamirHe('UZATILMAMASI'),
  'kapali-te': BookPageHeading(
    main: 'KAPALI “TE”',
    arabic: 'ة – ـة',
    audio: 's056_baslik_1',
  ),
  'kelime-sonu-duraklar': BookPageHeading(
    top: 'KELİME SONUNDAKİ',
    main: 'HAREKELİ HARFTE',
    bottom: 'NASIL DURULUR?',
    audio: 's057_baslik_1',
  ),
};

/// A lesson laid out like the book's pages: the heading, the explanations,
/// and between them the "Durulduğunda / Geçildiğinde" tables whose words can
/// be tapped to hear them. The text is the lesson's [LessonInfo] — the same
/// content the info (ⓘ) button shows.
class BookPage extends StatelessWidget {
  /// The widest the page gets.
  static const double maxContentWidth = 780;

  const BookPage({
    super.key,
    required this.info,
    required this.heading,
    this.pages,
  });

  final LessonInfo info;
  final BookPageHeading heading;

  /// The book's page number(s) shown at the bottom (e.g. "54", "57-59").
  final String? pages;

  @override
  Widget build(BuildContext context) {
    // A first span that only repeats the heading is left out of the page.
    final body =
        info.firstSpanIsBookHeading ? info.body.skip(1).toList() : info.body;
    return Stack(
      children: [
        const LetterPageBackground(),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 400;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 8 : 20,
                vertical: 14,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BookFrameHeading(
                          kicker: heading.top,
                          heading: heading.main,
                          subheading: heading.bottom,
                          arabic: heading.arabic ?? '',
                          audioId: heading.audio,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: narrow ? 6 : 14,
                            vertical: 16,
                          ),
                          child: BookPageBody(
                            body: body,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ),
                        if (pages != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Sayfa $pages',
                              key: const ValueKey('book-page-number'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A book page's text: its explanations ([TrAudioSpan]s) as listenable
/// blocks, everything else (headings, "Örnekler:", tables) as before. The
/// line breaks between the pieces become the same blank lines the text had
/// as one paragraph.
class BookPageBody extends StatelessWidget {
  const BookPageBody({super.key, required this.body, this.style});

  final List<InlineSpan> body;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var plain = <InlineSpan>[];
    var pendingBreaks = 0;

    void addGap(int breaks) {
      // n line breaks between two pieces = n - 1 empty lines.
      if (breaks > 1) {
        children.add(
          Text(List.filled(breaks - 1, ' ').join('\n'), style: style),
        );
      }
    }

    void flushPlain() {
      final (leading, trimmedStart) = _trimBreaks(plain, fromStart: true);
      final (trailing, trimmed) = _trimBreaks(trimmedStart, fromStart: false);
      plain = [];
      if (trimmed.isEmpty) {
        pendingBreaks += leading + trailing;
        return;
      }
      if (children.isNotEmpty) addGap(pendingBreaks + leading);
      children.add(Text.rich(TextSpan(children: trimmed), style: style));
      pendingBreaks = trailing;
    }

    for (final span in body) {
      if (span is! TrAudioSpan) {
        plain.add(span);
        continue;
      }
      flushPlain();
      if (children.isNotEmpty) addGap(pendingBreaks);
      pendingBreaks = 0;
      children.add(
        TurkishAudioBlock(
          audioId: span.audioId,
          child: Text.rich(span, style: style),
        ),
      );
    }
    flushPlain();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// [spans] without the line breaks at their start ([fromStart]) or end,
  /// and how many there were.
  static (int, List<InlineSpan>) _trimBreaks(
    List<InlineSpan> spans, {
    required bool fromStart,
  }) {
    final list = [...spans];
    var breaks = 0;
    while (list.isNotEmpty) {
      final edge = fromStart ? list.first : list.last;
      if (edge is! TextSpan || edge.children != null || edge.text == null) {
        break;
      }
      final text = edge.text!;
      final kept =
          fromStart
              ? text.replaceFirst(RegExp(r'^\n+'), '')
              : text.replaceFirst(RegExp(r'\n+$'), '');
      breaks += text.length - kept.length;
      if (kept.isNotEmpty) {
        final copy = TextSpan(text: kept, style: edge.style);
        if (fromStart) {
          list[0] = copy;
        } else {
          list[list.length - 1] = copy;
        }
        break;
      }
      fromStart ? list.removeAt(0) : list.removeLast();
    }
    return (breaks, list);
  }
}
