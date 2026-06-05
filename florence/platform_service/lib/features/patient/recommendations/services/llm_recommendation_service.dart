import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:florence/core/config/environment.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/recommendations/models/recommendation_models.dart';

/// Calls the LLM Engine Service to generate AI-powered health recommendations.
///
/// Uses the same auth pattern as the AI meal analysis — sends the Supabase
/// JWT so the backend can authenticate the request.
class LlmRecommendationService {
  static const _timeout = Duration(seconds: 120);

  /// Sends the patient's [HealthSummary] to the LLM Engine and returns
  /// a list of AI-generated [HealthRecommendation]s.
  ///
  /// Throws on any error (network failure, timeout, non-2xx status, parse error)
  /// so the caller can transparently fall back to rule-based logic.
  Future<List<HealthRecommendation>> generate(
    HealthSummary summary, {
    required String timeframe,
    int analysisPeriodDays = 7,
    List<String> previousTitles = const [],
    String glucoseUnit = 'mmol/L',
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    final url = Uri.parse(
      '${Environment.llmEngineServiceUrl}/recommendations/generate',
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };

    final body = jsonEncode({
      'health_summary': _summaryToSnakeCase(summary, glucoseUnit),
      'analysis_period_days': analysisPeriodDays,
      if (previousTitles.isNotEmpty)
        'previous_recommendation_titles': previousTitles,
    });

    debugPrint('[LlmRecommendationService] POST $url');

    final response = await http
        .post(url, headers: headers, body: body)
        .timeout(_timeout);

    debugPrint('[LlmRecommendationService] Status: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'LLM Engine returned ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = data['recommendations'] as List<dynamic>;

    return rawList
        .map((item) {
          final map = item as Map<String, dynamic>;
          map['timeframe'] = timeframe;
          return HealthRecommendation.fromJson(map);
        })
        .toList();
  }

  /// Maps [HealthSummary] camelCase fields → Python backend snake_case keys.
  Map<String, dynamic> _summaryToSnakeCase(HealthSummary summary, String glucoseUnit) {
    return {
      'glucose_unit': glucoseUnit,
      // Core aggregates
      'average_glucose': summary.averageGlucose,
      'glucose_std_dev': summary.glucoseStdDev,
      'hyper_events': summary.hyperEvents,
      'hypo_events': summary.hypoEvents,
      'time_in_range': summary.timeInRange,
      'estimated_a1c': summary.estimatedA1c,
      'total_meals': summary.totalMeals,
      'average_calories': summary.averageCalories,
      'total_activity_minutes': summary.totalActivityMinutes,
      'medication_adherence': summary.medicationAdherence,
      // Extended vitals
      if (summary.latestBmi != null) 'latest_bmi': summary.latestBmi,
      if (summary.latestSystolic != null) 'latest_systolic': summary.latestSystolic,
      if (summary.latestDiastolic != null) 'latest_diastolic': summary.latestDiastolic,
      if (summary.latestCholesterol != null) 'latest_cholesterol': summary.latestCholesterol,
      if (summary.latestHdl != null) 'latest_hdl': summary.latestHdl,
      if (summary.latestLdl != null) 'latest_ldl': summary.latestLdl,
      if (summary.latestTriglycerides != null) 'latest_triglycerides': summary.latestTriglycerides,
      if (summary.latestHba1c != null) 'latest_hba1c': summary.latestHba1c,
      // Disease & medication context (live from Supabase)
      if (summary.activeDiseaseNames.isNotEmpty) 'active_diseases': summary.activeDiseaseNames,
      if (summary.currentMedications.isNotEmpty) 'current_medications': summary.currentMedications,
      // Individual recent readings
      if (summary.recentGlucoseReadings.isNotEmpty)
        'recent_glucose_readings': summary.recentGlucoseReadings,
      if (summary.recentMeals.isNotEmpty) 'recent_meals': summary.recentMeals,
      if (summary.recentActivities.isNotEmpty) 'recent_activities': summary.recentActivities,
    };
  }

}
