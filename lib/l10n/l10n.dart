import 'package:flutter/widgets.dart';

import 'app_language.dart';
import 'language_controller.dart';
import 'strings/strings.dart';

export 'app_language.dart';
export 'language_controller.dart';

/// Puts the app's [LanguageController] above every screen. Widgets read the
/// current language with [AppLanguageScope.of] (or `context.t(...)`), and
/// rebuild when it changes. Without a scope (e.g. a widget test that pumps
/// one screen) everything is Turkish, as before.
class AppLanguageScope extends InheritedNotifier<LanguageController> {
  const AppLanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguage of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppLanguageScope>()
          ?.notifier
          ?.language ??
      AppLanguage.tr;

  static LanguageController? controllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppLanguageScope>()?.notifier;
}

/// Text in the user's language. Every text of the app is written in
/// Turkish in the code (the book's language); the Turkish text is the key
/// of its translations ([kStringTables]): one row of five, in the order of
/// [AppLanguage] after Turkish.
///
/// `{name}` placeholders are filled from `args` after translating.
abstract final class L10n {
  static Map<String, List<String>>? _merged;
  static final Map<(AppLanguage, String), String?> _templateCache = {};

  static Map<String, List<String>> get table =>
      _merged ??= {for (final table in kStringTables) ...table};

  /// The translation of [source], or null when [language] has none
  /// (Turkish is the source itself).
  static String? translationOf(AppLanguage language, String source) {
    if (language == AppLanguage.tr) return source;
    final row = table[source];
    if (row == null) {
      final cacheKey = (language, source);
      if (_templateCache.containsKey(cacheKey)) return _templateCache[cacheKey];
      // Some game engines compose feedback before handing it to a widget.
      // Match only explicit translation templates and preserve captured values.
      final placeholder = RegExp(r'\{(\w+)\}');
      final templates =
          table.entries
              .where((entry) => placeholder.hasMatch(entry.key))
              .toList()
            ..sort(
              (a, b) => b.key
                  .replaceAll(placeholder, '')
                  .length
                  .compareTo(a.key.replaceAll(placeholder, '').length),
            );
      for (final entry in templates) {
        final matches = placeholder.allMatches(entry.key).toList();
        if (matches.isEmpty) continue;
        final buffer = StringBuffer('^');
        var end = 0;
        for (final match in matches) {
          buffer.write(RegExp.escape(entry.key.substring(end, match.start)));
          buffer.write('(.*?)');
          end = match.end;
        }
        buffer.write(RegExp.escape(entry.key.substring(end)));
        buffer.write(r'$');
        final found = RegExp(
          buffer.toString(),
          dotAll: true,
        ).firstMatch(source);
        if (found == null) continue;
        final translated = entry.value[language.translationIndex];
        if (translated.isEmpty) continue;
        var result = translated;
        for (var i = 0; i < matches.length; i++) {
          final value = found.group(i + 1)!;
          final nested = table[value];
          final localized =
              nested == null || nested[language.translationIndex].isEmpty
                  ? value
                  : nested[language.translationIndex];
          result = result.replaceAll(matches[i].group(0)!, localized);
        }
        _templateCache[cacheKey] = result;
        return result;
      }
      _templateCache[cacheKey] = null;
      return null;
    }
    if (language.translationIndex >= row.length) return null;
    final text = row[language.translationIndex];
    return text.isEmpty ? null : text;
  }

  /// [source] in [language]; the Turkish text when a translation is missing
  /// (tests make sure none is).
  static String text(
    AppLanguage language,
    String source, [
    Map<String, Object?>? args,
  ]) {
    var text = translationOf(language, source) ?? source;
    if (args != null) {
      for (final MapEntry(:key, :value) in args.entries) {
        final rawValue = '$value';
        final nested = language == AppLanguage.tr ? null : table[rawValue];
        final localized =
            nested == null || nested[language.translationIndex].isEmpty
                ? rawValue
                : nested[language.translationIndex];
        text = text.replaceAll('{$key}', localized);
      }
    }
    return text;
  }
}

extension L10nContext on BuildContext {
  /// The current language (Turkish without an [AppLanguageScope]).
  AppLanguage get language => AppLanguageScope.of(this);

  /// [source] (Turkish) in the current language; see [L10n.text].
  String t(String source, [Map<String, Object?>? args]) =>
      L10n.text(language, source, args);
}
