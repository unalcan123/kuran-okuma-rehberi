// ⓘ penceresi dersin kendisini değil, yalnız açıklamasını gösterir: örnek
// tabloları, kelime ızgaraları ve "Örnekler:" başlıkları dersin sayfasında
// kalır (Ders 23-30'da pencere neredeyse bütün dersi gösteriyordu).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/lesson_info_data.dart';

String _plain(List<InlineSpan> spans) =>
    TextSpan(children: spans).toPlainText(includePlaceholders: false);

void main() {
  const lessons = [
    'el-takisi-okunan', // Ders 23
    'el-takisi-okunmayan', // 24
    'el-takisi-hemze', // 25
    'el-takisi-hemze-vasil', // 26
    'zamir-he-uzatilmasi', // 27
    'zamir-he-uzatma-med', // 28
    'kapali-te', // 29
    'kelime-sonu-duraklar', // 30
  ];

  test('Ders 23-30: ⓘ özetinde tablo / ızgara / "Örnekler" yok', () {
    for (final id in lessons) {
      final info = kLessonInfo[id]!;
      final summary = info.summary;
      final text = _plain(summary);
      expect(text.trim(), isNotEmpty, reason: id);
      var widgets = 0;
      for (final span in summary) {
        span.visitChildren((s) {
          if (s is WidgetSpan) widgets++;
          return true;
        });
      }
      expect(widgets, 0, reason: id);
      expect(text, isNot(contains('Örnekler')), reason: id);
      expect(text, isNot(contains('örnekler:')), reason: id);
      expect(text, isNot(contains('\n\n\n')), reason: id);
      // Sayfadaki içerik (tablolar dahil) değişmedi.
      var bodyWidgets = 0;
      for (final span in info.body) {
        span.visitChildren((s) {
          if (s is WidgetSpan) bodyWidgets++;
          return true;
        });
      }
      if (id != 'zamir-he-uzatilmasi') {
        expect(bodyWidgets, greaterThan(0), reason: id);
      }
    }
  });

  test('açıklama cümleleri kalır', () {
    expect(
      _plain(kLessonInfo['kelime-sonu-duraklar']!.summary),
      allOf(
        contains('Üstün, Esre veya Ötre harekeleri ile duruş yapılmaz.'),
        contains('İki Esre veya İki Ötreli harflerde ise, Cezim’le durulur.'),
      ),
    );
    expect(
      _plain(kLessonInfo['zamir-he-uzatilmasi']!.summary),
      allOf(
        contains('4 hareke'),
        contains('He Harfi Hangi Durumlarda Uzatılmaz?'),
      ),
    );
    expect(
      _plain(kLessonInfo['kapali-te']!.summary),
      contains('Sonunda “Kapalı Te” olan kelimede durulduğunda'),
    );
  });
}
