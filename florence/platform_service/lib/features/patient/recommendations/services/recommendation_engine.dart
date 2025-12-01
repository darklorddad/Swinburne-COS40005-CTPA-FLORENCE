import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/environment.dart';
import '../../../patient/core/models/health_data_models.dart';
import '../../../patient/core/providers/monitor_data_providers.dart';
import '../models/recommendation_models.dart';

final recommendationProvider = NotifierProvider<RecommendationNotifier, List<HealthRecommendation>>(RecommendationNotifier.new);

class RecommendationNotifier extends Notifier<List<HealthRecommendation>> {
  
  @override
  List<HealthRecommendation> build() {
    return [];
  }

  List<HealthRecommendation> get activeRecommendations =>
      state.where((r) => r.isActive).toList();

  /// Generate new recommendations based on recent health data
  Future<void> generateRecommendations({
    int daysToAnalyze = 7,
  }) async {
    final healthData = ref.read(monitorDataProvider).asData?.value;
    if (healthData == null) return;

    final summary = healthData.getHealthSummary(
      startDate: DateTime.now().subtract(Duration(days: daysToAnalyze)),
      endDate: DateTime.now(),
    );

    final newRecommendations = _generateRuleBasedRecommendations(summary);
    
    // Append new recommendations, avoiding duplicates if needed
    state = [...state, ...newRecommendations];
  }

  /// Generate rule-based recommendations
  List<HealthRecommendation> _generateRuleBasedRecommendations(HealthSummary summary) {
    final recommendations = <HealthRecommendation>[];

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

    return recommendations;
  }

  /// Mark recommendation as completed
  void completeRecommendation(String id) {
    state = [
      for (final r in state)
        if (r.id == id)
          r.copyWith(status: RecommendationStatus.completed)
        else
          r
    ];
  }

  /// Dismiss recommendation
  void dismissRecommendation(String id) {
    state = [
      for (final r in state)
        if (r.id == id)
          r.copyWith(status: RecommendationStatus.dismissed)
        else
          r
    ];
  }

  /// Clear all recommendations
  void clearRecommendations() {
    state = [];
  }
}
