import 'package:flutter/material.dart';

final _showMeaning = ValueNotifier<bool>(true);

class ReadingMeaning extends StatelessWidget {
  const ReadingMeaning({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _showMeaning,
    child: child,
    builder:
        (context, visible, child) => visible ? child! : const SizedBox.shrink(),
  );
}

class ReadingTextScale extends StatelessWidget {
  const ReadingTextScale({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final ValueNotifier<double> controller;

  static double factorOf(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return scaler is _ReadingTextScaler ? scaler.factor : 1;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: controller,
    child: child,
    builder:
        (context, scale, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: _ReadingTextScaler(
              MediaQuery.textScalerOf(context),
              scale,
            ),
          ),
          child: child!,
        ),
  );
}

class _ReadingTextScaler extends TextScaler {
  const _ReadingTextScaler(this.systemScaler, this.factor);

  final TextScaler systemScaler;
  final double factor;

  @override
  double scale(double fontSize) => systemScaler.scale(fontSize) * factor;

  @override
  double get textScaleFactor => systemScaler.scale(1) * factor;
}

class ReadingTextSettingsButton extends StatelessWidget {
  const ReadingTextSettingsButton({
    super.key,
    this.showMeaningToggle = true,
    required this.controller,
  });

  final bool showMeaningToggle;
  final ValueNotifier<double> controller;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Okuma ayarları',
    icon: const Icon(Icons.settings_outlined),
    onPressed:
        () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder:
              (context) => SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ValueListenableBuilder<double>(
                    valueListenable: controller,
                    builder:
                        (context, scale, _) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Yazı boyutu',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text('%${(scale * 100).round()}'),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Harfleri küçült',
                                  onPressed:
                                      scale <= 0.8
                                          ? null
                                          : () => _setScale(scale - 0.1),
                                  icon: const Icon(Icons.text_decrease),
                                ),
                                Expanded(
                                  child: Slider(
                                    min: 0.8,
                                    max: 1.8,
                                    divisions: 10,
                                    value: scale,
                                    label: '%${(scale * 100).round()}',
                                    onChanged: _setScale,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Harfleri büyüt',
                                  onPressed:
                                      scale >= 1.8
                                          ? null
                                          : () => _setScale(scale + 0.1),
                                  icon: const Icon(Icons.text_increase),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _setScale(1),
                              child: const Text('Varsayılan boyut'),
                            ),
                            if (showMeaningToggle) const Divider(),
                            if (showMeaningToggle)
                              ValueListenableBuilder<bool>(
                                valueListenable: _showMeaning,
                                builder:
                                    (context, visible, _) => SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Meali göster'),
                                      value: visible,
                                      onChanged:
                                          (value) => _showMeaning.value = value,
                                    ),
                              ),
                          ],
                        ),
                  ),
                ),
              ),
        ),
  );

  void _setScale(double value) {
    controller.value = (value * 10).round().clamp(8, 18) / 10;
  }
}

/// Keeps a fitted glyph's viewport in step with the user's reading size.
/// Otherwise FittedBox shrinks enlarged text straight back to its old size.
class ReadingFittedBox extends StatelessWidget {
  const ReadingFittedBox({
    super.key,
    required this.child,
    this.fit = BoxFit.contain,
  });

  final Widget child;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final factor = ReadingTextScale.factorOf(context);
    if (factor == 1) return FittedBox(fit: fit, child: child);
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = SizedBox(
          width:
              constraints.hasBoundedWidth
                  ? constraints.maxWidth * factor
                  : null,
          height:
              constraints.hasBoundedHeight
                  ? constraints.maxHeight * factor
                  : null,
          child: FittedBox(fit: fit, child: child),
        );
        if (constraints.hasBoundedHeight) {
          content = SingleChildScrollView(primary: false, child: content);
        }
        return Center(
          child: SingleChildScrollView(
            primary: false,
            scrollDirection: Axis.horizontal,
            child: content,
          ),
        );
      },
    );
  }
}
