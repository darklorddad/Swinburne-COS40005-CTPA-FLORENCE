/// AI-Powered Recommendation Engine for FLORENCE Digital Health Platform
/// Generates personalized health recommendations

import '../../../../core/config/environment.dart';
import '../../../patient/core/models/health_data_models.dart';
import '../../../patient/core/services/data_ingestion_service.dart';
import '../models/recommendation_models.dart';

/// Service for generating health recommendations
class RecommendationEngine {
  final DataIngestionService _dataService = DataIngestionService();

  // Singleton pattern
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  // Cache of generated recommendations
  final List<HealthRecommendation> _recommendations = [];

  List<HealthRecommendation> get allRecommendations =>
      List.unmodifiable(_recommendations);

  List<HealthRecommendation> get activeRecommendations =>
      _recommendations.where((r) => r.isActive).toList();

  /// Generate new recommendations based on recent health data
  Future<List<HealthRecommendation>> generateRecommendations({
    int daysToAnalyze = 7,
  }) async {
    // Currently only rule-based recommendations are supported
    // until the Python service exposes a recommendation endpoint.
    return _generateRuleBasedRecommendations();
  }

  /// Generate rule-based recommendations (fallback)
  List<HealthRecommendation> _generateRuleBasedRecommendations() {
    final recommendations = <HealthRecommendation>[];
    final summary = _dataService.getHealthSummary(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    );

    // High glucose
    if (summary.averageGlucose > Environment.glucoseHigh) {
      recommendations.add(HealthRecommendation(
        id: 'rec_glucose_high_${DateTime.now().millisecondsSinceEpoch}',
        category: RecommendationCategory.meal,
        title: 'Reduce Average Glucose',
        description: 'Your average glucose is ${summary.averageGlucose.toStringAsFixed(0)} mg/dL. Let\'s work on bringing it down.',
        priority: RecommendationPriority.high,
        status: RecommendationStatus.active,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        actionItems: [
          'Monitor carb portions',
          'Increase fiber intake',
          'Walk 10 mins after meals',
        ],
      ));
    }

    // Low activity
    if (summary.totalActivityMinutes < 150) {
      recommendations.add(HealthRecommendation(
        id: 'rec_activity_low_${DateTime.now().millisecondsSinceEpoch}',
        category: RecommendationCategory.activity,
        title: 'Increase Physical Activity',
        description: 'You logged ${summary.totalActivityMinutes} minutes this week. Aim for 150 minutes.',
        priority: RecommendationPriority.medium,
        status: RecommendationStatus.active,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        actionItems: [
          'Start with 10-minute walks',
          'Try post-meal walking',
          'Gradually increase duration',
        ],
      ));
    }

    _recommendations.addAll(recommendations);
    return recommendations;
  }

  /// Explain a specific recommendation
  Future<String> explainRecommendation(HealthRecommendation recommendation) async {
    // Return static rationale as AI explanation is currently unavailable
    return recommendation.explanation?.rationale ?? 'No explanation available';
  }

  /// Mark recommendation as completed
  void completeRecommendation(String id) {
    final index = _recommendations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recommendations[index] = _recommendations[index].copyWith(
        status: RecommendationStatus.completed,
      );
    }
  }

  /// Dismiss recommendation
  void dismissRecommendation(String id) {
    final index = _recommendations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recommendations[index] = _recommendations[index].copyWith(
        status: RecommendationStatus.dismissed,
      );
    }
  }

  /// Clear all recommendations
  void clearRecommendations() {
    _recommendations.clear();
  }
}
