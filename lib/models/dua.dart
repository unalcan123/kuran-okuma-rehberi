/// Source segments remain independently addressable for reading and playback.
class DuaSegment {
  final int id;
  final String arabic;
  final String? pronunciationTr;
  final String meaningTr;
  final String audioAsset;

  const DuaSegment({
    required this.id,
    required this.arabic,
    this.pronunciationTr,
    required this.meaningTr,
    required this.audioAsset,
  });
}

class Dua {
  final int order;
  final String id;
  final String titleTr;
  final List<DuaSegment> segments;

  const Dua({
    required this.order,
    required this.id,
    required this.titleTr,
    required this.segments,
  });

  List<String> get playlist => [for (final part in segments) part.audioAsset];
}
