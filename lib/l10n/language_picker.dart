import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import 'l10n.dart';

class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<AppLanguage>(
    tooltip: context.t('Dil seç'),
    initialValue: context.language,
    onSelected: (language) async {
      final controller = AppLanguageScope.controllerOf(context);
      if (controller == null || language == controller.language) return;
      final audio = context.read<AudioService>();
      if (audio.currentAsset?.startsWith(
            'audio/${controller.language.code}/',
          ) ??
          false) {
        await audio.stop();
      }
      await controller.setLanguage(language);
    },
    itemBuilder:
        (_) => [
          for (final language in AppLanguage.active)
            PopupMenuItem(value: language, child: Text(language.nativeName)),
        ],
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language),
          const SizedBox(width: 8),
          Text(context.language.nativeName),
        ],
      ),
    ),
  );
}
