import 'dart:ui' show Locale;

/// The languages of the app's own texts (menus, buttons, lesson
/// explanations and their recordings). The Arabic of the lessons, the
/// sure/dua texts and their recitations are the same in every language.
///
/// The order is fixed: translation tables list the texts of [es], [fr],
/// [de], [en], [bs] in this order after the Turkish source ([translationIndex]);
/// [nl] comes last, from its own table (`kNlStrings`, see [L10n.table]).
enum AppLanguage {
  tr('tr', 'Türkçe'),
  es('es', 'Español'),
  fr('fr', 'Français'),
  de('de', 'Deutsch'),
  en('en', 'English'),
  // Bosnian (Latin script), its own code: not Croatian or Serbian.
  bs('bs', 'Bosanski'),
  nl('nl', 'Nederlands');

  const AppLanguage(this.code, this.nativeName);

  /// ISO 639-1 code (also the folder of the explanation recordings).
  final String code;

  /// The language's name in itself, as the language picker shows it.
  final String nativeName;

  Locale get locale => Locale(code);

  /// Position in a translation table row, or -1 for the Turkish source.
  int get translationIndex => index - 1;

  static const active = [tr, es, fr, de, en, bs, nl];

  static AppLanguage? fromCode(String? code) {
    if (code == null) return null;
    final lower = code.toLowerCase();
    for (final language in values) {
      if (language.code == lower) return language;
    }
    return null;
  }

  /// The first of the device's languages the app has, else Turkish (the
  /// book's language).
  static AppLanguage fromDeviceLocales(Iterable<Locale> locales) {
    for (final locale in locales) {
      final language = fromCode(locale.languageCode);
      if (language != null && active.contains(language)) return language;
    }
    return tr;
  }
}
