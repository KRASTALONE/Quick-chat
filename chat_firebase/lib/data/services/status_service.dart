import 'package:chatappui/data/models/status_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  int get _activeThreshold {
    return DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;
  }

  Future<void> createStatus({
    required String mediaUrl,
    required StatusType type,
  }) async {
    final userId = _uid;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final statusRef = _firestore.collection('statuses').doc();

    final status = StatusModel(
      id: statusRef.id,
      userId: userId,
      mediaUrl: mediaUrl,
      type: type,
      timestamp: now,
    );

    await statusRef.set(status.toMap());
  }

  Stream<List<StatusModel>> activeStatusesStream() {
    return _firestore
        .collection('statuses')
        .where('timestamp', isGreaterThanOrEqualTo: _activeThreshold)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StatusModel.fromMap(doc.data(), doc.id))
              .where((status) => !status.isExpired)
              .toList(),
        );
  }

  Future<void> deleteExpiredStatuses() async {
    final snapshot = await _firestore
        .collection('statuses')
        .where('timestamp', isLessThan: _activeThreshold)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
