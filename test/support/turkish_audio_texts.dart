import 'package:flutter/painting.dart';
import 'package:kuran_okuma_rehberi/data/lesson_info_data.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/models/turkish_audio.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/book_page.dart';

/// One listenable text as the app shows it.
class ShownTurkishText {
  final String id;
  final String lessonId;
  final String text;

  ShownTurkishText(this.id, this.lessonId, this.text);

  bool get isHeading => id.contains('_baslik_');
  int get pdfPage => int.parse(id.substring(1, 4));
}

final _markup = RegExp('[⟪⟫⟦⟧«»]');
// Arabic letters (not the tatweel ـ that only carries a mark).
final _arabicLetter = RegExp('[ء-غف-يٱ]');

/// The text a recording says: the shown text without the coloring marks,
/// bullets and line breaks, and without a closing "Örnekler:" (those lead
/// to the table and are not read).
String spokenText(String shown) {
  var text =
      shown
          .replaceAll(_markup, '')
          .replaceAll(RegExp(r'(^|\n)\s*[-*•]\s+'), '\n')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  text = text.replaceFirst(RegExp(r'\s*Örnekler:$'), '');
  return text;
}

bool hasArabicLetter(String text) => _arabicLetter.hasMatch(text);

String _headingText(List<String?> lines, String? arabic) {
  final turkish = lines.whereType<String>().join(' ');
  if (arabic == null || !hasArabicLetter(arabic)) return spokenText(turkish);
  final name = arabic.trim();
  return spokenText(
    name.startsWith('(') ? '$turkish $name' : '$turkish ( $name )',
  );
}

void _collectParagraphs(
  List<String> paragraphs,
  Map<int, TrAudio> audio,
  String lessonId,
  List<ShownTurkishText> out,
) {
  for (final MapEntry(key: start, value: recording) in audio.entries) {
    final end = start + recording.paragraphs;
    if (end > paragraphs.length) {
      throw StateError('${recording.id}: $end > ${paragraphs.length} paragraf');
    }
    out.add(
      ShownTurkishText(
        recording.id,
        lessonId,
        spokenText(paragraphs.sublist(start, end).join('\n')),
      ),
    );
  }
}

void _collectSpans(
  List<InlineSpan> spans,
  String lessonId,
  List<ShownTurkishText> out,
) {
  for (final span in spans) {
    if (span is TrAudioSpan) {
      out.add(
        ShownTurkishText(
          span.audioId,
          lessonId,
          spokenText(span.toPlainText(includePlaceholders: false)),
        ),
      );
    }
  }
}

/// Every listenable text of every lesson, in lesson and page order.
List<ShownTurkishText> collectShownTurkishTexts() {
  final out = <ShownTurkishText>[];
  for (final lesson in kElifbaLessons) {
    final layout = lesson.pageLayout;
    if (layout != null) {
      for (final page in layout.pages) {
        if (page.headingAudio case final id?) {
          out.add(
            ShownTurkishText(
              id,
              lesson.id,
              _headingText([
                page.kicker,
                page.heading,
                page.subheading,
              ], page.arabicHeading),
            ),
          );
        }
        _collectParagraphs(page.intro, page.introAudio, lesson.id, out);
        for (final section in page.sections) {
          if (section.titleAudio case final id?) {
            out.add(
              ShownTurkishText(id, lesson.id, spokenText(section.title!)),
            );
          }
          _collectParagraphs(section.intro, section.introAudio, lesson.id, out);
          _collectParagraphs(section.outro, section.outroAudio, lesson.id, out);
        }
      }
    }
    final heading = kBookPageHeadings[lesson.id];
    final info = kLessonInfo[lesson.id];
    if (layout == null && heading != null && info != null) {
      if (heading.audio case final id?) {
        out.add(
          ShownTurkishText(
            id,
            lesson.id,
            _headingText([
              heading.top,
              heading.main,
              heading.bottom,
            ], heading.arabic),
          ),
        );
      }
      _collectSpans(info.body, lesson.id, out);
    }
  }
  return out;
}
