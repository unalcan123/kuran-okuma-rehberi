import '../../widgets/recitation_title_overlay.dart';
import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

import '../../data/recitation_card_images.dart';
import '../../data/sure_groups.dart';
import '../../models/surah.dart';
import '../../widgets/holy_places_background.dart';
import '../../widgets/recitation_card.dart';
import 'surah_detail_screen.dart';
import '../../widgets/tablet_zoom.dart';

/// "Sureler" home: without a [group], the three group cards
/// ([kSureGroups]); with one, that group's readings as picture cards
/// ([RecitationCard]). Columns: [RecitationCard.columnsFor] — two on an
/// upright phone, three or four on a tablet, fewer as the text grows.
class SurelerListScreen extends StatefulWidget {
  const SurelerListScreen({super.key, this.group});

  final SureGroup? group;

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

  // Actual image dimensions keep the new numbers over the baked badges.
  static const _cardImageSizes = {
    'fatiha': Size(491, 254),
    'fil': Size(480, 255),
    'kureysh': Size(491, 256),
    'maun': Size(491, 240),
    'ihlas': Size(479, 242),
    'kevser': Size(490, 243),
    'nas': Size(491, 230),
    'felak': Size(479, 229),
    'nasr': Size(490, 231),
    'tebbet': Size(590, 227),
    'kafirun': Size(590, 227),
    'ayetel-kursi': Size(491, 266),
    'nebe-son': Size(491, 266),
    'duha': Size(491, 266),
    'insirah': Size(491, 267),
    'tin': Size(491, 279),
    'kadir': Size(491, 278),
    'zilzal': Size(491, 279),
    'adiyat': Size(491, 279),
    'karia': Size(491, 283),
    'tekasur': Size(491, 282),
    'asr': Size(491, 283),
    'humeze': Size(491, 283),
  };

  static const double _maxContentWidth = 1100;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final count = group?.surahs.length ?? kSureGroups.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(group?.titleTr ?? 'Sureler')),
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
                        itemCount: count,
                        // Picture cards (PictureCard): every card has the
                        // pictures' shape; the whole card opens the surah.
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: RecitationCard.extentOf(
                            context,
                            width: cardWidth,
                            aspectRatio: kSurahCardAspectRatio,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          if (group == null) {
                            return _groupCard(context, kSureGroups[index]);
                          }
                          final surah = group.surahs[index];
                          final note = group.notesTr[surah.id];
                          final number =
                              note != null
                                  ? context.t(note)
                                  : context.t('Sure {n}', {'n': index + 1});
                          final textFree = kSurahTextFreeImages.containsKey(
                            surah.id,
                          );
                          return RecitationCard(
                            cardKey: ValueKey('surah-card-${surah.id}'),
                            captionKey: ValueKey('surah-caption-${surah.id}'),
                            image: surahCardImage(surah.id),
                            aspectRatio: kSurahCardAspectRatio,
                            radiusFactor: kSurahCardRadiusFactor,
                            number: number,
                            title: context.t(surah.titleTr),
                            arabic: surah.arabicName,
                            // An old picture shows the master's number, not
                            // the surah's place here: covered by the right one.
                            imageSize:
                                textFree ? null : _cardImageSizes[surah.id],
                            overlay:
                                textFree
                                    ? null
                                    : RecitationTitleOverlay(
                                      title: context.t(surah.titleTr),
                                      label: context.t('Sure {n}', {
                                        'n': index + 1,
                                      }),
                                      prayer: false,
                                      showTitle: false,
                                    ),
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
      ),
    );
  }

  Widget _groupCard(BuildContext context, SureGroup group) => RecitationCard(
    cardKey: ValueKey('sure-group-${group.id}'),
    captionKey: ValueKey('sure-group-caption-${group.id}'),
    image: surahCardImage(group.surahs.first.id),
    aspectRatio: kSurahCardAspectRatio,
    radiusFactor: kSurahCardRadiusFactor,
    number: context.t('{n} sure', {'n': group.surahs.length}),
    title: context.t(group.titleTr),
    onTap:
        () => Navigator.of(context).push(
          MaterialPageRoute(
            settings: RouteSettings(name: '/sureler/${group.id}'),
            builder: (_) => SurelerListScreen(group: group),
          ),
        ),
  );

  void _openSurah(BuildContext context, Surah surah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: '/sure/${surah.id}'),
        builder: (_) => SurahDetailScreen(surah: surah),
      ),
    );
  }
}
