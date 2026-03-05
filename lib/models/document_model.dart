import 'package:hive/hive.dart';

part 'document_model.g.dart';

@HiveType(typeId: 6)
class VehicleDocument {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String vehicleId;
  @HiveField(2)
  final String type;
  @HiveField(3)
  final String? imageUrl;
  @HiveField(4)
  final DateTime? expiryDate;

  VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.type,
    this.imageUrl,
    this.expiryDate,
  });

  factory VehicleDocument.fromMap(Map<String, dynamic> map) {
    return VehicleDocument(
      id: map['id'] ?? '',
      vehicleId: map['vehicle_id'] ?? '',
      type: map['type'] ?? '',
      imageUrl: map['image_url'],
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicle_id': vehicleId,
      'type': type,
      'image_url': imageUrl,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }
}
