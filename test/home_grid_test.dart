// Ana sayfa: 4 kart, 2 x 2 grid (çok dar ekranda tek sütun), kartlar 4:3.
// İlk kart yalnız "Kur'an Okuma Rehberi" görseli (ayrıca başlık yazılmaz) ve
// Elifba derslerini açar. Ders Grid görünümü hafif gökyüzü arka planında.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dualar_list_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/elifba_lessons_screen.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/all_letters_grid.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/lesson_page_view.dart';
import 'package:kuran_okuma_rehberi/screens/home/home_screen.dart';
import 'package:kuran_okuma_rehberi/screens/home/widgets/home_grid_card.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/oyunlar_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/sureler_list_screen.dart';
import 'package:kuran_okuma_rehberi/screens/oyunlar/harf_oyunlari/profil/player_repository.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/services/game_score_store.dart';
import 'package:kuran_okuma_rehberi/widgets/lesson_grid_background.dart';
import 'package:provider/provider.dart';

import 'book_pages_test.dart' show RecordingAudio, app, setSize;

const _titles = [
  "Kur'an Okuma Rehberi",
  'Namaz Duaları',
  'Namaz Sureleri',
  'Oyunlar',
];

Widget _home() => MultiProvider(
  providers: [
    ChangeNotifierProvider<AudioService>(create: (_) => RecordingAudio()),
    Provider<GameScoreStore>.value(value: GameScoreStore()),
    // Oyunlar menüsü ad sormasın (ad akışı player_ui_test.dart).
    ChangeNotifierProvider(
      create: (_) => PlayerRepository()..promptedThisSession = true,
    ),
  ],
  child: const MaterialApp(home: HomeScreen()),
);

void main() {
  for (final (size, columns) in const [
    (Size(360, 800), 2),
    (Size(800, 1280), 2),
    (Size(1280, 800), 2),
    (Size(800, 360), 2),
    (Size(1920, 1080), 2),
    (Size(300, 640), 1),
  ]) {
    testWidgets('ana sayfa gridi $size: $columns sütun, kartlar 4:3', (
      tester,
    ) async {
      setSize(tester, size);
      await tester.pumpWidget(_home());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final cards = find.byType(HomeGridCard);
      expect(cards, findsNWidgets(4));
      final rects = [for (var i = 0; i < 4; i++) tester.getRect(cards.at(i))];
      for (final r in rects) {
        expect(r.width / r.height, closeTo(4 / 3, 0.01));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(size.width));
      }
      final rowsOfFirstTwo = rects[0].top == rects[1].top;
      expect(rowsOfFirstTwo, columns == 2);

      // Her görsel kartını tamamen doldurur; başlık ayrıca yazılmaz.
      for (var i = 0; i < 4; i++) {
        final title = _titles[i];
        final image = tester.getRect(
          find.byKey(ValueKey('home-card-image-$title')),
        );
        expect(image, rects[i], reason: title);
      }
      // Geliştirici aracı ana sayfada yok (ayrı giriş noktası).
      expect(find.byKey(const ValueKey('home-tr-audio-qc')), findsNothing);
      expect(find.textContaining('Ses Kontrol'), findsNothing);
      // Yalnız sayfanın üst başlığı; kartlarda yazı yok.
      expect(find.text("Kur'an Okuma Rehberi"), findsOneWidget);
      for (final title in _titles.skip(1)) {
        expect(find.text(title), findsNothing);
      }
    });
  }

  test('kart görselleri küçük WebP (web açılışı hızlı)', () {
    final files = Directory('assets/images/home').listSync().whereType<File>();
    expect(files.map((f) => f.uri.pathSegments.last).toSet(), {
      'kuran_okuma_rehberi.webp',
      'namaz_dualari.webp',
      'namaz_sureleri.webp',
      'oyunlar.webp',
    });
    for (final f in files) {
      expect(f.lengthSync(), lessThan(200 * 1024), reason: f.path);
    }
  });

  testWidgets('sıra: Rehber, Dualar, Sureler, Oyunlar', (tester) async {
    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    final cards = find.byType(HomeGridCard);
    expect(
      [
        for (var i = 0; i < 4; i++) tester.widget<HomeGridCard>(cards.at(i)),
      ].map((c) => c.item.title),
      _titles,
    );
  });

  for (final (title, screen) in [
    (_titles[0], ElifbaLessonsScreen),
    (_titles[1], DualarListScreen),
    (_titles[2], SurelerListScreen),
    (_titles[3], OyunlarScreen),
  ]) {
    testWidgets('"$title" kartı kendi bölümünü açar', (tester) async {
      setSize(tester, const Size(1280, 800));
      await tester.pumpWidget(_home());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('home-card-image-$title')));
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget);
    });
  }

  testWidgets('ders Grid görünümü gökyüzü arka planında, Sayfa değil', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
    await tester.pumpAndSettle();
    expect(find.byType(LessonPageView), findsOneWidget);
    expect(find.byType(LessonGridBackground), findsNothing);

    await tester.tap(find.text('▦ Grid'));
    await tester.pumpAndSettle();
    expect(find.byType(AllLettersGrid), findsOneWidget);
    expect(find.byType(LessonGridBackground), findsOneWidget);
    // Arka plan dokunmaları almaz; kartlar üstünde, tam ekran.
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('lesson-grid-background')),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  test('arka plan her boyutta çizilir (boş ve çok küçük dahil)', () {
    const painter = LessonGridBackgroundPainter();
    for (final size in const [
      Size.zero,
      Size(10, 10),
      Size(360, 800),
      Size(1920, 1080),
    ]) {
      final recorder = ui.PictureRecorder();
      painter.paint(ui.Canvas(recorder), size);
      recorder.endRecording();
    }
  });
}
