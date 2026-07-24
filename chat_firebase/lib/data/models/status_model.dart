enum StatusType { image, video }

extension StatusTypeX on StatusType {
  String get value {
    switch (this) {
      case StatusType.image:
        return 'image';
      case StatusType.video:
        return 'video';
    }
  }

  static StatusType fromValue(String? value) {
    switch (value) {
      case 'video':
        return StatusType.video;
      default:
        return StatusType.image;
    }
  }
}

class StatusModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final StatusType type;
  final DateTime timestamp;

  const StatusModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.type,
    required this.timestamp,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map, String docId) {
    return StatusModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      mediaUrl: map['mediaUrl'] as String? ?? '',
      type: StatusTypeX.fromValue(map['type'] as String?),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaUrl': mediaUrl,
      'type': type.value,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  bool get isExpired {
    return DateTime.now().difference(timestamp).inHours >= 24;
  }
}
