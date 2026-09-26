import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuran_okuma_rehberi/data/book_highlights.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/models/game_score.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/elifba_lessons_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/lesson_letters_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_card.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/listen_pick/listen_pick_questions.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'support/silent_audio.dart';
import 'book_pages_test.dart' show setSize;

const suffixIds = [
  'zamir-he-uzatilmasi',
  'zamir-he-uzatma-med',
  'kapali-te',
  'kelime-sonu-duraklar',
  'alistirmalar-1',
  'alistirmalar-2',
  'alistirmalar-3',
  'alistirmalar-4',
];
const suffixPages = [
  [54, 55],
  [55],
  [56],
  [57, 58, 59],
  [60],
  [61],
  [62],
  [63],
];
const mergedIds = [
  'zamir-he-uzatma-yok',
  'zamir-he-uzatma-yok-cezimli',
  'zamir-he-uzatma-yok-cezimli-seddeli',
];

void main() {
  test('34 unique consecutive lesson labels, stable IDs and PDF pages', () {
    expect(
      kElifbaLessons.map((l) => l.label),
      List.generate(34, (i) => 'Ders ${i + 1}'),
    );
    expect(kElifbaLessons.map((l) => l.id).toSet(), hasLength(34));
    expect(kElifbaLessons.skip(26).map((l) => l.id), suffixIds);
    for (var i = 0; i < 8; i++) {
      final lesson = kElifbaLessons[26 + i];
      final range =
          kBookPageNumbers[lesson.id]?.split('-').map(int.parse).toList();
      final pages =
          lesson.pageLayout?.pages.map((p) => p.bookPage).toList() ??
          [for (var p = range!.first; p <= range.last; p++) p];
      expect(pages, suffixPages[i]);
      expect(listenPickGameKey(lesson), 'listen_pick.${suffixIds[i]}');
    }
    expect(kElifbaLessons[26].letters, hasLength(30));
    for (final id in mergedIds) {
      expect(kElifbaLessons.any((l) => l.id == id), isFalse);
    }
  });

  test('all lesson audio references still point to existing files', () {
    for (final lesson in kElifbaLessons) {
      for (final letter in lesson.letters) {
        if (letter.audioAsset case final String asset) {
          expect(File('assets/$asset').existsSync(), isTrue, reason: asset);
        }
      }
    }
  });

  test(
    'renumbered lessons load existing stable-ID records without migration',
    () async {
      SharedPreferences.setMockInitialValues({
        for (final id in suffixIds.skip(2))
          'game_score.listen_pick.$id.best_score': 75,
        for (final id in suffixIds.skip(2))
          'game_history.listen_pick.$id.plays': 4,
      });
      final store = GameScoreStore();
      for (final lesson in kElifbaLessons.skip(28)) {
        final key = listenPickGameKey(lesson);
        expect((await store.recordOf(key)).bestScore, 75);
        expect((await store.historyOf(key)).plays, 4);
      }
    },
  );

  test(
    'legacy section history is preserved, repeat reads and new games do not double count',
    () async {
      const target = 'listen_pick.zamir-he-uzatilmasi';
      final keys = [target, ...mergedIds.map((id) => 'listen_pick.$id')];
      SharedPreferences.setMockInitialValues({
        for (var i = 0; i < 4; i++)
          'game_score.${keys[i]}.best_score': 10 * (i + 1),
        for (var i = 0; i < 4; i++)
          'game_score.${keys[i]}.best_stars': i == 3 ? 3 : 1,
        for (var i = 0; i < 4; i++) 'game_history.${keys[i]}.plays': 1,
        for (var i = 0; i < 4; i++)
          'game_history.${keys[i]}.total': 10 * (i + 1),
        for (var i = 0; i < 4; i++) 'game_history.${keys[i]}.top': 10 * (i + 1),
        for (var i = 0; i < 4; i++)
          'game_history.${keys[i]}.recent': ['${10 * (i + 1)}'],
      });
      final store = GameScoreStore();
      for (var i = 0; i < 2; i++) {
        expect((await store.recordOf(target)).bestScore, 40);
        expect((await store.recordOf(target)).bestStars, 3);
        expect((await store.historyOf(target)).plays, 4);
        expect((await store.historyOf(target)).totalPoints, 100);
      }
      await store.submit(
        target,
        const GameResult(points: 50, firstTry: 5, total: 5),
      );
      expect((await store.historyOf(target)).plays, 5);
      expect((await store.historyOf(target)).totalPoints, 150);
      expect((await store.historyOf(target)).recent.last, 50);
      expect((await store.recordOf(target)).bestScore, 50);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('game_history.${keys.last}.total'), 40);
      await store.clearAll();
      expect((await store.historyOf(target)).plays, 0);
      expect((await store.recordOf(target)).hasPlayed, isFalse);
    },
  );

  testWidgets(
    'menu opens the correct stable lesson for every new number 27–34',
    (tester) async {
      setSize(tester, const Size(1280, 1000));
      await tester.pumpWidget(
        ChangeNotifierProvider<AudioService>.value(
          value: SilentAudio(),
          child: const MaterialApp(home: ElifbaLessonsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      for (final lesson in kElifbaLessons.skip(26)) {
        final card = find.byWidgetPredicate(
          (w) => w is LessonCard && w.lesson.id == lesson.id,
        );
        await tester.scrollUntilVisible(
          card,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<LessonLettersScreen>(find.byType(LessonLettersScreen))
              .lesson,
          same(lesson),
        );
        Navigator.of(tester.element(find.byType(LessonLettersScreen))).pop();
        await tester.pumpAndSettle();
      }
    },
  );
}
