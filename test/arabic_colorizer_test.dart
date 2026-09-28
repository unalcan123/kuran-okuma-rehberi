// ArabicColorizer'ın kitaptaki (ELIF BA BASKI DENEME 2012.pdf, s. 14-49)
// renk mantığını izlediğini denetler. Örnek kelimeler kitabın ilgili
// sayfalarından; beklenen renkler PDF'deki metin renklerinden okundu.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/helpers/arabic_colorizer.dart';
import 'package:kuran_okuma_rehberi/helpers/haraka_colors.dart';

ArabicClusterColors _cluster(String text, int index) =>
    ArabicColorizer.plan(text)[index];

/// [text]'teki [base] harfinin (ilk geçtiği) kümesi.
ArabicClusterColors _of(String text, String base, {int skip = 0}) =>
    ArabicColorizer.plan(text).where((c) => c.base == base).elementAt(skip);

void main() {
  group('harekeler (s. 14-27)', () {
    test('üstün kırmızı, harfin gövdesi boyanmaz', () {
      final c = _cluster('بَ', 0);
      expect(c.above, arabicRed);
      expect(c.body, isNull);
    });
    test('esre mavi, ötre yeşil, cezim kırmızı', () {
      expect(_cluster('بِ', 0).below, arabicBlue);
      expect(_cluster('بُ', 0).above, arabicGreen);
      expect(_of('أَبْ', 'ب').above, arabicRed);
    });
    test('kalın harf gövdesi kırmızı, harekesi kendi renginde', () {
      final c = _cluster('خِ', 0);
      expect(c.body, arabicRed);
      expect(c.below, arabicBlue);
      expect(_cluster('صُ', 0).above, arabicGreen);
    });
    test('ince harf gövdesi renksiz', () {
      for (final letter in ['ب', 'ت', 'ن', 'م', 'ل', 'ا']) {
        expect(_cluster(letter, 0).isColored, isFalse, reason: letter);
      }
    });
  });

  group('şedde (s. 28-31): şedde ve şeddeli harfin harekesi mavi', () {
    for (final word in ['أُمَّ', 'رَبُّ', 'كُلَّ']) {
      test(word, () {
        final c = ArabicColorizer.plan(word).last;
        expect(c.shaddaColor, arabicBlue);
        expect(c.above, arabicBlue);
      });
    }
    test('esreli şedde: esre de mavi', () {
      final c = _cluster('بِّ', 0);
      expect(c.shaddaColor, arabicBlue);
      expect(c.below, arabicBlue);
    });
    test('iki ötreli şedde: tenvin kendi renginde (yeşil)', () {
      final c = _cluster('بٌّ', 0);
      expect(c.shaddaColor, arabicBlue);
      expect(c.above, arabicGreen);
    });
  });

  group('uzatma harfleri (s. 32-38)', () {
    test('üstünden sonraki harekesiz elif kırmızı', () {
      expect(_of('بَالُ', 'ا').body, arabicRed);
      expect(_of('ءَامَنَ', 'ا').parts, contains(ArabicPart.maddAlif));
      expect(_of('لَا', 'ا').body, arabicRed);
    });
    test('esreden sonraki harekesiz yâ mavi', () {
      expect(_of('أَبِي', 'ي').body, arabicBlue);
      expect(_of('فِيهَا', 'ي').body, arabicBlue);
    });
    test('ötreden sonraki harekesiz vâv yeşil', () {
      expect(_of('أُوتُوا', 'و').body, arabicGreen);
      expect(_of('نُورُهُمْ', 'و').body, arabicGreen);
    });
    test('her elif/yâ/vâv boyanmaz', () {
      // vav-ı cemi'den sonraki elif
      expect(_of('أُوتُوا', 'ا').body, isNull);
      // iki üstünden sonraki elif (s. 40)
      expect(_of('بًا', 'ا').body, isNull);
      // harekeli vâv / yâ
      expect(_of('وَلَدَ', 'و').body, isNull);
      expect(_of('يَدُ', 'ي').body, isNull);
      // üstünden sonraki cezimli yâ (leyn) med değil
      expect(_of('بَيْتُ', 'ي').body, isNull);
      // hemzeli elif
      expect(_cluster('أَ', 0).body, isNull);
      // kelimenin ilk harfi, önünde hareke yok
      expect(_cluster('ا', 0).body, isNull);
    });
    test('kalın harfli kelimede yalnızca kalın harf kırmızı', () {
      final plan = ArabicColorizer.plan('خُو');
      expect(plan[0].body, arabicRed);
      expect(plan[0].above, arabicGreen);
      expect(plan[1].body, arabicGreen);
    });
  });

  group('çeker harekeler ve tenvin (s. 39-49)', () {
    test('çeker üstün, çeker esre, med işareti kırmızı', () {
      expect(_of('ذٰلِكَ', 'ذ').above, arabicRed);
      expect(_of('بِهٖ', 'ه').below, arabicRed);
      expect(_of('جَٓاءَ', 'ج').parts, contains(ArabicPart.maddah));
    });
    test('iki üstün kırmızı, iki esre mavi, iki ötre yeşil', () {
      expect(_cluster('بً', 0).above, arabicRed);
      expect(_cluster('بٍ', 0).below, arabicBlue);
      expect(_cluster('بٌ', 0).above, arabicGreen);
    });
  });

  group('sayfa profilleri (kitap s. 14-16, PDF metin renklerinden)', () {
    final p14 = kUstunPageLayout.pages[0].colorProfile;
    final p15 = kUstunPageLayout.pages[1].colorProfile;
    final p16 = kUstunPageLayout.pages[2].colorProfile;

    test('s. 14: üstün kırmızı, kalın harf kırmızı, ince harf siyah', () {
      final kh = ArabicColorizer.plan('خَ', profile: p14).single;
      expect(kh.body, arabicRed);
      expect(kh.above, arabicRed);
      final b = ArabicColorizer.plan('بَ', profile: p14).single;
      expect(b.body, isNull);
      expect(b.above, arabicRed);
    });

    test("s. 15-16: üstün kırmızı; kalın harf PDF'de siyah ama global "
        "kuralla kırmızı", () {
      for (final profile in [p15, p16]) {
        final plan = ArabicColorizer.plan('أَبَقَ', profile: profile);
        expect(plan.last.base, 'ق');
        expect(plan.last.body, arabicRed);
        expect(plan[1].body, isNull);
        expect(plan.every((c) => c.above == arabicRed), isTrue);
      }
    });

    test('her öğe kendi sayfasının profilini alır', () {
      final layout = kUstunPageLayout;
      expect(layout.colorProfileOf(0), p14);
      expect(layout.colorProfileOf(27), p14);
      expect(layout.colorProfileOf(28), p15);
      expect(layout.colorProfileOf(56), p16);
      expect(layout.colorProfileOf(91), p16);
    });

    test('profilde olmayan öğe boyanmaz', () {
      final plan = ArabicColorizer.plan('بِ', profile: p15).single;
      expect(plan.isColored, isFalse);
    });
  });

  test('metin hiç değişmez; kümeler metni eksiksiz kaplar', () {
    for (final lesson in kElifbaLessons) {
      for (final letter in lesson.letters) {
        final text = letter.isolatedForm;
        final plan = ArabicColorizer.plan(text);
        final covered = plan.map((c) => text.substring(c.start, c.end)).join();
        expect(covered, text.replaceFirst(RegExp(r'^[ً-ٟ]+'), ''),
            reason: '${lesson.label}: $text');
      }
    }
  });

  test('renk sabitleri kitaptaki tonlar', () {
    expect(arabicRed, const Color(0xFFED1C24));
    expect(arabicBlue, const Color(0xFF00AEEF));
    expect(arabicGreen, const Color(0xFF00A650));
  });
}
