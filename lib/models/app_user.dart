class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.bio,
    this.avatarData,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastSeenAt = lastSeenAt ?? DateTime.now();

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String bio;
  final String? avatarData;
  final DateTime createdAt;
  final DateTime lastSeenAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? bio,
    String? avatarData,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      bio: bio ?? this.bio,
      avatarData: avatarData ?? this.avatarData,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'bio': bio,
        'avatarData': avatarData,
        'createdAt': createdAt.toIso8601String(),
        'lastSeenAt': lastSeenAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarData: json['avatarData'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
