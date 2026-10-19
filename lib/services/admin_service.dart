import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// Admin-only actions. Every method checks isAdmin first.
/// Normal users never see the admin screens at all.
class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static void _checkAdmin() {
    if (!AuthService.isAdmin) {
      throw StateError('Not admin');
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return _db
        .collection('users')
        .orderBy('score', descending: true)
        .limit(100)
        .snapshots();
  }

  static Future<void> giveCoins(String uid, int amount) async {
    _checkAdmin();
    await _db.collection('users').doc(uid).update({
      'coins': FieldValue.increment(amount),
    });
  }

  static Future<void> takeCoins(String uid, int amount) async {
    _checkAdmin();
    await _db.collection('users').doc(uid).update({
      'coins': FieldValue.increment(-amount),
    });
  }

  static Future<void> setBanned(String uid, bool banned) async {
    _checkAdmin();
    await _db.collection('users').doc(uid).update({'banned': banned});
  }

  static Future<void> updateConfig(Map<String, dynamic> values) async {
    _checkAdmin();
    await _db
        .collection('config')
        .doc('game')
        .set(values, SetOptions(merge: true));
  }

  static Future<void> addSkin(Map<String, dynamic> skin) async {
    _checkAdmin();
    await _db.collection('skins').add({
      ...skin,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setAnnouncement(String text) async {
    _checkAdmin();
    await _db.collection('config').doc('game').set(
      {'announcement': text},
      SetOptions(merge: true),
    );
  }
}
