import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Google sign-in + guest login for Worm Snake V2.
/// Admin is decided by ONE email only - no other account ever sees the panel.
class AuthService {
  static const String adminEmail = 'muradhase457@gmail.com';

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _google = GoogleSignIn();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static bool get isAdmin => (_auth.currentUser?.email ?? '') == adminEmail;

  static Stream<User?> authChanges() => _auth.authStateChanges();

  static Future<User?> signInWithGoogle() async {
    final gUser = await _google.signIn();
    if (gUser == null) return null;
    final gAuth = await gUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );
    final res = await _auth.signInWithCredential(cred);
    return res.user;
  }

  static Future<User?> signInAsGuest() async {
    final res = await _auth.signInAnonymously();
    return res.user;
  }

  static Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Creates the users/{uid} doc on first login, updates lastSeen afterwards.
  /// Never overwrites existing coins/score/banned.
  static Future<void> ensureUserDoc() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final ref = _db.collection('users').doc(u.uid);
    try {
      final snap = await ref.get();
      final email = u.email ?? '';
      if (!snap.exists) {
        await ref.set({
          'email': email,
          'name': u.displayName ?? 'Player',
          'photo': u.photoURL ?? '',
          'coins': 340,
          'score': 0,
          'games': 0,
          'banned': false,
          'isAdmin': email == adminEmail,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({
          'lastSeen': FieldValue.serverTimestamp(),
          'isAdmin': email == adminEmail,
          if (email.isNotEmpty) 'email': email,
        });
      }
    } catch (_) {
      // Offline - the game still works with local coins.
    }
  }

  static Future<bool> isBanned(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      return (snap.data()?['banned'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }
}
