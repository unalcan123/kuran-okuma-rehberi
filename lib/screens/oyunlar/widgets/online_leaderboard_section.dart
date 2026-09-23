import 'package:flutter/material.dart';

import '../../../services/leaderboard/leaderboard_models.dart';
import '../harf_oyunlari/game_panels.dart';
import '../harf_oyunlari/game_texts.dart';

/// Oyun sonu panelindeki "Genel Sıralama" bölümü (tüm oyunlar için ortak):
/// ilk 10, oyuncunun kendi satırı ("SEN"), "N oyuncu arasında K. sıradasın".
/// Yüklenirken / çevrimdışıyken / hata olduğunda sakin bir mesaj ve
/// "Tekrar dene" gösterir; hiçbir durumda oyunu engellemez.
class OnlineLeaderboardSection extends StatefulWidget {
  const OnlineLeaderboardSection({
    super.key,
    required this.request,
    required this.onRetry,
    this.showHeader = true,
    this.hideWhenUnavailable = true,
  });

  /// Üstteki çizgi + "Genel Sıralama" başlığı (ayrı sayfada başlık zaten var).
  final bool showHeader;

  /// Çevrimiçi sıralama yoksa bölüm hiç görünmez (oyun sonu); `false` ise
  /// "yüklenemiyor" mesajı gösterilir (Genel Sıralama sayfası).
  final bool hideWhenUnavailable;

  /// Oyun sonunda başlatılan gönder + yükle isteği.
  final Future<OnlineOutcome> request;

  /// "Tekrar dene" (bekleyen skoru gönderir, sıralamayı yeniden yükler).
  final Future<OnlineOutcome> Function() onRetry;

  @override
  State<OnlineLeaderboardSection> createState() =>
      _OnlineLeaderboardSectionState();
}

class _OnlineLeaderboardSectionState extends State<OnlineLeaderboardSection> {
  OnlineOutcome? _outcome;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listen(widget.request);
  }

  @override
  void didUpdateWidget(covariant OnlineLeaderboardSection old) {
    super.didUpdateWidget(old);
    if (!identical(old.request, widget.request)) _listen(widget.request);
  }

  int _token = 0;

  /// initState / didUpdateWidget / _retry içinden çağrılır: build zaten
  /// ardından geleceği için `_loading` doğrudan atanır. Eski bir istek geç
  /// dönerse ([_token] değişmişse) yok sayılır.
  void _listen(Future<OnlineOutcome> f) {
    final token = ++_token;
    _loading = true;
    f
        .then<OnlineOutcome>(
          (o) => o,
          onError: (_) => const OnlineOutcome(OnlineStatus.loadFailed),
        )
        .then((o) {
          if (!mounted || token != _token) return;
          setState(() {
            _outcome = o;
            _loading = false;
          });
        });
  }

  void _retry() => setState(() => _listen(widget.onRetry()));

  @override
  Widget build(BuildContext context) {
    const l = GameTexts();
    var outcome = _outcome;
    final unavailable =
        outcome == null ||
        outcome.status == OnlineStatus.unavailable ||
        outcome.status == OnlineStatus.rejected;
    if (!_loading && unavailable) {
      if (widget.hideWhenUnavailable) return const SizedBox.shrink();
      outcome = const OnlineOutcome(OnlineStatus.loadFailed);
    }

    final Widget body;
    if (_loading) {
      body = _Message(
        key: const Key('online-loading'),
        leading: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
        text: l.onLoading,
      );
    } else {
      body = switch (outcome!.status) {
        OnlineStatus.ranked => _Ranking(snapshot: outcome.snapshot!),
        OnlineStatus.savedOffline => _Message(
          key: const Key('online-offline'),
          leading: const Icon(Icons.cloud_off_rounded, size: 20),
          text: l.onOffline,
          onRetry: _retry,
        ),
        OnlineStatus.loadFailed => _Message(
          key: const Key('online-failed'),
          leading: const Icon(Icons.cloud_queue_rounded, size: 20),
          text: l.onLoadFailed,
          onRetry: _retry,
        ),
        OnlineStatus.noPlayer => _Message(
          key: const Key('online-no-player'),
          leading: const Icon(Icons.person_outline_rounded, size: 20),
          text: l.onNoPlayer,
        ),
        OnlineStatus.invalidName => _Message(
          key: const Key('online-invalid-name'),
          leading: const Icon(Icons.info_outline_rounded, size: 20),
          text: l.onInvalidName,
        ),
        OnlineStatus.unavailable ||
        OnlineStatus.rejected => const SizedBox.shrink(),
      };
    }

    return Column(
      key: const Key('online-leaderboard'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          const SizedBox(height: 10),
          Divider(color: kGameInk.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFE0B040),
                size: 22,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.onTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: kGameInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        body,
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.leading,
    required this.text,
    this.onRetry,
  });

  final Widget leading;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    const l = GameTexts();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: kGameInk.withValues(alpha: 0.6)),
              child: leading,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: kGameInk.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
        if (onRetry != null)
          TextButton.icon(
            key: const Key('online-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l.onRetry),
            style: TextButton.styleFrom(foregroundColor: kGameAccent),
          ),
      ],
    );
  }
}

class _Ranking extends StatelessWidget {
  const _Ranking({required this.snapshot});

  final LeaderboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    const l = GameTexts();
    final me = snapshot.me;
    final meInTop = snapshot.meInTop;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot.top.isEmpty)
          Text(
            l.onEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: kGameInk.withValues(alpha: 0.7)),
          ),
        for (final r in snapshot.top)
          _RankRow(row: r, isMe: me != null && r.playerId == me.playerId),
        if (me != null && !meInTop) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: kGameInk.withValues(alpha: 0.35),
            ),
          ),
          _RankRow(row: me, isMe: true),
        ],
        const SizedBox(height: 8),
        Text(
          me != null
              ? l.onRankLine(me.rank, snapshot.totalPlayers)
              : l.onPlayers(snapshot.totalPlayers),
          key: const Key('online-rank-line'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kGameInk,
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row, required this.isMe});

  final LeaderboardRow row;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    const l = GameTexts();
    final medal = switch (row.rank) {
      1 => const Color(0xFFE0B040),
      2 => const Color(0xFFA9B4C2),
      3 => const Color(0xFFD29A6A),
      _ => null,
    };
    return Container(
      key: isMe ? const Key('online-me-row') : null,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFDDF0EC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '${row.rank}.',
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: medal ?? kGameInk.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                color: kGameInk,
              ),
            ),
          ),
          if (isMe)
            Container(
              margin: const EdgeInsets.only(left: 6, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: kGameAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l.onYou,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          Text(
            '${row.bestScore}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kGameInk,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
