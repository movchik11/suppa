class Profile {
  final String id;
  final String email;
  final String role;
  final String? displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final int loyaltyPoints;
  final String preferredContact;
  final bool notificationsEnabled;
  final String? referralCode;
  final String? referredBy;
  final bool isLightMode;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.loyaltyPoints = 0,
    this.preferredContact = 'Phone',
    this.notificationsEnabled = true,
    this.referralCode,
    this.referredBy,
    this.isLightMode = false,
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
      loyaltyPoints: map['loyalty_points'] ?? 0,
      preferredContact: map['preferred_contact'] ?? 'Phone',
      notificationsEnabled: map['notifications_enabled'] ?? true,
      referralCode: map['referral_code'],
      referredBy: map['referred_by'],
      isLightMode: map['is_light_mode'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role,
      'loyalty_points': loyaltyPoints,
      'preferred_contact': preferredContact,
      'notifications_enabled': notificationsEnabled,
      'is_light_mode': isLightMode,
    };
  }
}
