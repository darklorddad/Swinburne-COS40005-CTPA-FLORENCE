import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/environment.dart';
import '../automation/pattern_detection_service.dart';
import 'notification_models.dart';

/// Notification Provider
final notificationProvider = NotifierProvider<NotificationNotifier, List<HealthNotification>>(NotificationNotifier.new);

/// Notifier for managing notifications
class NotificationNotifier extends Notifier<List<HealthNotification>> {
  final PatternDetectionService _patternService = PatternDetectionService();
  
  Timer? _monitoringTimer;
  int _notificationsToday = 0;
  DateTime? _lastCheckDate;

  @override
  List<HealthNotification> build() {
    if (Environment.enableAutomation) {
      _startAutomationMonitoring();
    }
    return [];
  }

  List<HealthNotification> get unreadNotifications =>
      state.where((n) => !n.isRead).toList();

  List<HealthNotification> get criticalNotifications =>
      state.where((n) => n.priority == NotificationPriority.critical && !n.isRead).toList();

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
          message: pattern.description + '\n\nConsider a short walk or checking your recent meals.',
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
          message: pattern.description + '\n\nIf you feel symptoms, have a fast-acting carb.',
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
          message: pattern.description + '\n\nTip: A 10-minute walk after meals can help reduce spikes.',
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
          message: pattern.description + '\n\nReview your recent meals and activity.',
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
          message: pattern.description + '\n\nConsistent meal timing and portions can help stabilize levels.',
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

    if (notification != null) {
      await addNotification(notification);
    }
  }

  /// Add a notification
  Future<void> addNotification(HealthNotification notification) async {
    // Check daily limit
    if (_notificationsToday >= Environment.maxNotificationsPerDay) {
      print('Daily notification limit reached');
      return;
    }

    // Avoid duplicates within 1 hour
    final isDuplicate = state.any((n) =>
        n.title == notification.title &&
        DateTime.now().difference(n.createdAt).inHours < 1);

    if (isDuplicate) {
      return;
    }

    // Add to start of list
    state = [notification, ...state];
    _notificationsToday++;

    // TODO: In production, show system notification
    print('🔔 Notification: ${notification.title} - ${notification.message}');
  }

  /// Mark notification as read
  void markAsRead(String id) {
    state = [
      for (final notification in state)
        if (notification.id == id)
          notification.markAsRead()
        else
          notification
    ];
  }

  /// Mark all as read
  void markAllAsRead() {
    state = [
      for (final notification in state)
        if (!notification.isRead)
          notification.markAsRead()
        else
          notification
    ];
  }

  /// Delete notification
  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  /// Clear all notifications
  void clearAll() {
    state = [];
  }

  /// Clear old notifications (older than 7 days)
  void clearOldNotifications() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    state = state.where((n) => !(n.createdAt.isBefore(cutoffDate) && n.isRead)).toList();
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

  /// Manual trigger check (for testing)
  Future<void> checkNow() async {
    await _checkForTriggers();
  }
  
  // Helper methods for filtered access (though usually done in UI or selector)
  List<HealthNotification> getNotificationsByType(NotificationType type) {
    return state.where((n) => n.type == type).toList();
  }

  List<HealthNotification> getNotificationsByPriority(NotificationPriority priority) {
    return state.where((n) => n.priority == priority).toList();
  }
}
