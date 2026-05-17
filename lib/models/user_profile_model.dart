/// User profile model for Firestore
class UserProfile {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    required this.createdAt,
    this.lastLogin,
    this.metadata,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
    'metadata': metadata ?? {},
  };

  /// Create from Firestore document
  factory UserProfile.fromFirestore(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] as String,
    name: map['name'] as String?,
    email: map['email'] as String?,
    photoUrl: map['photoUrl'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    lastLogin: map['lastLogin'] != null
        ? DateTime.parse(map['lastLogin'] as String)
        : null,
    metadata: map['metadata'] as Map<String, dynamic>?,
  );

  /// Create copy with updates
  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? metadata,
  }) => UserProfile(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    createdAt: createdAt ?? this.createdAt,
    lastLogin: lastLogin ?? this.lastLogin,
    metadata: metadata ?? this.metadata,
  );
}
