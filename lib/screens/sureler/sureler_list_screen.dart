import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';

import '../../data/sureler_data.dart';
import '../../models/surah.dart';
import '../elifba/widgets/letter_page_background.dart';
import 'surah_detail_screen.dart';
import 'widgets/surah_card.dart';

/// "Namaz Sureleri" home — every short surah as a card on one
/// responsive grid.
///
/// Column count follows the same rule the Elifba grid uses: how many
/// cards actually fit at a comfortable minimum width, not how wide
/// the screen happens to be — so a card never gets squeezed just
/// because the device is nominally "tablet-sized".
class SurelerListScreen extends StatefulWidget {
  const SurelerListScreen({super.key});

  @override
  State<SurelerListScreen> createState() => _SurelerListScreenState();
}

class _SurelerListScreenState extends State<SurelerListScreen> {
  final _textScale = ValueNotifier<double>(1);

  @override
  void dispose() {
    _textScale.dispose();
    super.dispose();
  }

  static const double _maxContentWidth = 1100;
  static const double _minCardWidth = 220;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Sureleri'),
        actions: [
          ReadingTextSettingsButton(
            showMeaningToggle: false,
            controller: _textScale,
          ),
        ],
      ),
      body: ReadingTextScale(
        controller: _textScale,
        child: Stack(
          children: [
            const LetterPageBackground(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final readingScale = ReadingTextScale.factorOf(context);
                    // Bigger text needs wider cards: columns thin out one by one.
                    final columns = (constraints.maxWidth /
                            (_minCardWidth * (readingScale > 1 ? readingScale : 1)))
                        .floor()
                        .clamp(1, 4);

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: kSureler.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent:
                            290 + (readingScale - 1) * 40,
                      ),
                      itemBuilder: (context, index) {
                        final surah = kSureler[index];
                        return SurahCard(
                          surah: surah,
                          onTap: () => _openSurah(context, surah),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSurah(BuildContext context, Surah surah) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: surah)));
  }
}
