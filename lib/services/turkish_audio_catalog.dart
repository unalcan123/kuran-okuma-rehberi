import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Which Turkish explanation recordings (`assets/audio/tr/*.mp3`) the app
/// actually has. Explanations are recorded a few at a time; one without a
/// recording is shown as plain text (no speaker icon, nothing to tap), and
/// gets its icon by itself once its file is added.
class TurkishAudioCatalog {
  TurkishAudioCatalog._();

  /// Asset paths as [AudioService] plays them (`audio/tr/<id>.mp3`).
  static final ValueNotifier<Set<String>> available = ValueNotifier(const {});

  static Future<void>? _loading;

  /// Reads the app's asset list once; safe to call from every build.
  static void ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      available.value = {
        for (final asset in manifest.listAssets())
          if (asset.startsWith('assets/audio/tr/') && asset.endsWith('.mp3'))
            asset.substring('assets/'.length),
      };
    } catch (error) {
      // No list, no icons: the explanations stay readable.
      debugPrint('TurkishAudioCatalog: ses listesi okunamadı — $error');
    }
  }

  /// For tests: pretend exactly these recordings exist.
  @visibleForTesting
  static void debugSetAvailable(Set<String> assets) {
    _loading = Future.value();
    available.value = assets;
  }
}
