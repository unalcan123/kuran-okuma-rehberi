import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/letter_card.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/single_letter_pager.dart';

import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:provider/provider.dart';

import 'support/silent_audio.dart';

/// Silent audio that also accepts "play this letter".
class _PlayableSilentAudio extends SilentAudio {
  int plays = 0;

  @override
  Future<void> playLetter(ArabicLetter letter) async => plays++;
}

void main() {
  Widget card({required VoidCallback onTap, required VoidCallback onOpen}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 160,
            child: LetterCard(
              letter: kArabicLetters.first,
              onTap: onTap,
              onOpenDetail: onOpen,
            ),
          ),
        ),
      );

  testWidgets('one tap plays the sound and does not open the letter', (
    tester,
  ) async {
    var taps = 0, opens = 0;
    await tester.pumpWidget(card(onTap: () => taps++, onOpen: () => opens++));
    await tester.tap(find.byType(LetterCard));
    // Immediately: no waiting to see whether a second tap follows.
    expect(taps, 1);
    await tester.pump(const Duration(seconds: 1));
    expect((taps, opens), (1, 0));
  });

  testWidgets('two quick taps only play twice, they do not open the letter', (
    tester,
  ) async {
    var taps = 0, opens = 0;
    await tester.pumpWidget(card(onTap: () => taps++, onOpen: () => opens++));
    await tester.tap(find.byType(LetterCard));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byType(LetterCard));
    await tester.pump(const Duration(seconds: 1));
    expect((taps, opens), (2, 0));
  });

  testWidgets('pressing and holding opens the letter', (tester) async {
    var taps = 0, opens = 0;
    await tester.pumpWidget(card(onTap: () => taps++, onOpen: () => opens++));
    await tester.longPress(find.byType(LetterCard));
    await tester.pump(const Duration(seconds: 1));
    expect((taps, opens), (0, 1));
  });

  testWidgets('in a lesson: double tap stays on the grid, long press opens Tek Harf', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = _PlayableSilentAudio();
    await tester.pumpWidget(
      ChangeNotifierProvider<AudioService>.value(
        value: audio,
        child: MaterialApp(
          home: LessonLettersScreen(lesson: kElifbaLessons.first),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AllLettersGrid), findsOneWidget);

    await tester.tap(find.byType(LetterCard).first);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byType(LetterCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(AllLettersGrid), findsOneWidget);
    expect(find.byType(SingleLetterPager), findsNothing);
    expect(audio.plays, 2);

    await tester.longPress(find.byType(LetterCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(SingleLetterPager), findsOneWidget);
    expect(find.byType(AllLettersGrid), findsNothing);
  });
}
