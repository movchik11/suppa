class Service {
  final String id;
  final String name;
  final String description;
  final double durationHours;
  final double price;
  final String? imageUrl;
  final String category;
  final String? estimatedTime;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.durationHours,
    required this.price,
    this.imageUrl,
    this.category = 'General',
    this.estimatedTime,
    this.rating = 5.0,
    required this.createdAt,
    required this.updatedAt,
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
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
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
      'rating': rating,
    };
  }
}
