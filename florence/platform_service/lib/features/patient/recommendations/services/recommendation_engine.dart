import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/config/environment.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/features/patient/recommendations/models/recommendation_models.dart';
import 'package:florence/features/patient/recommendations/services/llm_recommendation_service.dart';

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, List<HealthRecommendation>>(
  RecommendationNotifier.new,
  isAutoDispose: true,
);

class RecommendationNotifier extends Notifier<List<HealthRecommendation>> {
  final LlmRecommendationService _llmService = LlmRecommendationService();

  @override
  List<HealthRecommendation> build() {
    return [];
  }

  List<HealthRecommendation> get activeRecommendations =>
      state.where((r) => r.isActive).toList();

  /// Generate new recommendations based on recent health data.
  ///
  /// Strategy:
  /// 1. If [Environment.enableAI] is true, call the LLM Engine Service.
  /// 2. On any failure (network, timeout, bad response), fall back to
  ///    [_generateRuleBasedRecommendations] transparently.
  /// 3. Append to state.
  /// Returns true if AI recommendations were used, false if rule-based fallback was used.
  Future<bool> generateRecommendations({int daysToAnalyze = 7}) async {
    final healthData = ref.read(monitorDataProvider).asData?.value;
    if (healthData == null) return false;

    final summary = healthData.getHealthSummary(
      startDate: DateTime.now().subtract(Duration(days: daysToAnalyze)),
      endDate: DateTime.now(),
    );

    // Collect current active titles so the LLM avoids repeating them
    final previousTitles = state
        .where((r) => r.status == RecommendationStatus.active)
        .map((r) => r.title)
        .toList();

    List<HealthRecommendation> newRecommendations;
    bool usedAI = false;

    if (Environment.enableAI) {
      try {
        debugPrint('[RecommendationEngine] Requesting LLM recommendations…');
        newRecommendations = await _llmService.generate(
          summary,
          analysisPeriodDays: daysToAnalyze,
          previousTitles: previousTitles,
        );
        debugPrint(
          '[RecommendationEngine] LLM returned ${newRecommendations.length} recommendations.',
        );
        usedAI = true;
      } catch (e) {
        debugPrint(
          '[RecommendationEngine] LLM failed, using rule-based fallback. Error: $e',
        );
        newRecommendations = _generateRuleBasedRecommendations(summary);
      }
    } else {
      debugPrint('[RecommendationEngine] AI disabled, using rule-based logic.');
      newRecommendations = _generateRuleBasedRecommendations(summary);
    }

    // Replace active recommendations; keep completed/dismissed history
    state = [
      ...state.where((r) => r.status != RecommendationStatus.active),
      ...newRecommendations,
    ];
    return usedAI;
  }

  /// Rule-based fallback — used when AI is disabled or the LLM call fails.
  List<HealthRecommendation> _generateRuleBasedRecommendations(
      HealthSummary summary) {
    final recommendations = <HealthRecommendation>[];

    // High glucose
    if (summary.averageGlucose > Environment.glucoseHigh) {
      recommendations.add(HealthRecommendation(
        id: 'rec_glucose_high_${DateTime.now().millisecondsSinceEpoch}',
        category: RecommendationCategory.meal,
        title: 'Reduce Average Glucose',
        description:
            'Your average glucose is ${summary.averageGlucose.toStringAsFixed(0)} mg/dL. Let\'s work on bringing it down.',
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
        description:
            'You logged ${summary.totalActivityMinutes} minutes this week. Aim for 150 minutes.',
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

  /// Mark recommendation as completed.
  void completeRecommendation(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: RecommendationStatus.completed) else r,
    ];
  }

  /// Dismiss recommendation.
  void dismissRecommendation(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: RecommendationStatus.dismissed) else r,
    ];
  }

  /// Clear all recommendations.
  void clearRecommendations() {
    state = [];
  }
}
