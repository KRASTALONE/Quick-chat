class BlockedUserModel {
  final String uid;
  final String username;
  final String displayName;
  final String photoUrl;
  final int blockedAt;

  const BlockedUserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.blockedAt,
  });

  factory BlockedUserModel.fromMap(Map<String, dynamic> map) {
    return BlockedUserModel(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      blockedAt: map['blockedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'blockedAt': blockedAt,
    };
  }
}
