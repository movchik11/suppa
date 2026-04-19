class Tenant {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? imageUrl;
  final DateTime createdAt;

  Tenant({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.imageUrl,
    required this.createdAt,
  });

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'],
      phone: map['phone'],
      imageUrl: map['image_url'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'image_url': imageUrl,
    };
  }
}
