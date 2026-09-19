import '../../widgets/reading_arabic_text.dart';
import '../../widgets/reading_text_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../models/surah.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_theme.dart';
import '../elifba/widgets/letter_page_background.dart';
import 'widgets/ayet_card.dart';
import 'widgets/surah_audio_controls.dart';

/// A surah's reading screen — Arabic text is the priority, the
/// besmele leads it, every ayet follows with its Turkish meaning kept
/// visually separate underneath, and a simple Dinle/Duraklat/Durdur
/// bar plays the whole thing straight through using the same
/// app-wide [AudioService] Elifba uses.
///
/// Whichever ayet is currently sounding — whether from the "Dinle"
/// playlist auto-advancing or a tap on a single ayet — scrolls into
/// view automatically, so following along during playback doesn't
/// need manual scrolling.
class SurahDetailScreen extends StatefulWidget {
  final Surah surah;

  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final _textScale = ValueNotifier<double>(1);
  final _scrollController = ScrollController();
  late final List<GlobalKey> _ayetKeys = List.generate(
    widget.surah.ayetler.length,
    (_) => GlobalKey(),
  );
  final _besmeleKey = GlobalKey();

  String? _lastScrolledAsset;
  late AudioService _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio = context.read<AudioService>();
    _audio.preload([
      widget.surah.besmeleAudioAsset,
      for (final ayet in widget.surah.ayetler) ayet.audioAsset,
    ]);
  }

  double _besmeleFontSize(DeviceClass deviceClass) => switch (deviceClass) {
    DeviceClass.mobile => 26,
    DeviceClass.tablet => 36,
    DeviceClass.desktop => 40,
  };

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
    if (currentAsset == widget.surah.besmeleAudioAsset) {
      targetKey = _besmeleKey;
    } else {
      final index = widget.surah.ayetler.indexWhere(
        (ayet) => ayet.audioAsset == currentAsset,
      );
      if (index >= 0) targetKey = _ayetKeys[index];
    }
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
    final surah = widget.surah;
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
              surah.titleTr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                surah.arabicName,
                style: AppTextTheme.arabicSmall(
                  fontSize: 18,
                ).copyWith(color: AppColors.textSecondary),
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
                                _BesmeleHeader(
                                  key: _besmeleKey,
                                  text: surah.besmele,
                                  fontSize: _besmeleFontSize(deviceClass),
                                  isHighlighted:
                                      audio.currentAsset ==
                                      surah.besmeleAudioAsset,
                                  onTap:
                                      () => audio.playOrToggle(
                                        surah.besmeleAudioAsset,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                for (var i = 0; i < surah.ayetler.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: AyetCard(
                                      key: _ayetKeys[i],
                                      ayet: surah.ayetler[i],
                                      isHighlighted:
                                          audio.currentAsset ==
                                          surah.ayetler[i].audioAsset,
                                      isPlaying:
                                          audio.currentAsset ==
                                              surah.ayetler[i].audioAsset &&
                                          audio.isPlaying,
                                      onTap:
                                          () => audio.playOrToggle(
                                            surah.ayetler[i].audioAsset,
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
                        child: SurahAudioControls(surah: surah),
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

class _BesmeleHeader extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _BesmeleHeader({
    super.key,
    required this.text,
    required this.fontSize,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isHighlighted ? AppColors.goldSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold.withValues(
                alpha: isHighlighted ? 0.7 : 0.35,
              ),
              width: isHighlighted ? 1.4 : 1,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ReadingArabicText(text,
              style: AppTextTheme.arabicSmall(
                fontSize: fontSize,
              ).copyWith(color: AppColors.gold, height: 1.8),
            ),
          ),
        ),
      ),
    );
  }
}
