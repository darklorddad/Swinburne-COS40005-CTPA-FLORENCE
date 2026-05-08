import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:florence/core/config/environment.dart';
import 'package:florence/core/services/automation/pattern_detection_service.dart';
import 'package:florence/core/services/notifications/notification_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';

/// Notification Provider
final notificationProvider = NotifierProvider<NotificationNotifier, List<HealthNotification>>(NotificationNotifier.new, isAutoDispose: true);

/// Notifier for managing notifications
class NotificationNotifier extends Notifier<List<HealthNotification>> {
  final PatternDetectionService _patternService = PatternDetectionService();
  
  Timer? _monitoringTimer;
  int _notificationsToday = 0;
  DateTime? _lastCheckDate;

  @override
  List<HealthNotification> build() {
    // Ensure timer is cancelled when provider is disposed/invalidated
    ref.onDispose(() {
      _monitoringTimer?.cancel();
    });

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

    final now = DateTime.now();
    if (_lastCheckDate == null || _lastCheckDate!.day != now.day) {
      _notificationsToday = 0;
      _lastCheckDate = now;
    }
    if (_notificationsToday >= Environment.maxNotificationsPerDay) return;

    try {
      final healthData = ref.read(monitorDataProvider).asData?.value;
      if (healthData == null) return;

      final patterns = _patternService.detectPatternsFromData(healthData);
      for (final pattern in patterns) {
        if (pattern.requiresAction) {
          await _generateNotificationForPattern(pattern);
        }
      }
    } catch (e) {
      debugPrint('Automation check error: $e');
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
          actionUrl: '/log/glucose',
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
          actionUrl: '/log/activity',
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
          actionUrl: '/log/activity',
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
          actionUrl: '/log/medication',
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

  /// Called immediately after a glucose reading is saved.
  /// Fires an alert if the value is outside the safe range.
  Future<void> checkAfterGlucoseLog(double valueMgDl) async {
    if (valueMgDl > Environment.glucoseHigh) {
      await addNotification(HealthNotification(
        id: 'notif_glucose_high_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.alert,
        priority: valueMgDl > 250
            ? NotificationPriority.critical
            : NotificationPriority.high,
        title: 'High Glucose Reading',
        message:
            'Reading of ${valueMgDl.toStringAsFixed(0)} mg/dL logged. Consider a short walk or checking your recent meals.',
        createdAt: DateTime.now(),
        actionUrl: '/recommendations',
        iconName: 'trending_up',
      ));
    } else if (valueMgDl < Environment.glucoseLow) {
      await addNotification(HealthNotification(
        id: 'notif_glucose_low_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.alert,
        priority: NotificationPriority.critical,
        title: 'Low Glucose Alert',
        message:
            'Reading of ${valueMgDl.toStringAsFixed(0)} mg/dL. If you feel symptoms, have a fast-acting carb.',
        createdAt: DateTime.now(),
        actionUrl: '/log/glucose',
        iconName: 'trending_down',
      ));
    }
  }

  /// Called immediately after a meal is saved.
  /// Fires an educational tip if the meal is high-calorie.
  Future<void> checkAfterMealLog(int? calories) async {
    if (calories == null || calories <= 600) return;
    await sendEducationalTip(
      'Your last meal had $calories kcal. A 10–15 minute walk after eating can help reduce glucose spikes.',
    );
  }

  /// Fired after an activity is saved.
  Future<void> checkAfterActivityLog(int? durationMinutes) async {
    if (durationMinutes == null) return;
    if (durationMinutes >= 30) {
      await sendAchievement(
        'Great workout!',
        'You logged $durationMinutes minutes of activity. Keep it up!',
      );
    } else {
      await sendEducationalTip(
        'Short sessions count! Even $durationMinutes minutes of movement helps manage glucose. Aim for 30+ minutes when you can.',
      );
    }
  }

  /// Fired after a blood pressure reading is saved.
  Future<void> checkAfterBloodPressureLog(double? systolic, double? diastolic) async {
    if (systolic == null || diastolic == null) return;
    if (systolic >= 180 || diastolic >= 120) {
      await addNotification(HealthNotification(
        id: 'notif_bp_crisis_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.alert,
        priority: NotificationPriority.critical,
        title: 'Hypertensive Crisis',
        message: 'BP of ${systolic.toStringAsFixed(0)}/${diastolic.toStringAsFixed(0)} mmHg is dangerously high. Seek medical attention immediately.',
        createdAt: DateTime.now(),
        actionUrl: '/recommendations',
        iconName: 'warning',
      ));
    } else if (systolic >= 140 || diastolic >= 90) {
      await addNotification(HealthNotification(
        id: 'notif_bp_high_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.alert,
        priority: NotificationPriority.high,
        title: 'High Blood Pressure',
        message: 'BP of ${systolic.toStringAsFixed(0)}/${diastolic.toStringAsFixed(0)} mmHg is above normal. Consider reducing sodium and stress.',
        createdAt: DateTime.now(),
        actionUrl: '/recommendations',
        iconName: 'monitor_heart',
      ));
    }
  }

  /// Fired after BMI is calculated and saved.
  Future<void> checkAfterBmiLog(double? bmi) async {
    if (bmi == null) return;
    if (bmi >= 30) {
      await sendEducationalTip(
        'BMI of ${bmi.toStringAsFixed(1)} is in the obese range. Gradual weight loss through diet and activity can significantly improve glucose control.',
      );
    } else if (bmi >= 25) {
      await sendEducationalTip(
        'BMI of ${bmi.toStringAsFixed(1)} is in the overweight range. Small lifestyle changes can make a big difference for your diabetes management.',
      );
    } else if (bmi < 18.5) {
      await sendEducationalTip(
        'BMI of ${bmi.toStringAsFixed(1)} is below the healthy range. Speak with your doctor about a nutrition plan.',
      );
    }
  }

  /// Fired after a cholesterol reading is saved.
  Future<void> checkAfterCholesterolLog(double? total, double? ldl, double? hdl) async {
    if (ldl != null && ldl > 130) {
      await addNotification(HealthNotification(
        id: 'notif_chol_ldl_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.alert,
        priority: NotificationPriority.high,
        title: 'High LDL Cholesterol',
        message: 'LDL of ${ldl.toStringAsFixed(0)} mg/dL is above the 130 mg/dL target. Reducing saturated fats and increasing activity can help.',
        createdAt: DateTime.now(),
        actionUrl: '/recommendations',
        iconName: 'bloodtype',
      ));
    } else if (total != null && total > 200) {
      await sendEducationalTip(
        'Total cholesterol of ${total.toStringAsFixed(0)} mg/dL is borderline high. A heart-healthy diet can help bring it down.',
      );
    }
  }

  /// Fired after an HbA1c reading is saved.
  Future<void> checkAfterHba1cLog(double value) async {
    if (value > Environment.hba1cTarget) {
      await addNotification(HealthNotification(
        id: 'notif_hba1c_high_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.alert,
        priority: value > 9.0 ? NotificationPriority.critical : NotificationPriority.high,
        title: 'HbA1c Above Target',
        message: 'HbA1c of ${value.toStringAsFixed(1)}% is above your ${Environment.hba1cTarget.toStringAsFixed(1)}% target. Check your recommendations for next steps.',
        createdAt: DateTime.now(),
        actionUrl: '/recommendations',
        iconName: 'pie_chart',
      ));
    } else {
      await sendAchievement(
        'HbA1c on Target!',
        'HbA1c of ${value.toStringAsFixed(1)}% is within your target range. Great glucose control!',
      );
    }
  }

  /// Called when the dashboard loads health data.
  /// Checks for activity drop and whether a weekly summary is due.
  Future<void> checkDashboardTriggers(HealthDataState healthData) async {
    await _checkActivityDrop(healthData);
    await _checkWeeklySummary(healthData);
  }

  Future<void> _checkActivityDrop(HealthDataState healthData) async {
    if (healthData.activities.isEmpty) return;
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final hasRecentActivity =
        healthData.activities.any((a) => a.startTime.isAfter(twoDaysAgo));
    if (!hasRecentActivity) {
      await sendMotivation(
        'No activity logged in 2 days. Even a 10-minute walk helps manage glucose and mood!',
      );
    }
  }

  Future<void> _checkWeeklySummary(HealthDataState healthData) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentMs = prefs.getInt('lam_last_weekly_summary') ?? 0;
    final lastSent = DateTime.fromMillisecondsSinceEpoch(lastSentMs);
    if (DateTime.now().difference(lastSent).inDays < 7) return;

    final now = DateTime.now();
    final summary = healthData.getHealthSummary(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
    );

    await sendWeeklySummary({
      'averageGlucose': summary.averageGlucose,
      'timeInRange': summary.timeInRange,
      'totalActivityMinutes': summary.totalActivityMinutes,
    });

    await prefs.setInt('lam_last_weekly_summary', now.millisecondsSinceEpoch);
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

class NotificationService extends ChangeNotifier {
  int get unreadCount => 0;
  
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
}
