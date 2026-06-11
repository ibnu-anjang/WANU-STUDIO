class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
  });

  final String id;
  final String role;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;

  bool get isAdmin => role == 'admin';

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'] as String,
    role: map['role'] as String,
    username: map['username'] as String?,
    displayName: map['display_name'] as String?,
    avatarUrl: map['avatar_url'] as String?,
    bio: map['bio'] as String?,
  );
}
