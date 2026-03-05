import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 5)
class Expense {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String vehicleId;
  @HiveField(2)
  final String profileId;
  @HiveField(3)
  final double amount;
  @HiveField(4)
  final String category;
  @HiveField(5)
  final String? description;
  @HiveField(6)
  final DateTime date;

  Expense({
    required this.id,
    required this.vehicleId,
    required this.profileId,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      vehicleId: map['vehicle_id'] ?? '',
      profileId: map['profile_id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Other',
      description: map['description'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicle_id': vehicleId,
      'profile_id': profileId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
