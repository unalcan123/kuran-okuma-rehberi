// Kitap sayfalarındaki Türkçe açıklamalar dinlenebilir (🔊). Metin ekranda
// gerçek Flutter metni olarak kalır; ses `assets/audio/tr/<id>.mp3`,
// kimliği PDF sayfasına bağlı (ders numarasına değil). Kayıtların metni
// `tool/turkish_audio/manifest.json`'da; oradaki metin ekrandakiyle aynı
// kalmalı. Dosyası olmayan açıklamada ikon yoktur ve dokunmak bir şey
// yapmaz. Türkçe ve Arapça ses aynı AudioService'ten çalar.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/models/lesson.dart';
import 'package:kuran_okuma_rehberi/screens/elifba/widgets/book_page.dart';
import 'package:kuran_okuma_rehberi/services/turkish_audio_catalog.dart';

import 'book_pages_test.dart' show app, lessonOf, setSize;
import 'support/silent_audio.dart';
import 'support/turkish_audio_texts.dart';

/// One player, like AudioService: whatever was asked last is the one
/// sound playing, Turkish or Arabic.
class _OnePlayer extends SilentAudio {
  final log = <String>[];

  @override
  bool get isPlaying => currentAsset != null;

  @override
  Future<void> playAsset(String assetPath) async => _play('tr', assetPath);

  @override
  Future<void> playLetter(ArabicLetter letter) async =>
      _play('ar', letter.audioAsset!);

  void _play(String kind, String asset) {
    log.add('$kind:$asset');
    currentAsset = asset;
    notifyListeners();
  }
}

Map<String, dynamic> _manifest() =>
    jsonDecode(File('tool/turkish_audio/manifest.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _entries() => [
  for (final e in _manifest()['entries'] as List) e as Map<String, dynamic>,
];

Set<String> _allAssets() => {
  for (final e in _entries()) 'audio/tr/${e['id']}.mp3',
};

Finder _block(String id) => find.byKey(ValueKey('tr-audio-$id'));
Finder _icon(String id) => find.byKey(ValueKey('tr-audio-icon-$id'));

bool _isPlayingIcon(WidgetTester tester, String id) =>
    tester.widget<Icon>(_icon(id)).icon == Icons.volume_up_rounded;

void main() {
  tearDown(() => TurkishAudioCatalog.debugSetAvailable(const {}));

  group('manifest ↔ uygulama', () {
    final shown = collectShownTurkishTexts();
    final entries = _entries();
    final byId = {for (final e in entries) e['id'] as String: e};

    test('kimlikler tek, kalıcı ve PDF sayfasına bağlı', () {
      final ids = shown.map((t) => t.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'uygulamada tekrar eden id',
      );
      expect(
        byId.length,
        entries.length,
        reason: 'manifest\'te tekrar eden id',
      );
      final pattern = RegExp(r'^s\d{3}_(\d{2}|baslik_\d)$');
      for (final e in entries) {
        final id = e['id'] as String;
        expect(pattern.hasMatch(id), isTrue, reason: id);
        // Ders numarası kimliğe girmez: dersler yeniden numaralansa da
        // dosya adları değişmez.
        expect(id, isNot(contains('ders')));
        expect(e['file'], 'assets/audio/tr/$id.mp3');
        expect(e['pdfPage'], int.parse(id.substring(1, 4)), reason: id);
        expect(e['kind'], id.contains('_baslik_') ? 'heading' : 'explanation');
      }
    });

    test('uygulamadaki her dinlenebilir metin manifest\'te, aynı metinle', () {
      expect(byId.keys.toSet(), shown.map((t) => t.id).toSet());
      for (final t in shown) {
        final e = byId[t.id]!;
        expect(
          e['text'],
          t.text,
          reason:
              '${t.id}: ekrandaki metin değişmiş. manifest.json "text" alanını '
              'güncelle (üretici değişen metni yeniden seslendirir).',
        );
        expect(e['lessonId'], t.lessonId, reason: t.id);
      }
      expect(
        kElifbaLessons.map((l) => l.id),
        containsAll(entries.map((e) => e['lessonId']).toSet()),
      );
    });

    test('Arapça içeren kayıt telaffuz incelemesi olmadan üretilmez', () {
      for (final e in entries) {
        final spoken = (e['ttsText'] as String?) ?? e['text'] as String;
        if (hasArabicLetter(spoken)) {
          expect(e['needsPronunciationReview'], isTrue, reason: e['id']);
        }
      }
    });

    test('sayılar: 71 açıklama + 34 başlık', () {
      final headings = entries.where((e) => e['kind'] == 'heading').length;
      expect(entries.length - headings, 71);
      expect(headings, 34);
      // Tekrar eden genel başlıklar (ÖRNEKLER, ALIŞTIRMALAR) seslendirilmez.
      for (final e in entries) {
        expect(e['text'], isNot(startsWith('ÖRNEKLER')));
        expect(e['text'], isNot(startsWith('ALIŞTIRMALAR')));
      }
    });
  });

  group('API anahtarı ve dosyalar', () {
    test('anahtar hiçbir yerde yok; .env git dışında', () {
      final raw = File('tool/turkish_audio/manifest.json').readAsStringSync();
      expect(raw.toLowerCase(), isNot(contains('api_key')));
      expect(raw.toLowerCase(), isNot(contains('apikey')));
      expect(raw, isNot(contains('xi-api-key')));
      for (final dir in ['lib', 'web']) {
        for (final file in Directory(dir).listSync(recursive: true)) {
          if (file is! File ||
              !RegExp(r'\.(dart|js|html|json)$').hasMatch(file.path)) {
            continue;
          }
          final text = file.readAsStringSync();
          expect(
            text.contains('ELEVENLABS') || text.contains('elevenlabs.io'),
            isFalse,
            reason: '${file.path}: uygulama ElevenLabs\'e bağlanmaz',
          );
        }
      }
      final ignore = File('.gitignore').readAsLinesSync();
      expect(ignore, contains('.env'));
    });

    test('assets/audio/tr/ pubspec\'te bir kez', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect('- assets/audio/tr/'.allMatches(pubspec).length, 1);
      expect(Directory('assets/audio/tr').existsSync(), isTrue);
    });

    test('manifest ↔ mp3: üretilen her kaydın dosyası var, fazlası yok', () {
      expect(
        File('tool/turkish_audio/manifest.json').readAsStringSync(),
        isNot(matches(RegExp(r'sk_[0-9a-f]{20,}'))),
      );
      final files = {
        for (final f in Directory('assets/audio/tr').listSync())
          if (f is File && f.path.endsWith('.mp3'))
            f.uri.pathSegments.last: f.lengthSync(),
      };
      final entries = _entries();
      final named = {for (final e in entries) '${e['id']}.mp3'};
      expect(
        files.keys.toSet().difference(named),
        isEmpty,
        reason: 'sahipsiz mp3',
      );
      for (final e in entries) {
        final name = '${e['id']}.mp3';
        if (e['status'] == 'generated') {
          expect(
            files[name],
            greaterThan(1024),
            reason: '$name eksik ya da boş',
          );
          expect(e['textHash'], startsWith('sha256:'), reason: name);
          expect(e['model'], isNotNull, reason: name);
          expect(e['voiceId'], isNotNull, reason: name);
        } else {
          expect(files.containsKey(name), isFalse, reason: '$name: status');
        }
        // Telaffuz incelemesi bitmeden kayıt üretilmez.
        if (e['needsPronunciationReview'] == true) {
          expect(e['status'], isNot('generated'), reason: name);
        }
      }
    });

    testWidgets('uygulama paketindeki Türkçe sesler = üretilen kayıtlar', (
      tester,
    ) async {
      final generated = {
        for (final e in _entries())
          if (e['status'] == 'generated') 'audio/tr/${e['id']}.mp3',
      };
      final manifest = await tester.runAsync(
        () => AssetManifest.loadFromAssetBundle(rootBundle),
      );
      final packaged = {
        for (final a in manifest!.listAssets())
          if (a.startsWith('assets/audio/tr/') && a.endsWith('.mp3'))
            a.substring('assets/'.length),
      };
      expect(packaged, generated);
    });
  });

  group('Sayfa görünümü', () {
    testWidgets('ses dosyası yoksa ikon yok, dokunmak bir şey yapmaz', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      TurkishAudioCatalog.debugSetAvailable(const {});
      final audio = _OnePlayer();
      await tester.pumpWidget(app(audio, kUstunLesson));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_up_outlined), findsNothing);
      expect(_block('s014_02'), findsNothing);
      await tester.tap(
        find.textContaining('Üstün, harfin', findRichText: true),
      );
      await tester.pump();
      expect(audio.log, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Türkçe ↔ Türkçe ↔ Arapça: her dokunuş öncekini keser', (
      tester,
    ) async {
      setSize(tester, const Size(1280, 800));
      TurkishAudioCatalog.debugSetAvailable(const {
        'audio/tr/s014_01.mp3',
        'audio/tr/s014_02.mp3',
      });
      final audio = _OnePlayer();
      await tester.pumpWidget(app(audio, kUstunLesson));
      await tester.pumpAndSettle();

      // Only the recorded ones get a speaker (heading has no file here).
      expect(_icon('s014_01'), findsOneWidget);
      expect(_icon('s014_02'), findsOneWidget);
      expect(_icon('s014_baslik_1'), findsNothing);

      // A two-paragraph rule is one block: either paragraph plays it.
      await tester.tap(
        find.textContaining('Fakat hiçbir hareke', findRichText: true),
      );
      await tester.pump();
      expect(audio.log, ['tr:audio/tr/s014_01.mp3']);
      expect(_isPlayingIcon(tester, 's014_01'), isTrue);

      await tester.tap(
        find.textContaining('Üstün, harfin', findRichText: true),
      );
      await tester.pump();
      expect(audio.log.last, 'tr:audio/tr/s014_02.mp3');
      expect(_isPlayingIcon(tester, 's014_01'), isFalse);
      expect(_isPlayingIcon(tester, 's014_02'), isTrue);

      // Arabic cell: the Turkish one stops.
      await tester.tap(find.byKey(const ValueKey('book-cell-1')));
      await tester.pump();
      expect(audio.log.last, startsWith('ar:'));
      expect(_isPlayingIcon(tester, 's014_02'), isFalse);

      // Turkish again: the Arabic one stops; same block again restarts it.
      await tester.tap(_block('s014_02'));
      await tester.tap(_block('s014_02'));
      await tester.pump();
      expect(audio.log.sublist(audio.log.length - 2), [
        'tr:audio/tr/s014_02.mp3',
        'tr:audio/tr/s014_02.mp3',
      ]);
      expect(audio.currentAsset, 'audio/tr/s014_02.mp3');
      expect(tester.takeException(), isNull);
    });

    testWidgets('başlığa dokununca başlığın sesi çalar', (tester) async {
      setSize(tester, const Size(800, 1280));
      TurkishAudioCatalog.debugSetAvailable(const {
        'audio/tr/s014_baslik_1.mp3',
      });
      final audio = _OnePlayer();
      await tester.pumpWidget(app(audio, kUstunLesson));
      await tester.pumpAndSettle();

      expect(_icon('s014_baslik_1'), findsOneWidget);
      await tester.tap(find.text('ÜSTÜN'));
      await tester.pump();
      expect(audio.log, ['tr:audio/tr/s014_baslik_1.mp3']);
    });
  });

  group('Kitap sayfası (Ders 23-30)', () {
    testWidgets('Kapalı Te: açıklama ve başlık dinlenir, tablo yerinde', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      TurkishAudioCatalog.debugSetAvailable(const {
        'audio/tr/s056_baslik_1.mp3',
        'audio/tr/s056_01.mp3',
        'audio/tr/s056_02.mp3',
      });
      final audio = _OnePlayer();
      await tester.pumpWidget(app(audio, lessonOf('kapali-te')));
      await tester.pumpAndSettle();

      expect(find.byType(BookPage), findsOneWidget);
      await tester.tap(
        find.textContaining(
          'Bu sadece kelime sonunda olur',
          findRichText: true,
        ),
      );
      await tester.pump();
      expect(audio.log, ['tr:audio/tr/s056_01.mp3']);

      await tester.ensureVisible(_block('s056_02'));
      await tester.pumpAndSettle();
      await tester.tap(_block('s056_02'));
      await tester.pump();
      expect(audio.log.last, 'tr:audio/tr/s056_02.mp3');
      expect(_isPlayingIcon(tester, 's056_01'), isFalse);

      await tester.ensureVisible(find.text('KAPALI “TE”'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KAPALI “TE”'));
      await tester.pump();
      expect(audio.log.last, 'tr:audio/tr/s056_baslik_1.mp3');
      expect(tester.takeException(), isNull);
    });
  });

  // Every recording of the manifest appears on its lesson's page, and the
  // pages still fit on a phone and a desktop with every speaker shown.
  for (final size in const [Size(360, 800), Size(1920, 1080)]) {
    testWidgets('bütün ikonlar görünürken bütün sayfalar sığar ($size)', (
      tester,
    ) async {
      setSize(tester, size);
      final all = _allAssets();
      TurkishAudioCatalog.debugSetAvailable(all);
      final seen = <String>{};
      final lessonIds = {for (final e in _entries()) e['lessonId'] as String};
      for (final Lesson lesson in kElifbaLessons.where(
        (l) => lessonIds.contains(l.id),
      )) {
        // A new screen per lesson, as when it is opened from the menu.
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey(lesson.id),
            child: app(_OnePlayer(), lesson),
          ),
        );
        await tester.pumpAndSettle();
        final pages = lesson.pageLayout?.pages.length ?? 1;
        for (var p = 0; p < pages; p++) {
          for (final element in find.byType(GestureDetector).evaluate()) {
            final key = element.widget.key;
            if (key is ValueKey<String> && key.value.startsWith('tr-audio-')) {
              final box = element.renderObject! as RenderBox;
              expect(box.size.height, greaterThan(16), reason: key.value);
              expect(box.size.width, greaterThan(60), reason: key.value);
              seen.add(key.value.substring('tr-audio-'.length));
            }
          }
          expect(tester.takeException(), isNull, reason: '${lesson.id} s.$p');
          if (p < pages - 1) {
            await tester.tap(find.byKey(const ValueKey('page-next')));
            await tester.pumpAndSettle();
          }
        }
      }
      expect(seen, {for (final e in _entries()) e['id']});
    });
  }
}
