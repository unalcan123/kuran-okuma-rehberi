// GLOBAL KURAL: 7 kalın harfin (خ ص ض ط ظ غ ق) GÖVDESİ uygulamanın her
// yerinde kırmızı (#ED1C24) — sayfa renk profili (PDF bazı sayfalarda siyah
// basmış olsa da) bunu kapatamaz. Harekeler kendi kurallarıyla boyanır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/letters_data.dart';
import 'package:kuran_okuma_rehberi/data/ustun_data.dart';
import 'package:kuran_okuma_rehberi/helpers/arabic_colorizer.dart';
import 'package:kuran_okuma_rehberi/helpers/colored_arabic_text.dart';
import 'package:kuran_okuma_rehberi/helpers/haraka_colors.dart';
import 'package:kuran_okuma_rehberi/models/arabic_letter.dart';
import 'package:kuran_okuma_rehberi/services/audio_service.dart';
import 'package:kuran_okuma_rehberi/widgets/word_cell.dart';
import 'package:provider/provider.dart';

import 'book_pages_test.dart' show RecordingAudio, app, setSize;

const _thick = ['خ', 'ص', 'ض', 'ط', 'ظ', 'غ', 'ق'];

/// Every profile a page of the app can use, including ones that color
/// nothing (the PDF prints the thick letters black there).
List<ArabicColorProfile> _allProfiles() => [
  ArabicColorProfile.standard,
  ArabicColorProfile.none,
  ArabicColorProfile.only({ArabicPart.fatha}),
  ArabicColorProfile.none.withClusterBodies({0: arabicBlue}),
  for (final lesson in kElifbaLessons)
    if (lesson.pageLayout != null)
      for (final page in lesson.pageLayout!.pages) page.colorProfile,
];

/// The thick letters of [text] with [profile] are red, the others are not
/// red because of this rule.
void _expectThickRed(String text, ArabicColorProfile profile, String reason) {
  for (final c in ArabicColorizer.plan(text, profile: profile)) {
    if (isThickArabicLetter(c.base)) {
      expect(c.body, arabicRed, reason: '$reason: "$text" ${c.base}');
    }
  }
}

void main() {
  test('tek merkezi liste: 7 kalın harf', () {
    expect(thickArabicLetters, _thick.toSet());
    for (final letter in _thick) {
      expect(isThickArabicLetter(letter), isTrue);
    }
    for (final letter in ['ب', 'ح', 'ه', 'ع', 'ك', 'ا', 'ء', 'ـ', ' ']) {
      expect(isThickArabicLetter(letter), isFalse, reason: letter);
    }
  });

  test('1. 7 kalın harfin her biri gövde olarak kırmızı', () {
    for (final letter in _thick) {
      final c = ArabicColorizer.plan(letter).single;
      expect(c.body, arabicRed, reason: letter);
      expect(c.parts, contains(ArabicPart.thickLetter));
    }
  });

  test('2. ince harfler bu kural yüzünden kırmızı olmaz', () {
    for (final letter in ['ب', 'ت', 'ح', 'ع', 'ك', 'ل', 'ه', 'ن', 'س']) {
      for (final profile in [
        ArabicColorProfile.standard,
        ArabicColorProfile.none,
      ]) {
        final c = ArabicColorizer.plan(letter, profile: profile).single;
        expect(c.body, isNull, reason: letter);
        expect(c.parts, isNot(contains(ArabicPart.thickLetter)));
      }
    }
  });

  test('3. خِ: خ kırmızı, esre kendi renginde (mavi)', () {
    final c = ArabicColorizer.plan('خِ').single;
    expect(c.body, arabicRed);
    expect(c.below, arabicBlue);
    expect(c.marks.single.color, harakaKasraColor);
  });

  test('4. قُ: ق kırmızı, ötre kendi renginde (yeşil)', () {
    final c = ArabicColorizer.plan('قُ').single;
    expect(c.body, arabicRed);
    expect(c.above, arabicGreen);
  });

  test('5. صْ: ص kırmızı, cezim dersin renginde', () {
    final c = ArabicColorizer.plan('صْ').single;
    expect(c.body, arabicRed);
    expect(c.above, harakaSukunColor);
    // Cezmi boyamayan bir sayfada cezim renksiz kalır, gövde yine kırmızı.
    final plain =
        ArabicColorizer.plan(
          'صْ',
          profile: ArabicColorProfile.only({ArabicPart.fatha}),
        ).single;
    expect(plain.body, arabicRed);
    expect(plain.marks.single.color, isNull);
  });

  test('6. kelime içindeki kalın harf kırmızı, diğer harfler değil', () {
    final plan = ArabicColorizer.plan(
      'يَقْطَعُ',
      profile: ArabicColorProfile.none,
    );
    expect(plan.map((c) => c.base).join(), 'يقطع');
    expect(plan.map((c) => c.body), [null, arabicRed, arabicRed, null]);
    // Harekeler renksiz kalır (profil boyamıyor): kural yalnız gövdeye.
    for (final c in plan) {
      expect(c.hasColoredMark, isFalse);
    }
  });

  test('7. sayfa profili kalın harfi siyah yapmaya çalışsa da kırmızı', () {
    // s. 15-16 (Üstün örnekleri): PDF'de kalın harfler siyah.
    final p15 = kUstunPageLayout.pages[1].colorProfile;
    final c = ArabicColorizer.plan('أَبَقَ', profile: p15).last;
    expect(c.base, 'ق');
    expect(c.body, arabicRed);
    expect(c.above, arabicRed); // üstün, sayfanın kuralı
    // Kümeye özel başka bir gövde rengi bile kalın harfi değiştiremez.
    final own =
        ArabicColorizer.plan(
          'قَ',
          profile: ArabicColorProfile.none.withClusterBodies({0: arabicBlue}),
        ).single;
    expect(own.body, arabicRed);
    // Bütün derslerin bütün sayfa profilleri, bütün kalın harfler.
    for (final profile in _allProfiles()) {
      for (final letter in _thick) {
        _expectThickRed('$letterَ', profile, 'profil');
        _expectThickRed('$letterِ', profile, 'profil');
      }
    }
    // Bütün derslerin bütün öğeleri, kendi sayfa profilleriyle.
    for (final lesson in kElifbaLessons) {
      final layout = lesson.pageLayout;
      for (var i = 0; i < lesson.letters.length; i++) {
        _expectThickRed(
          lesson.letters[i].isolatedForm,
          layout?.colorProfileOf(i) ?? ArabicColorProfile.standard,
          lesson.id,
        );
      }
    }
  });

  testWidgets('7b. çizimde: s. 15 profiliyle ق kırmızı piksel alır', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredArabicText(
          'بَقَ',
          style: const TextStyle(fontSize: 40),
          profile: kUstunPageLayout.pages[1].colorProfile,
        ),
      ),
    );
    // Kalın harf varken renkli katman çizilir (sıradan Text değil).
    expect(
      find.descendant(
        of: find.byType(ColoredArabicText),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
  });

  testWidgets('8. Sayfa / Grid / Tekli aynı sonucu kullanır', (tester) async {
    setSize(tester, const Size(800, 1280));
    await tester.pumpWidget(app(RecordingAudio(), kUstunLesson));
    await tester.pumpAndSettle();

    /// Every Arabic text on screen: its thick letters are red with the
    /// profile the view gave it.
    int checkVisible(String view) {
      var thick = 0;
      for (final w in tester.widgetList<ColoredArabicText>(
        find.byType(ColoredArabicText),
      )) {
        if (!w.text.split('').any(isThickArabicLetter)) continue;
        thick++;
        _expectThickRed(w.text, w.profile, view);
      }
      return thick;
    }

    expect(checkVisible('Sayfa'), greaterThan(0));
    await tester.tap(find.text('▦ Grid'));
    await tester.pumpAndSettle();
    expect(checkVisible('Grid'), greaterThan(0));
    // Grid sayfa sayfa: s. 15'e geç.
    await tester.tap(find.byKey(const ValueKey('page-next')));
    await tester.pumpAndSettle();
    expect(checkVisible('Grid s. 15'), greaterThan(0));
    // أَبَقَ: s. 15 (PDF'de ق siyah) — Grid'de de kırmızı.
    final word = tester.widget<ColoredArabicText>(
      find.byWidgetPredicate(
        (w) => w is ColoredArabicText && w.text == 'أَبَقَ',
      ),
    );
    expect(
      ArabicColorizer.plan(word.text, profile: word.profile).last.body,
      arabicRed,
    );
    await tester.tap(find.text('📖 Sayfa'));
    await tester.pumpAndSettle();
    // Sayfa, Grid'de kalınan s. 15'te açılır; s. 14'e dön.
    expect(find.text('Sayfa 15'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('page-previous')));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('book-cell-6')));
    await tester.pumpAndSettle();
    expect(find.text('7 / 92'), findsOneWidget);
    expect(checkVisible('Tekli'), greaterThan(0));
  });

  testWidgets(
    'kitap tablosu kelimesi (WordCell) de kalın harfi kırmızı çizer',
    (tester) async {
      const letter = ArabicLetter(
        order: 1,
        isolatedForm: 'خَلَقَهُ',
        audioAsset: 'audio/x.mp3',
      );
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AudioService(),
          child: const MaterialApp(
            home: Scaffold(
              body: WordCell(letter: letter, before: 'خَلَقَ', red: 'هُ'),
            ),
          ),
        ),
      );
      final w = tester.widget<ColoredArabicText>(
        find.byType(ColoredArabicText),
      );
      expect(w.text, 'خَلَقَهُ');
      final plan = ArabicColorizer.plan(w.text, profile: w.profile);
      expect(plan.map((c) => c.body), [arabicRed, null, arabicRed, isNotNull]);
      expect(plan.last.base, 'ه'); // vurgulanan son harf (kitabın kırmızısı)
    },
  );
}
