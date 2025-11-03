/// Notification Service for FLORENCE Digital Health Platform
/// Manages in-app notifications and automation triggers
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../config/environment.dart';
import '../automation/pattern_detection_service.dart';
import 'notification_models.dart';

/// Service for managing notifications
class NotificationService with ChangeNotifier {
  final PatternDetectionService _patternService = PatternDetectionService();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    if (Environment.enableAutomation) {
      _startAutomationMonitoring();
    }
  }

  // Notification storage
  final List<HealthNotification> _notifications = [];
  Timer? _monitoringTimer;
  int _notificationsToday = 0;
  DateTime? _lastCheckDate;

  List<HealthNotification> get allNotifications =>
      List.unmodifiable(_notifications);

  List<HealthNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<HealthNotification> get criticalNotifications =>
      _notifications.where((n) => n.priority == NotificationPriority.critical && !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;
  int get criticalCount => criticalNotifications.length;

  /// Start automated pattern monitoring
  void _startAutomationMonitoring() {
    // Check every 15 minutes (configurable)
    _monitoringTimer = Timer.periodic(
      Duration(minutes: Environment.automationCheckInterval),
      (_) => _checkForTriggers(),
    );

    // Initial check
    _checkForTriggers();
  }

  /// Check for automation triggers
  Future<void> _checkForTriggers() async {
    if (!Environment.enableAutomation) return;

    // Reset daily counter
    final now = DateTime.now();
    if (_lastCheckDate == null || _lastCheckDate!.day != now.day) {
      _notificationsToday = 0;
      _lastCheckDate = now;
    }

    // Don't exceed daily limit
    if (_notificationsToday >= Environment.maxNotificationsPerDay) {
      return;
    }

    try {
      // Detect patterns
      final patterns = await _patternService.detectPatterns(
        hoursToAnalyze: 24,
        useAI: true,
      );

      // Generate notifications for detected patterns
      for (var pattern in patterns) {
        if (pattern.requiresAction) {
          await _generateNotificationForPattern(pattern);
        }
      }
    } catch (e) {
      print('Error in automation monitoring: $e');
    }
  }

  /// Generate notification for detected pattern
  Future<void> _generateNotificationForPattern(DetectedPattern pattern) async {
    if (_notificationsToday >= Environment.maxNotificationsPerDay) return;

    HealthNotification? notification;

    switch (pattern.type) {
      case PatternType.glucoseSpike:
        notification = HealthNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.alert,
          priority: pattern.severity == PatternSeverity.critical
              ? NotificationPriority.critical
              : NotificationPriority.high,
          title: 'Glucose Spike Detected',
          message: '${pattern.description}\n\nConsider a short walk or checking your recent meals.',
          createdAt: DateTime.now(),
          actionUrl: '/glucose-trends',
          triggeredBy: {'pattern': pattern.type.name, 'metadata': pattern.metadata},
          iconName: 'trending_up',
        );
        break;

      case PatternType.glucoseDrop:
        notification = HealthNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.alert,
          priority: NotificationPriority.critical,
          title: 'Low Glucose Alert',
          message: '${pattern.description}\n\nIf you feel symptoms, have a fast-acting carb.',
          createdAt: DateTime.now(),
          actionUrl: '/log-glucose',
          triggeredBy: {'pattern': pattern.type.name, 'metadata': pattern.metadata},
          iconName: 'trending_down',
        );
        break;

      case PatternType.postMealSpike:
        notification = HealthNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.educational,
          priority: NotificationPriority.medium,
          title: 'Post-Meal Spike',
          message: '${pattern.description}\n\nTip: A 10-minute walk after meals can help reduce spikes.',
          createdAt: DateTime.now(),
          actionUrl: '/log-activity',
          triggeredBy: {'pattern': pattern.type.name, 'metadata': pattern.metadata},
          iconName: 'restaurant',
        );
        break;

      case PatternType.lowActivity:
        notification = HealthNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.motivational,
          priority: NotificationPriority.low,
          title: 'Time to Move!',
          message: 'You\'ve been less active today. Even a short walk helps manage glucose!',
          createdAt: DateTime.now(),
          actionUrl: '/log-activity',
          triggeredBy: {'pattern': pattern.type.name, 'metadata': pattern.metadata},
          iconName: 'directions_walk',
        );
        break;

      case PatternType.missedMedication:
        notification = HealthNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.reminder,
          priority: NotificationPriority.high,
          title: 'Medication Reminder',
          message: pattern.description,
          createdAt: DateTime.now(),
          actionUrl: '/medications',
          triggeredBy: {'pattern': pattern.type.name, 'metadata': pattern.metadata},
          iconName: 'medication',
        );
        break;

      case PatternType.consecutiveHigh:
        notification = HealthNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.alert,
          priority: NotificationPriority.high,
          title: 'Consecutive High Readings',
          message: '${pattern.description}\n\nReview your recent meals and activity.',
          createdAt: DateTime.now(),
          actionUrl: '/recommendations',
          triggeredBy: {'pattern': pattern.type.name, 'metadata': pattern.metadata},
          iconName: 'warning',
        );
        break;

      case PatternType.highVariability:
        notification = HealthNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.educational,
          priority: NotificationPriority.medium,
          title: 'High Glucose Variability',
          message: '${pattern.description}\n\nConsistent meal timing and portions can help stabilize levels.',
          createdAt: DateTime.now(),
          actionUrl: '/trends',
          triggeredBy: {'pattern': pattern.type.name, 'metadata': pattern.metadata},
          iconName: 'show_chart',
        );
        break;

      default:
        // Generic notification for other patterns
        notification = HealthNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.alert,
          priority: pattern.severity == PatternSeverity.critical
              ? NotificationPriority.critical
              : NotificationPriority.medium,
          title: pattern.typeLabel,
          message: pattern.description,
          createdAt: DateTime.now(),
          triggeredBy: {'pattern': pattern.type.name, 'metadata': pattern.metadata},
        );
    }

    await addNotification(notification);
    }

  /// Add a notification
  Future<void> addNotification(HealthNotification notification) async {
    // Check daily limit
    if (_notificationsToday >= Environment.maxNotificationsPerDay) {
      print('Daily notification limit reached');
      return;
    }

    // Avoid duplicates within 1 hour
    final isDuplicate = _notifications.any((n) =>
        n.title == notification.title &&
        DateTime.now().difference(n.createdAt).inHours < 1);

    if (isDuplicate) {
      return;
    }

    _notifications.insert(0, notification);
    _notificationsToday++;
    notifyListeners();

    // TODO: In production, show system notification
    print('🔔 Notification: ${notification.title} - ${notification.message}');
  }

  /// Mark notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].markAsRead();
      notifyListeners();
    }
  }

  /// Mark all as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].markAsRead();
      }
    }
    notifyListeners();
  }

  /// Delete notification
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Clear old notifications (older than 7 days)
  void clearOldNotifications() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    _notifications.removeWhere((n) => n.createdAt.isBefore(cutoffDate) && n.isRead);
    notifyListeners();
  }

  /// Send a weekly summary notification
  Future<void> sendWeeklySummary(Map<String, dynamic> summaryData) async {
    final notification = HealthNotification(
      id: 'notif_weekly_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.summary,
      priority: NotificationPriority.medium,
      title: 'Your Weekly Health Summary',
      message: _generateWeeklySummaryMessage(summaryData),
      createdAt: DateTime.now(),
      actionUrl: '/trends',
      iconName: 'summarize',
    );

    await addNotification(notification);
  }

  /// Generate weekly summary message
  String _generateWeeklySummaryMessage(Map<String, dynamic> data) {
    final avgGlucose = data['averageGlucose'] ?? 0;
    final timeInRange = data['timeInRange'] ?? 0;
    final activityMinutes = data['totalActivityMinutes'] ?? 0;

    return '''
Avg Glucose: ${avgGlucose.toStringAsFixed(0)} mg/dL
Time in Range: ${timeInRange.toStringAsFixed(0)}%
Activity: $activityMinutes minutes

Tap to see detailed trends!
''';
  }

  /// Send achievement notification
  Future<void> sendAchievement(String title, String description) async {
    final notification = HealthNotification(
      id: 'notif_achievement_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.achievement,
      priority: NotificationPriority.low,
      title: title,
      message: description,
      createdAt: DateTime.now(),
      iconName: 'emoji_events',
    );

    await addNotification(notification);
  }

  /// Send motivational message
  Future<void> sendMotivation(String message) async {
    final motivations = [
      'Keep up the great work!',
      'You\'re doing amazing!',
      'Every healthy choice counts!',
      'Proud of your progress!',
      'You\'ve got this!',
    ];

    final notification = HealthNotification(
      id: 'notif_motivation_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.motivational,
      priority: NotificationPriority.low,
      title: motivations[DateTime.now().millisecond % motivations.length],
      message: message,
      createdAt: DateTime.now(),
      iconName: 'favorite',
    );

    await addNotification(notification);
  }

  /// Send educational tip
  Future<void> sendEducationalTip(String tip) async {
    final notification = HealthNotification(
      id: 'notif_education_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.educational,
      priority: NotificationPriority.low,
      title: 'Health Tip',
      message: tip,
      createdAt: DateTime.now(),
      iconName: 'lightbulb',
    );

    await addNotification(notification);
  }

  /// Get notifications by type
  List<HealthNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get notifications by priority
  List<HealthNotification> getNotificationsByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  /// Manual trigger check (for testing)
  Future<void> checkNow() async {
    await _checkForTriggers();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}
