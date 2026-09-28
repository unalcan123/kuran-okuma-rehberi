import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../theme/app_colors.dart';
import '../elifba/elifba_lessons_screen.dart';
import '../dualar/dualar_list_screen.dart';
import '../oyunlar/oyunlar_screen.dart';
import '../sureler/sureler_list_screen.dart';
import 'home_menu_item.dart';
import 'widgets/home_grid_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Below this content width the grid falls back to one column.
  static const double minTwoColumnWidth = 280;

  /// A card is never narrowed below this to fit the screen's height.
  static const double minCardWidth = 150;

  /// Height of everything on the page but the grid (margins, title lines).
  static const double _chromeHeight = 64 + 150;

  List<HomeMenuItem> _menuItems() {
    return [
      HomeMenuItem(
        title: "Kur'an Okuma Rehberi",
        subtitle: 'Harfleri tanı, dinle ve öğren',
        icon: Icons.menu_book_rounded,
        background: AppColors.turquoiseSoft,
        foreground: AppColors.turquoise,
        image: 'assets/images/home/kuran_okuma_rehberi.webp',
        screenBuilder: (_) => const ElifbaLessonsScreen(),
      ),
      HomeMenuItem(
        title: 'Namaz Duaları',
        subtitle: 'Namaz dualarını öğren',
        icon: Icons.volunteer_activism_rounded,
        background: AppColors.sageSoft,
        foreground: AppColors.sage,
        image: 'assets/images/home/namaz_dualari.webp',
        screenBuilder: (_) => const DualarListScreen(),
      ),
      HomeMenuItem(
        title: 'Namaz Sureleri',
        subtitle: 'Kısa sureleri öğren',
        icon: Icons.auto_stories_rounded,
        background: AppColors.skyBlueSoft,
        foreground: AppColors.skyBlue,
        image: 'assets/images/home/namaz_sureleri.webp',
        screenBuilder: (_) => const SurelerListScreen(),
      ),
      HomeMenuItem(
        title: 'Oyunlar',
        subtitle: 'Öğrendiklerini pekiştir',
        icon: Icons.extension_rounded,
        background: AppColors.goldSoft,
        foreground: AppColors.gold,
        image: 'assets/images/home/oyunlar.webp',
        screenBuilder: (_) => const OyunlarScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _menuItems();
    final deviceClass = Responsive.deviceClassOf(context);
    final maxContentWidth = deviceClass == DeviceClass.desktop ? 900.0 : 640.0;
    final sidePadding = deviceClass == DeviceClass.mobile ? 16.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: sidePadding,
                vertical: 32,
              ),
              children: [
                Text(
                  "Kur'an Okuma Rehberi",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bugün ne öğrenmek istersin?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                // 2 x 2 on every device; one column only on very narrow
                // screens. Cells are 4:3, the illustrations' own ratio.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing =
                        deviceClass == DeviceClass.mobile ? 12.0 : 20.0;
                    final columns =
                        constraints.maxWidth < minTwoColumnWidth ? 1 : 2;
                    // On wide, short windows (landscape) the 2 x 2 grid is
                    // narrowed so all four cards fit the screen's height;
                    // it never gets smaller than [minCardWidth] a card
                    // (below that the page scrolls).
                    final rowsHeight =
                        MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).vertical -
                        _chromeHeight;
                    final fitWidth =
                        ((rowsHeight - spacing) / 2) * 4 / 3 * 2 + spacing;
                    final width =
                        columns == 1
                            ? constraints.maxWidth
                            : fitWidth
                                .clamp(
                                  minCardWidth * 2 + spacing,
                                  constraints.maxWidth,
                                )
                                .toDouble();
                    return Center(
                      child: SizedBox(
                        width: width,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                childAspectRatio: 4 / 3,
                              ),
                          itemBuilder:
                              (context, index) =>
                                  HomeGridCard(item: items[index]),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
