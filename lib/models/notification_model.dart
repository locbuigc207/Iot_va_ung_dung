class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationPriority priority;
  final String? zoneId;
  final String? zoneName;
  final String? sensorId;
  final String? sensorName;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.priority = NotificationPriority.medium,
    this.zoneId,
    this.zoneName,
    this.sensorId,
    this.sensorName,
    this.data,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'priority': priority.name,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'sensorId': sensorId,
      'sensorName': sensorName,
      'data': data,
    };
  }

  // Create from Firebase Map
  factory NotificationModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.info,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isRead: map['isRead'] ?? false,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      zoneId: map['zoneId'],
      zoneName: map['zoneName'],
      sensorId: map['sensorId'],
      sensorName: map['sensorName'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }

  // Copy with method
  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      priority: priority,
      zoneId: zoneId,
      zoneName: zoneName,
      sensorId: sensorId,
      sensorName: sensorName,
      data: data,
    );
  }

  // Get icon based on type
  String getIcon() {
    switch (type) {
      case NotificationType.wateringStart:
        return '💧';
      case NotificationType.wateringEnd:
        return '✅';
      case NotificationType.sensorAlert:
        return '⚠️';
      case NotificationType.leakDetected:
        return '🚨';
      case NotificationType.scheduleStart:
        return '⏰';
      case NotificationType.systemError:
        return '❌';
      case NotificationType.info:
        return 'ℹ️';
    }
  }

  // Get time ago text
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

enum NotificationType {
  wateringStart,
  wateringEnd,
  sensorAlert,
  leakDetected,
  scheduleStart,
  systemError,
  info,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.wateringStart:
        return 'Bắt đầu tưới';
      case NotificationType.wateringEnd:
        return 'Kết thúc tưới';
      case NotificationType.sensorAlert:
        return 'Cảnh báo cảm biến';
      case NotificationType.leakDetected:
        return 'Phát hiện rò rỉ';
      case NotificationType.scheduleStart:
        return 'Lịch trình tưới';
      case NotificationType.systemError:
        return 'Lỗi hệ thống';
      case NotificationType.info:
        return 'Thông tin';
    }
  }
}
