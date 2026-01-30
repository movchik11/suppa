class VehicleDocument {
  final String id;
  final String vehicleId;
  final String type;
  final String? imageUrl;
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
