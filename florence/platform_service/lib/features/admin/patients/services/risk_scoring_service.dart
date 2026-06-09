/// Risk Scoring Service for FLORENCE Digital Health Platform
/// Calculates patient risk scores for clinician prioritization
library;

import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/core/config/environment.dart';

/// Patient risk level
enum RiskLevel {
  critical,  // Immediate attention needed
  high,      // Review within 24 hours
  medium,    // Review within week
  low,       // Routine monitoring
}

/// Patient risk assessment
class PatientRiskAssessment {
  final String patientId;
  final double riskScore; // 0-100
  final RiskLevel riskLevel;
  final DateTime assessedAt;
  final Map<String, double> riskFactors;
  final List<String> concerns;
  final String? aiInsight;

  const PatientRiskAssessment({
    required this.patientId,
    required this.riskScore,
    required this.riskLevel,
    required this.assessedAt,
    required this.riskFactors,
    this.concerns = const [],
    this.aiInsight,
  });

  bool get requiresUrgentAction => riskLevel == RiskLevel.critical;
  bool get requiresReview => riskLevel == RiskLevel.critical || riskLevel == RiskLevel.high;

  String get riskLevelLabel {
    switch (riskLevel) {
      case RiskLevel.critical:
        return 'Critical';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.low:
        return 'Low';
    }
  }
}

/// Service for calculating patient risk scores
class RiskScoringService {
  final DataIngestionService _dataService = DataIngestionService();

  // Singleton pattern
  static final RiskScoringService _instance = RiskScoringService._internal();
  factory RiskScoringService() => _instance;
  RiskScoringService._internal();

  /// Calculate risk score for a patient
  PatientRiskAssessment calculateRiskScore({
    String patientId = 'current_patient',
    int daysToAnalyze = 30,
  }) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysToAnalyze));

    // Get health summary
    final summary = _dataService.getHealthSummary(
      startDate: startDate,
      endDate: endDate,
    );

    // Get recent data
    final recentGlucose = _dataService.getGlucoseReadings(
      startDate: startDate,
      endDate: endDate,
    );

    final riskFactors = <String, double>{};
    final concerns = <String>[];
    double totalScore = 0;

    // Factor 1: Average Glucose Control (0-25 points)
    final glucoseScore = _calculateGlucoseScore(summary.averageGlucose);
    riskFactors['Average Glucose'] = glucoseScore;
    totalScore += glucoseScore;

    if (summary.averageGlucose > 200) {
      concerns.add('Very high average glucose (${summary.averageGlucose.toStringAsFixed(0)} mg/dL)');
    }

    // Factor 2: Glucose Variability (0-20 points)
    final variabilityScore = _calculateVariabilityScore(summary.glucoseStdDev);
    riskFactors['Glucose Variability'] = variabilityScore;
    totalScore += variabilityScore;

    if (summary.glucoseStdDev > 60) {
      concerns.add('High glucose variability (SD: ${summary.glucoseStdDev.toStringAsFixed(0)})');
    }

    // Factor 3: Hypoglycemia Events (0-20 points)
    final hypoScore = _calculateHypoScore(summary.hypoEvents, daysToAnalyze);
    riskFactors['Hypoglycemia Events'] = hypoScore;
    totalScore += hypoScore;

    if (summary.hypoEvents > 10) {
      concerns.add('${summary.hypoEvents} hypoglycemia events in $daysToAnalyze days');
    }

    // Factor 4: Time in Range (0-15 points) - inverted (lower TIR = higher risk)
    final tirScore = _calculateTimeInRangeScore(summary.timeInRange);
    riskFactors['Time in Range'] = tirScore;
    totalScore += tirScore;

    if (summary.timeInRange < 50) {
      concerns.add('Low time in range (${summary.timeInRange.toStringAsFixed(0)}%)');
    }

    // Factor 5: Medication Adherence (0-10 points) - inverted
    final adherenceScore = _calculateAdherenceScore(summary.medicationAdherence);
    riskFactors['Medication Adherence'] = adherenceScore;
    totalScore += adherenceScore;

    if (summary.medicationAdherence < 0.8) {
      concerns.add('Low medication adherence (${(summary.medicationAdherence * 100).toStringAsFixed(0)}%)');
    }

    // Factor 6: Activity Level (0-5 points) - inverted
    final activityScore = _calculateActivityScore(summary.totalActivityMinutes, daysToAnalyze);
    riskFactors['Physical Activity'] = activityScore;
    totalScore += activityScore;

    if (summary.totalActivityMinutes < Environment.activityTargetWeekly) {
      concerns.add('Low activity level (${summary.totalActivityMinutes} min/$daysToAnalyze days)');
    }

    // Factor 7: Recent Critical Events (0-10 points)
    final criticalScore = _calculateCriticalEventsScore(recentGlucose);
    riskFactors['Critical Events'] = criticalScore;
    totalScore += criticalScore;

    // Determine risk level
    final riskLevel = _getRiskLevel(totalScore);

    return PatientRiskAssessment(
      patientId: patientId,
      riskScore: totalScore.clamp(0, 100),
      riskLevel: riskLevel,
      assessedAt: DateTime.now(),
      riskFactors: riskFactors,
      concerns: concerns,
    );
  }

  /// Calculate glucose control score (0-25)
  double _calculateGlucoseScore(double avgGlucose) {
    if (avgGlucose > 250) return 25;
    if (avgGlucose > 200) return 20;
    if (avgGlucose > 180) return 15;
    if (avgGlucose > 160) return 10;
    if (avgGlucose > 140) return 5;
    return 0;
  }

  /// Calculate variability score (0-20)
  double _calculateVariabilityScore(double stdDev) {
    if (stdDev > 70) return 20;
    if (stdDev > 60) return 15;
    if (stdDev > 50) return 10;
    if (stdDev > 40) return 5;
    return 0;
  }

  /// Calculate hypoglycemia score (0-20)
  double _calculateHypoScore(int hypoEvents, int days) {
    final eventsPerWeek = (hypoEvents / days) * 7;
    if (eventsPerWeek > 4) return 20;
    if (eventsPerWeek > 3) return 15;
    if (eventsPerWeek > 2) return 10;
    if (eventsPerWeek > 1) return 5;
    return 0;
  }

  /// Calculate time in range score (0-15, inverted)
  double _calculateTimeInRangeScore(double timeInRange) {
    if (timeInRange < 40) return 15;
    if (timeInRange < 50) return 12;
    if (timeInRange < 60) return 8;
    if (timeInRange < 70) return 4;
    return 0;
  }

  /// Calculate adherence score (0-10, inverted)
  double _calculateAdherenceScore(double adherence) {
    if (adherence < 0.6) return 10;
    if (adherence < 0.7) return 8;
    if (adherence < 0.8) return 5;
    if (adherence < 0.9) return 2;
    return 0;
  }

  /// Calculate activity score (0-5, inverted)
  double _calculateActivityScore(int totalMinutes, int days) {
    final avgPerDay = totalMinutes / days;
    final targetPerDay = Environment.activityTargetDaily;

    if (avgPerDay < targetPerDay * 0.3) return 5;
    if (avgPerDay < targetPerDay * 0.5) return 3;
    if (avgPerDay < targetPerDay * 0.7) return 1;
    return 0;
  }

  /// Calculate critical events score (0-10)
  double _calculateCriticalEventsScore(List<GlucoseReading> readings) {
    final last7Days = DateTime.now().subtract(const Duration(days: 7));
    final recentReadings = readings.where((r) => r.timestamp.isAfter(last7Days)).toList();

    int criticalHigh = recentReadings.where((r) => r.value > 300).length;
    int criticalLow = recentReadings.where((r) => r.value < 54).length;

    if (criticalHigh + criticalLow > 5) return 10;
    if (criticalHigh + criticalLow > 3) return 7;
    if (criticalHigh + criticalLow > 1) return 4;
    return 0;
  }

  /// Determine risk level from score
  RiskLevel _getRiskLevel(double score) {
    if (score >= 70) return RiskLevel.critical;
    if (score >= 50) return RiskLevel.high;
    if (score >= 30) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Get priority color for UI
  String getPriorityColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return '#D32F2F'; // Red
      case RiskLevel.high:
        return '#F57C00'; // Orange
      case RiskLevel.medium:
        return '#FBC02D'; // Yellow
      case RiskLevel.low:
        return '#388E3C'; // Green
    }
  }

  /// Get recommended action for risk level
  String getRecommendedAction(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return 'Contact patient immediately';
      case RiskLevel.high:
        return 'Review within 24 hours';
      case RiskLevel.medium:
        return 'Review this week';
      case RiskLevel.low:
        return 'Routine monitoring';
    }
  }
}
