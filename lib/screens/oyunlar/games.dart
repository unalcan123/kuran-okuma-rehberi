import 'package:flutter/material.dart';

import '../../data/drag_drop_game_data.dart';
import '../../data/letters_data.dart';
import '../../data/memory_game_data.dart';
import '../../theme/app_colors.dart';
import 'drag_drop/drag_drop_levels_screen.dart';
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
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final WidgetBuilder builder;
  final List<GameVariant> variants;
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
];
