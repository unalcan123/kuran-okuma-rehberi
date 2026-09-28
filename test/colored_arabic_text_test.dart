// ColoredArabicText'in Arapça harf birleşimini (shaping) BOZMADIĞINI ve
// harf gövdesine renk TAŞIRMADIĞINI kanıtlar. Hasenat.ttf, uygulamanın
// kullandığı dosya.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/helpers/arabic_colorizer.dart';
import 'package:kuran_okuma_rehberi/helpers/colored_arabic_text.dart';

Future<void> _loadHasenat() async {
  final loader = FontLoader('Hasenat');
  final file = File('assets/fonts/Hasenat.ttf');
  loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}

const style = TextStyle(
  fontFamily: 'Hasenat',
  fontSize: 60,
  height: 1.55,
  color: Colors.black,
);

/// Only the marks (no letter bodies): what may never bleed into a letter.
final _marksOnly = ArabicColorProfile({
  for (final e in arabicPartColors.entries)
    if (!const {
      ArabicPart.thickLetter,
      ArabicPart.maddAlif,
      ArabicPart.maddYa,
      ArabicPart.maddWaw,
    }.contains(e.key))
      e.key: e.value,
});

class _Px {
  _Px(this.r, this.g, this.b);
  final int r, g, b;
  bool get isInk => r < 200 && g < 200 && b < 200;
  bool get isReddish => r > g + 40 && r > b + 40;
  bool get isBlueish => b > r + 40 && b > g + 20;
  bool get isGreenish => g > r + 40 && g > b + 40;
  bool get isColored => isReddish || isBlueish || isGreenish;
}

const _w = 720, _h = 130;

Future<List<List<_Px>>> _grid(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(_w + 0.0, _h + 0.0));
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('b'),
      child: Container(
        color: Colors.white,
        width: _w + 0.0,
        height: _h + 0.0,
        alignment: Alignment.topCenter,
        child: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('b')),
  );
  final bytes =
      (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final data = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        return data!.buffer.asUint8List();
      }))!;
  return [
    for (var y = 0; y < _h; y++)
      [
        for (var x = 0; x < _w; x++)
          _Px(
            bytes[(y * _w + x) * 4],
            bytes[(y * _w + x) * 4 + 1],
            bytes[(y * _w + x) * 4 + 2],
          ),
      ],
  ];
}

/// No colored pixel of [text] lies on the ink of its letters (drawn without
/// marks); returns how many colored pixels there are.
Future<int> _expectNoColorOnLetters(
  WidgetTester tester,
  String text,
  ArabicColorProfile profile,
) async {
  final letters = await _grid(
    tester,
    Text(stripArabicMarks(text), style: style),
  );
  // The 7 thick letters' bodies are red on purpose (global rule): their
  // pixels (and the anti-aliased edge next to them) may be colored.
  final thick = await _grid(
    tester,
    ColoredArabicText(
      stripArabicMarks(text),
      style: style,
      profile: ArabicColorProfile.none,
    ),
  );
  bool onThickLetter(int x, int y) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final yy = y + dy, xx = x + dx;
        if (yy < 0 || yy >= _h || xx < 0 || xx >= _w) continue;
        if (thick[yy][xx].isReddish) return true;
      }
    }
    return false;
  }
  final colored = await _grid(
    tester,
    ColoredArabicText(text, style: style, profile: profile),
  );
  var count = 0;
  for (var y = 0; y < _h; y++) {
    for (var x = 0; x < _w; x++) {
      if (!colored[y][x].isColored) continue;
      count++;
      if (onThickLetter(x, y)) continue;
      expect(
        letters[y][x].isInk,
        isFalse,
        reason: '"$text": harf gövdesi ($x,$y) renk almış',
      );
    }
  }
  return count;
}

bool _any(List<List<_Px>> g, bool Function(_Px) test) =>
    g.any((row) => row.any(test));

void main() {
  setUpAll(_loadHasenat);

  test('harekeler çıkarılınca harflerin yeri değişmez (bütün dersler)', () {
    // Renkli katmanlar harekesiz metni silgi olarak kullanır; bu ancak
    // harfler iki metinde de tam aynı yerdeyse doğru çalışır.
    for (final lesson in kElifbaLessons) {
      for (final letter in lesson.letters) {
        final text = letter.isolatedForm;
        final bare = stripArabicMarks(text);
        TextPainter paint(String t) => TextPainter(
          text: TextSpan(text: t, style: style),
          textDirection: TextDirection.rtl,
        )..layout();
        final full = paint(text), stripped = paint(bare);
        expect(stripped.width, closeTo(full.width, 0.5), reason: text);
        final plan = ArabicColorizer.plan(text);
        var offset = 0;
        for (final cluster in plan) {
          final a = full.getBoxesForSelection(
            TextSelection(baseOffset: cluster.start, extentOffset: cluster.end),
          );
          final b = stripped.getBoxesForSelection(
            TextSelection(
              baseOffset: offset,
              extentOffset: offset + cluster.base.length,
            ),
          );
          offset += cluster.base.length;
          if (a.isEmpty || b.isEmpty) continue;
          expect(
            b.first.left,
            closeTo(a.first.left, 0.5),
            reason: '${lesson.label} "$text" harf ${cluster.base}',
          );
        }
        full.dispose();
        stripped.dispose();
      }
    }
  });

  group('işaretin rengi harfin gövdesine hiç taşmaz', () {
    testWidgets('بَ بِ بُ بْ بّ بً بٍ بٌ', (tester) async {
      for (final text in ['بَ', 'بِ', 'بُ', 'بْ', 'بَّ', 'بً', 'بٍ', 'بٌ']) {
        final n = await _expectNoColorOnLetters(tester, text, _marksOnly);
        expect(n, greaterThan(0), reason: '"$text" işareti renk almadı');
      }
    });

    testWidgets('Ders 3 (Üstün): bütün öğeler, kitap profilleriyle', (
      tester,
    ) async {
      final lesson = kUstunLesson;
      for (var i = 0; i < lesson.letters.length; i++) {
        final text = lesson.letters[i].isolatedForm;
        final profile = lesson.pageLayout!.colorProfileOf(i);
        // Kalın harf gövdesi kasıtlı boyanır (s. 14); gövde testi yalnızca
        // işaretler için.
        final marks = ArabicColorProfile({
          for (final e in profile.colors.entries)
            if (e.key != ArabicPart.thickLetter) e.key: e.value,
        });
        final n = await _expectNoColorOnLetters(tester, text, marks);
        expect(n, greaterThan(0), reason: text);
      }
    });

    testWidgets('bütün derslerden örnekler (şedde, tenvin, çeker, med)', (
      tester,
    ) async {
      for (final lesson in kElifbaLessons) {
        for (final letter in lesson.letters.take(12)) {
          await _expectNoColorOnLetters(
            tester,
            letter.isolatedForm,
            _marksOnly,
          );
        }
      }
    });

    testWidgets('bütün dersler: öğenin kitap sayfası profiliyle (işaretler)', (
      tester,
    ) async {
      // Harf gövdesini kasıtlı boyayan kurallar (kalın harf, med harfi,
      // s. 50-59 vurgusu) hariç: işaretlerin rengi gövdeye taşmamalı.
      for (final lesson in kElifbaLessons) {
        final layout = lesson.pageLayout;
        if (layout == null) continue;
        for (var i = 0; i < lesson.letters.length; i += 3) {
          final profile = layout.colorProfileOf(i);
          final marks = ArabicColorProfile(
            {
              for (final e in profile.colors.entries)
                if (!const {
                  ArabicPart.letter,
                  ArabicPart.thickLetter,
                  ArabicPart.maddAlif,
                  ArabicPart.maddYa,
                  ArabicPart.maddWaw,
                }.contains(e.key))
                  e.key: e.value,
            },
            plainMarks: profile.plainMarks,
          );
          await _expectNoColorOnLetters(
            tester,
            lesson.letters[i].isolatedForm,
            marks,
          );
        }
      }
    });
  });

  group('renkler', () {
    testWidgets('üstün kırmızı, esre mavi, ötre yeşil', (tester) async {
      final f = await _grid(tester, const ColoredArabicText('بَ', style: style));
      expect(_any(f, (p) => p.isReddish), isTrue);
      final k = await _grid(tester, const ColoredArabicText('بِ', style: style));
      expect(_any(k, (p) => p.isBlueish), isTrue);
      final d = await _grid(tester, const ColoredArabicText('بُ', style: style));
      expect(_any(d, (p) => p.isGreenish), isTrue);
    });

    testWidgets('kalın harf: her profilde kırmızı (s. 14, s. 15, hiçbiri)', (
      tester,
    ) async {
      final p14 = kUstunPageLayout.pages[0].colorProfile;
      final p15 = kUstunPageLayout.pages[1].colorProfile;
      final bare = ArabicColorProfile.only({ArabicPart.thickLetter});
      final onlyThick = await _grid(
        tester,
        ColoredArabicText('ق', style: style, profile: bare),
      );
      expect(_any(onlyThick, (p) => p.isReddish), isTrue);
      final a = await _grid(
        tester,
        ColoredArabicText('ق', style: style, profile: p14),
      );
      expect(_any(a, (p) => p.isReddish), isTrue);
      for (final profile in [p15, ArabicColorProfile.none]) {
        final b = await _grid(
          tester,
          ColoredArabicText('ق', style: style, profile: profile),
        );
        expect(_any(b, (p) => p.isReddish), isTrue);
      }
    });

    testWidgets('şedde + iki ötre: şedde mavi, tenvin yeşil', (tester) async {
      final g = await _grid(
        tester,
        const ColoredArabicText('بٌّ', style: style),
      );
      expect(_any(g, (p) => p.isBlueish), isTrue);
      expect(_any(g, (p) => p.isGreenish), isTrue);
    });

    testWidgets('lâm-elif (لَا) tek glif: elif ayrı renk almaz (kitap s. 33)', (
      tester,
    ) async {
      final g = await _grid(
        tester,
        ColoredArabicText(
          'لَا',
          style: style,
          profile: ArabicColorProfile.only({ArabicPart.maddAlif}),
        ),
      );
      expect(_any(g, (p) => p.isColored), isFalse);
    });
  });

  testWidgets('metin tek parça: renkli çizim yalnızca üstte bir katman', (
    tester,
  ) async {
    for (final text in ['مَدَّ', 'حَقَّ', 'خِ', 'قَّ', 'فَبَشِّرْهُ']) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: ColoredArabicText(text, style: style),
        ),
      );
      await tester.pump();
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts, hasLength(1));
      expect(texts.single.data, text, reason: '"$text" bölünmüş görünüyor');
    }
  });

  testWidgets('boyanacak bir şey yoksa sıradan Text', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredArabicText(
          'بَ',
          style: style,
          profile: ArabicColorProfile.none,
        ),
      ),
    );
    await tester.pump();
    expect(tester.widget<Text>(find.byType(Text)).data, 'بَ');
    expect(
      find.descendant(
        of: find.byType(ColoredArabicText),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });
}
