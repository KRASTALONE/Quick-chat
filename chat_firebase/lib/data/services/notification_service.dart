import 'package:chatappui/data/services/user_service.dart';
import 'package:chatappui/presentation/screens/chats/chat_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'Notifications for incoming messages',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _requestPermissions();
    await _configureLocalNotifications();
    await syncTokenForCurrentUser();

    _messaging.onTokenRefresh.listen((_) => syncTokenForCurrentUser());
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleOpenedMessage(initialMessage);
    }

    _initialized = true;
  }

  Future<void> syncTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  Future<void> clearTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'fcmToken': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> queueChatNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String previewText,
  }) async {
    if (receiverId == senderId) return;

    await _firestore.collection('notification_queue').add({
      'receiverId': receiverId,
      'senderId': senderId,
      'chatUserId': senderId,
      'senderName': senderName,
      'previewText': previewText,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'processed': false,
    });
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        final chatUserId = response.payload;
        if (chatUserId == null || chatUserId.isEmpty) return;
        await openChatFromNotification(chatUserId);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_chatChannel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final senderName = message.notification?.title ??
        (message.data['senderName'] as String?) ??
        'New message';
    final previewText = message.notification?.body ??
        (message.data['previewText'] as String?) ??
        'Open chat to view';
    final chatUserId = message.data['chatUserId'] as String?;

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      senderName,
      previewText,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chatChannel.id,
          _chatChannel.name,
          channelDescription: _chatChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: chatUserId,
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final chatUserId = message.data['chatUserId'] as String?;
    if (chatUserId == null || chatUserId.isEmpty) return;
    await openChatFromNotification(chatUserId);
  }

  Future<void> openChatFromNotification(String otherUserId) async {
    final user = await UserService().getUserById(otherUserId);
    final navigatorState = navigatorKey.currentState;
    if (user == null || navigatorState == null) return;

    navigatorState.push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(otherUser: user),
      ),
    );
  }
}
