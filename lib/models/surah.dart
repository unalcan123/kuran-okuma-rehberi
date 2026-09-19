/// A single verse of a [Surah]. Modeled separately (rather than one
/// big block of Arabic text per surah) so later modes — ayet-by-ayet
/// playback, "ezberle" (memorize), hide-and-reveal, reordering games —
/// have something to address individually without a data migration.
class Ayet {
  final int number;
  final String arabic;
  final String meaningTr;
  final String audioAsset;

  const Ayet({
    required this.number,
    required this.arabic,
    required this.meaningTr,
    required this.audioAsset,
  });
}

/// A short surah taught for prayer. [besmele] is kept separate from
/// [ayetler] because it isn't numbered as a verse of the surah itself
/// (Al-Fatiha aside) — it has its own recitation and its own audio
/// clip, recited before the surah rather than as part of it.
class Surah {
  final int order;
  final String id;
  final String titleTr;
  final String arabicName;
  final String besmele;
  final String besmeleAudioAsset;
  final List<Ayet> ayetler;

  const Surah({
    required this.order,
    required this.id,
    required this.titleTr,
    required this.arabicName,
    required this.besmele,
    required this.besmeleAudioAsset,
    required this.ayetler,
  });

  /// Besmele followed by every ayet's audio, in recitation order —
  /// what the "Dinle" control plays straight through.
  List<String> get playlist => [
    besmeleAudioAsset,
    for (final ayet in ayetler) ayet.audioAsset,
  ];
}
