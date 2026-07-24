import 'dart:io';

import 'package:chatappui/data/models/block_status.dart';
import 'package:chatappui/data/models/blocked_user_model.dart';
import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _blockedUsersCollection(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).collection('blocked_users');
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel?> getCurrentUser() async {
    final uid = _uid;
    if (uid == null) return null;
    return getUserById(uid);
  }

  Stream<UserModel?> userStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null);
  }

  Future<List<UserModel>> searchByUsername(String query) async {
    if (query.isEmpty) return <UserModel>[];

    final lower = query.toLowerCase();
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lower)
        .where('username', isLessThan: '$lower\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != _uid)
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  Future<UserModel> updateProfile({
    required String firstName,
    String? lastName,
    String? bio,
    File? photoFile,
    ValueChanged<double>? onPhotoUploadProgress,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    String? photoUrl;
    if (photoFile != null) {
      photoUrl = await _cloudinaryService.uploadProfilePhoto(
        imageFile: photoFile,
        onProgress: onPhotoUploadProgress,
      );
    }

    final updates = <String, dynamic>{
      'firstName': firstName.trim(),
      if (lastName != null) 'lastName': lastName.trim(),
      if (bio != null) 'bio': bio.trim(),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .set(updates, SetOptions(merge: true));

    final doc = await _firestore.collection('users').doc(uid).get();
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> blockUser(UserModel user) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final blockedUser = BlockedUserModel(
      uid: user.uid,
      username: user.username,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      blockedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _blockedUsersCollection(uid).doc(user.uid).set(blockedUser.toMap());
  }

  Future<void> unblockUser(String blockedUserId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    await _blockedUsersCollection(uid).doc(blockedUserId).delete();
  }

  Stream<List<BlockedUserModel>> blockedUsersStream() {
    final uid = _uid;
    if (uid == null) return const Stream<List<BlockedUserModel>>.empty();

    return _blockedUsersCollection(uid)
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BlockedUserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<BlockStatus> blockStatusStream(String otherUserId) {
    final uid = _uid;
    if (uid == null) {
      return Stream<BlockStatus>.value(const BlockStatus());
    }

    final blockedByMeStream =
        _blockedUsersCollection(uid).doc(otherUserId).snapshots();
    final blockedByOtherStream =
        _blockedUsersCollection(otherUserId).doc(uid).snapshots();

    return Rx.combineLatest2<DocumentSnapshot<Map<String, dynamic>>,
        DocumentSnapshot<Map<String, dynamic>>, BlockStatus>(
      blockedByMeStream,
      blockedByOtherStream,
      (blockedByMe, blockedByOther) => BlockStatus(
        blockedByMe: blockedByMe.exists,
        blockedByOther: blockedByOther.exists,
      ),
    );
  }

  Future<Set<String>> getBlockedUserIds() async {
    final uid = _uid;
    if (uid == null) return <String>{};

    final snapshot = await _blockedUsersCollection(uid).get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  Future<void> setOnline() async => _setPresence(true);
  Future<void> setOffline() async => _setPresence(false);

  Future<void> _setPresence(bool online) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'isOnline': online,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
