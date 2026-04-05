import 'package:supa/models/profile_model.dart';
import 'package:supa/models/vehicle_model.dart';

import 'package:hive/hive.dart';

part 'order_model.g.dart';

@HiveType(typeId: 2)
class Order {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String? vehicleId;
  @HiveField(3)
  final String carModel;
  @HiveField(4)
  final String issueDescription;
  @HiveField(5)
  final String status;
  @HiveField(6)
  final DateTime? scheduledAt;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;
  @HiveField(9)
  final String? branchName;
  @HiveField(10)
  final String urgencyLevel;
  @HiveField(11)
  final String? serviceId;
  @HiveField(12)
  final Profile? user;
  @HiveField(13)
  final Vehicle? vehicle;
  @HiveField(14)
  final double? totalPrice;
  @HiveField(15)
  final String? tenantId;

  Order({
    required this.id,
    required this.userId,
    this.vehicleId,
    required this.carModel,
    required this.issueDescription,
    required this.status,
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.branchName,
    this.urgencyLevel = 'Normal',
    this.serviceId,
    this.user,
    this.vehicle,
    this.totalPrice,
    this.tenantId,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      vehicleId: map['vehicle_id'],
      carModel: map['car_model'] ?? '',
      issueDescription: map['issue_description'] ?? '',
      status: map['status'] ?? 'pending',
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      branchName: map['branch_name'],
      urgencyLevel: map['urgency_level'] ?? 'Normal',
      serviceId: map['service_id'],
      user: map['user'] != null ? Profile.fromMap(map['user']) : null,
      vehicle: map['vehicle'] != null ? Vehicle.fromMap(map['vehicle']) : null,
      totalPrice: map['total_price'] != null
          ? (map['total_price'] as num).toDouble()
          : null,
      tenantId: map['tenant_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'vehicle_id': vehicleId,
      'car_model': carModel,
      'issue_description': issueDescription,
      'status': status,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'branch_name': branchName,
      'urgency_level': urgencyLevel,
      'service_id': serviceId,
      'total_price': totalPrice,
      'tenant_id': tenantId,
    };
  }
}
