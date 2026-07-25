import '../screens/goal_screen.dart'; // for GoalStatus

class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? dueDate;
  final GoalStatus? status;
  final String? iconEmoji;

  const Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.dueDate,
    this.status,
    this.iconEmoji,
  });

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? dueDate,
    GoalStatus? status,
    String? iconEmoji,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  /// Deserialise from your API response JSON.
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['goalID'].toString(),
      title: json['goalName']?.toString() ?? '',
      targetAmount: _parseAmount(json['goalTargetAmt']),
      savedAmount: _parseAmount(json['goalCurrentAmt']),
      dueDate: json['goalDueDate'] != null
          ? DateTime.tryParse(json['goalDueDate'].toString())
          : null,
      status: _statusFromString(json['goalStatus']?.toString()),
      iconEmoji: (json['goalIcon'] ?? json['goalIconEmoji'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'goalID': id,
    'goalName': title,
    'goalTargetAmt': targetAmount,
    'goalCurrentAmt': savedAmount,
    'goalDueDate': dueDate?.toIso8601String(),
    'goalStatus': status?.name,
    'goalIconEmoji': iconEmoji,
  };

  /// Postgres NUMERIC/DECIMAL columns come back through node-postgres as
  /// Strings (to avoid floating point precision loss), not as num — so this
  /// has to tolerate both instead of doing a hard `as num` cast.
  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static GoalStatus? _statusFromString(String? s) {
    if (s == null) return null;
    return GoalStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => GoalStatus.onTrack,
    );
  }
}
