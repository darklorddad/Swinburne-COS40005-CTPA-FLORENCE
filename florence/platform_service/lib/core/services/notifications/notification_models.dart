/// Notification Models for FLORENCE Digital Health Platform
library;

import 'package:flutter/foundation.dart';

/// Notification type
enum NotificationType {
  alert,        // Critical alerts (hypo/hyper)
  reminder,     // Reminders (medication, activity)
  educational,  // Educational tips
  motivational, // Motivational messages
  summary,      // Health summaries
  achievement,  // Achievements and milestones
}

/// Notification priority
enum NotificationPriority {
  critical,
  high,
  medium,
  low,
}

/// Health Notification Model
@immutable
class HealthNotification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String? actionUrl; // Deep link to relevant screen
  final Map<String, dynamic>? triggeredBy; // Data that triggered this
  final String? iconName; // Icon to display

  const HealthNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.actionUrl,
    this.triggeredBy,
    this.iconName,
  });

  String get typeLabel {
    switch (type) {
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.educational:
        return 'Tip';
      case NotificationType.motivational:
        return 'Encouragement';
      case NotificationType.summary:
        return 'Summary';
      case NotificationType.achievement:
        return 'Achievement';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case NotificationPriority.critical:
        return 'Critical';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.low:
        return 'Low';
    }
  }

  bool get requiresAction => priority == NotificationPriority.critical;

  HealthNotification copyWith({
    String? id,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? actionUrl,
    Map<String, dynamic>? triggeredBy,
    String? iconName,
  }) {
    return HealthNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      iconName: iconName ?? this.iconName,
    );
  }

  HealthNotification markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'actionUrl': actionUrl,
      'triggeredBy': triggeredBy,
      'iconName': iconName,
    };
  }

  factory HealthNotification.fromJson(Map<String, dynamic> json) {
    return HealthNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      actionUrl: json['actionUrl'] as String?,
      triggeredBy: json['triggeredBy'] as Map<String, dynamic>?,
      iconName: json['iconName'] as String?,
    );
  }
}
