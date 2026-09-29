// Namaz Duaları / Sureleri listeleri: sevimli kutsal mekânlar arka planı
// (Kâbe, yeşil kubbe, cami; şekillerle çizilir, fotoğraf yok).
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dualar_list_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/sureler_list_screen.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/widgets/holy_places_background.dart';
import 'package:provider/provider.dart';

import 'book_pages_test.dart' show RecordingAudio, setSize;

Widget _app(Widget home) => ChangeNotifierProvider<AudioService>(
  create: (_) => RecordingAudio(),
  child: MaterialApp(home: home),
);

void main() {
  for (final (name, screen) in const [
    ('Dualar', DualarListScreen()),
    ('Sureler', SurelerListScreen()),
  ]) {
    for (final size in const [Size(360, 800), Size(1280, 800)]) {
      testWidgets('$name listesi $size: arka plan altta, dokunmaz', (
        tester,
      ) async {
        setSize(tester, size);
        await tester.pumpWidget(_app(screen));
        await tester.pumpAndSettle();
        expect(find.byType(HolyPlacesBackground), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey('holy-places-background')),
            matching: find.byType(IgnorePointer),
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('Kâbe her genişlikte yatayda tam ortada, altta çimenlikte', () {
    for (final size in const [
      Size(360, 800),
      Size(800, 1280),
      Size(1280, 800),
      Size(1920, 1080),
    ]) {
      final center = HolyPlacesPainter.kaabaCenterX(size);
      final half = HolyPlacesPainter.kaabaWidthFor(size) / 2;
      // Sol ve sağ kenara eşit uzaklık.
      expect(center - half, closeTo(size.width - (center + half), 0.001));
      // Ekrana sığar; sahne alt kısımda kalır.
      expect(center - half, greaterThan(0));
      expect(
        HolyPlacesPainter.sceneHeightFor(size),
        lessThan(size.height * 0.45),
      );
    }
  });

  test('her boyutta çizilir (boş ve çok küçük dahil)', () {
    const painter = HolyPlacesPainter();
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
