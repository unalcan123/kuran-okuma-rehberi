import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../theme/app_colors.dart';
import '../elifba/elifba_lessons_screen.dart';
import '../dualar/dualar_list_screen.dart';
import '../oyunlar/oyunlar_screen.dart';
import '../sureler/sureler_list_screen.dart';
import '../iletisim/contact_screen.dart';
import 'home_menu_item.dart';
import 'widgets/home_grid_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Phones (narrower than [AppBreakpoints.mobile], 600 px) get one column:
  /// each card nearly as wide as the screen. From 600 px: 2 x 2.
  static int columnsFor(double screenWidth) =>
      screenWidth < AppBreakpoints.mobile ? 1 : 2;

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
    final phone = deviceClass == DeviceClass.mobile;
    final sidePadding = phone ? 18.0 : 24.0;
    final columns = columnsFor(MediaQuery.sizeOf(context).width);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: sidePadding,
                vertical: phone ? 20 : 32,
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
                SizedBox(height: phone ? 16 : 28),
                // One column on a phone, 2 x 2 from 600 px. Cells are 4:3,
                // the illustrations' own ratio (never stretched).
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = phone ? 16.0 : 20.0;
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
                SizedBox(height: phone ? 20 : 28),
                const ContactEntryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
