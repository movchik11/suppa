import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 3)
class Profile {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String role;
  @HiveField(3)
  final String? displayName;
  @HiveField(4)
  final String? phoneNumber;
  @HiveField(5)
  final String? avatarUrl;
  @HiveField(6)
  final int loyaltyPoints;
  @HiveField(7)
  final String preferredContact;
  @HiveField(8)
  final bool notificationsEnabled;
  @HiveField(9)
  final String? referralCode;
  @HiveField(10)
  final String? referredBy;
  @HiveField(11)
  final bool isLightMode;
  @HiveField(12)
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
