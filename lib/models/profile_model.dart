class Profile {
  final String id;
  final String email;
  final String role;
  final String? displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      displayName: map['display_name'],
      phoneNumber: map['phone_number'],
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role,
    };
  }
}
