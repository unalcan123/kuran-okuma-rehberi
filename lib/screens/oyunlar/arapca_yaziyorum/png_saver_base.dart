enum SaveOutcome { saved, unsupported, failed }

class SaveResult {
  const SaveResult(this.outcome, [this.location]);

  final SaveOutcome outcome;

  /// Kaydedilen yer (masaüstünde dosya yolu, web'de "İndirilenler").
  final String? location;
}
