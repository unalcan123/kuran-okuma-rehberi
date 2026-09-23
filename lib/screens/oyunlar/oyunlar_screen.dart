import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../theme/app_colors.dart';
import '../home/home_menu_item.dart';
import '../home/widgets/home_menu_card.dart';
import 'games.dart';
import 'harf_oyunlari/profil/player_picker.dart';
import 'harf_oyunlari/profil/genel_siralama_sayfasi.dart';
import 'results/game_results_screen.dart';

/// The games menu: one card per entry of [kGames], then the global
/// leaderboard and the results page. Add a game to [kGames] and it shows up
/// here and on the results. İlk girişte oyuncunun adı bir kez sorulur.
class OyunlarScreen extends StatefulWidget {
  const OyunlarScreen({super.key});

  @override
  State<OyunlarScreen> createState() => _OyunlarScreenState();
}

class _OyunlarScreenState extends State<OyunlarScreen> {
  static final HomeMenuItem _leaderboard = HomeMenuItem(
    title: 'Genel Sıralama',
    subtitle: 'Tüm oyuncular arasında sıran',
    icon: Icons.emoji_events_rounded,
    background: AppColors.goldSoft,
    foreground: AppColors.gold,
    screenBuilder: (_) => const GenelSiralamaSayfasi(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ensureActivePlayer(context);
    });
  }

  static final HomeMenuItem _results = HomeMenuItem(
    title: 'Sonuçlarım',
    subtitle: 'Puanlarına ve ilerlemene bak',
    icon: Icons.bar_chart_rounded,
    background: AppColors.sageSoft,
    foreground: AppColors.sage,
    screenBuilder: (_) => const GameResultsScreen(),
  );

  @override
  Widget build(BuildContext context) {
    final maxContentWidth = Responsive.isDesktop(context) ? 800.0 : 640.0;
    final items = [
      for (final game in kGames)
        HomeMenuItem(
          title: game.title,
          subtitle: game.subtitle,
          icon: game.icon,
          background: game.background,
          foreground: game.foreground,
          screenBuilder: game.builder,
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyunlar'),
        // "Oyuncu: Elif ✎" → adı düzelt.
        actions: const [PlayerChip(), SizedBox(width: 8)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final item in items) ...[
                HomeMenuCard(item: item),
                const SizedBox(height: 16),
              ],
              HomeMenuCard(item: _leaderboard),
              const SizedBox(height: 16),
              HomeMenuCard(item: _results),
            ],
          ),
        ),
      ),
    );
  }
}
