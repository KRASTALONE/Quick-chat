import 'dart:io';

import 'package:image_picker/image_picker.dart';

class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return null;
    return File(file.path);
  }

  Future<File?> pickImageFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;
    return File(file.path);
  }

  Future<File?> pickVideoFromGallery() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (file == null) return null;
    return File(file.path);
  }
}
