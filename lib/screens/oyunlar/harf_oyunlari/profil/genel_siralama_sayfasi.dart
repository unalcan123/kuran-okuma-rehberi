import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/leaderboard/leaderboard_models.dart';
import '../../../../services/leaderboard/leaderboard_service.dart';
import '../../widgets/online_leaderboard_section.dart';
import '../game_texts.dart';
import 'player_models.dart';
import 'player_picker.dart';
import 'player_repository.dart';

/// Çevrimiçi "Genel Sıralama": oyun başına ilk 10, oyuncunun kendi sırası ve
/// toplam oyuncu. Oyunlar menüsünden ve oyun sonu panelinden açılır; oyun
/// bitmeden de bakılabilir. Açılışta bekleyen skorlar da gönderilir.
class GenelSiralamaSayfasi extends StatefulWidget {
  const GenelSiralamaSayfasi({
    super.key,
    this.initialGameId = GameIds.bulPatlat,
  });

  final String initialGameId;

  @override
  State<GenelSiralamaSayfasi> createState() => _GenelSiralamaSayfasiState();
}

class _GenelSiralamaSayfasiState extends State<GenelSiralamaSayfasi> {
  static const Color _ink = Color(0xFF0B2452);
  late String _gameId = widget.initialGameId;
  Future<OnlineOutcome>? _request;

  String _gameName(GameTexts l, String id) => switch (id) {
    GameIds.harfArabalari => l.haGame,
    _ => l.bpGame,
  };

  Future<OnlineOutcome> _load() {
    final service = maybeLeaderboardService(context);
    if (service == null) {
      return Future.value(const OnlineOutcome(OnlineStatus.unavailable));
    }
    return service.retry(
      profileId: context.read<PlayerRepository>().activePlayer?.id,
      gameId: _gameId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  void _select(String id) {
    if (id == _gameId) return;
    setState(() {
      _gameId = id;
      _request = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    const l = GameTexts();
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
            child: RefreshIndicator(
              onRefresh: () {
                final f = _load();
                setState(() => _request = f);
                return f;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  Wrap(
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
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                          onSelected: (_) => _select(id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Center(child: PlayerChip()),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: OnlineLeaderboardSection(
                      key: ValueKey(_gameId),
                      request: _request!,
                      onRetry: _load,
                      showHeader: false,
                      hideWhenUnavailable: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
