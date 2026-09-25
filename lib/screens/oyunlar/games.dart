import 'package:flutter/material.dart';

import '../../data/drag_drop_game_data.dart';
import '../../data/letters_data.dart';
import '../../data/memory_game_data.dart';
import '../../theme/app_colors.dart';
import 'drag_drop/drag_drop_levels_screen.dart';
import 'arapca_yaziyorum/arapca_yaziyorum_screen.dart';
import 'arapca_yaziyorum/yazi_data.dart';
import 'harf_ciziyorum/harf_ciziyorum_screen.dart';
import 'harf_dedektifi/dedektif_engine.dart';
import 'harf_dedektifi/harf_dedektifi_screen.dart';
import 'harf_treni/harf_treni_screen.dart';
import 'harf_treni/tren_engine.dart';
import 'harf_oyunlari/bul_patlat/bul_patlat_screen.dart';
import 'harf_oyunlari/harf_arabalari/harf_arabalari_screen.dart';
import 'harf_oyunlari/profil/player_models.dart';
import 'listen_pick/listen_pick_lessons_screen.dart';
import 'listen_pick/listen_pick_questions.dart';
import 'memory/memory_levels_screen.dart';

/// One separate game inside a game family — a Sürükle & Bırak level, a
/// Dinle ve Seç lesson. Results are kept per variant, so the last five
/// scores and the average always belong to the *same* game.
class GameVariant {
  const GameVariant({required this.key, required this.title});

  final String key;
  final String title;
}

/// One playable game. This list feeds both the games menu and the
/// results page, so a new game is added here once and appears in both.
class GameEntry {
  const GameEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.builder,
    required this.variants,
    this.showInResults = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final WidgetBuilder builder;
  final List<GameVariant> variants;

  /// Puanlı oyunlar "Sonuçlarım"da görünür. Puanı olmayan (yalnızca harf
  /// başına yıldız tutan) oyunlar görünmez; ilerleme kendi ekranındadır.
  final bool showInResults;
}

final List<GameEntry> kGames = [
  GameEntry(
    id: kDragDropGameKey,
    title: 'Sürükle & Bırak',
    subtitle: 'Harfleri doğru yerlere taşı',
    icon: Icons.touch_app_rounded,
    background: AppColors.goldSoft,
    foreground: AppColors.gold,
    builder: (_) => const DragDropLevelsScreen(),
    variants: [
      for (final level in kDragDropLevels)
        GameVariant(key: level.gameKey, title: level.title),
    ],
  ),
  GameEntry(
    id: kListenPickGameKey,
    title: 'Dinle ve Seç',
    subtitle: 'Sesi dinle, doğru olanı bul',
    icon: Icons.hearing_rounded,
    background: AppColors.skyBlueSoft,
    foreground: AppColors.skyBlue,
    builder: (_) => const ListenPickLessonsScreen(),
    variants: [
      for (final lesson in kElifbaLessons)
        GameVariant(
          key: listenPickGameKey(lesson),
          title: '${lesson.label} · ${lesson.title}',
        ),
    ],
  ),
  GameEntry(
    id: kMemoryGameKey,
    title: 'Hafıza',
    subtitle: 'Aynı harfleri bul',
    icon: Icons.extension_rounded,
    background: AppColors.turquoiseSoft,
    foreground: AppColors.turquoise,
    builder: (_) => const MemoryLevelsScreen(),
    variants: [
      for (final level in kMemoryLevels)
        GameVariant(key: level.gameKey, title: level.title),
    ],
  ),
  GameEntry(
    id: GameIds.bulPatlat,
    title: 'Bul & Patlat',
    subtitle: 'Sesi dinle, doğru harfi bul ve balonu patlat',
    icon: Icons.bubble_chart_rounded,
    background: AppColors.skyBlueSoft,
    foreground: AppColors.skyBlue,
    builder: (_) => const BulPatlatOyunu(),
    // Her seviyenin geçmişi ayrı tutulur (hız farklı).
    variants: [
      GameVariant(key: '${GameIds.bulPatlat}.l1', title: 'Seviye 1 · Yavaş'),
      GameVariant(
        key: '${GameIds.bulPatlat}.l2',
        title: 'Seviye 2 · Biraz Hızlı',
      ),
      GameVariant(key: '${GameIds.bulPatlat}.l3', title: 'Seviye 3 · Hızlı'),
    ],
  ),
  GameEntry(
    id: GameIds.harfArabalari,
    title: 'Harf Arabaları',
    subtitle: 'Sesi dinle, doğru harfli arabayı yakala',
    icon: Icons.directions_car_filled_rounded,
    background: AppColors.goldSoft,
    foreground: AppColors.gold,
    builder: (_) => const HarfArabalariOyunu(),
    // Her seviyenin geçmişi ayrı (seviye 2 = ilk sürümün hızı, eski anahtar).
    variants: [
      GameVariant(
        key: '${GameIds.harfArabalari}.l1',
        title: 'Seviye 1 · Yavaş',
      ),
      GameVariant(key: GameIds.harfArabalari, title: 'Seviye 2 · Biraz Hızlı'),
      GameVariant(
        key: '${GameIds.harfArabalari}.l3',
        title: 'Seviye 3 · Hızlı',
      ),
    ],
  ),
  GameEntry(
    id: kHarfDedektifiGameKey,
    title: 'Harf Dedektifi',
    subtitle: 'Harfleri farklı şekilleriyle ve kelimelerin içinde bul',
    icon: Icons.search_rounded,
    background: AppColors.sageSoft,
    foreground: AppColors.sage,
    builder: (_) => const HarfDedektifiScreen(),
    // Her mod ayrı oyun: puanlar yalnızca aynı modla karşılaştırılır.
    variants: [
      for (final mode in DetectiveMode.values)
        GameVariant(key: mode.gameKey, title: mode.title),
    ],
  ),
  GameEntry(
    id: 'harf_ciziyorum',
    title: 'Harf Çiziyorum',
    subtitle: 'İzini takip et, noktalarını koy, harfi öğren',
    icon: Icons.brush_rounded,
    background: AppColors.goldSoft,
    foreground: AppColors.gold,
    builder: (_) => const HarfCiziyorumScreen(),
    // Puan yok: harf başına en çok 2 yıldız, kendi başlangıç ekranında.
    variants: const [],
    showInResults: false,
  ),
  GameEntry(
    id: kHarfTreniGameKey,
    title: 'Harf Treni',
    subtitle: 'Aynı harfleri bul, vagonları doldur',
    icon: Icons.train_rounded,
    background: AppColors.turquoiseSoft,
    foreground: AppColors.turquoise,
    builder: (_) => const HarfTreniScreen(),
    // Her seviye ayrı oyun: puanlar yalnızca aynı seviyeyle karşılaştırılır.
    variants: [
      for (final level in TrainLevel.values)
        GameVariant(key: level.gameKey, title: 'Seviye ${level.number} · ${level.title}'),
    ],
  ),
  GameEntry(
    id: kArapcaYaziyorumGameKey,
    title: 'Arapça Yazıyorum',
    subtitle: 'Adını ve istediğin kelimeleri Arapça yaz',
    icon: Icons.keyboard_rounded,
    background: AppColors.sageSoft,
    foreground: AppColors.sage,
    builder: (_) => const ArapcaYaziyorumScreen(),
    // Yalnızca "Bak ve Yaz" puanlanır; ad ve serbest yazı puansız.
    variants: const [GameVariant(key: kBakYazGameKey, title: 'Bak ve Yaz')],
  ),
];
