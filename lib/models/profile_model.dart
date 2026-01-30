class Profile {
  final String id;
  final String email;
  final String role;
  final String? displayName;
  final String? phoneNumber;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.phoneNumber,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      displayName: map['display_name'],
      phoneNumber: map['phone_number'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'phone_number': phoneNumber,
      'role': role,
    };
  }
}
