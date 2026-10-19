import 'package:cloud_firestore/cloud_firestore.dart';
import '../game/models.dart';

/// Reads the remote game config written by the Admin Panel.
/// If Firestore is missing or offline, V2 defaults are returned,
/// so the game always starts.
class ConfigService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('config').doc('game');

  static Future<GameConfig> fetchGameConfig() async {
    try {
      final snap = await _doc.get().timeout(const Duration(seconds: 5));
      if (snap.exists && snap.data() != null) {
        return GameConfig.fromMap(snap.data()!);
      }
    } catch (_) {}
    return GameConfig.defaults();
  }

  static Stream<GameConfig> listenGameConfig() {
    return _doc.snapshots().map((s) =>
        (s.exists && s.data() != null)
            ? GameConfig.fromMap(s.data()!)
            : GameConfig.defaults());
  }
}
