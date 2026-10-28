import '../../../../l10n/l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/leaderboard/leaderboard_service.dart';
import '../../../../services/leaderboard/nickname_policy.dart';
import '../game_texts.dart';
import 'player_models.dart';
import 'player_repository.dart';

const Color _ink = Color(0xFF0B2452);

/// "Oyuncu Adın" alt sayfası: cihaz başına tek oyuncu. İlk kez ad verilir,
/// sonra yalnızca düzeltilir (skorlar ve sıralamadaki yer korunur).
Future<void> showPlayerNameSheet(BuildContext context, {String? conflictName}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFFFFBF2),
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => PlayerNameSheet(conflictName: conflictName),
  );
}

/// Ad henüz verilmediyse (ve bu oturumda sorulmadıysa) bir kez sorar. Oyunlar
/// menüsü açılınca ve harf oyunlarında BAŞLA'da çağrılır.
Future<void> ensureActivePlayer(BuildContext context) async {
  final repo = context.read<PlayerRepository>();
  if (!repo.loaded) await repo.load();
  if (!context.mounted) return;
  final player = repo.activePlayer;
  final online = maybeLeaderboardService(context);
  if (player != null) {
    if (online == null) return;
    final conflict = await online.nameConflictFor(player.id);
    if (!context.mounted) return;
    if (conflict != null &&
        conflict == player.displayName &&
        !repo.promptedThisSession) {
      repo.promptedThisSession = true;
      await showPlayerNameSheet(context, conflictName: conflict);
      return;
    }
    if (!await online.isClaimed(player.id, player.displayName)) {
      unawaited(
        online.claimName(player.id, player.displayName, remember: true),
      );
    }
    return;
  }
  if (repo.promptedThisSession) return;
  repo.promptedThisSession = true;
  await showPlayerNameSheet(context);
}

/// Küçük "Oyuncu: Elif ✎" düğmesi (dokununca ad düzeltilir).
class PlayerChip extends StatelessWidget {
  const PlayerChip({super.key, this.color = _ink});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = GameTexts.of(context);
    return Consumer<PlayerRepository>(
      builder: (context, repo, _) {
        final player = repo.activePlayer;
        final avatar = player == null ? null : avatarById(player.avatarId);
        return InkWell(
          key: const Key('player-chip'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => showPlayerNameSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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
                        : l.playerLine(player.displayName),
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
  const PlayerNameSheet({super.key, this.conflictName});

  /// Ad başka bir oyuncuda çıktıysa o ad (nazik not + öneriler).
  final String? conflictName;

  @override
  State<PlayerNameSheet> createState() => _PlayerNameSheetState();
}

class _PlayerNameSheetState extends State<PlayerNameSheet> {
  late final TextEditingController _name = TextEditingController(
    text: context.read<PlayerRepository>().activePlayer?.displayName ?? '',
  );
  PlayerNameError? _error;
  List<String> _suggestions = const [];
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final conflict = widget.conflictName;
    final online = maybeLeaderboardService(context);
    if (conflict != null && online != null) {
      final id = context.read<PlayerRepository>().claimId;
      online.suggestionsFor(id, conflict).then((list) {
        if (mounted) setState(() => _suggestions = list);
      });
    }
  }

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
    PlayerNameError.takenOnline => context.t(
      'Bu ad başka bir oyuncuda. Aşağıdakilerden birini seçebilir ya da yeni bir ad yazabilirsin.',
    ),
  };

  Future<void> _save() async {
    if (_checking) return;
    final repo = context.read<PlayerRepository>();
    final online = maybeLeaderboardService(context);
    final before = repo.activePlayer;
    final localError = repo.validateName(_name.text, forRename: true);
    if (localError != null) {
      setState(() {
        _error = localError;
        _suggestions = const [];
      });
      return;
    }
    final name = PlayerRepository.normalizeName(_name.text);
    final sameKey =
        before != null &&
        NicknamePolicy.claimKey(before.displayName) ==
            NicknamePolicy.claimKey(name);
    // Ad bütün oyuncular arasında tek olmalı: alınmışsa öneri göster.
    if (online != null && (!sameKey || widget.conflictName != null)) {
      setState(() => _checking = true);
      final claim = await online.claimName(
        repo.claimId,
        name,
        previous: before?.displayName,
      );
      if (!mounted) return;
      setState(() => _checking = false);
      if (claim.status == NameClaimStatus.taken) {
        setState(() {
          _error = PlayerNameError.takenOnline;
          _suggestions = claim.suggestions;
        });
        return;
      }
    }
    final error = await repo.setName(name);
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

  void _pick(String suggestion) {
    _name.text = suggestion;
    _name.selection = TextSelection.collapsed(offset: suggestion.length);
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = GameTexts.of(context);
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
                context.t(l.plNameLabel),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.t(l.plNameIntro),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: _ink.withValues(alpha: 0.75),
                ),
              ),
              if (widget.conflictName != null) ...[
                const SizedBox(height: 10),
                Container(
                  key: const Key('player-name-conflict'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    context.t(
                      '“{name}” adını başka bir oyuncu daha önce almış. Lütfen kendine yeni bir ad seç.',
                      {'name': widget.conflictName},
                    ),
                    style: const TextStyle(color: _ink, height: 1.3),
                  ),
                ),
              ],
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
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  context.t('Öneriler'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in _suggestions)
                      ActionChip(
                        key: Key('name-suggestion-$suggestion'),
                        label: Text(suggestion), // l10n-ignore
                        avatar: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                        ),
                        onPressed: () => _pick(suggestion),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('save-player-name'),
                onPressed: _checking ? null : _save,
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
