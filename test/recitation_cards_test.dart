import 'package:kuran_okuma_rehberi/data/dua_groups.dart';
import 'package:kuran_okuma_rehberi/data/supplementary_sureler_data.dart';
// Sure ve dua listeleri: master görsellerden kırpılmış kartlar
// (tool/crop_lesson_cards.py), Elifba ders kartlarıyla aynı PictureCard.
// Sureler Kur’an sırasındadır; kart numaraları 1–11 olarak gösterilir.
// Görsel dosyaları eski kimlik eşleşmelerini korur.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/additional_dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/dualar_data.dart';
import 'package:kuran_okuma_rehberi/data/recitation_card_images.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/l10n/l10n.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dua_detail_screen.dart';
import 'package:kuran_okuma_rehberi/screens/dualar/dualar_list_screen.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/surah_detail_screen.dart';
import 'package:kuran_okuma_rehberi/data/sure_groups.dart';
import 'package:kuran_okuma_rehberi/screens/sureler/sureler_list_screen.dart';
import 'package:kuran_okuma_rehberi/widgets/picture_card.dart';
import 'package:kuran_okuma_rehberi/widgets/recitation_title_overlay.dart';

import 'dualar_test.dart' show TestAudioService, harness;

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('dualar: 9 kart, sırayla, dosyalar var; başlık kimlikten ayrı', () {
    expect(kDualar, hasLength(9));
    for (final dua in kDualar) {
      final image = kDuaCardImages[dua.id]!;
      expect(
        image,
        endsWith('dua_${dua.order.toString().padLeft(2, '0')}.png'),
      );
      expect(File(image).existsSync(), isTrue, reason: image);
      expect(kDuaDisplayTitles[dua.id], isNotNull, reason: dua.id);
    }
    expect(kDuaCardImages.values.toSet(), hasLength(15));
    expect(kDuaDisplayTitles['7_kunut1_duasi'], contains('Kunut 1'));
    expect(kDuaDisplayTitles['8_kunut2_duasi'], contains('Kunut 2'));
    // Kunut 1 / 2 metinle uyumlu (görseldeki başlıklar).
    expect(
      kDualar.firstWhere((d) => d.id == '7_kunut1_duasi').segments.first.arabic,
      contains('نَسْتَعِينُكَ'),
    );
    expect(
      kDualar.firstWhere((d) => d.id == '8_kunut2_duasi').segments.first.arabic,
      contains('اِيَّاكَ نَعْبُدُ'),
    );
  });

  test(
    'yazısız dua resimleri: 15 resim sırayla, hepsi aynı dikey biçimde',
    () async {
      for (final dua in kAllDualar) {
        final path = kDuaTextFreeImages[dua.id]!;
        expect(duaCardImage(dua.id), path);
        expect(
          path,
          endsWith('dua_${dua.order.toString().padLeft(2, '0')}.png'),
        );
        final codec = await ui.instantiateImageCodec(
          File(path).readAsBytesSync(),
        );
        final image = (await codec.getNextFrame()).image;
        expect(
          Size(image.width * 1.0, image.height * 1.0),
          kDuaCardImageSize,
          reason: path,
        );
      }
    },
  );

  testWidgets('başka dilde resim aynen kalır, çeviri kartın altında (dua)', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1280));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    final controller = LanguageController(initial: AppLanguage.nl);
    await tester.pumpWidget(
      AppLanguageScope(
        controller: controller,
        child: harness(
          DualarListScreen(
            group: kDuaGroups.firstWhere((g) => g.ids.contains('15_tefriciye')),
          ),
          audio,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('dua-card-15_tefriciye'));
    final caption = find.byKey(const ValueKey('dua-caption-15_tefriciye'));
    await tester.scrollUntilVisible(caption, 300);
    await tester.pumpAndSettle();
    // The same picture as in Turkish; over it only the number.
    expect(
      tester.widget<PictureCard>(card).image,
      duaCardImage('15_tefriciye'),
    );
    expect(tester.widget<PictureCard>(card).overlay, isNull);
    expect(
      find.descendant(of: caption, matching: find.text('Gebed 3')),
      findsOneWidget,
    );
    // Caption right under the picture, inside its own cell.
    final pic = tester.getRect(card), cap = tester.getRect(caption);
    expect(cap.top, closeTo(pic.bottom, 1));
    expect(cap.width, closeTo(pic.width, 1));
    expect(
      find.descendant(
        of: caption,
        matching: find.textContaining(
          'Salat Tafrijiyya gebed',
          findRichText: true,
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    // Tapping the caption opens the prayer too.
    await tester.tap(caption);
    await tester.pumpAndSettle();
    expect(find.byType(DuaDetailScreen), findsOneWidget);
  });

  testWidgets('Türkçede de başlık kartların altında (dua ve sure)', (
    tester,
  ) async {
    setSize(tester, const Size(800, 1280));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    for (final (screen, card, caption, text) in [
      (
        DualarListScreen(group: kDuaGroups.first) as Widget,
        'dua-card-1_subhaneke_duasi',
        'dua-caption-1_subhaneke_duasi',
        'Sübhâneke Duası',
      ),
      (
        SurelerListScreen(group: kSureGroups.first),
        'surah-card-fatiha',
        'surah-caption-fatiha',
        kSureler.first.titleTr,
      ),
    ]) {
      await tester.pumpWidget(harness(screen, audio));
      await tester.pumpAndSettle();
      final pic = tester.getRect(find.byKey(ValueKey(card)));
      final cap = find.byKey(ValueKey(caption));
      expect(tester.getRect(cap).top, closeTo(pic.bottom, 1));
      expect(
        find.descendant(of: cap, matching: find.text(text)),
        findsOneWidget,
      );
      // Nothing written over the surah picture but its number.
      final overlay =
          tester.widget<PictureCard>(find.byKey(ValueKey(card))).overlay;
      if (overlay is RecitationTitleOverlay) expect(overlay.showTitle, isFalse);
      expect(tester.takeException(), isNull);
    }
  });

  for (final (size, min, max) in [
    // Upright phone: two columns (user, 2026-10-31); tablet three or four.
    (const Size(360, 800), 2, 2),
    (const Size(390, 844), 2, 2),
    (const Size(800, 1280), 2, 3),
    (const Size(1280, 800), 3, 4),
    (const Size(1920, 1080), 3, 4),
  ]) {
    testWidgets('dua ve sure kartları $size: $min-$max sütun, yazı taşmaz', (
      tester,
    ) async {
      setSize(tester, size);
      final audio = TestAudioService();
      addTearDown(audio.dispose);
      for (final (screen, prefix) in [
        (DualarListScreen(group: kDuaGroups.first) as Widget, 'dua-card-'),
        (SurelerListScreen(group: kSureGroups.first), 'surah-card-'),
      ]) {
        await tester.pumpWidget(harness(screen, audio));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$prefix $size');
        final cards = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(prefix),
        );
        final firstTop = tester.getRect(cards.first).top;
        final columns =
            [
              for (final e in cards.evaluate())
                if ((tester.getRect(find.byWidget(e.widget)).top - firstTop)
                        .abs() <
                    1)
                  e,
            ].length;
        expect(columns, inInclusiveRange(min, max), reason: '$prefix $size');
      }
    });
  }

  test('yazısız sure resimleri: 26 öğe, hepsi aynı kare biçimde', () async {
    final pictured = kAllNamazTexts;
    expect(kSurahTextFreeImages.keys, pictured.map((s) => s.id));
    expect(kSurahTextFreeImages.values.toSet(), hasLength(26));
    for (final surah in pictured) {
      final path = kSurahTextFreeImages[surah.id]!;
      expect(surahCardImage(surah.id), path);
      final codec = await ui.instantiateImageCodec(
        File(path).readAsBytesSync(),
      );
      final image = (await codec.getNextFrame()).image;
      expect(
        Size(image.width * 1.0, image.height * 1.0),
        kSurahCardImageSize,
        reason: path,
      );
    }
  });

  test('sureler: 11 kart, uygulamanın sırasıyla, dosyalar var', () {
    expect(kSureler.map((s) => s.id), [
      'fatiha',
      'fil',
      'kureysh',
      'maun',
      'kevser',
      'kafirun',
      'nasr',
      'tebbet',
      'ihlas',
      'felak',
      'nas',
    ]);
    expect(kSureler.map((s) => s.order), List.generate(11, (i) => i + 1));
    const originalImages = {
      'fatiha': 1,
      'fil': 2,
      'kureysh': 3,
      'maun': 4,
      'ihlas': 5,
      'kevser': 6,
      'nas': 7,
      'felak': 8,
      'nasr': 9,
      'tebbet': 10,
      'kafirun': 11,
    };
    for (final surah in kSureler) {
      final image = kSurahCardImages[surah.id]!;
      expect(
        image,
        endsWith(
          'sure_${originalImages[surah.id].toString().padLeft(2, '0')}.png',
        ),
      );
      expect(File(image).existsSync(), isTrue, reason: image);
    }
    // Kartlar 12-23: kAllNamazTexts'in kSureler'den sonrası, sırayla
    // (24 Âmenerrasûlü'nün, 25 Hüvellezî'nin, 26 Hüvallâhüllezî'nin eski kartı yok).
    for (var i = kSureler.length; i < 23; i++) {
      final image = kSurahCardImages[kAllNamazTexts[i].id]!;
      expect(image, endsWith('sure_${i + 1}.png'), reason: image);
      expect(File(image).existsSync(), isTrue, reason: image);
    }
    expect(kAllNamazTexts, hasLength(26));
    expect(kSurahCardImages.values.toSet(), hasLength(23));
    final files =
        Directory(
            'assets/images/lessons/sureler',
          ).listSync().map((f) => f.uri.pathSegments.last).toList()
          ..sort();
    expect(files, [
      for (var n = 1; n <= 23; n++) 'sure_${n.toString().padLeft(2, '0')}.png',
    ]);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/images/lessons/sureler/'));
    expect(pubspec, contains('assets/images/lessons/dualar/'));
  });

  testWidgets('dua kartı: resmin üstünde yazı yok, dokununca o dua açılır', (
    tester,
  ) async {
    setSize(tester, const Size(1280, 800));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(DualarListScreen(group: kDuaGroups.first), audio),
    );
    await tester.pumpAndSettle();
    final card = find.byKey(ValueKey('dua-card-${kDualar[6].id}'));
    await tester.scrollUntilVisible(card, 200);
    await tester.pumpAndSettle();
    // Nothing written over the picture; number and name under it.
    expect(
      find.descendant(of: card, matching: find.byType(Text)),
      findsNothing,
    );
    final caption = find.byKey(ValueKey('dua-caption-${kDualar[6].id}'));
    expect(
      find.descendant(of: caption, matching: find.text('Dua 7')),
      findsOneWidget,
    );
    final size = tester.getSize(card);
    expect(size.width / size.height, closeTo(kDuaCardAspectRatio, 0.01));
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DuaDetailScreen>(find.byType(DuaDetailScreen)).dua,
      same(kDualar[6]),
    );
  });

  testWidgets('sure kartları görselli, numara güncel; dokununca o sure '
      'açılır', (tester) async {
    setSize(tester, const Size(1280, 800));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      harness(SurelerListScreen(group: kSureGroups.first), audio),
    );
    await tester.pumpAndSettle();
    // The number is written under the picture (its title area).
    final fatiha = find.byKey(const ValueKey('surah-card-fatiha'));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('surah-caption-fatiha')),
        matching: find.text('Sure 1'),
      ),
      findsOneWidget,
    );
    for (var i = 0; i < kSureler.length; i++) {
      final card = find.byKey(ValueKey('surah-caption-${kSureler[i].id}'));
      await tester.scrollUntilVisible(card, 150);
      expect(
        find.descendant(
          of: card,
          matching: find.text(
            'Sure ${kAllNamazTexts.indexOf(kSureler[i]) + 1}',
          ),
        ),
        findsOneWidget,
      );
    }
    await tester.scrollUntilVisible(fatiha, -150);
    // Every picture area has the cards' shape.
    final size = tester.getSize(fatiha);
    expect(size.width / size.height, closeTo(kSurahCardAspectRatio, 0.01));

    await tester.ensureVisible(fatiha);
    await tester.pumpAndSettle();
    await tester.tap(fatiha);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SurahDetailScreen>(find.byType(SurahDetailScreen)).surah,
      same(kSureler.first),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    final fil = find.byKey(const ValueKey('surah-card-fil'));
    await tester.scrollUntilVisible(fil, 150);
    await tester.ensureVisible(fil);
    await tester.pumpAndSettle();
    await tester.tap(fil);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SurahDetailScreen>(find.byType(SurahDetailScreen)).surah,
      same(kSureler[1]),
    );
  });

  for (final size in const [
    Size(360, 800),
    Size(800, 1280),
    Size(1280, 800),
    Size(800, 360),
    Size(1920, 1080),
  ]) {
    testWidgets('$size: sure ve dua listeleri taşmaz, kartlar okunur boyda', (
      tester,
    ) async {
      setSize(tester, size);
      final audio = TestAudioService();
      addTearDown(audio.dispose);
      for (final screen in [
        SurelerListScreen(group: kSureGroups.first),
        DualarListScreen(group: kDuaGroups.first),
      ]) {
        await tester.pumpWidget(harness(screen, audio));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // On screen (TabletZoom enlarges it on a tablet or a desktop).
        final first = tester.getRect(find.byType(PictureCard).first).size;
        // Two columns on an upright phone (~150 px cards, 2026-10-31).
        expect(first.width, greaterThanOrEqualTo(140), reason: '$screen');
        for (var i = 0; i < 10; i++) {
          await tester.drag(find.byType(GridView), const Offset(0, -300));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

  testWidgets('Sureler girişi: üç grup kartı; dokununca grubun sureleri açılır', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    expect(kSureGroups.map((g) => g.titleTr), [
      'Namazda Okunan Kısa Sureler',
      'Amme Cüzündeki Aşirler',
      'Namazlardan Sonra Okunan Sureler, Aşirler',
    ]);
    expect(kSureGroups[0].surahs, kSureler);
    expect(kSureGroups[1].surahs.map((s) => s.id), [
      'duha', 'insirah', 'tin', 'kadir', 'zilzal', 'adiyat', 'karia',
      'tekasur', 'asr', 'humeze',
    ]);
    expect(
      kSureGroups[2].surahs.map((s) => s.id),
      orderedEquals([
        'ayetel-kursi',
        'huvallahullezi',
        'huvellezi',
        'nebe-son',
        'amenerrasulu',
      ]),
    );
    // Every reading is in exactly one group.
    expect(
      [for (final g in kSureGroups) ...g.surahs.map((s) => s.id)]..sort(),
      kAllNamazTexts.map((s) => s.id).toList()..sort(),
    );
    for (final g in kSureGroups.skip(2)) {
      for (final s in g.surahs) {
        expect(g.notesTr[s.id], isNotNull, reason: s.id);
      }
    }

    await tester.pumpWidget(harness(const SurelerListScreen(), audio));
    await tester.pumpAndSettle();
    for (final g in kSureGroups) {
      expect(find.byKey(ValueKey('sure-group-${g.id}')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('surah-card-fatiha')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('sure-group-namaz-sonrasi')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('surah-card-nebe-son')), findsOneWidget);
    expect(find.text('İkindi namazından sonra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dualar girişi: dört grup kartı, her dua bir grupta', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final audio = TestAudioService();
    addTearDown(audio.dispose);
    expect(kDuaGroups.map((g) => g.titleTr), [
      'Namazda Okunan Dualar',
      'Namazdan Sonra Okunan Dualar',
      'Günlük Dualar',
      'Ezan, Kamet, Namaz Lafızları',
    ]);
    expect(kDuaGroups.first.ids, kDualar.take(8).map((d) => d.id));
    expect(kDuaGroups[1].ids, ['12_namaz_tesbihati', '14_salaten_tuncina']);
    expect(kDuaGroups[2].ids, ['9_amentu_duasi', '13_yemek_duasi', '15_tefriciye']);
    expect(kDuaGroups[3].ids, contains('10_ezan_duasi'));
    expect(
      [for (final g in kDuaGroups) ...g.ids]..sort(),
      kAllDualar.map((d) => d.id).toList()..sort(),
    );
    await tester.pumpWidget(harness(const DualarListScreen(), audio));
    await tester.pumpAndSettle();
    for (final g in kDuaGroups) {
      expect(find.byKey(ValueKey('dua-group-${g.id}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('dua-group-gunluk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dua-card-9_amentu_duasi')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
