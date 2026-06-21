class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;

  const Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'].toString(),
      title: json['title'],
      targetAmount: double.parse(json['targetAmount'].toString()),
      savedAmount: double.parse(json['savedAmount'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
    };
  }
}
