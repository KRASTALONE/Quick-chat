import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) {
      throw Exception('Username cannot be empty');
    }

    final usernameDoc =
        await _firestore.collection('usernames').doc(cleanUsername).get();
    if (usernameDoc.exists) {
      throw Exception('Username already taken');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final now = DateTime.now().millisecondsSinceEpoch;

      final user = UserModel(
        uid: uid,
        email: email.trim().toLowerCase(),
        username: cleanUsername,
        firstName: '',
        lastSeen: now,
        createdAt: now,
      );

      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(uid), user.toMap());
      batch.set(_firestore.collection('usernames').doc(cleanUsername), {
        'uid': uid,
      });
      await batch.commit();

      return user;
    } on FirebaseAuthException catch (error) {
      throw Exception(error.message);
    }
  }

  Future<UserModel> loginWithEmailOrUsername({
    required String emailOrUsername,
    required String password,
  }) async {
    String email = emailOrUsername.trim();

    if (!email.contains('@')) {
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(email.toLowerCase())
          .get();

      if (!usernameDoc.exists) {
        throw Exception('No account found with that username.');
      }

      final uid = usernameDoc.data()!['uid'] as String;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      email = userDoc.data()!['email'] as String;
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email.toLowerCase(),
      password: password,
    );

    final uid = credential.user!.uid;
    final userDoc = await _firestore.collection('users').doc(uid).get();

    await _firestore.collection('users').doc(uid).update({
      'isOnline': true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });

    return UserModel.fromMap(userDoc.data()!);
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
      await NotificationService.instance.clearTokenForCurrentUser();
    }

    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<UserModel?> fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
