/// Pattern Detection Service for FLORENCE Digital Health Platform
/// AI-powered pattern recognition for automation triggers

import 'dart:math';
import '../../config/environment.dart';
import '../../../features/patient/core/models/health_data_models.dart';
// import '../../../features/patient/core/services/data_ingestion_service.dart';

/// Type of detected pattern
enum PatternType {
  glucoseSpike,
  glucoseDrop,
  highVariability,
  postMealSpike,
  dawnPhenomenon,
  lowActivity,
  missedMedication,
  poorSleep,
  highCarbs,
  consecutiveHigh,
  consecutiveLow,
}

/// Severity of detected pattern
enum PatternSeverity {
  critical,
  high,
  medium,
  low,
}

/// Detected health pattern
class DetectedPattern {
  final String id;
  final PatternType type;
  final PatternSeverity severity;
  final String description;
  final DateTime detectedAt;
  final List<String> dataPointIds;
  final Map<String, dynamic> metadata;
  final String? aiInsight;

  const DetectedPattern({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
    required this.dataPointIds,
    this.metadata = const {},
    this.aiInsight,
  });

  String get typeLabel {
    switch (type) {
      case PatternType.glucoseSpike:
        return 'Glucose Spike';
      case PatternType.glucoseDrop:
        return 'Glucose Drop';
      case PatternType.highVariability:
        return 'High Variability';
      case PatternType.postMealSpike:
        return 'Post-Meal Spike';
      case PatternType.dawnPhenomenon:
        return 'Dawn Phenomenon';
      case PatternType.lowActivity:
        return 'Low Activity';
      case PatternType.missedMedication:
        return 'Missed Medication';
      case PatternType.poorSleep:
        return 'Poor Sleep';
      case PatternType.highCarbs:
        return 'High Carbs';
      case PatternType.consecutiveHigh:
        return 'Consecutive High Readings';
      case PatternType.consecutiveLow:
        return 'Consecutive Low Readings';
    }
  }

  bool get requiresAction => severity == PatternSeverity.critical || severity == PatternSeverity.high;
}

/// Service for detecting patterns in health data
class PatternDetectionService {
  // final DataIngestionService _dataService = DataIngestionService();

  // Singleton pattern
  static final PatternDetectionService _instance = PatternDetectionService._internal();
  factory PatternDetectionService() => _instance;
  PatternDetectionService._internal();

  /// Detect patterns in recent health data
  Future<List<DetectedPattern>> detectPatterns({
    int hoursToAnalyze = 24,
    bool useAI = true,
  }) async {
    final patterns = <DetectedPattern>[];

    // Rule-based pattern detection
    // patterns.addAll(await _detectGlucosePatterns(hoursToAnalyze));
    // patterns.addAll(await _detectActivityPatterns(hoursToAnalyze));
    // patterns.addAll(await _detectMedicationPatterns(hoursToAnalyze));
    // patterns.addAll(await _detectMealPatterns(hoursToAnalyze));

    // AI-powered deep pattern analysis
    if (useAI && Environment.enableAI && patterns.isNotEmpty) {
      await _enrichPatternsWithAI(patterns, hoursToAnalyze);
    }

    // Sort by severity
    patterns.sort((a, b) => _severityScore(b.severity).compareTo(_severityScore(a.severity)));

    return patterns;
  }

  /*
  /// Detect glucose patterns
  Future<List<DetectedPattern>> _detectGlucosePatterns(int hours) async {
    final patterns = <DetectedPattern>[];
    final startTime = DateTime.now().subtract(Duration(hours: hours));

    final readings = _dataService.getGlucoseReadings(
      startDate: startTime,
      endDate: DateTime.now(),
    );

    if (readings.isEmpty) return patterns;

    // Detect spikes (rapid increase)
    for (int i = 1; i < readings.length; i++) {
      final current = readings[i];
      final previous = readings[i - 1];

      // Spike detection: increase of 50+ mg/dL within 2 hours
      if (current.value - previous.value > 50 &&
          current.timestamp.difference(previous.timestamp).inHours <= 2) {
        patterns.add(DetectedPattern(
          id: 'pattern_spike_${current.id}',
          type: PatternType.glucoseSpike,
          severity: current.value > 250 ? PatternSeverity.critical : PatternSeverity.high,
          description: 'Glucose spiked from ${previous.value.toStringAsFixed(0)} to ${current.value.toStringAsFixed(0)} mg/dL',
          detectedAt: current.timestamp,
          dataPointIds: [previous.id, current.id],
          metadata: {
            'increase': current.value - previous.value,
            'previousValue': previous.value,
            'currentValue': current.value,
          },
        ));
      }

      // Drop detection
      if (previous.value - current.value > 50 &&
          current.timestamp.difference(previous.timestamp).inHours <= 2) {
        patterns.add(DetectedPattern(
          id: 'pattern_drop_${current.id}',
          type: PatternType.glucoseDrop,
          severity: current.value < 70 ? PatternSeverity.critical : PatternSeverity.medium,
          description: 'Glucose dropped from ${previous.value.toStringAsFixed(0)} to ${current.value.toStringAsFixed(0)} mg/dL',
          detectedAt: current.timestamp,
          dataPointIds: [previous.id, current.id],
          metadata: {
            'decrease': previous.value - current.value,
            'previousValue': previous.value,
            'currentValue': current.value,
          },
        ));
      }
    }

    // Detect consecutive high readings
    int consecutiveHigh = 0;
    for (var reading in readings) {
      if (reading.isHigh) {
        consecutiveHigh++;
      } else {
        if (consecutiveHigh >= 3) {
          patterns.add(DetectedPattern(
            id: 'pattern_consecutive_high_${DateTime.now().millisecondsSinceEpoch}',
            type: PatternType.consecutiveHigh,
            severity: PatternSeverity.high,
            description: '$consecutiveHigh consecutive high glucose readings detected',
            detectedAt: DateTime.now(),
            dataPointIds: readings
                .where((r) => r.isHigh)
                .take(consecutiveHigh)
                .map((r) => r.id)
                .toList(),
            metadata: {'count': consecutiveHigh},
          ));
        }
        consecutiveHigh = 0;
      }
    }

    // Detect high variability
    if (readings.length >= 5) {
      final values = readings.map((r) => r.value).toList();
      final stdDev = _calculateStdDev(values);

      if (stdDev > 50) {
        patterns.add(DetectedPattern(
          id: 'pattern_variability_${DateTime.now().millisecondsSinceEpoch}',
          type: PatternType.highVariability,
          severity: stdDev > 70 ? PatternSeverity.high : PatternSeverity.medium,
          description: 'High glucose variability detected (SD: ${stdDev.toStringAsFixed(1)})',
          detectedAt: DateTime.now(),
          dataPointIds: readings.map((r) => r.id).toList(),
          metadata: {'standardDeviation': stdDev},
        ));
      }
    }

    // Detect dawn phenomenon (high morning readings)
    final morningReadings = readings.where((r) {
      final hour = r.timestamp.hour;
      return hour >= 5 && hour <= 9;
    }).toList();

    if (morningReadings.length >= 3) {
      final avgMorning = morningReadings.map((r) => r.value).reduce((a, b) => a + b) / morningReadings.length;
      if (avgMorning > 140) {
        patterns.add(DetectedPattern(
          id: 'pattern_dawn_${DateTime.now().millisecondsSinceEpoch}',
          type: PatternType.dawnPhenomenon,
          severity: PatternSeverity.medium,
          description: 'High morning glucose detected (avg: ${avgMorning.toStringAsFixed(0)} mg/dL)',
          detectedAt: DateTime.now(),
          dataPointIds: morningReadings.map((r) => r.id).toList(),
          metadata: {'averageMorningGlucose': avgMorning},
        ));
      }
    }

    return patterns;
  }

  /// Detect activity patterns
  Future<List<DetectedPattern>> _detectActivityPatterns(int hours) async {
    final patterns = <DetectedPattern>[];
    final startTime = DateTime.now().subtract(Duration(hours: hours));

    final activities = _dataService.getActivities(
      startDate: startTime,
      endDate: DateTime.now(),
    );

    // Low activity detection
    final totalMinutes = activities.isEmpty
        ? 0
        : activities.map((a) => a.duration).reduce((a, b) => a + b);

    final expectedMinutes = (hours / 24) * Environment.activityTargetDaily;

    if (totalMinutes < expectedMinutes * 0.5) {
      patterns.add(DetectedPattern(
        id: 'pattern_low_activity_${DateTime.now().millisecondsSinceEpoch}',
        type: PatternType.lowActivity,
        severity: PatternSeverity.medium,
        description: 'Low activity detected: ${totalMinutes} minutes in last $hours hours',
        detectedAt: DateTime.now(),
        dataPointIds: activities.map((a) => a.id).toList(),
        metadata: {
          'totalMinutes': totalMinutes,
          'expectedMinutes': expectedMinutes,
        },
      ));
    }

    return patterns;
  }

  /// Detect medication patterns
  Future<List<DetectedPattern>> _detectMedicationPatterns(int hours) async {
    final patterns = <DetectedPattern>[];
    final startTime = DateTime.now().subtract(Duration(hours: hours));

    final medications = _dataService.allMedications;

    for (var medication in medications) {
      final recentDoses = medication.doses.where((d) {
        return d.scheduledTime.isAfter(startTime) && !d.taken && !d.skipped;
      }).toList();

      if (recentDoses.length >= 2) {
        patterns.add(DetectedPattern(
          id: 'pattern_missed_med_${medication.id}',
          type: PatternType.missedMedication,
          severity: PatternSeverity.high,
          description: '${recentDoses.length} doses of ${medication.medicationName} not taken',
          detectedAt: DateTime.now(),
          dataPointIds: recentDoses.map((d) => d.id).toList(),
          metadata: {
            'medicationName': medication.medicationName,
            'missedCount': recentDoses.length,
          },
        ));
      }
    }

    return patterns;
  }

  /// Detect meal patterns
  Future<List<DetectedPattern>> _detectMealPatterns(int hours) async {
    final patterns = <DetectedPattern>[];
    final startTime = DateTime.now().subtract(Duration(hours: hours));

    final meals = _dataService.getMeals(
      startDate: startTime,
      endDate: DateTime.now(),
    );

    // Detect high-carb meals
    for (var meal in meals) {
      if (meal.carbs > 80) {
        // Check if there's a glucose spike after this meal
        final glucoseAfterMeal = _dataService.getGlucoseReadings(
          startDate: meal.timestamp,
          endDate: meal.timestamp.add(const Duration(hours: 2)),
        );

        final spike = glucoseAfterMeal.isNotEmpty &&
                      glucoseAfterMeal.any((r) => r.value > 180);

        patterns.add(DetectedPattern(
          id: 'pattern_high_carb_${meal.id}',
          type: spike ? PatternType.postMealSpike : PatternType.highCarbs,
          severity: spike ? PatternSeverity.high : PatternSeverity.medium,
          description: 'High carb meal (${meal.carbs.toStringAsFixed(0)}g)${spike ? " caused glucose spike" : ""}',
          detectedAt: meal.timestamp,
          dataPointIds: [meal.id, ...glucoseAfterMeal.map((r) => r.id)],
          metadata: {
            'carbs': meal.carbs,
            'mealDescription': meal.description,
            'glucoseSpike': spike,
          },
        ));
      }
    }

    return patterns;
  }
  */

  /// Enrich patterns with AI insights
  Future<void> _enrichPatternsWithAI(List<DetectedPattern> patterns, int hours) async {
    // AI enrichment temporarily disabled as DeepSeekService is removed
    return;
  }

  /// Calculate standard deviation
  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  /// Get severity score for sorting
  int _severityScore(PatternSeverity severity) {
    switch (severity) {
      case PatternSeverity.critical:
        return 4;
      case PatternSeverity.high:
        return 3;
      case PatternSeverity.medium:
        return 2;
      case PatternSeverity.low:
        return 1;
    }
  }

  /// Check for patterns that need immediate action
  Future<List<DetectedPattern>> detectCriticalPatterns() async {
    final allPatterns = await detectPatterns(hoursToAnalyze: 4);
    return allPatterns.where((p) => p.severity == PatternSeverity.critical).toList();
  }
}
