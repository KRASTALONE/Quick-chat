import 'dart:io';

import 'package:chatappui/core/constants/cloudinary_config.dart';
import 'package:chatappui/data/models/message_model.dart';
import 'package:chatappui/data/models/status_model.dart';
import 'package:dio/dio.dart';

enum CloudinaryResourceType { image, video }

extension CloudinaryResourceTypeX on CloudinaryResourceType {
  String get apiPath {
    switch (this) {
      case CloudinaryResourceType.image:
        return 'image';
      case CloudinaryResourceType.video:
        return 'video';
    }
  }
}

class CloudinaryService {
  final Dio _dio;

  CloudinaryService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  Future<String> uploadProfilePhoto({
    required File imageFile,
    void Function(double progress)? onProgress,
  }) {
    return _uploadFile(
      file: imageFile,
      resourceType: CloudinaryResourceType.image,
      folder: CloudinaryConfig.profileFolder,
      onProgress: onProgress,
    );
  }

  Future<String> uploadChatMedia({
    required File mediaFile,
    required MessageType messageType,
    required String chatId,
    void Function(double progress)? onProgress,
  }) {
    return _uploadFile(
      file: mediaFile,
      resourceType: messageType == MessageType.video
          ? CloudinaryResourceType.video
          : CloudinaryResourceType.image,
      folder: CloudinaryConfig.chatFolderFor(chatId),
      onProgress: onProgress,
    );
  }

  Future<String> uploadStatusMedia({
    required File mediaFile,
    required StatusType statusType,
    void Function(double progress)? onProgress,
  }) {
    return _uploadFile(
      file: mediaFile,
      resourceType: statusType == StatusType.video
          ? CloudinaryResourceType.video
          : CloudinaryResourceType.image,
      folder: CloudinaryConfig.statusFolder,
      onProgress: onProgress,
    );
  }

  Future<String> _uploadFile({
    required File file,
    required CloudinaryResourceType resourceType,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Please update cloudinary_config.dart with your Cloudinary cloud name '
        'and unsigned upload preset before uploading media.',
      );
    }

    final fileName = file.uri.pathSegments.isEmpty
        ? 'upload_file'
        : file.uri.pathSegments.last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'upload_preset': CloudinaryConfig.unsignedUploadPreset,
      'folder': folder,
    });

    final url = 'https://api.cloudinary.com/v1_1/'
        '${CloudinaryConfig.cloudName}/${resourceType.apiPath}/upload';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: formData,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          onProgress?.call(sent / total);
        },
      );

      final secureUrl = response.data?['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Cloudinary did not return a secure media URL.');
      }

      onProgress?.call(1);
      return secureUrl;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      String? responseMessage;

      if (responseData is Map<String, dynamic>) {
        final errorData = responseData['error'];
        if (errorData is Map<String, dynamic>) {
          responseMessage = errorData['message'] as String?;
        }
      }

      throw Exception(
        responseMessage ??
            'Media upload failed. Please check your internet connection and '
                'Cloudinary configuration.',
      );
    }
  }
}
