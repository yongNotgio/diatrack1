class NotificationModel {
  final String notificationId;
  final String userId;
  final String userRole;
  final String title;
  final String message;
  final String? type; // 'appointment', 'patient', 'medication', 'wound'
  final String? referenceId;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.userRole,
    required this.title,
    required this.message,
    this.type,
    this.referenceId,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notification_id'] as String,
      userId: map['user_id'] as String,
      userRole: map['user_role'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String?,
      referenceId: map['reference_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: map['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'user_role': userRole,
      'title': title,
      'message': message,
      'type': type,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? userRole,
    String? title,
    String? message,
    String? type,
    String? referenceId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
