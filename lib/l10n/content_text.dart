import 'package:flutter/widgets.dart';

import '../data/lesson_info_data.dart' show TrAudioSpan;
import 'app_language.dart';

/// One piece of a lesson's rich text ([LessonInfo.body]) as it is
/// translated: an explanation read as one recording ([audioId]), a run of
/// other text between tables, or a table ([widget]).
class InfoSegment {
  final String? audioId;

  /// The Turkish text of the piece, without its leading/trailing line
  /// breaks (those are layout, kept in [leadingBreaks]/[trailingBreaks]).
  final String text;
  final int leadingBreaks;
  final int trailingBreaks;
  final WidgetSpan? widget;

  /// The original spans (the Turkish rendering uses them unchanged).
  final List<InlineSpan> spans;

  const InfoSegment({
    this.audioId,
    this.text = '',
    this.leadingBreaks = 0,
    this.trailingBreaks = 0,
    this.widget,
    this.spans = const [],
  });

  bool get isBlank => widget == null && text.trim().isEmpty;
}

/// [body] cut into [InfoSegment]s: each [TrAudioSpan] alone, each table
/// alone, and the runs of other spans between them merged.
List<InfoSegment> infoSegments(List<InlineSpan> body) {
  final out = <InfoSegment>[];
  var run = <InlineSpan>[];

  InfoSegment text(List<InlineSpan> spans, {String? audioId}) {
    final plain =
        spans.map((s) => s.toPlainText(includePlaceholders: false)).join();
    final lead = RegExp(r'^\s*').firstMatch(plain)![0]!;
    final trail = RegExp(r'\s*$').firstMatch(plain)![0]!;
    final trimmed = plain.trim();
    return InfoSegment(
      audioId: audioId,
      text: trimmed,
      leadingBreaks: trimmed.isEmpty ? 0 : '\n'.allMatches(lead).length,
      trailingBreaks:
          trimmed.isEmpty
              ? '\n'.allMatches(plain).length
              : '\n'.allMatches(trail).length,
      spans: spans,
    );
  }

  void flush() {
    if (run.isNotEmpty) out.add(text(run));
    run = [];
  }

  for (final span in body) {
    if (span is TrAudioSpan) {
      flush();
      out.add(text([span], audioId: span.audioId));
    } else if (span is WidgetSpan) {
      flush();
      out.add(InfoSegment(widget: span, spans: [span]));
    } else {
      run.add(span);
    }
  }
  flush();
  return out;
}

/// The label that leads to an example table ("Örnekler:") in each language.
const Map<AppLanguage, String> kExamplesLabel = {
  AppLanguage.tr: 'Örnekler:',
  AppLanguage.es: 'Ejemplos:',
  AppLanguage.fr: 'Exemples :',
  AppLanguage.de: 'Beispiele:',
  AppLanguage.en: 'Examples:',
  AppLanguage.bs: 'Primjeri:',
};

/// Coloring marks of the book texts (see `BookMarkup`).
final RegExp _markup = RegExp('[⟪⟫⟦⟧«»]|\\*\\*');

/// [text] ending with its language's "Örnekler:" label, and without it.
final Map<AppLanguage, RegExp> _trailingExamples = {
  for (final MapEntry(:key, :value) in kExamplesLabel.entries)
    key: RegExp(
      '\\s*${RegExp.escape(value.replaceFirst(RegExp(r'\s*:$'), ''))}'
      '\\s*:\\s*\$',
    ),
};

/// [text] without a closing "Örnekler:" (in [language]); null when it
/// had none.
String? withoutTrailingExamples(String text, AppLanguage language) {
  final trimmed = text.replaceFirst(_trailingExamples[language]!, '');
  return trimmed == text ? null : trimmed;
}

/// The text a recording says, from the text the screen shows: without the
/// coloring marks, bullets and line breaks, and without a closing
/// "Örnekler:" (it leads to the table and is not read).
String spokenText(String shown, [AppLanguage language = AppLanguage.tr]) {
  var text =
      shown
          .replaceAll(_markup, '')
          .replaceAll(RegExp(r'(^|\n)\s*[-*•]\s+'), '\n')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  text = withoutTrailingExamples(text, language) ?? text;
  return text;
}

/// A heading's text as recorded: its Turkish (or translated) lines and its
/// Arabic name in brackets.
String headingSpokenText(
  List<String?> lines,
  String? arabic, [
  AppLanguage language = AppLanguage.tr,
]) {
  final text = lines.whereType<String>().join(' ');
  if (arabic == null || !hasArabicLetter(arabic)) {
    return spokenText(text, language);
  }
  final name = arabic.trim();
  return spokenText(
    name.startsWith('(') ? '$text $name' : '$text ( $name )',
    language,
  );
}

// Arabic letters (not the tatweel ـ that only carries a mark).
final RegExp _arabicLetter = RegExp('[ء-غف-يٱ]');

bool hasArabicLetter(String text) => _arabicLetter.hasMatch(text);
