import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../services/game_score_store.dart';
import '../../harf_oyunlari/profil/player_repository.dart';
import 'learning_repository.dart';
import 'letter_learning.dart';

/// Sürükle & Bırak'ın açık oturumu: oyuncunun durumu, motoru ve kaydı.
/// Ana ekran ve oyun ekranı aynı nesneyi paylaşır.
class LearningSession extends ChangeNotifier {
  LearningSession({
    required this.engine,
    required this.repository,
    required this.state,
    this.profileId,
    DateTime Function()? clock,
    math.Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? math.Random();

  final LetterLearningEngine engine;
  final LearningRepository repository;
  final LearningState state;
  final String? profileId;
  final DateTime Function() _clock;
  final math.Random _random;

  DateTime get now => _clock();

  /// Ağaçtaki oyuncu ve (varsa) bulutla durumu yükler.
  static Future<LearningSession> open(
    BuildContext context, {
    DateTime Function()? clock,
  }) async {
    PlayerRepository? players;
    LearningCloud? cloud;
    GameScoreStore? scores;
    try {
      players = context.read<PlayerRepository>();
    } on ProviderNotFoundException {
      players = null;
    }
    try {
      cloud = context.read<LearningCloud>();
    } on ProviderNotFoundException {
      cloud = null;
    }
    try {
      scores = context.read<GameScoreStore>();
    } on ProviderNotFoundException {
      scores = null;
    }
    if (players != null && !players.loaded) await players.load();
    final profileId = players?.activePlayer?.id;
    final engine = LetterLearningEngine();
    final repository = LearningRepository(
      engine: engine,
      cloud: cloud,
      clock: clock,
    );
    final state = await repository.load(profileId: profileId, scores: scores);
    return LearningSession(
      engine: engine,
      repository: repository,
      state: state,
      profileId: profileId,
      clock: clock,
    );
  }

  bool get dailyReviewDue => engine.dailyReviewDue(state, now);
  int get learnedCount => engine.learnedCount(state);
  int get letterCount => engine.letterCount;
  int get stageCount => engine.groups.length;

  DragDropRound nextRound({bool daily = false}) =>
      engine.nextRound(state, now, _random, daily: daily);

  Future<StageEvent> complete(DragDropRound round, RoundOutcome outcome) async {
    final event = engine.apply(state, round, outcome, now);
    notifyListeners();
    await repository.save(state, profileId: profileId);
    return event;
  }

  Future<void> setDifficulty(DragDropDifficulty difficulty) async {
    if (state.difficulty == difficulty) return;
    state
      ..difficulty = difficulty
      ..updatedAt = now.millisecondsSinceEpoch;
    notifyListeners();
    await repository.save(state, profileId: profileId);
  }
}
