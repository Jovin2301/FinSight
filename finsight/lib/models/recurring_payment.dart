class RecurringPayment {
  final String id;
  final String name;
  final String category;
  final double amount;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;

  const RecurringPayment({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.status = 'active',
  });

  factory RecurringPayment.fromJson(Map<String, dynamic> json) {
    return RecurringPayment(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      category: json['category'] ?? 'Bills',
      amount: double.parse(json['amount'].toString()),
      frequency: json['frequency'] ?? 'monthly',
      startDate: DateTime.parse(json['startDate'].toString()),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'].toString()),
      status: json['status'] ?? 'active',
    );
  }

  RecurringPayment copyWith({
    String? id,
    String? name,
    String? category,
    double? amount,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'amount': amount,
      'frequency': frequency,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate?.toIso8601String().split('T')[0],
      'status': status,
    };
  }
}
