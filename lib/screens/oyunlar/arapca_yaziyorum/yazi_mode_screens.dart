import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/game_score.dart';
import '../../../services/audio_service.dart';
import '../../../services/game_score_store.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_theme.dart';
import '../harf_oyunlari/profil/player_repository.dart';
import 'png_saver.dart';
import 'widgets/name_card.dart';
import 'widgets/writing_pad.dart';
import 'yazi_data.dart';
import 'yazi_store.dart';
import 'yazi_text.dart';

typedef PngSaver =
    Future<SaveResult> Function(Uint8List bytes, String fileName);

String? _profileIdOf(BuildContext context) {
  try {
    return context.read<PlayerRepository>().activePlayer?.id;
  } catch (_) {
    return null;
  }
}

/// Ortak: başlık, ses düğmesi, taslak kaydı, "Temizle" + geri al.
mixin _WritingScreen<T extends StatefulWidget> on State<T> {
  final controller = TextEditingController();
  final store = YaziStore();
  bool muted = false;
  Timer? _draftTimer;

  /// Ekran açılırken bir kez alınır: kapanırken (dispose) context'e
  /// dokunmak güvenli değildir.
  late final AudioService audio = context.read<AudioService>();
  late final String? profileId = _profileIdOf(context);

  /// Taslağı saklanacak mod (null = saklanmaz).
  String? get draftMode;

  void initWriting() {
    // late final alanları şimdi (context geçerliyken) doldur.
    audio;
    profileId;
    store.getBool(YaziStore.mutedKey).then((m) {
      if (mounted) {
        setState(() => muted = m);
      }
    });
    final mode = draftMode;
    if (mode != null) {
      store.loadDraft(profileId, mode).then((text) {
        if (mounted && controller.text.isEmpty && text.isNotEmpty) {
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      });
    }
  }

  void onEdited() {
    final mode = draftMode;
    if (mode == null) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 600), () {
      store.saveDraft(profileId, mode, controller.text);
    });
  }

  void disposeWriting() {
    _draftTimer?.cancel();
    _noticeTimer?.cancel();
    final mode = draftMode;
    if (mode != null) {
      store.saveDraft(profileId, mode, controller.text);
    }
    controller.dispose();
    Future.microtask(audio.stop);
  }

  Future<void> toggleMute() async {
    setState(() => muted = !muted);
    if (muted) await audio.stop();
    await store.setBool(YaziStore.mutedKey, muted);
  }

  // Kısa mesajlar yazı alanının ÜSTÜNDE gösterilir: alttan açılan bir
  // bildirim klavyenin Sil/Boşluk satırını kapatırdı.
  String? notice;
  String? noticeActionLabel;
  VoidCallback? noticeAction;
  Timer? _noticeTimer;

  void showNotice(
    String text, {
    String? actionLabel,
    VoidCallback? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _noticeTimer?.cancel();
    setState(() {
      notice = text;
      noticeActionLabel = actionLabel;
      noticeAction = action;
    });
    _noticeTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          notice = null;
          noticeAction = null;
        });
      }
    });
  }

  void snack(String text) => showNotice(text);

  void clearWithUndo() {
    final previous = controller.value;
    if (previous.text.isEmpty) return;
    controller.value = const TextEditingValue();
    onEdited();
    showNotice(
      'Yazı temizlendi.',
      actionLabel: 'Geri Al',
      duration: const Duration(seconds: 5),
      action: () {
        if (!mounted) return;
        controller.value = previous;
        onEdited();
        _noticeTimer?.cancel();
        setState(() {
          notice = null;
          noticeAction = null;
        });
      },
    );
  }

  Widget noticeBar(BuildContext context) => SizedBox(
    // Alçak ekranda boşken yer kaplamaz.
    height: notice == null && MediaQuery.sizeOf(context).height < 500 ? 0 : 40,
    child:
        notice == null
            ? null
            : Semantics(
              liveRegion: true,
              child: Container(
                key: const ValueKey('notice'),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.skyBlueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.navySoft,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notice!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (noticeAction != null)
                      TextFieldTapRegion(
                        child: TextButton(
                          key: const ValueKey('notice-action'),
                          onPressed: noticeAction,
                          child: Text(noticeActionLabel ?? ''),
                        ),
                      ),
                  ],
                ),
              ),
            ),
  );

  PreferredSizeWidget appBar(String title) => AppBar(
    title: Text(title),
    actions: [
      IconButton(
        key: const ValueKey('mute-button'),
        tooltip: muted ? 'Sesi aç' : 'Sesi kapat',
        onPressed: toggleMute,
        icon: Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: AppColors.navy,
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}

Widget _body(Widget child) => SafeArea(
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: child,
      ),
    ),
  ),
);

/// Yönerge + düğmeler: geniş ekranda tek satır, dar ekranda iki satır.
Widget _header(BuildContext context, String text, List<Widget> buttons) =>
    MediaQuery.sizeOf(context).width >= 600
        ? Row(
          children: [Expanded(child: _instruction(context, text)), ...buttons],
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _instruction(context, text),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons),
          ],
        );

Widget _instruction(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  ),
);

// ---------------------------------------------------------------------------
// A — Adını Yaz

class NameModeScreen extends StatefulWidget {
  const NameModeScreen({super.key, this.saver = savePng});

  final PngSaver saver;

  @override
  State<NameModeScreen> createState() => _NameModeScreenState();
}

class _NameModeScreenState extends State<NameModeScreen> with _WritingScreen {
  final _cardKey = GlobalKey();
  bool _showCard = false;
  int _palette = 0;
  CardFrame _frame = CardFrame.simple;
  bool _saving = false;

  @override
  String? get draftMode => 'ad';

  @override
  void initState() {
    super.initState();
    initWriting();
  }

  @override
  void dispose() {
    disposeWriting();
    super.dispose();
  }

  void _finish() {
    if (controller.text.trim().isEmpty) {
      snack('Önce adını yaz.');
      return;
    }
    setState(() => _showCard = true);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final png = await renderCardPng(_cardKey);
      if (png == null) {
        snack('Görsel oluşturulamadı.');
        return;
      }
      final result = await widget.saver(
        Uint8List.fromList(png),
        'arapca-isim-karti',
      );
      switch (result.outcome) {
        case SaveOutcome.saved:
          snack('Kaydedildi: ${result.location ?? ''}');
        case SaveOutcome.unsupported:
          snack(
            'Bu cihazda görsel kaydetme henüz yok. Ekran görüntüsü alabilirsin.',
          );
        case SaveOutcome.failed:
          snack('Kaydedilemedi. Bir daha dene.');
      }
    } catch (_) {
      snack('Kaydedilemedi. Bir daha dene.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar('Adını Arapça yaz!'),
    body: _body(_showCard ? _card(context) : _writing(context)),
  );

  Widget _writing(BuildContext context) => WritingPad(
    controller: controller,
    maxLength: kNameMaxLength,
    muted: muted,
    multiline: false,
    fontSize: 48,
    onUserEdit: onEdited,
    header: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, 'Harfleri seç, adını oluştur!', [
          OutlinedButton(
            key: const ValueKey('clear-button'),
            onPressed: clearWithUndo,
            child: const Text('Temizle'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            key: const ValueKey('done-button'),
            onPressed: _finish,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Bitirdim'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise),
          ),
        ]),
        const SizedBox(height: 4),
        noticeBar(context),
        const SizedBox(height: 4),
        const SizedBox(height: 6),
      ],
    ),
  );

  Widget _card(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        noticeBar(context),
        const SizedBox(height: 6),
        RepaintBoundary(
          key: _cardKey,
          child: NameCard(
            name: controller.text,
            palette: _palette,
            frame: _frame,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          children: [
            for (var i = 0; i < kCardPalettes.length; i++)
              Semantics(
                button: true,
                selected: i == _palette,
                label: 'Renk ${i + 1}',
                child: InkWell(
                  key: ValueKey('palette-$i'),
                  onTap: () => setState(() => _palette = i),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kCardPalettes[i].$1,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kCardPalettes[i].$2,
                        width: i == _palette ? 4 : 2,
                      ),
                    ),
                    child:
                        i == _palette
                            ? Icon(
                              Icons.check_rounded,
                              color: kCardPalettes[i].$2,
                            )
                            : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final f in CardFrame.values)
              ChoiceChip(
                key: ValueKey('frame-${f.name}'),
                label: Text(f.label),
                selected: f == _frame,
                onSelected: (_) => setState(() => _frame = f),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              key: const ValueKey('save-card-button'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Görsel olarak kaydet'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.turquoise,
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('edit-button'),
              onPressed: () => setState(() => _showCard = false),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Düzenle'),
            ),
          ],
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// B — Bak ve Yaz

class CopyModeScreen extends StatefulWidget {
  const CopyModeScreen({super.key, this.random});

  final math.Random? random;

  @override
  State<CopyModeScreen> createState() => _CopyModeScreenState();
}

enum _CheckState { none, correct, wrong }

class _CopyModeScreenState extends State<CopyModeScreen> with _WritingScreen {
  late final math.Random _random = widget.random ?? math.Random();
  late List<CopyTask> _tasks = buildCopyTasks(_random);
  int _index = 0;
  bool _hintUsed = false;
  String? _highlight;
  String? _message;
  _CheckState _check = _CheckState.none;
  int _independent = 0;
  int _withHint = 0;
  bool _finished = false;
  bool _saved = false;
  GameResult? _result;
  GameSubmission? _submission;

  CopyTask get _task => _tasks[_index];

  @override
  String? get draftMode => null;

  @override
  void initState() {
    super.initState();
    initWriting();
  }

  @override
  void dispose() {
    disposeWriting();
    super.dispose();
  }

  void _hint() {
    final (:next, :wrongFrom) = nextNeeded(controller.text, _task.text);
    setState(() {
      if (wrongFrom != null) {
        _highlight = null;
        _message = 'Bir yerde farklı bir harf var. Sondan silip tekrar dene.';
      } else if (next == null) {
        _highlight = null;
        _message = 'Hepsini yazdın gibi. "Kontrol Et"e bas.';
      } else {
        _hintUsed = true;
        _highlight = next;
        _message = 'İpucu: parlayan tuşa bas.';
      }
    });
  }

  void _checkAnswer() {
    if (controller.text.trim().isEmpty) {
      setState(() => _message = 'Önce örneği yaz.');
      return;
    }
    final ok = sameArabic(controller.text, _task.text);
    setState(() {
      _highlight = null;
      _check = ok ? _CheckState.correct : _CheckState.wrong;
      _message =
          ok
              ? 'Harika! Aynısını yazdın.'
              : 'Bir daha bakalım! Örneğe dikkatle bak. Yazın silinmedi.';
    });
    if (!ok) return;
    if (_hintUsed) {
      _withHint++;
    } else {
      _independent++;
    }
    store.recordCopy(profileId, _task.text, withHint: _hintUsed);
  }

  void _next({bool skip = false}) {
    if (_index + 1 >= _tasks.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _hintUsed = false;
      _highlight = null;
      _message = null;
      _check = _CheckState.none;
      controller.value = const TextEditingValue();
    });
  }

  void _finish() {
    final done = _independent + _withHint;
    final result = GameResult(
      points: done * 10,
      firstTry: _independent,
      total: done,
    );
    setState(() {
      _finished = true;
      _result = result;
    });
    if (_saved || done == 0) return;
    _saved = true;
    context.read<GameScoreStore>().submit(kBakYazGameKey, result).then((s) {
      if (mounted) {
        setState(() => _submission = s);
      }
    });
  }

  void _restart() => setState(() {
    _tasks = buildCopyTasks(_random);
    _index = 0;
    _hintUsed = false;
    _highlight = null;
    _message = null;
    _check = _CheckState.none;
    _independent = 0;
    _withHint = 0;
    _finished = false;
    _saved = false;
    _result = null;
    _submission = null;
    controller.value = const TextEditingValue();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar('Bak ve Yaz'),
    body: _body(_finished ? _summary(context) : _game(context)),
  );

  Widget _game(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return WritingPad(
      key: ValueKey('pad-$_index'),
      controller: controller,
      maxLength: kCopyMaxLength,
      muted: muted,
      multiline: false,
      fontSize: 48,
      highlight: _highlight,
      onUserEdit: () {
        if (_check == _CheckState.wrong || _highlight != null) {
          setState(() {
            _check = _CheckState.none;
            _highlight = null;
          });
        }
      },
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('example'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_index + 1} / ${_tasks.length}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(_task.stage.label, style: textTheme.bodySmall),
                  ],
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _task.text,
                      key: const ValueKey('example-text'),
                      textDirection: TextDirection.rtl,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: AppTextTheme.arabicFontFamily,
                        fontSize:
                            MediaQuery.sizeOf(context).height < 500 ? 36 : 52,
                        height: 1.5,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child:
                _message == null
                    ? _instruction(context, 'Örneğin aynısını yaz.')
                    : Row(
                      children: [
                        Icon(
                          _check == _CheckState.correct
                              ? Icons.star_rounded
                              : Icons.info_outline_rounded,
                          color:
                              _check == _CheckState.correct
                                  ? AppColors.gold
                                  : AppColors.navySoft,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _message!,
                            key: const ValueKey('copy-message'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          Row(
            children: [
              if (_check != _CheckState.correct) ...[
                // Dar ekranda taşmasın: eşit paylar, yazı gerekirse küçülür.
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    key: const ValueKey('hint-button'),
                    onPressed: _hint,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: const FittedBox(child: Text('İpucu')),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    key: const ValueKey('skip-button'),
                    onPressed: () => _next(skip: true),
                    child: const FittedBox(child: Text('Atla')),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: FilledButton.icon(
                    key: const ValueKey('check-button'),
                    onPressed: _checkAnswer,
                    icon: const Icon(Icons.check_rounded),
                    label: const FittedBox(child: Text('Kontrol Et')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.turquoise,
                    ),
                  ),
                ),
              ] else ...[
                const Spacer(),
                FilledButton.icon(
                  key: const ValueKey('next-button'),
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _index + 1 >= _tasks.length ? 'Bitir' : 'Sonraki',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = _independent + _withHint;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 56,
                color: AppColors.turquoise,
              ),
              Text(
                done == 0 ? 'Alıştırmalar bitti.' : 'Tebrikler!',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$done / ${_tasks.length} örneği yazdın.\n'
                'Kendi başına: $_independent · İpucuyla: $_withHint',
                key: const ValueKey('copy-summary'),
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (_submission?.isNewBest ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Yeni rekor!',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              if (_result != null && done > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_result!.points} Puan',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.turquoise,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('restart-button'),
                onPressed: _restart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Yeni alıştırmalar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                key: const ValueKey('exit-button'),
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Geri dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// C — Serbest Yaz

class FreeModeScreen extends StatefulWidget {
  const FreeModeScreen({super.key});

  @override
  State<FreeModeScreen> createState() => _FreeModeScreenState();
}

class _FreeModeScreenState extends State<FreeModeScreen> with _WritingScreen {
  @override
  String? get draftMode => 'serbest';

  @override
  void initState() {
    super.initState();
    initWriting();
  }

  @override
  void dispose() {
    disposeWriting();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = controller.text;
    if (text.trim().isEmpty) {
      snack('Kopyalanacak yazı yok.');
      return;
    }
    try {
      // Metin olduğu gibi (mantıksal sırayla) kopyalanır.
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        snack('Kopyalandı.');
      }
    } catch (_) {
      if (mounted) {
        snack(
          'Kopyalanamadı. Yazıyı seçip cihazın menüsüyle kopyalayabilirsin.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar('İstediğini yaz!'),
    body: _body(
      WritingPad(
        controller: controller,
        maxLength: kFreeMaxLength,
        muted: muted,
        fontSize: 40,
        onUserEdit: onEdited,
        header: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, 'Harfler, kelimeler, cümleler…', [
              OutlinedButton.icon(
                key: const ValueKey('copy-button'),
                onPressed: _copy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Kopyala'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const ValueKey('clear-button'),
                onPressed: clearWithUndo,
                child: const Text('Temizle'),
              ),
            ]),
            const SizedBox(height: 4),
            noticeBar(context),
            const SizedBox(height: 4),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ),
  );
}
