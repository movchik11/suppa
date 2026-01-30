class Expense {
  final String id;
  final String vehicleId;
  final String profileId;
  final double amount;
  final String category;
  final String? description;
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
