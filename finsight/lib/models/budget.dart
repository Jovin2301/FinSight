import '../constants/category_icons.dart';

class Budget {
  final String id;
  final String name;
  final String icon;
  final String category;
  final double limit;
  final String description;
  final String frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final double spent;

  const Budget({
    required this.id,
    required this.category,
    required this.limit,
    this.name = '',
    this.icon = '💰',
    this.description = '',
    this.frequency = 'monthly',
    this.startDate,
    this.endDate,
    this.spent = 0,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'].toString(),
      name: json['name'] ?? json['category'] ?? '',
      icon: json['icon'] ?? categoryEmoji(json['category'] ?? ''),
      category: json['category'],
      limit: double.parse(json['limit'].toString()),
      description: json['description'] ?? '',
      frequency: json['frequency'] ?? 'monthly',
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'].toString()),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'].toString()),
      spent: double.tryParse((json['spent'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.isEmpty ? '$category Budget' : name,
      'icon': icon,
      'category': category,
      'limit': limit,
      'description': description,
      'frequency': frequency,
      'startDate': startDate?.toIso8601String().split('T')[0],
      'endDate': endDate?.toIso8601String().split('T')[0],
    };
  }

  double get remainingAmount => limit - spent;

  double get progress {
    if (limit <= 0) return 0;
    return (spent / limit).clamp(0.0, 1.0);
  }

  bool isActiveOn(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    final start = startDate == null
        ? null
        : DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = endDate == null
        ? null
        : DateTime(endDate!.year, endDate!.month, endDate!.day);

    if (start != null && checkDate.isBefore(start)) return false;
    if (end != null && checkDate.isAfter(end)) return false;
    return true;
  }
}
