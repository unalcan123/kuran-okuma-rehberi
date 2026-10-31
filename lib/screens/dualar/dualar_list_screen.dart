import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

import '../../data/dua_groups.dart';
import '../../data/recitation_card_images.dart';
import '../../models/dua.dart';
import '../../widgets/holy_places_background.dart';
import 'dua_detail_screen.dart';
import '../../widgets/recitation_card.dart';
import '../../widgets/tablet_zoom.dart';

/// "Dualar" home: without a [group], the three group cards ([kDuaGroups]);
/// with one, its prayers as picture cards ([RecitationCard], [duaCardImage]):
/// the picture, and under it the number and the name, written by the app.
/// Columns: [RecitationCard.columnsFor], like the Sureler grid.
class DualarListScreen extends StatefulWidget {
  const DualarListScreen({super.key, this.group});

  final DuaGroup? group;

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
    final group = widget.group;
    final duas = group?.duas;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(group?.titleTr ?? 'Dualar')),
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
                        itemCount: duas?.length ?? kDuaGroups.length,
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
                          if (duas == null) {
                            return _groupCard(context, kDuaGroups[index]);
                          }
                          final dua = duas[index];
                          final note = group!.notesTr[dua.id];
                          final label =
                              note != null
                                  ? context.t(note)
                                  : context.t('Dua {n}', {'n': index + 1});
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

  Widget _groupCard(BuildContext context, DuaGroup group) => RecitationCard(
    cardKey: ValueKey('dua-group-${group.id}'),
    captionKey: ValueKey('dua-group-caption-${group.id}'),
    image: duaCardImage(group.ids.first),
    aspectRatio: kDuaCardAspectRatio,
    radiusFactor: kDuaCardRadiusFactor,
    number: context.t('{n} dua', {'n': group.ids.length}),
    title: context.t(group.titleTr),
    onTap:
        () => Navigator.of(context).push(
          MaterialPageRoute(
            settings: RouteSettings(name: '/dualar/${group.id}'),
            builder: (_) => DualarListScreen(group: group),
          ),
        ),
  );

  void _openDua(BuildContext context, Dua dua) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: '/dua/${dua.id}'),
        builder: (_) => DuaDetailScreen(dua: dua),
      ),
    );
  }
}
