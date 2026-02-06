class Service {
  final String id;
  final String name;
  final String description;
  final double durationHours;
  final double price;
  final String? imageUrl;
  final String category;
  final String? estimatedTime;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.durationHours,
    this.imageUrl,
    this.estimatedTime,
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
    };
  }
}
