import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';

import '../../data/dualar_data.dart';
import '../../data/recitation_card_images.dart';
import '../../models/dua.dart';
import '../../widgets/holy_places_background.dart';
import 'dua_detail_screen.dart';
import '../../widgets/picture_card.dart';
import '../../widgets/tablet_zoom.dart';

/// "Namaz Duaları" home — each prayer as a picture card ([PictureCard],
/// [kDuaCardImages]) on one responsive grid.
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
  static const double _minCardWidth = 240;

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
                    final columns = ((constraints.maxWidth - 40 + 16) /
                            (_minCardWidth * (readingScale > 1 ? readingScale : 1) + 16))
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
                      itemCount: kDualar.length,
                      // Picture cards (PictureCard): every card has the
                      // pictures' shape; the whole card opens the prayer.
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: kDuaCardAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final dua = kDualar[index];
                        return PictureCard(
                          key: ValueKey('dua-card-${dua.id}'),
                          image: kDuaCardImages[dua.id],
                          aspectRatio: kDuaCardAspectRatio,
                          radiusFactor: kDuaCardRadiusFactor,
                          label: 'Dua ${dua.order}',
                          title: kDuaDisplayTitles[dua.id] ?? dua.titleTr,
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
      )),
    );
  }

  void _openDua(BuildContext context, Dua dua) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DuaDetailScreen(dua: dua)));
  }
}
