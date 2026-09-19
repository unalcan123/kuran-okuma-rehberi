import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../models/dua.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors.dart';
import '../elifba/widgets/letter_page_background.dart';
import 'widgets/dua_segment_card.dart';
import '../../widgets/recitation_audio_controls.dart';

class DuaDetailScreen extends StatefulWidget {
  final Dua dua;

  const DuaDetailScreen({super.key, required this.dua});

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  final _textScale = ValueNotifier<double>(1);
  final _scrollController = ScrollController();
  late final List<GlobalKey> _segmentKeys = List.generate(
    widget.dua.segments.length,
    (_) => GlobalKey(),
  );

  String? _lastScrolledAsset;
  late AudioService _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<AudioService>();
  }

  @override
  void dispose() {
    Future.microtask(_audio.stop);
    _scrollController.dispose();
    _textScale.dispose();
    super.dispose();
  }

  void _maybeScrollTo(String? currentAsset) {
    if (currentAsset == null || currentAsset == _lastScrolledAsset) return;
    _lastScrolledAsset = currentAsset;

    GlobalKey? targetKey;
    final index = widget.dua.segments.indexWhere(
      (part) => part.audioAsset == currentAsset,
    );
    if (index >= 0) targetKey = _segmentKeys[index];
    if (targetKey == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = targetKey?.currentContext;
      if (targetContext == null || !_scrollController.hasClients) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dua = widget.dua;
    final deviceClass = Responsive.deviceClassOf(context);
    final maxContentWidth = switch (deviceClass) {
      DeviceClass.mobile => 640.0,
      DeviceClass.tablet => 760.0,
      DeviceClass.desktop => 820.0,
    };

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        actions: [ReadingTextSettingsButton(controller: _textScale)],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dua.titleTr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const LetterPageBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: ReadingTextScale(
                        controller: _textScale,
                        child: Consumer<AudioService>(
                          builder: (context, audio, _) {
                            _maybeScrollTo(audio.currentAsset);
                            return ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                12,
                              ),
                              children: [
                                for (var i = 0; i < dua.segments.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: DuaSegmentCard(
                                      key: _segmentKeys[i],
                                      segment: dua.segments[i],
                                      number: i + 1,
                                      isHighlighted:
                                          audio.currentAsset ==
                                          dua.segments[i].audioAsset,
                                      isPlaying:
                                          audio.currentAsset ==
                                              dua.segments[i].audioAsset &&
                                          audio.isPlaying,
                                      onTap:
                                          () => audio.playOrToggle(
                                            dua.segments[i].audioAsset,
                                          ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: RecitationAudioControls(playlist: dua.playlist),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
