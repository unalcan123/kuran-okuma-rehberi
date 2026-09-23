import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/leaderboard/leaderboard_service.dart';
import '../game_texts.dart';
import 'player_models.dart';
import 'player_repository.dart';

const Color _ink = Color(0xFF0B2452);

/// "Oyuncu Adın" alt sayfası: cihaz başına tek oyuncu. İlk kez ad verilir,
/// sonra yalnızca düzeltilir (skorlar ve sıralamadaki yer korunur).
Future<void> showPlayerNameSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFFFFBF2),
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => const PlayerNameSheet(),
  );
}

/// Ad henüz verilmediyse (ve bu oturumda sorulmadıysa) bir kez sorar. Oyunlar
/// menüsü açılınca ve harf oyunlarında BAŞLA'da çağrılır.
Future<void> ensureActivePlayer(BuildContext context) async {
  final repo = context.read<PlayerRepository>();
  if (!repo.loaded) await repo.load();
  if (!context.mounted) return;
  if (repo.activePlayer != null || repo.promptedThisSession) return;
  repo.promptedThisSession = true;
  await showPlayerNameSheet(context);
}

/// Küçük "Oyuncu: Elif ✎" düğmesi (dokununca ad düzeltilir).
class PlayerChip extends StatelessWidget {
  const PlayerChip({super.key, this.color = _ink});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const l = GameTexts();
    return Consumer<PlayerRepository>(
      builder: (context, repo, _) {
        final player = repo.activePlayer;
        final avatar = player == null ? null : avatarById(player.avatarId);
        return InkWell(
          key: const Key('player-chip'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => showPlayerNameSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  avatar?.icon ?? Icons.person_outline_rounded,
                  size: 20,
                  color: avatar?.color ?? color,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    player == null
                        ? l.plEnterName
                        : '${l.plLabel}: ${player.displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit_rounded, size: 16, color: color),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlayerNameSheet extends StatefulWidget {
  const PlayerNameSheet({super.key});

  @override
  State<PlayerNameSheet> createState() => _PlayerNameSheetState();
}

class _PlayerNameSheetState extends State<PlayerNameSheet> {
  late final TextEditingController _name = TextEditingController(
    text: context.read<PlayerRepository>().activePlayer?.displayName ?? '',
  );
  PlayerNameError? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _errorText(GameTexts l, PlayerNameError e) => switch (e) {
    PlayerNameError.empty => l.plErrEmpty,
    PlayerNameError.tooShort => l.plErrShort,
    PlayerNameError.tooLong => l.plErrLong,
    PlayerNameError.invalidChars => l.plErrChars,
    PlayerNameError.notAllowed => l.plErrNotAllowed,
    PlayerNameError.taken => l.plErrTaken,
  };

  Future<void> _save() async {
    final repo = context.read<PlayerRepository>();
    final online = maybeLeaderboardService(context);
    final before = repo.activePlayer;
    final error = await repo.setName(_name.text);
    if (error != null) {
      if (mounted) setState(() => _error = error);
      return;
    }
    final after = repo.activePlayer!;
    // Ad düzeltildiyse çevrimiçi sıralamadaki ad da güncellenir.
    if (online != null &&
        before != null &&
        before.displayName != after.displayName) {
      unawaited(online.renamePlayer(after.id, after.displayName));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const l = GameTexts();
    final hasName = context.watch<PlayerRepository>().activePlayer != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.plNameLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.plNameIntro,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: _ink.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('player-name-field'),
                controller: _name,
                autofocus: !hasName,
                maxLength: PlayerRepository.maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: l.plNameLabel,
                  helperText: l.plNameHint,
                  errorText: _error == null ? null : _errorText(l, _error!),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('save-player-name'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3F9C8F),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(hasName ? l.plSave : l.plContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
