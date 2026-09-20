import '../game_texts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'player_models.dart';
import 'player_repository.dart';

const Color _ink = Color(0xFF0B2452);

/// "Kim oynuyor?" alt sayfasını açar: oyuncu seç, yeni oyuncu ekle, sil.
Future<void> showPlayerPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFFFFBF2),
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => const PlayerPickerSheet(),
  );
}

/// Aktif oyuncu yoksa (ve bu oturumda hâlâ sorulmadıysa) bir kez sorar. Profil
/// varsa hiçbir şey sormaz: her oyun açılışında isim istenmez.
Future<void> ensureActivePlayer(BuildContext context) async {
  final repo = context.read<PlayerRepository>();
  if (repo.activePlayer != null || repo.promptedThisSession) return;
  repo.promptedThisSession = true;
  await showPlayerPicker(context);
}

/// Küçük "Oyuncu: Elif ▼" düğmesi.
class PlayerChip extends StatelessWidget {
  const PlayerChip({super.key, this.color = _ink});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = const GameTexts();
    return Consumer<PlayerRepository>(
      builder: (context, repo, _) {
        final player = repo.activePlayer;
        final avatar = player == null ? null : avatarById(player.avatarId);
        return InkWell(
          key: const Key('player-chip'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => showPlayerPicker(context),
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
                        ? l.plSelect
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
                Icon(Icons.arrow_drop_down_rounded, color: color),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlayerPickerSheet extends StatefulWidget {
  const PlayerPickerSheet({super.key});

  @override
  State<PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<PlayerPickerSheet> {
  final TextEditingController _name = TextEditingController();
  String _avatarId = kPlayerAvatars.first.id;
  bool? _creating; // null: ilk kurulumda, profil yoksa doğrudan form
  PlayerNameError? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _errorText(GameTexts l, PlayerNameError e) => switch (e) {
    PlayerNameError.empty => l.plErrEmpty,
    PlayerNameError.tooLong => l.plErrLong,
    PlayerNameError.taken => l.plErrTaken,
  };

  Future<void> _create(PlayerRepository repo) async {
    final error = repo.validateName(_name.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await repo.createProfile(_name.text, _avatarId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete(PlayerRepository repo, PlayerProfile p) async {
    final l = const GameTexts();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l.plDeleteTitle),
            content: Text('${p.displayName}\n${l.plDeleteBody}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.plCancel),
              ),
              TextButton(
                key: const Key('confirm-delete'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.plDelete),
              ),
            ],
          ),
    );
    if (ok == true) await repo.deleteProfile(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = const GameTexts();
    final repo = context.watch<PlayerRepository>();
    final creating = _creating ?? repo.profiles.isEmpty;

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
                l.plWhoPlays,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 12),
              if (creating) ..._buildForm(l, repo) else ..._buildList(l, repo),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList(GameTexts l, PlayerRepository repo) {
    return [
      for (final p in repo.profiles)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color:
                p.id == repo.activePlayer?.id
                    ? const Color(0xFFDDF0EC)
                    : Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              key: Key('player-${p.displayName}'),
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await repo.selectProfile(p.id);
                if (mounted) Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                child: Row(
                  children: [
                    _AvatarDot(avatarById(p.avatarId), size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                    if (p.id == repo.activePlayer?.id)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF3F9C8F),
                      ),
                    IconButton(
                      key: Key('delete-${p.displayName}'),
                      tooltip: l.plDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: _ink.withValues(alpha: 0.45),
                      ),
                      onPressed: () => _confirmDelete(repo, p),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      const SizedBox(height: 4),
      FilledButton.icon(
        key: const Key('new-player'),
        onPressed:
            () => setState(() {
              _creating = true;
              _error = null;
            }),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.plNewPlayer.replaceFirst('+ ', '')),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3F9C8F),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    ];
  }

  List<Widget> _buildForm(GameTexts l, PlayerRepository repo) {
    return [
      TextField(
        key: const Key('player-name-field'),
        controller: _name,
        autofocus: repo.profiles.isEmpty,
        maxLength: PlayerRepository.maxNameLength,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _create(repo),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          labelText: l.plNameLabel,
          helperText: l.plNameHint,
          errorText: _error == null ? null : _errorText(l, _error!),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        l.plChooseIcon,
        style: TextStyle(color: _ink.withValues(alpha: 0.7), fontSize: 13),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          for (final a in kPlayerAvatars)
            GestureDetector(
              key: Key('avatar-${a.id}'),
              onTap: () => setState(() => _avatarId = a.id),
              child: _AvatarDot(a, size: 48, selected: a.id == _avatarId),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          if (repo.profiles.isNotEmpty) ...[
            Expanded(
              child: OutlinedButton(
                onPressed:
                    () => setState(() {
                      _creating = false;
                      _error = null;
                    }),
                child: Text(l.plCancel),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              key: const Key('create-player'),
              onPressed: () => _create(repo),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3F9C8F),
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.plCreate),
            ),
          ),
        ],
      ),
    ];
  }
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot(this.avatar, {required this.size, this.selected = false});

  final PlayerAvatar avatar;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: avatar.color.withValues(alpha: 0.22),
      border: Border.all(
        color: selected ? _ink : avatar.color.withValues(alpha: 0.5),
        width: selected ? 3 : 1.5,
      ),
    ),
    child: Icon(avatar.icon, color: avatar.color, size: size * 0.55),
  );
}

/// Skor tablosu ve sonuç panelinde kullanılan avatar.
class PlayerAvatarDot extends StatelessWidget {
  const PlayerAvatarDot(this.avatarId, {super.key, this.size = 36});

  final String avatarId;
  final double size;

  @override
  Widget build(BuildContext context) =>
      _AvatarDot(avatarById(avatarId), size: size);
}
