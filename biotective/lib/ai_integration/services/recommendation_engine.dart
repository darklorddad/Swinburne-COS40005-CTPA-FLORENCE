import 'dart:math';
import '../models/health_data.dart';
import 'deepseek_service.dart';

class RecommendationEngine {
  static const Map<String, double> _glucoseThresholds = {
    'normal_min': 70,
    'normal_max': 140,
    'high_threshold': 180,
    'low_threshold': 70,
  };


  static const Map<String, int> _activityThresholds = {
    'low': 5000,
    'moderate': 10000,
    'high': 15000,
  };

  /// Generate personalized recommendations based on health data
  static Future<List<Recommendation>> generateRecommendations({
    required String patientId,
    required List<HealthData> recentData,
    required PatientProfile patientProfile,
  }) async {
    final recommendations = <Recommendation>[];

    // Analyze glucose patterns
    final glucoseRecommendations = await _analyzeGlucosePatterns(
      patientId: patientId,
      data: recentData,
      profile: patientProfile,
    );
    recommendations.addAll(glucoseRecommendations);

    // Analyze activity patterns
    final activityRecommendations = await _analyzeActivityPatterns(
      patientId: patientId,
      data: recentData,
      profile: patientProfile,
    );
    recommendations.addAll(activityRecommendations);

    // Analyze medication adherence
    final medicationRecommendations = await _analyzeMedicationAdherence(
      patientId: patientId,
      data: recentData,
      profile: patientProfile,
    );
    recommendations.addAll(medicationRecommendations);

    // Analyze sleep patterns
    final sleepRecommendations = await _analyzeSleepPatterns(
      patientId: patientId,
      data: recentData,
      profile: patientProfile,
    );
    recommendations.addAll(sleepRecommendations);

    // Sort by priority and return top recommendations
    recommendations.sort((a, b) => _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority)));
    return recommendations.take(5).toList();
  }

  /// Analyze glucose patterns and generate recommendations
  static Future<List<Recommendation>> _analyzeGlucosePatterns({
    required String patientId,
    required List<HealthData> data,
    required PatientProfile profile,
  }) async {
    final recommendations = <Recommendation>[];
    final glucoseReadings = data.where((d) => d.glucoseLevel != null).toList();

    if (glucoseReadings.isEmpty) return recommendations;

    // Calculate average glucose
    final avgGlucose = glucoseReadings.map((d) => d.glucoseLevel!).reduce((a, b) => a + b) / glucoseReadings.length;

    // Check for high glucose patterns
    if (avgGlucose > _glucoseThresholds['high_threshold']!) {
      final highReadings = glucoseReadings.where((d) => d.glucoseLevel! > _glucoseThresholds['high_threshold']!).length;
      final percentage = (highReadings / glucoseReadings.length) * 100;

      if (percentage > 30) {
        final recommendation = await _createGlucoseRecommendation(
          patientId: patientId,
          type: 'high_glucose',
          avgGlucose: avgGlucose,
          percentage: percentage,
          profile: profile,
        );
        recommendations.add(recommendation);
      }
    }

    // Check for low glucose patterns
    final lowReadings = glucoseReadings.where((d) => d.glucoseLevel! < _glucoseThresholds['low_threshold']!).length;
    if (lowReadings > 0) {
      final recommendation = await _createGlucoseRecommendation(
        patientId: patientId,
        type: 'low_glucose',
        avgGlucose: avgGlucose,
        percentage: (lowReadings / glucoseReadings.length) * 100,
        profile: profile,
      );
      recommendations.add(recommendation);
    }

    return recommendations;
  }

  /// Analyze activity patterns and generate recommendations
  static Future<List<Recommendation>> _analyzeActivityPatterns({
    required String patientId,
    required List<HealthData> data,
    required PatientProfile profile,
  }) async {
    final recommendations = <Recommendation>[];
    final activityData = data.where((d) => d.steps != null).toList();

    if (activityData.isEmpty) return recommendations;

    // Calculate average daily steps
    final avgSteps = activityData.map((d) => d.steps!).reduce((a, b) => a + b) / activityData.length;

    if (avgSteps < _activityThresholds['low']!) {
      final recommendation = await _createActivityRecommendation(
        patientId: patientId,
        avgSteps: avgSteps,
        profile: profile,
      );
      recommendations.add(recommendation);
    }

    return recommendations;
  }

  /// Analyze medication adherence and generate recommendations
  static Future<List<Recommendation>> _analyzeMedicationAdherence({
    required String patientId,
    required List<HealthData> data,
    required PatientProfile profile,
  }) async {
    final recommendations = <Recommendation>[];

    // Check for missed medications
    final medicationData = data.where((d) => d.medicationTaken != null).toList();
    if (medicationData.isNotEmpty) {
      final missedCount = medicationData.where((d) => d.medicationTaken == 'no' || d.medicationTaken == 'missed').length;
      final adherenceRate = ((medicationData.length - missedCount) / medicationData.length) * 100;

      if (adherenceRate < 80) {
        final recommendation = await _createMedicationRecommendation(
          patientId: patientId,
          adherenceRate: adherenceRate,
          profile: profile,
        );
        recommendations.add(recommendation);
      }
    }

    return recommendations;
  }

  /// Analyze sleep patterns and generate recommendations
  static Future<List<Recommendation>> _analyzeSleepPatterns({
    required String patientId,
    required List<HealthData> data,
    required PatientProfile profile,
  }) async {
    final recommendations = <Recommendation>[];
    final sleepData = data.where((d) => d.sleepHours != null).toList();

    if (sleepData.isEmpty) return recommendations;

    // Calculate average sleep hours
    final avgSleep = sleepData.map((d) => d.sleepHours!).reduce((a, b) => a + b) / sleepData.length;

    if (avgSleep < 6 || avgSleep > 9) {
      final recommendation = await _createSleepRecommendation(
        patientId: patientId,
        avgSleep: avgSleep,
        profile: profile,
      );
      recommendations.add(recommendation);
    }

    return recommendations;
  }

  /// Create glucose-related recommendation using AI
  static Future<Recommendation> _createGlucoseRecommendation({
    required String patientId,
    required String type,
    required double avgGlucose,
    required double percentage,
    required PatientProfile profile,
  }) async {
    final healthData = {
      'avgGlucose': avgGlucose,
      'percentage': percentage,
      'type': type,
    };

    final patientProfile = '${profile.name}, ${profile.age} years old, ${profile.diabetesType} diabetes';

    final aiResponse = await DeepSeekService.generateHealthRecommendation(
      healthData: healthData,
      patientProfile: patientProfile,
      recommendationType: 'glucose_management',
    );

    return Recommendation(
      id: _generateId(),
      patientId: patientId,
      createdAt: DateTime.now(),
      category: 'glucose_monitoring',
      title: type == 'high_glucose' ? 'High Glucose Alert' : 'Low Glucose Alert',
      description: aiResponse,
      explanation: 'Based on your recent glucose readings showing ${percentage.toStringAsFixed(1)}% ${type == 'high_glucose' ? 'high' : 'low'} values',
      priority: percentage > 50 ? 'urgent' : 'high',
      metadata: {
        'avgGlucose': avgGlucose,
        'percentage': percentage,
        'type': type,
      },
    );
  }

  /// Create activity-related recommendation using AI
  static Future<Recommendation> _createActivityRecommendation({
    required String patientId,
    required double avgSteps,
    required PatientProfile profile,
  }) async {
    final healthData = {
      'avgSteps': avgSteps,
      'targetSteps': _activityThresholds['moderate'],
    };

    final patientProfile = '${profile.name}, ${profile.age} years old, ${profile.diabetesType} diabetes';

    final aiResponse = await DeepSeekService.generateHealthRecommendation(
      healthData: healthData,
      patientProfile: patientProfile,
      recommendationType: 'activity_improvement',
    );

    return Recommendation(
      id: _generateId(),
      patientId: patientId,
      createdAt: DateTime.now(),
      category: 'activity_reminders',
      title: 'Increase Daily Activity',
      description: aiResponse,
      explanation: 'Your average daily steps (${avgSteps.toStringAsFixed(0)}) are below the recommended minimum',
      priority: 'medium',
      metadata: {
        'avgSteps': avgSteps,
        'targetSteps': _activityThresholds['moderate'],
      },
    );
  }

  /// Create medication-related recommendation using AI
  static Future<Recommendation> _createMedicationRecommendation({
    required String patientId,
    required double adherenceRate,
    required PatientProfile profile,
  }) async {
    final healthData = {
      'adherenceRate': adherenceRate,
      'medications': profile.medications,
    };

    final patientProfile = '${profile.name}, ${profile.age} years old, ${profile.diabetesType} diabetes';

    final aiResponse = await DeepSeekService.generateHealthRecommendation(
      healthData: healthData,
      patientProfile: patientProfile,
      recommendationType: 'medication_adherence',
    );

    return Recommendation(
      id: _generateId(),
      patientId: patientId,
      createdAt: DateTime.now(),
      category: 'medication_reminders',
      title: 'Improve Medication Adherence',
      description: aiResponse,
      explanation: 'Your medication adherence rate is ${adherenceRate.toStringAsFixed(1)}%, below the recommended 80%',
      priority: 'high',
      metadata: {
        'adherenceRate': adherenceRate,
        'medications': profile.medications,
      },
    );
  }

  /// Create sleep-related recommendation using AI
  static Future<Recommendation> _createSleepRecommendation({
    required String patientId,
    required double avgSleep,
    required PatientProfile profile,
  }) async {
    final healthData = {
      'avgSleep': avgSleep,
      'recommendedSleep': 7.5,
    };

    final patientProfile = '${profile.name}, ${profile.age} years old, ${profile.diabetesType} diabetes';

    final aiResponse = await DeepSeekService.generateHealthRecommendation(
      healthData: healthData,
      patientProfile: patientProfile,
      recommendationType: 'sleep_improvement',
    );

    return Recommendation(
      id: _generateId(),
      patientId: patientId,
      createdAt: DateTime.now(),
      category: 'sleep_improvement',
      title: 'Improve Sleep Quality',
      description: aiResponse,
      explanation: 'Your average sleep of ${avgSleep.toStringAsFixed(1)} hours is ${avgSleep < 6 ? 'too little' : 'too much'} for optimal health',
      priority: 'medium',
      metadata: {
        'avgSleep': avgSleep,
        'recommendedSleep': 7.5,
      },
    );
  }

  /// Get priority value for sorting
  static int _getPriorityValue(String priority) {
    switch (priority) {
      case 'urgent': return 4;
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }

  /// Generate unique ID
  static String _generateId() {
    return 'rec_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
