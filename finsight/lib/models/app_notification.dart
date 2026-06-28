class AppNotification {
  final String id;
  final String type;
  final String message;
  final DateTime date;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.date,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      type: json['type'] ?? 'alert',
      message: json['message'] ?? '',
      date: DateTime.parse(json['date'].toString()),
      isRead: json['isRead'] == true,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      message: message,
      date: date,
      isRead: isRead ?? this.isRead,
    );
  }
}
