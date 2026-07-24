import 'dart:io';

import 'package:chatappui/data/models/message_model.dart';
import 'package:chatappui/data/services/chat_service.dart';
import 'package:chatappui/data/services/cloudinary_service.dart';
import 'package:chatappui/data/services/media_picker_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final MediaPickerService _mediaPickerService = MediaPickerService();

  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;

  Future<void> sendTextMessage({
    required String receiverId,
    required String text,
  }) async {
    await _chatService.sendMessage(
      receiverId: receiverId,
      text: text,
    );
  }

  Future<bool> pickAndSendImage({required String receiverId}) async {
    final file = await _mediaPickerService.pickImageFromGallery();
    if (file == null) return false;

    await _sendMedia(
      receiverId: receiverId,
      file: file,
      type: MessageType.image,
    );
    return true;
  }

  Future<bool> pickAndSendVideo({required String receiverId}) async {
    final file = await _mediaPickerService.pickVideoFromGallery();
    if (file == null) return false;

    await _sendMedia(
      receiverId: receiverId,
      file: file,
      type: MessageType.video,
    );
    return true;
  }

  Future<void> _sendMedia({
    required String receiverId,
    required File file,
    required MessageType type,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('Not authenticated');
    }

    _isUploading = true;
    _uploadProgress = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final chatId = _chatService.getChatId(currentUserId, receiverId);
      final mediaUrl = await _cloudinaryService.uploadChatMedia(
        mediaFile: file,
        messageType: type,
        chatId: chatId,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      await _chatService.sendMessage(
        receiverId: receiverId,
        mediaUrl: mediaUrl,
        type: type,
      );
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isUploading = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }
}
