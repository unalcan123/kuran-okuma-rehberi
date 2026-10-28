import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/data/sureler_data.dart';
import 'package:kuran_okuma_rehberi/models/reading_segment.dart';

void main() {
  test('Fatiha besmele is 1; last two cards share ayet 7', () {
    final segments = ReadingSegment.ofSurah(kFatiha);
    expect(segments.map((s) => s.number), [1, 2, 3, 4, 5, 6, 7, 7]);
    expect(segments.map((s) => s.id).toSet(), hasLength(8));
    expect(segments.map((s) => s.audioAsset), kFatiha.playlist);
  });
  test('Other surahs keep an unnumbered besmele and existing ayet numbers', () {
    for (final surah in kSureler.where((s) => s.id != 'fatiha')) {
      final segments = ReadingSegment.ofSurah(surah);
      expect(segments.first.number, isNull, reason: surah.id);
      expect(
        segments.skip(1).map((s) => s.number),
        surah.ayetler.map((a) => a.number),
      );
    }
  });
}
