import 'package:flutter/semantics.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'dualar_test.dart' show TestAudioService, harness;

void main() {
  testWidgets('First lesson reads Elif, Be, Te, Se in book order', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final audio = TestAudioService();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(LessonLettersScreen(lesson: kElifbaLessons.first), audio),
    );
    await tester.pumpAndSettle();
    final root =
        tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!;
    final labels = <String>[];
    void visit(SemanticsNode node) {
      labels.add(node.label);
      for (final child in node.debugListChildrenInOrder(
        DebugSemanticsDumpOrder.traversalOrder,
      )) {
        visit(child);
      }
    }

    visit(root);
    final positions =
        ['Elif', 'Be', 'Te', 'Se']
            .map((name) => labels.indexWhere((l) => l.startsWith('$name.')))
            .toList();
    expect(positions.every((i) => i >= 0), isTrue, reason: labels.join('\n'));
    expect(positions, orderedEquals([...positions]..sort()));
    semantics.dispose();
  });
}
