/// NotificationModel
///
/// Represents a push notification in the application.
/// Follows Single Responsibility Principle (SRP) - only handles notification data.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime receivedAt;
  final bool isRead;
  final String? imageUrl;
  final NotificationType type;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    required this.receivedAt,
    this.isRead = false,
    this.imageUrl,
    this.type = NotificationType.general,
  });

  /// Create NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      receivedAt: json['receivedAt'] != null
          ? DateTime.parse(json['receivedAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      type: NotificationType.fromString(json['type'] ?? 'general'),
    );
  }

  /// Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'receivedAt': receivedAt.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'type': type.value,
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? receivedAt,
    bool? isRead,
    String? imageUrl,
    NotificationType? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, body: $body, receivedAt: $receivedAt, isRead: $isRead, type: ${type.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.receivedAt == receivedAt &&
        other.isRead == isRead &&
        other.imageUrl == imageUrl &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        body.hashCode ^
        receivedAt.hashCode ^
        isRead.hashCode ^
        imageUrl.hashCode ^
        type.hashCode;
  }
}

/// NotificationType
///
/// Enum for different notification types
enum NotificationType {
  general('general'),
  feed('feed'),
  attendance('attendance'),
  eftekad('eftekad'),
  classUpdate('class_update'),
  announcement('announcement'),
  reminder('reminder');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    switch (value) {
      case 'feed':
        return NotificationType.feed;
      case 'attendance':
        return NotificationType.attendance;
      case 'eftekad':
        return NotificationType.eftekad;
      case 'class_update':
        return NotificationType.classUpdate;
      case 'announcement':
        return NotificationType.announcement;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.general;
    }
  }
}

/// NotificationPayload
///
/// Represents the payload to send a notification
class NotificationPayload {
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? imageUrl;

  const NotificationPayload({
    required this.title,
    required this.body,
    this.data,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      if (data != null) 'data': data,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
