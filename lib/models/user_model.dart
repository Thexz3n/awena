// User model used across the app.
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String language;       // "en" or "ckb"
  final bool isVerified;
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.language,
    required this.isVerified,
    required this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      language: (json['language'] as String?) ?? 'en',
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'language': language,
        'is_verified': isVerified,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? language,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      isVerified: isVerified,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  // Initial used for the avatar circle on the home screen.
  String get initial => name.trim().isNotEmpty
      ? name.trim().substring(0, 1).toUpperCase()
      : email.substring(0, 1).toUpperCase();

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : email.split('@').first;
  }
}
