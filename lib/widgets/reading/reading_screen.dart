import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../models/reading_segment.dart';
import '../../services/audio_service.dart';
import '../../services/reading_playback_controller.dart';
import '../../services/reading_settings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_theme.dart';
import '../holy_places_background.dart';
import 'reading_segment_card.dart';
import 'reading_settings_sheet.dart';

/// The children's reading screen shared by a surah and a prayer: a calm
/// picture on top (mosque, a boy with his Mushaf, a stream), the parts on
/// clean light cards, holy places drawn in the side margins only (never
/// behind the text), and a big "Dinle" bar at the bottom.
///
/// Playing, highlighting, repeating, speed, auto-scroll and memorizing are
/// one engine for both ([ReadingPlaybackController] on the app's single
/// [AudioService]); the settings are shared and kept on the device
/// ([ReadingSettings]).
///
/// Auto-scroll: "Dinle" and every new active part bring that part to the
/// upper middle of the screen with a short, smooth scroll. If the student
/// scrolls by hand, the page is left alone while the active part stays in
/// view; the next part that is off screen is brought back.
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({
    super.key,
    required this.title,
    required this.segments,
    required this.nouns,
    this.arabicTitle,
    this.settings,
  });

  final String title;
  final String? arabicTitle;
  final List<ReadingSegment> segments;
  final ReadingNouns nouns;

  /// Defaults to [ReadingSettings.instance].
  final ReadingSettings? settings;

  /// Header picture (cut from the design sheet by `tool/crop_lesson_cards.py`).
  static const String sceneAsset = 'assets/images/reading/reading_scene.webp';

  @override
  State<ReadingScreen> createState() => ReadingScreenState();
}

class ReadingScreenState extends State<ReadingScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  late final List<GlobalKey> _keys = [
    for (final _ in widget.segments) GlobalKey(),
  ];
  late final ReadingSettings _settings =
      widget.settings ?? ReadingSettings.instance;
  late final ReadingPlaybackController _player;

  int? _lastActive;
  bool _userScrolled = false;
  bool _autoScrolling = false;

  /// The engine (for tests).
  ReadingPlaybackController get player => _player;

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioService>();
    audio.preload([for (final s in widget.segments) s.audioAsset]);
    _player = ReadingPlaybackController(
      segments: widget.segments,
      audio: audio,
      settings: _settings,
    )..addListener(_onPlayer);
    _settings.ensureLoaded();
  }

  @override
  void dispose() {
    _player
      ..removeListener(_onPlayer)
      ..dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onPlayer() {
    final active = _player.activeIndex;
    if (active != null && active != _lastActive) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _bringIntoView(active),
      );
    }
    _lastActive = active;
  }

  /// Whether segment [index] is wholly inside the visible part of the list.
  bool _isVisible(int index) {
    final box = _keys[index].currentContext?.findRenderObject() as RenderBox?;
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || viewport == null || !box.attached) return false;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    return top >= 0 && top + box.size.height <= viewport.size.height;
  }

  Future<void> _bringIntoView(int index) async {
    if (!mounted || !_scroll.hasClients) return;
    // The student scrolled by hand and can see the part: leave the page.
    if (_userScrolled && _isVisible(index)) return;
    final target = _keys[index].currentContext;
    if (target == null) return;
    _userScrolled = false;
    _autoScrolling = true;
    try {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.18,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _autoScrolling = false;
    }
  }

  /// "Dinle": from the first part, which is brought into view.
  Future<void> startListening() async {
    _userScrolled = false;
    _lastActive = null;
    await _player.start();
  }

  /// "Ezberle": the same, each part repeated.
  Future<void> startMemorizing() async {
    _userScrolled = false;
    _lastActive = null;
    await _player.startMemorizing();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (!_autoScrolling &&
        notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userScrolled = true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final device = Responsive.deviceClassOf(context);
    final maxContentWidth = switch (device) {
      DeviceClass.mobile => 640.0,
      DeviceClass.tablet => 760.0,
      DeviceClass.desktop => 820.0,
    };
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDDEFFB),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        toolbarHeight: widget.arabicTitle == null ? 60 : 72,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
            if (widget.arabicTitle case final arabic?)
              Text(
                arabic,
                textDirection: TextDirection.rtl,
                style: AppTextTheme.arabicSmall(
                  fontSize: 20,
                ).copyWith(color: AppColors.navySoft, height: 1.3),
              ),
          ],
        ),
        actions: [
          ReadingSettingsButton(nouns: widget.nouns, settings: _settings),
        ],
      ),
      body: Stack(
        children: [
          // Sky, Kâbe, Mescid-i Nebevî, mosque, lanterns, moon — in the
          // side margins only; the cards in the middle stay on calm sky.
          HolyPlacesBackground(contentWidth: maxContentWidth),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([_settings, _player]),
                      builder: (context, _) => _list(maxContentWidth, device),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: Listenable.merge([_settings, _player]),
                  builder:
                      (context, _) => ReadingPlaybackBar(
                        player: _player,
                        maxWidth: maxContentWidth,
                        repeatCount: _settings.repeatCount,
                        nouns: widget.nouns,
                        segments: widget.segments,
                        onListen: startListening,
                        onMemorize: startMemorizing,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(double maxContentWidth, DeviceClass device) {
    final base = ReadingSettings.arabicBaseFontSize(
      wide: device != DeviceClass.mobile,
      large: device == DeviceClass.desktop,
    );
    final fontSize = base * _settings.arabicScale;
    return SingleChildScrollView(
      key: _viewportKey,
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Scene(),
              const SizedBox(height: 16),
              for (var i = 0; i < widget.segments.length; i++)
                Padding(
                  key: _keys[i],
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ReadingSegmentCard(
                    index: i,
                    segment: widget.segments[i],
                    // The besmele heading is set a little smaller.
                    fontSize:
                        widget.segments[i].isOpening
                            ? fontSize * 0.87
                            : fontSize,
                    showArabic: _settings.showArabic,
                    showMeaning: _settings.showMeaning,
                    isActive: _player.activeIndex == i,
                    isPlaying: _player.activeIndex == i && _player.isPlaying,
                    isTextHidden: _player.isTextHidden(i),
                    onPlay: () => _player.playSingle(i),
                    onReveal: _player.reveal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The header picture: rounded, never taller than a third of a phone.
class _Scene extends StatelessWidget {
  const _Scene();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = (constraints.maxWidth * 368 / 572).clamp(120.0, 260.0);
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: SizedBox(
          height: height,
          child: Image.asset(
            ReadingScreen.sceneAsset,
            key: const ValueKey('reading-scene'),
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.35),
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      );
    },
  );
}

/// The bottom bar. Idle: two big buttons — "Dinle" (start to end, once)
/// and "Ezberle 3x" (each part repeated). While reading: "Duraklat" (or
/// "Devam Et") and "Durdur", and while memorizing a small line saying where
/// the student is ("Ezber · 2. Ayet · 1/3"). Above the system bars
/// (SafeArea), never over the cards (it sits below the list).
class ReadingPlaybackBar extends StatelessWidget {
  const ReadingPlaybackBar({
    super.key,
    required this.player,
    required this.onListen,
    required this.onMemorize,
    required this.repeatCount,
    required this.nouns,
    required this.segments,
    this.maxWidth = 820,
  });

  final ReadingPlaybackController player;
  final Future<void> Function() onListen;
  final Future<void> Function() onMemorize;
  final int repeatCount;
  final ReadingNouns nouns;
  final List<ReadingSegment> segments;
  final double maxWidth;

  static const double _height = 60;

  @override
  Widget build(BuildContext context) {
    final playingAll = player.isPlayingAll;
    final playing = playingAll && player.isPlaying;
    final step = player.currentStep;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 19,
      fontWeight: FontWeight.w800,
    );

    Widget bigButton({
      required Key key,
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed,
      String? badge,
    }) => SizedBox(
      height: _height,
      child: FilledButton(
        key: key,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          // From the theme (keeps the app's font family).
          textStyle: textStyle,
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 8),
              Text(label),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(badge),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final Widget buttons;
    if (!playingAll) {
      buttons = Row(
        children: [
          Expanded(
            child: bigButton(
              key: const ValueKey('reading-listen'),
              icon: Icons.volume_up_rounded,
              label: 'Dinle',
              color: AppColors.turquoise,
              onPressed: onListen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: bigButton(
              key: const ValueKey('reading-memorize'),
              icon: Icons.psychology_rounded,
              label: 'Ezberle',
              badge: '${repeatCount}x',
              color: AppColors.skyBlue,
              onPressed: onMemorize,
            ),
          ),
        ],
      );
    } else {
      buttons = Row(
        children: [
          Expanded(
            child: bigButton(
              key: const ValueKey('reading-pause'),
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: playing ? 'Duraklat' : 'Devam Et',
              color:
                  player.isMemorizing ? AppColors.skyBlue : AppColors.turquoise,
              onPressed: playing ? player.pause : player.resume,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: _height,
            height: _height,
            child: IconButton.filledTonal(
              key: const ValueKey('reading-stop'),
              tooltip: 'Durdur',
              onPressed: player.stop,
              iconSize: 30,
              icon: const Icon(Icons.stop_rounded),
            ),
          ),
        ],
      );
    }

    String? status;
    if (player.isMemorizing && step != null) {
      final segment = segments[step.segment];
      final name =
          segment.isOpening
              ? 'Besmele'
              : '${segment.number ?? step.segment + 1}. ${nouns.one}';
      status =
          step.of > 1
              ? 'Ezber · $name · ${step.repeat}/${step.of}'
              : 'Ezber · $name';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        status,
                        key: const ValueKey('reading-status'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  buttons,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
