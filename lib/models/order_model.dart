class Order {
  final String id;
  final String userId;
  final String? vehicleId;
  final String carModel;
  final String issueDescription;
  final String status;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

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
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
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
    };
  }
}
