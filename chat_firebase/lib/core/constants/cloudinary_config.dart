class CloudinaryConfig {
  static const String cloudName = 'dklofuc93';
  static const String unsignedUploadPreset = 'chat_app_upload';

  static const String profileFolder = 'chat_app/profile_photos';
  static const String statusFolder = 'chat_app/statuses';
  static const String chatFolder = 'chat_app/messages';

  static String chatFolderFor(String chatId) => '$chatFolder/$chatId';

  static bool get isConfigured {
    return cloudName.isNotEmpty &&
        unsignedUploadPreset.isNotEmpty;
  }
}