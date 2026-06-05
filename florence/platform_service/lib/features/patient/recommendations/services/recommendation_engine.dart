import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/config/environment.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:florence/features/patient/recommendations/models/recommendation_models.dart';
import 'package:florence/features/patient/recommendations/services/llm_recommendation_service.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';

import 'package:florence/core/services/api_service.dart';

final recommendationProvider =
    AsyncNotifierProvider<RecommendationNotifier, List<HealthRecommendation>>(
  RecommendationNotifier.new,
);

class RecommendationNotifier extends AsyncNotifier<List<HealthRecommendation>> {
  final LlmRecommendationService _llmService = LlmRecommendationService();
  final ApiService _apiService = ApiService();

  @override
  Future<List<HealthRecommendation>> build() async {
    final response = await _apiService.get('/patients/me/recommendations');
    if (response == null) return [];
    
    return (response as List)
        .map((json) => HealthRecommendation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Generate new recommendations based on recent health data.
  ///
  /// Strategy:
  /// 1. If [Environment.enableAI] is true, call the LLM Engine Service.
  /// 2. On any failure (network, timeout, bad response), fall back to
  ///    [_generateRuleBasedRecommendations] transparently.
  /// 3. Append to state.
  /// Returns true if AI recommendations were used, false if rule-based fallback was used.
  Future<bool> generateRecommendations({required String timeframe}) async {
    final healthData = ref.read(monitorDataProvider).asData?.value;
    if (healthData == null) return false;

    final settings = ref.read(patientSettingsProvider);
    final gUnit = settings.glucoseUnit;
    final cUnit = settings.cholesterolUnit;

    // Daily looks at 1 day, Weekly looks at 7 days
    final daysToAnalyze = timeframe == 'daily' ? 1 : 7;

    final summary = healthData.getHealthSummary(
      startDate: DateTime.now().subtract(Duration(days: daysToAnalyze)),
      endDate: DateTime.now(),
    );

    final currentRecs = state.value ?? [];
    final previousTitles = currentRecs
        .where((r) => r.status == RecommendationStatus.active && r.timeframe == timeframe)
        .map((r) => r.title)
        .toList();

    List<HealthRecommendation> newRecommendations;
    bool usedAI = false;

    if (Environment.enableAI) {
      try {
        debugPrint('[RecommendationEngine] Requesting $timeframe LLM recommendations…');
        newRecommendations = await _llmService.generate(
          summary,
          timeframe: timeframe,
          analysisPeriodDays: daysToAnalyze,
          previousTitles: previousTitles,
          glucoseUnit: gUnit,
          cholesterolUnit: cUnit,
        );
        debugPrint(
          '[RecommendationEngine] LLM returned ${newRecommendations.length} recommendations.',
        );
        usedAI = true;
      } catch (e) {
        debugPrint(
          '[RecommendationEngine] LLM failed, using rule-based fallback. Error: $e',
        );
        newRecommendations = _generateRuleBasedRecommendations(summary, timeframe, healthData);
      }
    } else {
      debugPrint('[RecommendationEngine] AI disabled, using rule-based logic.');
      newRecommendations = _generateRuleBasedRecommendations(summary, timeframe, healthData);
    }

    try {
      // Save new recommendations to database
      await _apiService.post('/patients/me/recommendations', {
        'timeframe': timeframe,
        'recommendations': newRecommendations.map((r) => r.toJson()).toList()
      });
      
      // Reload from database if provider is still alive
      try {
        ref.invalidateSelf();
      } catch (_) {
        // Ignore if provider was already disposed (e.g. user left screen)
      }
    } catch (e) {
      debugPrint('[RecommendationEngine] Failed to save recommendations: $e');
    }

    return usedAI;
  }

  /// Rule-based fallback — used when AI is disabled or the LLM call fails.
  List<HealthRecommendation> _generateRuleBasedRecommendations(
      HealthSummary summary, String timeframe, HealthDataState healthData) {
    final recommendations = <HealthRecommendation>[];
    final gUnit = ref.read(patientSettingsProvider).glucoseUnit;

    HealthThreshold? t;
    try {
      t = healthData.healthThresholds.firstWhere((t) => t.dataType == MonitorDataType.GLUCOSE);
    } catch (_) {}
    final highBound = t?.maxValue ?? Environment.glucoseHigh;

    // High glucose
    if (summary.averageGlucose > highBound) {
      recommendations.add(HealthRecommendation(
        id: 'rec_glucose_high_${DateTime.now().millisecondsSinceEpoch}',
        timeframe: timeframe,
        category: RecommendationCategory.meal,
        title: 'Reduce Average Glucose',
        description:
            'Your average glucose is ${summary.averageGlucose.toStringAsFixed(gUnit == 'mmol/L' ? 1 : 0)} $gUnit. Let\'s work on bringing it down.',
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
        timeframe: timeframe,
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

  Future<void> completeRecommendation(String id) async {
    await _updateStatus(id, RecommendationStatus.completed);
  }

  Future<void> dismissRecommendation(String id) async {
    await _updateStatus(id, RecommendationStatus.dismissed);
  }
  
  Future<void> _updateStatus(String id, RecommendationStatus status) async {
    try {
      // Optimistic update
      final currentList = state.value ?? [];
      state = AsyncData([
        for (final r in currentList)
          if (r.id == id) r.copyWith(status: status) else r,
      ]);

      await _apiService.patch('/patients/me/recommendations/$id', {
        'status': status.name,
      });
    } catch (e) {
      debugPrint('[RecommendationEngine] Failed to update status: $e');
      ref.invalidateSelf(); // Revert on failure
    }
  }
}
