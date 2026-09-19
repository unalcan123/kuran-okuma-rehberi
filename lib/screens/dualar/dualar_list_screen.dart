import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';

import '../../data/dualar_data.dart';
import '../../models/dua.dart';
import '../elifba/widgets/letter_page_background.dart';
import 'dua_detail_screen.dart';
import '../../widgets/recitation_card.dart';

/// "Namaz Duaları" home — each prayer as a card on one
/// responsive grid.
///
/// Column count follows the same rule the Elifba grid uses: how many
/// cards actually fit at a comfortable minimum width, not how wide
/// the screen happens to be — so a card never gets squeezed just
/// because the device is nominally "tablet-sized".
class DualarListScreen extends StatefulWidget {
  const DualarListScreen({super.key});

  @override
  State<DualarListScreen> createState() => _DualarListScreenState();
}

class _DualarListScreenState extends State<DualarListScreen> {
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
        title: const Text('Namaz Duaları'),
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
                    final columns = ((constraints.maxWidth - 40 + 16) /
                            (_minCardWidth * (readingScale > 1 ? readingScale : 1) + 16))
                        .floor()
                        .clamp(1, 4);

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: kDualar.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent:
                            290 + (readingScale - 1) * 40,
                      ),
                      itemBuilder: (context, index) {
                        final dua = kDualar[index];
                        return RecitationCard(
                          title: dua.titleTr,
                          arabic: dua.segments.first.arabic,
                          isPreview: true,
                          onTap: () => _openDua(context, dua),
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

  void _openDua(BuildContext context, Dua dua) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DuaDetailScreen(dua: dua)));
  }
}
