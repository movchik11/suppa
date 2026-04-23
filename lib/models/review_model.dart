import 'package:hive/hive.dart';

part 'review_model.g.dart';

@HiveType(typeId: 7)
class Review {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? orderId;
  @HiveField(2)
  final String userId;
  @HiveField(3)
  final String? serviceId;
  @HiveField(4)
  final double rating;
  @HiveField(5)
  final String comment;
  @HiveField(6)
  final DateTime createdAt;

  Review({
    required this.id,
    this.orderId,
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
