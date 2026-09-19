/// A single unit taught in an Elifba lesson — usually one letter, but
/// the same shape also covers a letter+hareke or a short practice
/// word (Ders 3 onward), since all of them need only a big glyph, an
/// optional short label and a sound.
///
/// [initialForm], [medialForm] and [finalForm] (başta/ortada/sonda)
/// are only populated for lessons that teach positional writing.
/// [turkishName] is null for practice words, which have no short
/// Turkish label. [groupLabel] separates a lesson's content into
/// named sections (e.g. "Harf + Üstün" vs "Kelime Okuma") when a
/// lesson mixes more than one kind of content.
enum Mahrec {
  bogaz('Boğaz mahreci', 'Bu harflerin çıkış yeri boğazımızdır.'),
  dil('Dil mahreci', 'Bu harfleri çıkarırken dilimiz görev alır.'),
  dudak('Dudak mahreci', 'Bu harfleri çıkarırken dudaklarımız görev alır.');

  const Mahrec(this.label, this.description);
  final String label;
  final String description;
}

class ArabicLetter {
  final int order;
  final String isolatedForm;
  final String? turkishName;
  final String? audioAsset;
  final String? initialForm;
  final String? medialForm;
  final String? finalForm;
  final List<String>? positionExamples;
  final String? groupLabel;
  final bool isHeavyLetter;
  final Mahrec? mahrec;

  const ArabicLetter({
    required this.order,
    required this.isolatedForm,
    this.turkishName,
    this.audioAsset,
    this.initialForm,
    this.medialForm,
    this.finalForm,
    this.positionExamples,
    this.groupLabel,
    this.isHeavyLetter = false,
    this.mahrec,
  });

  bool get hasPositionForms =>
      initialForm != null && medialForm != null && finalForm != null;
}
