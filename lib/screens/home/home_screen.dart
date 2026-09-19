import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../theme/app_colors.dart';
import '../elifba/elifba_lessons_screen.dart';
import '../dualar/dualar_list_screen.dart';
import '../oyunlar/oyunlar_screen.dart';
import '../sureler/sureler_list_screen.dart';
import 'home_menu_item.dart';
import 'widgets/home_menu_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<HomeMenuItem> _menuItems() {
    return [
      HomeMenuItem(
        title: 'Elifba Dersleri',
        subtitle: 'Harfleri tanı, dinle ve öğren',
        icon: Icons.menu_book_rounded,
        background: AppColors.turquoiseSoft,
        foreground: AppColors.turquoise,
        screenBuilder: (_) => const ElifbaLessonsScreen(),
      ),
      HomeMenuItem(
        title: 'Namaz Sureleri',
        subtitle: 'Kısa sureleri öğren',
        icon: Icons.auto_stories_rounded,
        background: AppColors.skyBlueSoft,
        foreground: AppColors.skyBlue,
        screenBuilder: (_) => const SurelerListScreen(),
      ),
      HomeMenuItem(
        title: 'Namaz Duaları',
        subtitle: 'Namaz dualarını öğren',
        icon: Icons.volunteer_activism_rounded,
        background: AppColors.sageSoft,
        foreground: AppColors.sage,
        screenBuilder: (_) => const DualarListScreen(),
      ),
      HomeMenuItem(
        title: 'Oyunlar',
        subtitle: 'Öğrendiklerini pekiştir',
        icon: Icons.extension_rounded,
        background: AppColors.goldSoft,
        foreground: AppColors.gold,
        screenBuilder: (_) => const OyunlarScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _menuItems();
    final deviceClass = Responsive.deviceClassOf(context);
    final crossAxisCount = switch (deviceClass) {
      DeviceClass.mobile => 1,
      DeviceClass.tablet => 2,
      DeviceClass.desktop => 2,
    };
    final maxContentWidth = deviceClass == DeviceClass.desktop ? 900.0 : 640.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 136,
                  ),
                  itemBuilder:
                      (context, index) => HomeMenuCard(item: items[index]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
