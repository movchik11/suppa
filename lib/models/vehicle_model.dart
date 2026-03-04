import 'package:hive/hive.dart';

part 'vehicle_model.g.dart';

@HiveType(typeId: 1)
class Vehicle {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String brand;
  @HiveField(3)
  final String model;
  @HiveField(4)
  final int? year;
  @HiveField(5)
  final String? licensePlate;
  @HiveField(6)
  final String? color;
  @HiveField(7)
  final String? imageUrl;
  @HiveField(8)
  final DateTime? lastServiceDate;
  @HiveField(9)
  final int? nextServiceMileage;
  @HiveField(10)
  final DateTime? insuranceExpiry;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    this.year,
    this.licensePlate,
    this.color,
    this.imageUrl,
    this.lastServiceDate,
    this.nextServiceMileage,
    this.insuranceExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'],
      licensePlate: map['license_plate'],
      color: map['color'],
      imageUrl: map['image_url'],
      lastServiceDate: map['last_service_date'] != null
          ? DateTime.parse(map['last_service_date'])
          : null,
      nextServiceMileage: map['next_service_mileage'],
      insuranceExpiry: map['insurance_expiry'] != null
          ? DateTime.parse(map['insurance_expiry'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'color': color,
      'image_url': imageUrl,
      'user_id': userId,
      'last_service_date': lastServiceDate?.toIso8601String(),
      'next_service_mileage': nextServiceMileage,
      'insurance_expiry': insuranceExpiry?.toIso8601String(),
    };
  }
}
