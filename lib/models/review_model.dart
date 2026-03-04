class Review {
  final String id;
  final String orderId;
  final String userId;
  final String? serviceId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.orderId,
    required this.userId,
    this.serviceId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      orderId: map['order_id'],
      userId: map['user_id'],
      serviceId: map['service_id'],
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'service_id': serviceId,
      'rating': rating,
      'comment': comment,
    };
  }
}
