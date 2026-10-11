import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

/// The one language setting of the app. Until the user picks one, the
/// device's language is used when the app has it (else Turkish); a pick is
/// kept on the device (`app.language`) and wins from then on.
class LanguageController extends ChangeNotifier {
  LanguageController({AppLanguage? initial, Iterable<Locale>? deviceLocales})
    : _language =
          initial ??
          AppLanguage.fromDeviceLocales(
            deviceLocales ?? WidgetsBinding.instance.platformDispatcher.locales,
          );

  static const String prefsKey = 'app.language';

  AppLanguage _language;
  bool _chosen = false;

  AppLanguage get language => _language;

  /// Whether the user picked the language (not just the device default).
  bool get chosen => _chosen;

  /// Reads the saved pick, if any.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = AppLanguage.fromCode(prefs.getString(prefsKey));
      if (saved != null && AppLanguage.active.contains(saved)) {
        _chosen = true;
        if (saved != _language) {
          _language = saved;
          notifyListeners();
        }
      }
    } catch (error) {
      debugPrint('LanguageController: dil tercihi okunamadı — $error');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _chosen = true;
    if (language != _language) {
      _language = language;
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, language.code);
    } catch (error) {
      // Not saved (private mode etc.): the language still changes now.
      debugPrint('LanguageController: dil tercihi kaydedilemedi — $error');
    }
  }
}
