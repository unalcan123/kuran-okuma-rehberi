import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../screens/oyunlar/drag_drop/learning/learning_repository.dart';
import 'leaderboard_service.dart';

/// Öğrenme durumunun Firestore kopyası (kurallar: `firestore.rules`):
///
/// `learning_progress/{playerId}` — playerId, ownerUid, gameId
/// (`drag_drop`), state (harf başına ilerleme), updatedAt (istemci ms),
/// savedAt (sunucu zamanı). `playerId = <anonim UID>_<profil id>`, sıralamadaki
/// gibi; yalnızca sahibi okur/yazar.
class FirestoreLearningCloud implements LearningCloud {
  FirestoreLearningCloud({required this.ready});

  /// Firebase başlatıldığında tamamlanır (main.dart; hata = çevrimdışı).
  final Future<Object?> ready;

  static const String collection = 'learning_progress';
  static const String gameId = 'drag_drop';

  Future<DocumentReference<Map<String, dynamic>>> _doc(String profileId) async {
    final backend = await ready;
    if (backend == null) throw StateError('Firebase yok');
    final auth = FirebaseAuth.instance;
    final uid =
        auth.currentUser?.uid ?? (await auth.signInAnonymously()).user!.uid;
    return FirebaseFirestore.instance
        .collection(collection)
        .doc(LeaderboardService.playerIdFor(uid, profileId));
  }

  @override
  Future<Map<String, Object?>?> fetch(String profileId) async {
    final snap = await (await _doc(profileId)).get();
    final state = snap.data()?['state'];
    return state is Map ? Map<String, Object?>.from(state) : null;
  }

  @override
  Future<void> push(String profileId, Map<String, Object?> state) async {
    final ref = await _doc(profileId);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await ref.set({
      'playerId': ref.id,
      'ownerUid': uid,
      'gameId': gameId,
      'state': state,
      'updatedAt': state['updatedAt'] is int ? state['updatedAt'] : 0,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }
}
