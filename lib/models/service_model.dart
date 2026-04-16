import 'package:hive/hive.dart';

part 'service_model.g.dart';

@HiveType(typeId: 0)
class Service {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final double durationHours;
  @HiveField(4)
  final double price;
  @HiveField(5)
  final String? imageUrl;
  @HiveField(6)
  final String category;
  @HiveField(7)
  final String? estimatedTime;
  @HiveField(8)
  final String? tenantId;
  final String? tenantName;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.durationHours,
    this.imageUrl,
    this.estimatedTime,
    this.tenantId,
    this.tenantName,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      durationHours: (map['duration_hours'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'],
      category: map['category'] ?? 'General',
      estimatedTime: map['estimated_time'],
      tenantId: map['tenant_id'],
      tenantName: map['tenants'] != null ? map['tenants']['name'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'duration_hours': durationHours,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'estimated_time': estimatedTime,
      'tenant_id': tenantId,
    };
  }
}
