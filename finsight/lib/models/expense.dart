class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String paymentMethod;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.paymentMethod = 'Cash',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'].toString(),
      title: json['title'],
      category: json['category'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['date']),
      paymentMethod: json['paymentMethod'] ?? 'Cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'paymentMethod': paymentMethod,
    };
  }
}
