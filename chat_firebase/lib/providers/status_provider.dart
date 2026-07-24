import 'dart:io';

import 'package:chatappui/data/models/status_model.dart';
import 'package:chatappui/data/services/cloudinary_service.dart';
import 'package:chatappui/data/services/media_picker_service.dart';
import 'package:chatappui/data/services/status_service.dart';
import 'package:flutter/material.dart';

class StatusProvider extends ChangeNotifier {
  final StatusService _statusService = StatusService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final MediaPickerService _mediaPickerService = MediaPickerService();

  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;

  Future<void> cleanupExpiredStatuses() {
    return _statusService.deleteExpiredStatuses();
  }

  Future<bool> createImageStatus() async {
    final file = await _mediaPickerService.pickImageFromGallery();
    if (file == null) return false;

    await _uploadStatus(file: file, type: StatusType.image);
    return true;
  }

  Future<bool> createVideoStatus() async {
    final file = await _mediaPickerService.pickVideoFromGallery();
    if (file == null) return false;

    await _uploadStatus(file: file, type: StatusType.video);
    return true;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _uploadStatus({
    required File file,
    required StatusType type,
  }) async {
    _isUploading = true;
    _uploadProgress = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final mediaUrl = await _cloudinaryService.uploadStatusMedia(
        mediaFile: file,
        statusType: type,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      await _statusService.createStatus(mediaUrl: mediaUrl, type: type);
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
