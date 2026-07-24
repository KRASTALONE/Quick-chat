class UserModel {
  final String uid;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String bio;
  final String photoUrl;
  final String fcmToken;
  final bool isOnline;
  final int lastSeen;
  final int createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.firstName,
    this.lastName = '',
    this.bio = '',
    this.photoUrl = '',
    this.fcmToken = '',
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      fcmToken: map['fcmToken'] as String? ?? '',
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: (map['lastSeen'] as int?) ?? 0,
      createdAt: (map['createdAt'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? bio,
    String? photoUrl,
    String? fcmToken,
    bool? isOnline,
    int? lastSeen,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : username;
  bool get hasProfilePhoto => photoUrl.trim().isNotEmpty;
}
