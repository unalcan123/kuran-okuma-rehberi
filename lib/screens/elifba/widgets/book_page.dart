import 'package:flutter/material.dart';

import '../../../data/lesson_info_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import 'letter_page_background.dart';

/// The heading printed on a book page: up to three lines of Turkish and
/// an optional Arabic line.
class BookPageHeading {
  final String? top;
  final String main;
  final String? bottom;
  final String? arabic;

  const BookPageHeading({this.top, required this.main, this.bottom, this.arabic});
}

BookPageHeading _zamirHe(String main) => BookPageHeading(
  top: 'ZAMİR “HE”’NİN',
  main: main,
  arabic: 'هـ ه',
);

/// Lessons shown as a book page (pages 50-59 of the book), by lesson id.
final Map<String, BookPageHeading> kBookPageHeadings = {
  'el-takisi-okunan': BookPageHeading(main: 'ELİF - LÂM'),
  'el-takisi-okunmayan': BookPageHeading(main: 'ELİF - LÂM'),
  'el-takisi-hemze': BookPageHeading(main: 'EL TAKISI’NDAKİ HEMZE'),
  'el-takisi-hemze-vasil': BookPageHeading(
    main: 'OKUNMAYAN HEMZE',
    bottom: '(Vasıl Hemzesi)',
    arabic: 'ٱ',
  ),
  'zamir-he-uzatilmasi': _zamirHe('UZATILMASI'),
  'zamir-he-uzatma-med': BookPageHeading(main: 'UZUN MED İŞARETİ', arabic: 'ـٓـ'),
  'zamir-he-uzatma-yok': _zamirHe('UZATILMAMASI'),
  'zamir-he-uzatma-yok-cezimli': _zamirHe('UZATILMAMASI'),
  'zamir-he-uzatma-yok-cezimli-seddeli': _zamirHe('UZATILMAMASI'),
  'kapali-te': BookPageHeading(main: 'KAPALI “TE”', arabic: 'ة – ـة'),
  'kelime-sonu-duraklar': BookPageHeading(
    top: 'KELİME SONUNDAKİ',
    main: 'HAREKELİ HARFTE',
    bottom: 'NASIL DURULUR?',
  ),
};

/// A lesson laid out like the book's pages: the heading, the explanations,
/// and between them the "Durulduğunda / Geçildiğinde" tables whose words can
/// be tapped to hear them. The text is the lesson's [LessonInfo] — the same
/// content the info (ⓘ) button shows.
class BookPage extends StatelessWidget {
  const BookPage({super.key, required this.info, required this.heading});

  final LessonInfo info;
  final BookPageHeading heading;

  @override
  Widget build(BuildContext context) {
    // A first span that only repeats the heading is left out of the page.
    final body = info.firstSpanIsBookHeading ? info.body.skip(1).toList() : info.body;
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
                  constraints: const BoxConstraints(maxWidth: 780),
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
                        _Heading(heading),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: narrow ? 6 : 14,
                            vertical: 16,
                          ),
                          child: Text.rich(
                            TextSpan(children: body),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.5),
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

class _Heading extends StatelessWidget {
  final BookPageHeading heading;

  const _Heading(this.heading);

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(color: AppColors.navySoft, letterSpacing: 0.6);
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            if (heading.top != null) ...[
              Text(heading.top!, textAlign: TextAlign.center, style: small),
              const SizedBox(height: 4),
            ],
            Text(
              heading.main,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (heading.bottom != null) ...[
              const SizedBox(height: 4),
              Text(heading.bottom!, textAlign: TextAlign.center, style: small),
            ],
            if (heading.arabic != null) ...[
              const SizedBox(height: 6),
              Text(
                heading.arabic!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTextTheme.arabicSmall(fontSize: 30).copyWith(color: AppColors.gold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
