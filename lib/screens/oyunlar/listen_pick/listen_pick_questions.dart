import 'dart:math' as math;

import '../../../models/arabic_letter.dart';
import '../../../models/lesson.dart';

/// Where in a word a letter is written. Ders 2 teaches the same letter
/// three ways, so its questions ask for one of them.
enum LetterPosition {
  initial('Başta'),
  medial('Ortada'),
  ending('Sonda');

  const LetterPosition(this.label);

  final String label;

  /// How [letter] is written in this position.
  String formOf(ArabicLetter letter) => switch (this) {
    LetterPosition.initial => letter.initialForm!,
    LetterPosition.medial => letter.medialForm!,
    LetterPosition.ending => letter.finalForm!,
  };
}

class ListenPickQuestion {
  const ListenPickQuestion({
    required this.answer,
    required this.options,
    this.position,
  });

  /// What the recording says.
  final ArabicLetter answer;

  /// Shuffled choices; always contains [answer] exactly once.
  final List<ArabicLetter> options;

  /// When set, every choice is shown written in this position (başta /
  /// ortada / sonda) instead of on its own.
  final LetterPosition? position;

  /// The text a choice is drawn with.
  String textOf(ArabicLetter item) =>
      (position?.formOf(item) ?? item.isolatedForm).trim();
}

/// Prefix of this game's keys: every lesson is a game of its own, with
/// its own best score and history.
const String kListenPickGameKey = 'listen_pick';

String listenPickGameKey(Lesson lesson) => '$kListenPickGameKey.${lesson.id}';

const int kListenPickQuestionCount = 5;
const int kListenPickOptionCount = 4;

/// Stable identity for a card: the written form, ignoring padding.
String listenPickId(ArabicLetter item) => item.isolatedForm.trim();

/// Items a lesson can quiz on: those with a recording, one per written
/// form (a lesson can list the same text twice with different sounds,
/// which would make a question ambiguous).
List<ArabicLetter> listenPickPool(Iterable<ArabicLetter> items) {
  final seen = <String>{};
  return [
    for (final item in items)
      if (item.audioAsset != null && seen.add(listenPickId(item))) item,
  ];
}

/// Whether a lesson teaches written positions (every item has başta,
/// ortada and sonda forms) and so is quizzed on them.
bool listenPickUsesPositions(Iterable<ArabicLetter> items) =>
    items.isNotEmpty && items.every((item) => item.hasPositionForms);

/// Draws up to [count] different questions from [pool]: each has a
/// recording to hear and up to [optionCount] written choices. A question
/// is never repeated within one game — the old game could ask the same
/// letter twice.
///
/// With [positions] each question also asks for one written position; the
/// positions are dealt in shuffled rounds so all three come up.
List<ListenPickQuestion> buildListenPickQuestions(
  List<ArabicLetter> pool, {
  int count = kListenPickQuestionCount,
  int optionCount = kListenPickOptionCount,
  bool positions = false,
  math.Random? random,
}) {
  final rng = random ?? math.Random();
  final answers = List.of(pool)..shuffle(rng);
  final dealt = <LetterPosition>[];
  while (positions && dealt.length < count) {
    dealt.addAll(List.of(LetterPosition.values)..shuffle(rng));
  }
  return [
    for (var i = 0; i < math.min(count, answers.length); i++)
      _question(
        answers[i],
        pool,
        optionCount,
        positions ? dealt[i] : null,
        rng,
      ),
  ];
}

ListenPickQuestion _question(
  ArabicLetter answer,
  List<ArabicLetter> pool,
  int optionCount,
  LetterPosition? position,
  math.Random rng,
) {
  String textOf(ArabicLetter item) =>
      (position?.formOf(item) ?? item.isolatedForm).trim();
  // Choices must read differently, or the answer would be ambiguous.
  final shown = {textOf(answer)};
  final distractors = [
    for (final item in List.of(pool)..shuffle(rng))
      if (!identical(item, answer) && shown.add(textOf(item))) item,
  ];
  return ListenPickQuestion(
    answer: answer,
    position: position,
    options: [answer, ...distractors.take(optionCount - 1)]..shuffle(rng),
  );
}
