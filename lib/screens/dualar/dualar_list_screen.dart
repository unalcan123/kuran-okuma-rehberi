import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

import '../../data/additional_dualar_data.dart';
import '../../data/recitation_card_images.dart';
import '../../models/dua.dart';
import '../../widgets/holy_places_background.dart';
import 'dua_detail_screen.dart';
import '../../widgets/recitation_card.dart';
import '../../widgets/tablet_zoom.dart';

/// "Dualar" home — each prayer as a picture card ([PictureCard],
/// [duaCardImage]) on one responsive grid ([RecitationCard]): the picture,
/// and under it the number and the name, written by the app.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Dualar')),
        actions: [
          ReadingTextSettingsButton(
            showMeaningToggle: false,
            controller: _textScale,
          ),
        ],
      ),
      body: TabletZoom(
        child: ReadingTextScale(
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
                      final columns = RecitationCard.columnsFor(
                        constraints.maxWidth,
                        readingScale,
                      );

                      final cardWidth =
                          (constraints.maxWidth - 40 - 16 * (columns - 1)) /
                          columns;

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
                        itemCount: kAllDualar.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: RecitationCard.extentOf(
                            context,
                            width: cardWidth,
                            aspectRatio: kDuaCardAspectRatio,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final dua = kAllDualar[index];
                          final label = context.t('Dua {n}', {'n': dua.order});
                          final title = context.t(
                            kDuaDisplayTitles[dua.id] ?? dua.titleTr,
                          );
                          return RecitationCard(
                            cardKey: ValueKey('dua-card-${dua.id}'),
                            captionKey: ValueKey('dua-caption-${dua.id}'),
                            image: duaCardImage(dua.id),
                            aspectRatio: kDuaCardAspectRatio,
                            radiusFactor: kDuaCardRadiusFactor,
                            number: label,
                            title: title,
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
      ),
    );
  }

  void _openDua(BuildContext context, Dua dua) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: '/dua/${dua.id}'),
        builder: (_) => DuaDetailScreen(dua: dua),
      ),
    );
  }
}
