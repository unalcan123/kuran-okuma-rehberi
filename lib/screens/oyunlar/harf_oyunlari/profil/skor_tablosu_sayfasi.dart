import '../game_texts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'player_models.dart';
import 'player_picker.dart';
import 'player_repository.dart';

/// Bu cihazdaki oyuncuların, OYUN BAŞINA ayrı "İlk 10" skor tablosu.
///
/// Sıralama kişisel en iyi skorlara göredir; çocukları agresif rekabete
/// yönlendiren ifade (kaybettin, sonuncusun…) yoktur. Aktif oyuncunun satırı
/// hafifçe vurgulanır ("Sen"). Online/global sıralama bilerek YOKTUR.
class SkorTablosuSayfasi extends StatefulWidget {
  const SkorTablosuSayfasi({super.key, this.initialGameId = GameIds.bulPatlat});

  static String route = 'SkorTablosu';

  final String initialGameId;

  @override
  State<SkorTablosuSayfasi> createState() => _SkorTablosuSayfasiState();
}

class _SkorTablosuSayfasiState extends State<SkorTablosuSayfasi> {
  static const Color _ink = Color(0xFF0B2452);
  late String _gameId = widget.initialGameId;

  String _gameName(GameTexts l, String id) => switch (id) {
    GameIds.harfArabalari => l.haGame,
    _ => l.bpGame,
  };

  @override
  Widget build(BuildContext context) {
    final l = const GameTexts();
    final repo = context.watch<PlayerRepository>();
    final active = repo.activePlayer;
    final entries = repo.leaderboard(_gameId);
    final myEntry = active == null ? null : repo.entryOf(active.id, _gameId);
    final myOutsideTop = myEntry != null && myEntry.rank > entries.length;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F9C8F),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l.lbTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final id in GameIds.leaderboardGames)
                        ChoiceChip(
                          key: Key('game-$id'),
                          label: Text(_gameName(l, id)),
                          selected: id == _gameId,
                          selectedColor: const Color(0xFFBFE3DC),
                          onSelected: (_) => setState(() => _gameId = id),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${l.lbTop10} · ${l.lbDeviceNote}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: _ink.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  child:
                      entries.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l.lbEmpty,
                                key: const Key('leaderboard-empty'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: _ink.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          )
                          : ListView(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                            children: [
                              for (final e in entries)
                                _row(l, e, isMe: e.profile.id == active?.id),
                              if (myOutsideTop) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    '${l.lbYourRank}:',
                                    style: TextStyle(
                                      color: _ink.withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                _row(l, myEntry, isMe: true),
                              ],
                            ],
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PlayerChip(color: _ink.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(GameTexts l, LeaderboardEntry e, {required bool isMe}) {
    final medal = switch (e.rank) {
      1 => const Color(0xFFE0B040),
      2 => const Color(0xFFB7C2CC),
      3 => const Color(0xFFD1996C),
      _ => null,
    };
    return Padding(
      key: Key('row-${e.profile.displayName}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDDF0EC) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isMe ? const Color(0xFF3F9C8F) : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (medal ?? _ink).withValues(
                  alpha: medal == null ? 0.08 : 0.28,
                ),
              ),
              child: Text(
                '${e.rank}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            PlayerAvatarDot(e.profile.avatarId, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                e.profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            if (isMe)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F9C8F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l.plYou,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Text(
              '${e.stats.bestScore}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
