import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../services/audio_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_theme.dart';
import '../yazi_data.dart';
import '../yazi_store.dart';
import '../yazi_text.dart';
import 'arabic_keyboard.dart';

/// Yazı alanı + ekran klavyesi.
///
/// Yazı alanı gerçek, düzenlenebilir bir [TextField]'dır (sağdan sola, Unicode
/// metin): seçim, kopyala/yapıştır, fiziksel klavye ve erişilebilirlik
/// Flutter'ın kendi metin sistemindedir. Ekran klavyesi yalnızca
/// denetleyicinin değerini imleçte/seçimde değiştirir; harfler hiçbir
/// zaman ters çevrilmez, birleşmeyi metin motoru yapar.
///
/// Ekran klavyesi açıkken yazı alanı `TextInputType.none` kullanır: odak ve
/// imleç durur ama cihazın klavyesi açılıp ekranı kaplamaz. "Cihaz
/// klavyesini kullan" normal girişe geçer (Latin harfler Arapçaya
/// çevrilmez).
class WritingPad extends StatefulWidget {
  const WritingPad({
    super.key,
    required this.controller,
    required this.maxLength,
    required this.muted,
    this.multiline = true,
    this.highlight,
    this.hintText,
    this.fontSize = 40,
    this.onUserEdit,
    this.header,
  });

  /// Yazı alanının üstündeki bölüm (yönerge, örnek, düğmeler). Yatay
  /// ekranda yazı alanıyla aynı sütunda, klavyenin yanında durur.
  final Widget? header;

  final TextEditingController controller;
  final int maxLength;
  final bool muted;
  final bool multiline;

  /// İpucu: belirginleşecek tuşun karakteri (bölüm kendiliğinden açılır).
  final String? highlight;
  final String? hintText;
  final double fontSize;

  /// Klavye/tuş ile yapılan her değişiklikten sonra.
  final VoidCallback? onUserEdit;

  @override
  State<WritingPad> createState() => WritingPadState();
}

class WritingPadState extends State<WritingPad> {
  final FocusNode _focus = FocusNode(debugLabel: 'arapca-yazi');
  final _store = YaziStore();
  KeySection _section = KeySection.letters;
  bool _deviceKeyboard = false;
  String? _tip;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    _store.getBool(YaziStore.deviceKeyboardKey).then((v) {
      if (mounted && v) setState(() => _deviceKeyboard = true);
    });
  }

  @override
  void didUpdateWidget(WritingPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    final h = widget.highlight;
    if (h != null && h != oldWidget.highlight) {
      final s = sectionOf(h);
      if (s != null && s != _section) setState(() => _section = s);
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _showTip(String text) {
    _tipTimer?.cancel();
    setState(() => _tip = text);
    _tipTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _tip = null);
    });
  }

  void _apply(TextEditingValue? next) {
    if (next == null) {
      _showTip('Yazı sınırına geldin (${widget.maxLength} karakter).');
      return;
    }
    widget.controller.value = next;
    // Odak kaybolduysa geri gelir; seçim/imleç korunur.
    if (!_focus.hasFocus) _focus.requestFocus();
    widget.onUserEdit?.call();
  }

  void _onKey(YaziKey key, KeySection section) {
    if (section == KeySection.haraka) {
      final (value, result) = applyHaraka(widget.controller.value, key.insert);
      if (result == HarakaResult.noLetter) {
        _showTip('Önce bir harf yaz, sonra harekeyi ekle.');
        return;
      }
      if (value.text.length > widget.maxLength) {
        _showTip('Yazı sınırına geldin (${widget.maxLength} karakter).');
        return;
      }
      _apply(value);
      return;
    }
    _apply(
      insertAtCursor(
        widget.controller.value,
        key.insert,
        maxLength: widget.maxLength,
      ),
    );
    final audio = key.audio;
    if (!widget.muted && audio != null) {
      // Tek oynatıcı: önceki harf sesi kesilir, üst üste binmez. Dosya
      // yoksa AudioService hatayı yutar, yazma sürer.
      context.read<AudioService>().playAsset(audio);
    }
  }

  void _backspace() => _apply(deleteBackward(widget.controller.value));

  void _space() => _apply(
    insertAtCursor(widget.controller.value, ' ', maxLength: widget.maxLength),
  );

  void _newline() => _apply(
    insertAtCursor(widget.controller.value, '\n', maxLength: widget.maxLength),
  );

  Future<void> _toggleDeviceKeyboard() async {
    final next = !_deviceKeyboard;
    setState(() => _deviceKeyboard = next);
    await _store.setBool(YaziStore.deviceKeyboardKey, next);
    // Giriş türü yeni bağlantıda geçerli olur: odağı bırak ve yeniden al.
    _focus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final field = TextField(
      key: const ValueKey('writing-field'),
      controller: widget.controller,
      focusNode: _focus,
      autofocus: true,
      keyboardType:
          _deviceKeyboard
              ? (widget.multiline
                  ? TextInputType.multiline
                  : TextInputType.text)
              : TextInputType.none,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      maxLines: widget.multiline ? null : 1,
      expands: widget.multiline,
      textAlignVertical: TextAlignVertical.top,
      maxLength: widget.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      onChanged: (_) => widget.onUserEdit?.call(),
      style: TextStyle(
        fontFamily: AppTextTheme.arabicFontFamily,
        fontSize: widget.fontSize,
        height: 1.6,
        color: AppColors.navy,
      ),
      buildCounter:
          (context, {required currentLength, required isFocused, maxLength}) =>
              Text(
                'Kalan: ${(maxLength ?? 0) - currentLength}',
                key: const ValueKey('remaining'),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        hintText: widget.hintText,
        hintTextDirection: TextDirection.ltr,
        hintStyle: textTheme.titleMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.turquoise, width: 2),
        ),
      ),
    );
    final tipBar = SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration:
                  MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
              child:
                  _tip == null
                      ? const SizedBox.shrink()
                      : Row(
                        key: ValueKey(_tip),
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _tip!,
                              key: const ValueKey('pad-tip'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          Flexible(
            child: TextFieldTapRegion(
              child: TextButton.icon(
                key: const ValueKey('device-keyboard-toggle'),
                onPressed: _toggleDeviceKeyboard,
                icon: Icon(
                  _deviceKeyboard
                      ? Icons.grid_view_rounded
                      : Icons.keyboard_rounded,
                  size: 18,
                ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _deviceKeyboard ? 'Ekran klavyesi' : 'Cihaz klavyesi',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    ArabicKeyboard? keyboard({bool fill = false}) =>
        _deviceKeyboard
            ? null
            : ArabicKeyboard(
              section: _section,
              onSection: (s) => setState(() => _section = s),
              onKey: _onKey,
              onBackspace: _backspace,
              onSpace: _space,
              onNewline: widget.multiline ? _newline : null,
              highlight: widget.highlight,
              fillHeight: fill,
            );
    // Tek satırlık alan büzülmesin: tam genişlik, üstte.
    final fieldBox =
        widget.multiline
            ? field
            : Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: double.infinity, child: field),
            );
    final header = widget.header;
    return LayoutBuilder(
      builder: (context, c) {
        // Yatay ve alçak ekran: üst bölüm + yazı alanı solda, klavye sağda
        // (bölüm seçimi ve Sil/Boşluk her zaman görünür).
        if (!_deviceKeyboard &&
            c.maxWidth > c.maxHeight * 1.4 &&
            c.maxHeight < 520) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (header != null)
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(child: header),
                      ),
                    SizedBox(
                      height: widget.multiline ? 120 : 84,
                      child: fieldBox,
                    ),
                    tipBar,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: (c.maxWidth * 0.55).clamp(320.0, 460.0),
                child: keyboard(fill: true),
              ),
            ],
          );
        }
        // Dikey ama alçak: bütün alan kayar, yazı alanı en az 110 px.
        if (!_deviceKeyboard && c.maxHeight < 470) {
          return SingleChildScrollView(
            child: Column(
              children: [
                if (header != null) header,
                SizedBox(height: 110, child: field),
                tipBar,
                keyboard()!,
              ],
            ),
          );
        }
        final kb = keyboard();
        return Column(
          children: [
            if (header != null) header,
            Expanded(child: fieldBox),
            tipBar,
            if (kb != null) kb,
          ],
        );
      },
    );
  }
}
