import 'package:flutter/widgets.dart';

import 'l10n.dart';

/// Kısa tarih ("12 Eki 2026") seçilen dilde; intl paketi kullanılmaz.
const Map<AppLanguage, List<String>> _months = {
  AppLanguage.tr: ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'],
  AppLanguage.es: ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'],
  AppLanguage.fr: ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
  AppLanguage.de: ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.'],
  AppLanguage.en: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  AppLanguage.bs: ['jan.', 'feb.', 'mar.', 'apr.', 'maj', 'jun.', 'jul.', 'aug.', 'sept.', 'okt.', 'nov.', 'dec.'],
  AppLanguage.nl: ['jan.', 'feb.', 'mrt.', 'apr.', 'mei', 'jun.', 'jul.', 'aug.', 'sep.', 'okt.', 'nov.', 'dec.'],
};

String shortDate(DateTime date, AppLanguage language) {
  final d = date.toLocal();
  final month = (_months[language] ?? _months[AppLanguage.tr]!)[d.month - 1];
  // Almanca ve Boşnakçada gün noktayla yazılır ("12. Okt. 2026").
  final day =
      language == AppLanguage.de || language == AppLanguage.bs
          ? '${d.day}.'
          : '${d.day}';
  return '$day $month ${d.year}';
}

extension ShortDateContext on BuildContext {
  /// [date] bu bağlamın dilinde kısa tarih olarak.
  String shortDateOf(DateTime date) => shortDate(date, language);
}
