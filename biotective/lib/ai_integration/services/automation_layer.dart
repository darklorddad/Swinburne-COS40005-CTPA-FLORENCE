import 'dart:async';
import '../models/health_data.dart';
import 'deepseek_service.dart';
import 'anomaly_detector.dart';

class AutomationLayer {
  static Timer? _monitoringTimer;
  static final Map<String, List<AutomationTrigger>> _activeTriggers = {};

  /// Start monitoring for automation triggers
  static void startMonitoring({
    required String patientId,
    required List<HealthData> recentData,
    required PatientProfile patientProfile,
  }) {
    _monitoringTimer?.cancel();
    
    _monitoringTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkTriggers(patientId, recentData, patientProfile);
    });
  }

  /// Stop monitoring
  static void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Check for automation triggers
  static Future<void> _checkTriggers(
    String patientId,
    List<HealthData> recentData,
    PatientProfile patientProfile,
  ) async {
    // Detect anomalies
    final anomalies = AnomalyDetector.detectAnomalies(
      patientId: patientId,
      recentData: recentData,
      patientProfile: patientProfile,
    );

    // Process each anomaly for triggers
    for (final anomaly in anomalies) {
      await _processAnomalyTrigger(patientId, anomaly, patientProfile);
    }

    // Check for scheduled triggers
    await _checkScheduledTriggers(patientId, recentData, patientProfile);
  }

  /// Process anomaly-based triggers
  static Future<void> _processAnomalyTrigger(
    String patientId,
    Anomaly anomaly,
    PatientProfile patientProfile,
  ) async {
    AutomationTrigger? trigger;

    switch (anomaly.anomalyType) {
      case 'glucose_spike':
        trigger = await _createGlucoseSpikeTrigger(patientId, anomaly, patientProfile);
        break;
      case 'glucose_low':
        trigger = await _createGlucoseLowTrigger(patientId, anomaly, patientProfile);
        break;
      case 'glucose_critical_high':
        trigger = await _createCriticalGlucoseTrigger(patientId, anomaly, patientProfile);
        break;
      case 'glucose_critical_low':
        trigger = await _createCriticalGlucoseTrigger(patientId, anomaly, patientProfile);
        break;
      case 'inactivity_pattern':
        trigger = await _createInactivityTrigger(patientId, anomaly, patientProfile);
        break;
      case 'medication_non_adherence':
        trigger = await _createMedicationReminderTrigger(patientId, anomaly, patientProfile);
        break;
      case 'insufficient_sleep':
        trigger = await _createSleepImprovementTrigger(patientId, anomaly, patientProfile);
        break;
      case 'high_hba1c':
        trigger = await _createClinicianAlertTrigger(patientId, anomaly, patientProfile);
        break;
    }

    if (trigger != null) {
      _addTrigger(patientId, trigger);
      await _executeTrigger(trigger);
    }
  }

  /// Check for scheduled triggers (weekly summaries, etc.)
  static Future<void> _checkScheduledTriggers(
    String patientId,
    List<HealthData> recentData,
    PatientProfile patientProfile,
  ) async {
    final now = DateTime.now();
    
    // Weekly summary trigger (every Sunday at 9 AM)
    if (now.weekday == DateTime.sunday && now.hour == 9 && now.minute < 15) {
      final trigger = await _createWeeklySummaryTrigger(patientId, recentData, patientProfile);
      if (trigger != null) {
        _addTrigger(patientId, trigger);
        await _executeTrigger(trigger);
      }
    }

    // Daily motivation trigger (every day at 8 AM)
    if (now.hour == 8 && now.minute < 15) {
      final trigger = await _createDailyMotivationTrigger(patientId, recentData, patientProfile);
      if (trigger != null) {
        _addTrigger(patientId, trigger);
        await _executeTrigger(trigger);
      }
    }
  }

  /// Create glucose spike trigger
  static Future<AutomationTrigger> _createGlucoseSpikeTrigger(
    String patientId,
    Anomaly anomaly,
    PatientProfile patientProfile,
  ) async {
    final glucoseLevel = anomaly.context['glucoseLevel'] as double;
    
    final message = await DeepSeekService.generateHealthRecommendation(
      healthData: {
        'glucoseLevel': glucoseLevel,
        'timestamp': anomaly.detectedAt.toIso8601String(),
        'mealType': anomaly.context['mealType'],
      },
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
      recommendationType: 'glucose_spike_response',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'glucose_spike_alert',
      priority: 'high',
      message: message,
      actionType: 'immediate_alert',
      metadata: {
        'glucoseLevel': glucoseLevel,
        'anomalyId': anomaly.id,
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create glucose low trigger
  static Future<AutomationTrigger> _createGlucoseLowTrigger(
    String patientId,
    Anomaly anomaly,
    PatientProfile patientProfile,
  ) async {
    final glucoseLevel = anomaly.context['glucoseLevel'] as double;
    
    final message = await DeepSeekService.generateHealthRecommendation(
      healthData: {
        'glucoseLevel': glucoseLevel,
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
      recommendationType: 'glucose_low_response',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'glucose_low_alert',
      priority: 'urgent',
      message: message,
      actionType: 'emergency_alert',
      metadata: {
        'glucoseLevel': glucoseLevel,
        'anomalyId': anomaly.id,
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create critical glucose trigger
  static Future<AutomationTrigger> _createCriticalGlucoseTrigger(
    String patientId,
    Anomaly anomaly,
    PatientProfile patientProfile,
  ) async {
    final glucoseLevel = anomaly.context['glucoseLevel'] as double;
    final isHigh = glucoseLevel > 250;
    
    final message = await DeepSeekService.generateHealthRecommendation(
      healthData: {
        'glucoseLevel': glucoseLevel,
        'isCritical': true,
        'isHigh': isHigh,
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
      recommendationType: 'critical_glucose_response',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'critical_glucose_alert',
      priority: 'critical',
      message: message,
      actionType: 'emergency_alert',
      metadata: {
        'glucoseLevel': glucoseLevel,
        'anomalyId': anomaly.id,
        'timestamp': anomaly.detectedAt.toIso8601String(),
        'isHigh': isHigh,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create inactivity trigger
  static Future<AutomationTrigger> _createInactivityTrigger(
    String patientId,
    Anomaly anomaly,
    PatientProfile patientProfile,
  ) async {
    final consecutiveDays = anomaly.context['consecutiveDays'] as int;
    
    final message = await DeepSeekService.generateMotivationalMessage(
      activityData: {
        'consecutiveDays': consecutiveDays,
        'avgSteps': anomaly.context['avgSteps'],
        'targetSteps': 10000,
      },
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'inactivity_motivation',
      priority: 'medium',
      message: message,
      actionType: 'motivation_reminder',
      metadata: {
        'consecutiveDays': consecutiveDays,
        'anomalyId': anomaly.id,
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create medication reminder trigger
  static Future<AutomationTrigger> _createMedicationReminderTrigger(
    String patientId,
    Anomaly anomaly,
    PatientProfile patientProfile,
  ) async {
    final adherenceRate = anomaly.context['adherenceRate'] as double;
    
    final message = await DeepSeekService.generateHealthRecommendation(
      healthData: {
        'adherenceRate': adherenceRate,
        'medications': anomaly.context['medications'],
        'missedCount': anomaly.context['missedCount'],
      },
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
      recommendationType: 'medication_adherence',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'medication_reminder',
      priority: 'high',
      message: message,
      actionType: 'medication_reminder',
      metadata: {
        'adherenceRate': adherenceRate,
        'anomalyId': anomaly.id,
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create sleep improvement trigger
  static Future<AutomationTrigger> _createSleepImprovementTrigger(
    String patientId,
    Anomaly anomaly,
    PatientProfile patientProfile,
  ) async {
    final sleepHours = anomaly.context['sleepHours'] as double;
    
    final message = await DeepSeekService.generateHealthRecommendation(
      healthData: {
        'sleepHours': sleepHours,
        'recommendedSleep': 7.5,
        'stressLevel': anomaly.context['stressLevel'],
      },
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
      recommendationType: 'sleep_improvement',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'sleep_improvement',
      priority: 'medium',
      message: message,
      actionType: 'sleep_reminder',
      metadata: {
        'sleepHours': sleepHours,
        'anomalyId': anomaly.id,
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create clinician alert trigger
  static Future<AutomationTrigger> _createClinicianAlertTrigger(
    String patientId,
    Anomaly anomaly,
    PatientProfile patientProfile,
  ) async {
    final hba1cLevel = anomaly.context['hba1cLevel'] as double;
    
    final message = await DeepSeekService.generateHealthRecommendation(
      healthData: {
        'hba1cLevel': hba1cLevel,
        'diabetesType': anomaly.context['diabetesType'],
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
      recommendationType: 'clinician_alert',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'clinician_alert',
      priority: 'high',
      message: message,
      actionType: 'clinician_notification',
      metadata: {
        'hba1cLevel': hba1cLevel,
        'anomalyId': anomaly.id,
        'timestamp': anomaly.detectedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create weekly summary trigger
  static Future<AutomationTrigger?> _createWeeklySummaryTrigger(
    String patientId,
    List<HealthData> recentData,
    PatientProfile patientProfile,
  ) async {
    // Get data from the past week
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weeklyData = recentData.where((d) => d.timestamp.isAfter(weekAgo)).toList();

    if (weeklyData.isEmpty) return null;

    final message = await DeepSeekService.generateWeeklySummary(
      weeklyData: _summarizeWeeklyData(weeklyData),
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'weekly_summary',
      priority: 'low',
      message: message,
      actionType: 'weekly_summary',
      metadata: {
        'weekStart': weekAgo.toIso8601String(),
        'weekEnd': DateTime.now().toIso8601String(),
        'dataPoints': weeklyData.length,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create daily motivation trigger
  static Future<AutomationTrigger?> _createDailyMotivationTrigger(
    String patientId,
    List<HealthData> recentData,
    PatientProfile patientProfile,
  ) async {
    // Get yesterday's data
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayData = recentData.where((d) => 
      d.timestamp.day == yesterday.day && 
      d.timestamp.month == yesterday.month && 
      d.timestamp.year == yesterday.year
    ).toList();

    if (yesterdayData.isEmpty) return null;

    final message = await DeepSeekService.generateMotivationalMessage(
      activityData: _summarizeDailyData(yesterdayData),
      patientProfile: '${patientProfile.name}, ${patientProfile.age} years old, ${patientProfile.diabetesType} diabetes',
    );

    return AutomationTrigger(
      id: _generateId(),
      patientId: patientId,
      triggerType: 'daily_motivation',
      priority: 'low',
      message: message,
      actionType: 'motivation_reminder',
      metadata: {
        'date': yesterday.toIso8601String(),
        'dataPoints': yesterdayData.length,
      },
      createdAt: DateTime.now(),
    );
  }

  /// Summarize weekly data for AI processing
  static Map<String, dynamic> _summarizeWeeklyData(List<HealthData> data) {
    final glucoseReadings = data.where((d) => d.glucoseLevel != null).map((d) => d.glucoseLevel!).toList();
    final activityData = data.where((d) => d.steps != null).map((d) => d.steps!).toList();
    final sleepData = data.where((d) => d.sleepHours != null).map((d) => d.sleepHours!).toList();

    return {
      'totalDataPoints': data.length,
      'glucoseReadings': glucoseReadings.length,
      'avgGlucose': glucoseReadings.isNotEmpty ? glucoseReadings.reduce((a, b) => a + b) / glucoseReadings.length : 0,
      'maxGlucose': glucoseReadings.isNotEmpty ? glucoseReadings.reduce((a, b) => a > b ? a : b) : 0,
      'minGlucose': glucoseReadings.isNotEmpty ? glucoseReadings.reduce((a, b) => a < b ? a : b) : 0,
      'totalSteps': activityData.isNotEmpty ? activityData.reduce((a, b) => a + b) : 0,
      'avgSteps': activityData.isNotEmpty ? activityData.reduce((a, b) => a + b) / activityData.length : 0,
      'avgSleep': sleepData.isNotEmpty ? sleepData.reduce((a, b) => a + b) / sleepData.length : 0,
    };
  }

  /// Summarize daily data for AI processing
  static Map<String, dynamic> _summarizeDailyData(List<HealthData> data) {
    final glucoseReadings = data.where((d) => d.glucoseLevel != null).map((d) => d.glucoseLevel!).toList();
    final activityData = data.where((d) => d.steps != null).map((d) => d.steps!).toList();
    final sleepData = data.where((d) => d.sleepHours != null).map((d) => d.sleepHours!).toList();

    return {
      'totalDataPoints': data.length,
      'glucoseReadings': glucoseReadings.length,
      'avgGlucose': glucoseReadings.isNotEmpty ? glucoseReadings.reduce((a, b) => a + b) / glucoseReadings.length : 0,
      'totalSteps': activityData.isNotEmpty ? activityData.reduce((a, b) => a + b) : 0,
      'sleepHours': sleepData.isNotEmpty ? sleepData.first : 0,
    };
  }

  /// Add trigger to active triggers
  static void _addTrigger(String patientId, AutomationTrigger trigger) {
    _activeTriggers.putIfAbsent(patientId, () => []).add(trigger);
  }

  /// Execute trigger action
  static Future<void> _executeTrigger(AutomationTrigger trigger) async {
    // In a real implementation, this would:
    // 1. Send push notification
    // 2. Update UI
    // 3. Log the trigger
    // 4. Send to clinician if needed
    
    print('Executing trigger: ${trigger.triggerType} for patient ${trigger.patientId}');
    print('Message: ${trigger.message}');
    print('Priority: ${trigger.priority}');
    print('Action: ${trigger.actionType}');
  }

  /// Get active triggers for a patient
  static List<AutomationTrigger> getActiveTriggers(String patientId) {
    return _activeTriggers[patientId] ?? [];
  }

  /// Clear resolved triggers
  static void clearResolvedTriggers(String patientId) {
    _activeTriggers[patientId]?.removeWhere((trigger) => trigger.isResolved);
  }

  /// Generate unique ID
  static String _generateId() {
    return 'trigger_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}

class AutomationTrigger {
  final String id;
  final String patientId;
  final String triggerType;
  final String priority;
  final String message;
  final String actionType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  bool isResolved;
  DateTime? resolvedAt;

  AutomationTrigger({
    required this.id,
    required this.patientId,
    required this.triggerType,
    required this.priority,
    required this.message,
    required this.actionType,
    required this.metadata,
    required this.createdAt,
    this.isResolved = false,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'triggerType': triggerType,
      'priority': priority,
      'message': message,
      'actionType': actionType,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}
