class Vehicle {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? color;
  final String? imageUrl;
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
    };
  }
}
