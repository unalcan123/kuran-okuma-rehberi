import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/turkish_audio.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import 'turkish_audio_qc.dart';
import 'turkish_audio_qc_data.dart';

enum _Filter {
  all('Tümü'),
  unchecked('Bakılmadı'),
  good('İyi'),
  regenerate('Yeniden üretilecek'),
  fixText('Metni düzeltilecek');

  const _Filter(this.label);
  final String label;

  bool matches(TrAudioQcStatus? status) => switch (this) {
    _Filter.all => true,
    _Filter.unchecked => status == null,
    _Filter.good => status == TrAudioQcStatus.good,
    _Filter.regenerate => status == TrAudioQcStatus.regenerate,
    _Filter.fixText => status == TrAudioQcStatus.fixText,
  };
}

/// Geliştirici aracı: üretilmiş Türkçe seslerin hepsini PDF sırasıyla dinleyip
/// iyi / yeniden üret / metni düzelt diye işaretlemek ve raporunu almak için.
/// Ses üretmez, dosyalara dokunmaz; seçimler cihazda saklanır.
class TurkishAudioQcScreen extends StatefulWidget {
  const TurkishAudioQcScreen({
    super.key,
    this.entries = kTrAudioQcEntries,
    TrAudioQcStore? store,
  }) : _store = store;

  final List<TrAudioQcEntry> entries;
  final TrAudioQcStore? _store;

  @override
  State<TurkishAudioQcScreen> createState() => _TurkishAudioQcScreenState();
}

class _TurkishAudioQcScreenState extends State<TurkishAudioQcScreen> {
  late final TrAudioQcStore _store = widget._store ?? TrAudioQcStore();
  late final AudioService _audio;
  Map<String, TrAudioQcStatus> _statuses = {};
  _Filter _filter = _Filter.all;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    _store.load().then((statuses) {
      if (!mounted) return;
      setState(() {
        // Load finishing after a tap must not lose that tap.
        _statuses = {...statuses, ..._statuses};
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _audio.stop();
    super.dispose();
  }

  void _setStatus(String id, TrAudioQcStatus status) {
    setState(() {
      // Tapping the chosen status again clears it.
      if (_statuses[id] == status) {
        _statuses.remove(id);
      } else {
        _statuses[id] = status;
      }
    });
    _store.save(_statuses);
  }

  int _count(_Filter filter) =>
      widget.entries.where((e) => filter.matches(_statuses[e.id])).length;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final entry in widget.entries)
        if (_filter.matches(_statuses[entry.id])) entry,
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Türkçe Ses Kontrol'),
        actions: [
          IconButton(
            key: const ValueKey('qc-export'),
            tooltip: 'Raporu dışa aktar',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _showReport,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Geliştirici aracı · ${widget.entries.length} üretilmiş ses, '
                  'PDF sırasıyla. Seçimler bu cihazda saklanır; seçili duruma '
                  'yeniden dokunmak onu kaldırır.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final filter in _Filter.values)
                      ChoiceChip(
                        key: ValueKey('qc-filter-${filter.name}'),
                        label: Text('${filter.label} (${_count(filter)})'),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child:
                    !_loaded
                        ? const Center(child: CircularProgressIndicator())
                        : visible.isEmpty
                        ? const Center(child: Text('Bu filtrede kayıt yok.'))
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: visible.length,
                          itemBuilder:
                              (context, index) => _QcRow(
                                entry: visible[index],
                                status: _statuses[visible[index].id],
                                onStatus:
                                    (status) =>
                                        _setStatus(visible[index].id, status),
                              ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReport() async {
    var onlyToRedo = false;
    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              final report = trAudioQcReport(
                widget.entries,
                _statuses,
                only:
                    onlyToRedo
                        ? {TrAudioQcStatus.regenerate, TrAudioQcStatus.fixText}
                        : null,
              );
              return AlertDialog(
                title: const Text('Kontrol raporu'),
                content: SizedBox(
                  width: 760,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilterChip(
                        key: const ValueKey('qc-report-only-redo'),
                        label: const Text(
                          'Yalnız yeniden üretilecek / düzeltilecek',
                        ),
                        selected: onlyToRedo,
                        onSelected:
                            (value) => setDialogState(() => onlyToRedo = value),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: SingleChildScrollView(
                          child: SelectableText(
                            report,
                            key: const ValueKey('qc-report-text'),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kapat'),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('qc-report-copy'),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Kopyala'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: report));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rapor kopyalandı')),
                      );
                    },
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _QcRow extends StatelessWidget {
  const _QcRow({
    required this.entry,
    required this.status,
    required this.onStatus,
  });

  final TrAudioQcEntry entry;
  final TrAudioQcStatus? status;
  final ValueChanged<TrAudioQcStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = turkishAudioAsset(entry.id);
    final playing = context.select<AudioService, bool>(
      (audio) => audio.currentAsset == asset && audio.isPlaying,
    );
    final sameText = entry.ttsText == null || entry.ttsText == entry.text;
    return Card(
      key: ValueKey('qc-row-${entry.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        's. ${entry.pdfPage}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      SelectableText(
                        entry.id,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      if (entry.heading)
                        Text(
                          'başlık',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  key: ValueKey('qc-play-${entry.id}'),
                  icon: Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(playing ? 'Durdur' : 'Dinle'),
                  onPressed: () {
                    final audio = context.read<AudioService>();
                    playing ? audio.stop() : audio.playAsset(asset);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Labeled(label: 'Ekrandaki metin', text: entry.text),
            const SizedBox(height: 6),
            _Labeled(
              label:
                  sameText
                      ? 'Seslendirilen (ttsText) — metinle aynı'
                      : 'Seslendirilen (ttsText)',
              text: entry.spokenText,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in TrAudioQcStatus.values)
                  ChoiceChip(
                    key: ValueKey('qc-status-${entry.id}-${option.code}'),
                    label: Text(option.label),
                    selected: status == option,
                    onSelected: (_) => onStatus(option),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SelectableText(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
