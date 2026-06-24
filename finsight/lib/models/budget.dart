class Budget {
  final String id;
  final String category;
  final double limit;

  const Budget({required this.id, required this.category, required this.limit});

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'].toString(),
      category: json['category'],
      limit: double.parse(json['limit'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'category': category, 'limit': limit};
  }
}
