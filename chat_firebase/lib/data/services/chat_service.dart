import 'package:chatappui/data/models/message_model.dart';
import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String getChatId(String uid1, String uid2) {
    final sorted = <String>[uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> sendMessage({
    required String receiverId,
    String? text,
    String? mediaUrl,
    MessageType type = MessageType.text,
  }) async {
    final senderId = _uid;
    if (senderId == null) throw Exception('Not authenticated');

    if (type == MessageType.text && (text == null || text.trim().isEmpty)) {
      throw Exception('Text message cannot be empty.');
    }

    if (type.isMedia && (mediaUrl == null || mediaUrl.trim().isEmpty)) {
      throw Exception('Media message is missing its URL.');
    }

    final isBlocked = await _isMessagingBlocked(
      senderId: senderId,
      receiverId: receiverId,
    );
    if (isBlocked) {
      throw Exception(
        'You cannot send messages because one of you has blocked the other user.',
      );
    }

    final chatId = getChatId(senderId, receiverId);
    final now = DateTime.now();

    final message = MessageModel(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      text: text?.trim(),
      mediaUrl: mediaUrl?.trim(),
      type: type,
      timestamp: now,
    );

    final batch = _firestore.batch();
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    batch.set(messageRef, message.toMap());

    // When a new message arrives, a previously hidden chat should appear again.
    batch.set(
      chatRef,
      {
        'participants': <String>[senderId, receiverId],
        'lastMessage': message.previewText,
        'lastMessageType': type.value,
        'lastTimestamp': now.millisecondsSinceEpoch,
        'lastSenderId': senderId,
        'hiddenFor': FieldValue.arrayRemove(<String>[senderId, receiverId]),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    final senderUser = await _getCurrentSender();
    await NotificationService.instance.queueChatNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderUser?.displayName ?? 'New message',
      previewText: message.previewText,
    );
  }

  Stream<List<MessageModel>> messagesStream(String otherUid) {
    final senderId = _uid;
    if (senderId == null) return const Stream<List<MessageModel>>.empty();

    final chatId = getChatId(senderId, otherUid);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> deleteMessage({
    required String otherUserId,
    required MessageModel message,
  }) async {
    final myUid = _uid;
    if (myUid == null) throw Exception('Not authenticated');

    final chatId = getChatId(myUid, otherUserId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .delete();

    await _refreshChatMetadata(chatId);
  }

  Future<void> deleteChat(String otherUserId) async {
    final myUid = _uid;
    if (myUid == null) throw Exception('Not authenticated');

    final chatId = getChatId(myUid, otherUserId);
    await _firestore.collection('chats').doc(chatId).set({
      'hiddenFor': FieldValue.arrayUnion(<String>[myUid]),
    }, SetOptions(merge: true));
  }

  Future<void> markAsRead(String otherUid) async {
    final myUid = _uid;
    if (myUid == null) return;

    final chatId = getChatId(myUid, otherUid);
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: myUid)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, <String, dynamic>{'isRead': true});
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> myChatsStream() {
    final myUid = _uid;
    if (myUid == null) return const Stream<List<Map<String, dynamic>>>.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{'chatId': doc.id, ...doc.data()})
              .where((chat) {
            final hiddenFor = List<String>.from(
              chat['hiddenFor'] ?? <String>[],
            );
            return !hiddenFor.contains(myUid);
          }).toList(),
        );
  }

  Future<bool> _isMessagingBlocked({
    required String senderId,
    required String receiverId,
  }) async {
    final senderBlockedReceiver = await _firestore
        .collection('users')
        .doc(senderId)
        .collection('blocked_users')
        .doc(receiverId)
        .get();

    final receiverBlockedSender = await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('blocked_users')
        .doc(senderId)
        .get();

    return senderBlockedReceiver.exists || receiverBlockedSender.exists;
  }

  Future<void> _refreshChatMetadata(String chatId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final latestMessageSnapshot = await chatRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (latestMessageSnapshot.docs.isEmpty) {
      await chatRef.delete();
      return;
    }

    final latestMessageDoc = latestMessageSnapshot.docs.first;
    final latestMessage = MessageModel.fromMap(
      latestMessageDoc.data(),
      latestMessageDoc.id,
    );

    await chatRef.set({
      'lastMessage': latestMessage.previewText,
      'lastMessageType': latestMessage.type.value,
      'lastTimestamp': latestMessage.timestamp.millisecondsSinceEpoch,
      'lastSenderId': latestMessage.senderId,
    }, SetOptions(merge: true));
  }

  Future<UserModel?> _getCurrentSender() async {
    final senderId = _uid;
    if (senderId == null) return null;

    final doc = await _firestore.collection('users').doc(senderId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
