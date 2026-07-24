enum MessageType { text, image, video }

extension MessageTypeX on MessageType {
  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
    }
  }

  static MessageType fromValue(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }

  bool get isMedia => this == MessageType.image || this == MessageType.video;
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? mediaUrl;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.mediaUrl,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    final type = MessageTypeX.fromValue(map['type'] as String?);
    final legacyContent = map['content'] as String?;

    return MessageModel(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['text'] as String? ??
          (type == MessageType.text ? legacyContent : null),
      mediaUrl:
          map['mediaUrl'] as String? ?? (type.isMedia ? legacyContent : null),
      type: type,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? 0,
      ),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type.value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  String get previewText {
    switch (type) {
      case MessageType.image:
        return '[Photo]';
      case MessageType.video:
        return '[Video]';
      case MessageType.text:
        return (text ?? '').trim();
    }
  }
}
