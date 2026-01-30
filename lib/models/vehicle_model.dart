class Vehicle {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? color;
  final String? imageUrl;
  final DateTime? lastServiceDate;
  final int? nextServiceMileage;
  final DateTime? insuranceExpiry;
  final DateTime createdAt;
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
