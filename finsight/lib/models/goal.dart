// models/goal.dart
import '../screens/goal_screen.dart'; // for GoalStatus

class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? dueDate;       // NEW
  final GoalStatus? status;      // NEW
  final String? iconEmoji;       // NEW

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
      id: json['goalID'] as String,
      title: json['goalName'] as String,
      targetAmount: (json['goalTargetAmt'] as num).toDouble(),
      savedAmount: (json['goalCurrentAmt'] as num).toDouble(),
      dueDate: json['goalDueDate'] != null
          ? DateTime.parse(json['goalDueDate'] as String)
          : null,
      status: _statusFromString(json['goalStatus'] as String?),
      iconEmoji: json['goalIconEmoji'] as String?,
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

  static GoalStatus? _statusFromString(String? s) {
    if (s == null) return null;
    return GoalStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => GoalStatus.onTrack,
    );
  }
}