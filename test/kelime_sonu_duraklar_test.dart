import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/kapali_te_data.dart';
import 'package:kuran_okuma_rehberi/data/kelime_sonu_duraklar_data.dart';
import 'package:kuran_okuma_rehberi/models/waqf_example.dart';

void main() {
  final tables = {
    'Ders 32 (Kapalı Te)': (kKapaliTeExamples, kKapaliTeWords),
    'Ders 33 (Kelime Sonu Durakları)': (kWaqfAllExamples, kKelimeSonuDuraklarWords),
  };

  tables.forEach((name, data) {
    final (examples, words) = data;

    test("$name: the example table lists exactly the lesson's words, in order", () {
      expect(examples.length * 2, words.length);
      for (var i = 0; i < examples.length; i++) {
        expect(examples[i].pair, i + 1);
        expect(identical(examples[i].words, words), isTrue);
      }
    });

    test('$name: red parts stay inside the word', () {
      for (final e in examples) {
        for (final (word, red) in [(e.pass, e.passRedLetters), (e.stop, e.stopRedLetters)]) {
          final (head, tail) = splitLastLetters(word, red);
          expect(head + tail, word);
          expect(tail, isNotEmpty, reason: word);
          expect(head, isNotEmpty, reason: word);
        }
      }
    });

    test('$name: every word has a recording', () {
      for (final w in words) {
        expect(w.audioAsset, isNotEmpty, reason: w.isolatedForm);
      }
    });
  });

  test('splitting never separates a hareke from its letter', () {
    // "رِ" is a letter with its kesre; the mark must go with the letter.
    final (head, tail) = splitLastLetters('صُدُورِ', 1);
    expect(tail, 'رِ');
    expect(head, 'صُدُو');
    final (head2, tail2) = splitLastLetters('خَيْرًا', 2);
    expect(head2 + tail2, 'خَيْرًا');
    expect(tail2.length, greaterThan(1));
    expect(splitLastLetters('ab', 5), ('', 'ab'));
  });

  test('a closed te (ة) is read as a He (ه) when stopping, like in the book', () {
    // Ders 33: مُطَهَّرَهْ and مَرْضِيَّهْ.
    final words = [for (final w in kKelimeSonuDuraklarWords) w.isolatedForm];
    expect(words[19], endsWith('هْ'));
    expect(words[21], endsWith('هْ'));
    expect(words.where((w) => w.contains('ة') && w.endsWith('ْ')), isEmpty);
    // Ders 32: every stopping form ends in a He with cezim, every passing
    // form in a ة.
    for (var i = 0; i < kKapaliTeWords.length; i += 2) {
      expect(kKapaliTeWords[i].isolatedForm, contains('ة'));
      expect(kKapaliTeWords[i + 1].isolatedForm, endsWith('هْ'));
    }
  });

  test('Ders 32: the last pair is الصَّلٰوة (with the waw), as in the book', () {
    for (final w in [kKapaliTeWords[10], kKapaliTeWords[11]]) {
      expect(w.isolatedForm, contains('لٰو'), reason: 'lam + dagger alif + waw');
    }
  });
}
