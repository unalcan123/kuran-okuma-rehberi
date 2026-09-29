import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';

import '../../data/recitation_card_images.dart';
import '../../data/sureler_data.dart';
import '../../models/surah.dart';
import '../../widgets/holy_places_background.dart';
import '../../widgets/picture_card.dart';
import 'surah_detail_screen.dart';
import '../../widgets/tablet_zoom.dart';

/// "Namaz Sureleri" home — every short surah as a picture card
/// ([PictureCard], [kSurahCardImages]) on one responsive grid.
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
  static const double _minCardWidth = 240;

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
      body: TabletZoom(child: ReadingTextScale(
        controller: _textScale,
        child: Stack(
          children: [
            // Cute holy places (Kâbe, green dome, mosque), drawn in shapes.
            const HolyPlacesBackground(contentWidth: _maxContentWidth),
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
                      // At the end, room to see the Kâbe scene.
                      padding: EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        20 +
                            HolyPlacesPainter.sceneHeightFor(
                              MediaQuery.sizeOf(context),
                            ),
                      ),
                      itemCount: kSureler.length,
                      // Picture cards (PictureCard): every card has the
                      // pictures' shape; the whole card opens the surah.
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: kSurahCardAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final surah = kSureler[index];
                        return PictureCard(
                          key: ValueKey('surah-card-${surah.id}'),
                          image: kSurahCardImages[surah.id],
                          aspectRatio: kSurahCardAspectRatio,
                          radiusFactor: kSurahCardRadiusFactor,
                          label: 'Sure ${surah.order}',
                          title: surah.titleTr,
                          arabic: surah.arabicName,
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
      )),
    );
  }

  void _openSurah(BuildContext context, Surah surah) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: surah)));
  }
}
