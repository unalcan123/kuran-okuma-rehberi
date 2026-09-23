import 'game_texts.dart';
import 'package:flutter/material.dart';

import 'profil/player_picker.dart';

/// Harf oyunlarının (Bul & Patlat, Harf Arabaları) ortak giriş ve sonuç panelleri.
const Color kGameInk = Color(0xFF0B2452);
const Color kGameAccent = Color(0xFF3F9C8F);

class GamePanel extends StatelessWidget {
  const GamePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

/// Kısa giriş: oyun adı, tek cümle açıklama, aktif oyuncu ve BAŞLA.
class GameIntroPanel extends StatelessWidget {
  const GameIntroPanel({
    super.key,
    required this.title,
    required this.description,
    required this.onStart,
    this.extra,
  });

  final String title;
  final String description;
  final VoidCallback onStart;

  /// BAŞLA'nın üstünde gösterilecek ek içerik (örn. seviye seçici).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final l = const GameTexts();
    return GamePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: kGameInk,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.35,
              color: kGameInk.withValues(alpha: 0.85),
            ),
          ),
          if (extra != null) ...[const SizedBox(height: 12), extra!],
          const SizedBox(height: 8),
          const PlayerChip(),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              l.bpStart,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: kGameAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sade sonuç: başlık, yıldızlar, istatistikler, tekrar oyna / oyunlara dön.
class GameResultPanel extends StatelessWidget {
  const GameResultPanel({
    super.key,
    required this.title,
    required this.stars,
    required this.stats,
    required this.footer,
    required this.onReplay,
    required this.onBack,
    this.onLeaderboard,
    this.playerName,
    this.extra,
    this.online,
  });

  final String title;
  final int stars;

  /// (etiket, değer) çiftleri.
  final List<(String, String)> stats;
  final String footer;
  final VoidCallback onReplay;
  final VoidCallback onBack;
  final VoidCallback? onLeaderboard;

  /// Sonucun yazıldığı oyuncu (varsa küçük not).
  final String? playerName;

  /// TEKRAR OYNA'nın üstünde gösterilecek ek içerik (örn. seviye seçici).
  final Widget? extra;

  /// İstatistiklerin altındaki çevrimiçi "Genel Sıralama" bölümü.
  final Widget? online;

  @override
  Widget build(BuildContext context) {
    final l = const GameTexts();
    Widget stat((String, String) s) => SizedBox(
      width: 118,
      child: Column(
        children: [
          Text(
            s.$2,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: kGameInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.$1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: kGameInk.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );

    return GamePanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kGameInk,
            ),
          ),
          if (playerName != null) ...[
            const SizedBox(height: 2),
            Text(
              playerName!,
              style: TextStyle(
                fontSize: 14,
                color: kGameInk.withValues(alpha: 0.65),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // En az 1 yıldız: oyunu bitiren çocuk "başarısız" görünmez.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 3; i++)
                Icon(
                  i <= stars ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 38,
                  color: const Color(0xFFE0B040),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 12,
            children: [for (final s in stats) stat(s)],
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kGameInk.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
          if (online != null) online!,
          if (extra != null) ...[const SizedBox(height: 10), extra!],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onReplay,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.playAgain),
            style: FilledButton.styleFrom(
              backgroundColor: kGameAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          if (onLeaderboard != null)
            TextButton.icon(
              onPressed: onLeaderboard,
              icon: const Icon(Icons.emoji_events_outlined, size: 20),
              label: Text(l.lbTitle),
              style: TextButton.styleFrom(foregroundColor: kGameInk),
            ),
          TextButton(
            onPressed: onBack,
            child: Text(
              l.bpBackToGames,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: kGameInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3 seviyelik seçici (1 yavaş, 2 biraz hızlı, 3 hızlı).
class GameLevelPicker extends StatelessWidget {
  const GameLevelPicker({
    super.key,
    required this.level,
    required this.onChanged,
    required this.levelWord,
    required this.labels,
  });

  final int level;
  final ValueChanged<int> onChanged;

  /// "Seviye" kelimesi.
  final String levelWord;

  /// Seviye 1, 2, 3 için kısa adlar (Yavaş, Biraz Hızlı, Hızlı).
  final List<String> labels;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 6,
    children: [
      for (var i = 1; i <= labels.length; i++)
        ChoiceChip(
          key: Key('level-$i'),
          label: Text('$levelWord $i · ${labels[i - 1]}'),
          selected: level == i,
          selectedColor: const Color(0xFFBFE3DC),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kGameInk,
          ),
          onSelected: (_) => onChanged(i),
        ),
    ],
  );
}
