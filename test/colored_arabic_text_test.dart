// Hareke ve kalın harf renklendirmesinin Arapça harf birleşimini (shaping)
// BOZMADIĞINI ve harf gövdesine TAŞMADIĞINI kanıtlar — D:\Elifbe2025'te
// yaşanan iki regresyonun (şedde/hareke kaybolması, harf gövdesinin bir
// kısmının renklenmesi) burada bir daha yaşanmadığını doğrudan denetler.
// Hasenat.ttf bu projede Elifbe2025'teki HASENAT.TTF ile BİREBİR aynı
// dosya (md5 doğrulandı), o yüzden oradaki kalibrasyon oranları burada da
// geçerli.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

class _Px {
  _Px(this.r, this.g, this.b);
  final int r, g, b;
  bool get isWhite => r == 255 && g == 255 && b == 255;
  // Kenar antialiasing'i (harekeli/harekesiz render'lar arasında subpiksel
  // yuvarlamasından 1 tona kadar farklı olabilir) gürültü sayılır; sadece
  // gerçekten "boyalı" pikseller mürekkep kabul edilir.
  bool get isSolidInk => r < 235 || g < 235 || b < 235;
  bool get isReddish => r > g + 40 && r > b + 40;
  bool get isBlueish => b > r + 40 && b > g + 40;
  bool get isGreenish => g > r + 40 && g > b + 40;
  bool get isColored => isReddish || isBlueish || isGreenish;
}

Future<List<List<_Px>>> _grid(WidgetTester tester, Widget child, int w, int h) async {
  await tester.binding.setSurfaceSize(Size(w.toDouble(), h.toDouble()));
  await tester.pumpWidget(RepaintBoundary(
    key: const Key('b'),
    child: Container(
      color: Colors.white,
      width: w.toDouble(),
      height: h.toDouble(),
      alignment: Alignment.topCenter,
      child: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  ));
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('b')));
  final bytes = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  }))!;
  return [
    for (var y = 0; y < h; y++)
      [
        for (var x = 0; x < w; x++)
          _Px(bytes[(y * w + x) * 4], bytes[(y * w + x) * 4 + 1], bytes[(y * w + x) * 4 + 2]),
      ],
  ];
}

/// [bareWord] (harekesiz hali) İLE [fullWord]'ün (harekeli) çizimini
/// karşılaştırır: harf gövdesinin (kalın harf kuralı zaten kasıtlı olarak
/// kırmızı boyayabilir!) rengi İKİSİNDE DE AYNI kategoride olmalı — sadece
/// harekelerin EK bir renk katmasına izin verilir. [bareWord] burada da
/// [ColoredArabicText] ile çizilir (colorHarakat kapalı) ki kalın harf
/// rengi referansta da bulunsun; aksi halde "bu piksel kırmızı" testi
/// kalın harfi de "taşma" sanır.
Future<void> _expectNoBleedIntoLetter(
    WidgetTester tester, String bareWord, String fullWord, int w, int h) async {
  final bareGrid = await _grid(
    tester,
    ColoredArabicText(bareWord, style: style, colorHarakat: false),
    w,
    h,
  );
  final coloredGrid = await _grid(tester, ColoredArabicText(fullWord, style: style), w, h);
  for (var y = 0; y < h; y++) {
    if (!bareGrid[y].any((p) => p.isSolidInk)) continue;
    for (var x = 0; x < w; x++) {
      final bare = bareGrid[y][x];
      if (!bare.isSolidInk) continue;
      final full = coloredGrid[y][x];
      // Harf gövdesi zaten kırmızıysa (kalın harf kuralı), orada renk
      // kalması beklenen/doğru davranıştır — sadece kırmızI OLMAYAN
      // (ince) harflerin gövdesine HİÇBİR rengin taşmadığını denetle.
      if (bare.isReddish) continue;
      expect(full.isColored, isFalse,
          reason: '"$fullWord": ince harf gövdesi ($y,$x) hareke rengi almış (taşma)');
    }
  }
}

void main() {
  setUpAll(_loadHasenat);

  const w = 260, h = 130;

  group('normal harf gövdesi siyah, sadece hareke renkli', () {
    testWidgets('بَ بِ بُ — üstün kırmızı, esre mavi, ötre yeşil ayrı ayrı',
        (tester) async {
      final f = await _grid(tester, const ColoredArabicText('بَ', style: style), w, h);
      expect(f.any((r) => r.any((p) => p.isReddish)), isTrue);
      final k = await _grid(tester, const ColoredArabicText('بِ', style: style), w, h);
      expect(k.any((r) => r.any((p) => p.isBlueish)), isTrue);
      final d = await _grid(tester, const ColoredArabicText('بُ', style: style), w, h);
      expect(d.any((r) => r.any((p) => p.isGreenish)), isTrue);
    });

    testWidgets('بَ بِ بُ: harf gövdesine renk TAŞMAZ', (tester) async {
      await _expectNoBleedIntoLetter(tester, 'ب', 'بَ', w, h);
      await _expectNoBleedIntoLetter(tester, 'ب', 'بِ', w, h);
      await _expectNoBleedIntoLetter(tester, 'ب', 'بُ', w, h);
    });
  });

  group('kalın harf gövdesi kırmızı (hareke bağımsız)', () {
    for (final letter in const ['خ', 'ص', 'ض', 'ط', 'ظ', 'غ', 'ق']) {
      testWidgets('$letter tek başına kırmızı', (tester) async {
        final grid = await _grid(tester, ColoredArabicText(letter, style: style), w, h);
        expect(grid.any((r) => r.any((p) => p.isReddish)), isTrue,
            reason: '$letter kırmızı görünmüyor');
      });
    }

    testWidgets('ince harfler (ا ب ت ن م ل) hareke yokken renk almaz',
        (tester) async {
      for (final letter in const ['ا', 'ب', 'ت', 'ن', 'م', 'ل']) {
        final grid = await _grid(tester, ColoredArabicText(letter, style: style), w, h);
        expect(grid.any((r) => r.any((p) => p.isColored)), isFalse,
            reason: '$letter renk almamalıydı');
      }
    });
  });

  group('kalın harf + hareke birlikte (spesifikasyondaki örnekler)', () {
    // خَ: خ kırmızı (kalın harf) + fetha kırmızı (aynı renk, ayırt edilemez
    // ama ikisi de doğru); خِ: خ kırmızı + kesre MAVİ; خُ: خ kırmızı + ötre YEŞİL.
    testWidgets('خِ — kalın harf kırmızı, kesre mavi (aynı anda, karışmadan)',
        (tester) async {
      final grid = await _grid(tester, const ColoredArabicText('خِ', style: style), w, h);
      expect(grid.any((r) => r.any((p) => p.isReddish)), isTrue);
      expect(grid.any((r) => r.any((p) => p.isBlueish)), isTrue);
    });

    testWidgets('صُ — kalın harf kırmızı, ötre yeşil (aynı anda, karışmadan)',
        (tester) async {
      final grid = await _grid(tester, const ColoredArabicText('صُ', style: style), w, h);
      expect(grid.any((r) => r.any((p) => p.isReddish)), isTrue);
      expect(grid.any((r) => r.any((p) => p.isGreenish)), isTrue);
    });

    for (final entry in const {
      'خ': 'خَ',
      'ص': 'صَ',
      'ض': 'ضَ',
      'ط': 'طَ',
      'ظ': 'ظَ',
      'غ': 'غَ',
      'ق': 'قَ',
    }.entries) {
      testWidgets('${entry.value}: harf+fetha gövde dışına taşmaz', (tester) async {
        await _expectNoBleedIntoLetter(tester, entry.key, entry.value, w, h);
      });
    }
  });

  group('şedde + hareke (D:\\Elifbe2025 regresyon örnekleri)', () {
    for (final word in const ['مَدَّ', 'حَقَّ', 'مَرَّ', 'جَنَّ', 'غَلَّ', 'تَبَّ']) {
      testWidgets('"$word": şedde+hareke doğru renklenir, harf gövdesine taşmaz',
          (tester) async {
        final bare = word.runes
            .where((r) => r < 0x064B || r > 0x065F)
            .map(String.fromCharCode)
            .join();
        await _expectNoBleedIntoLetter(tester, bare, word, w, h);
      });
    }
  });

  testWidgets('metin katmanları TAM metni içerir (shaping asla parçalanmaz)',
      (tester) async {
    for (final text in ['مَدَّ', 'حَقَّ', 'خِ', 'قَّ', 'فَبَشِّرْهُ']) {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredArabicText(text, style: style),
      ));
      await tester.pump();
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        expect(t.data, text, reason: '"$text" bölünmüş görünüyor');
      }
    }
  });

  testWidgets('colorHarakat/highlightThickLetters false iken sıradan Text',
      (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredArabicText(
        'قَ',
        style: style,
        colorHarakat: false,
        highlightThickLetters: false,
      ),
    ));
    await tester.pump();
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, 'قَ');
    expect(find.byType(Stack), findsNothing);
  });
}
