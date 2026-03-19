import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/environment.dart';
import '../../../patient/core/models/health_data_models.dart';
import '../models/recommendation_models.dart';

/// Calls the LLM Engine Service to generate AI-powered health recommendations.
///
/// Does NOT use [ApiService] — that class hardcodes [Environment.dataServiceUrl].
/// This service calls [Environment.llmEngineServiceUrl] directly, following the
/// same pattern as the chatbot service. No auth header is needed (internal service).
class LlmRecommendationService {
  static const _timeout = Duration(seconds: 45);
  static const _headers = {'Content-Type': 'application/json'};

  /// Sends the patient's [HealthSummary] to the LLM Engine and returns
  /// a list of AI-generated [HealthRecommendation]s.
  ///
  /// Throws on any error (network failure, timeout, non-2xx status, parse error)
  /// so the caller can transparently fall back to rule-based logic.
  Future<List<HealthRecommendation>> generate(
    HealthSummary summary, {
    int analysisPeriodDays = 7,
  }) async {
    final url = Uri.parse(
      '${Environment.llmEngineServiceUrl}/recommendations/generate',
    );

    final body = jsonEncode({
      'health_summary': _summaryToSnakeCase(summary),
      'analysis_period_days': analysisPeriodDays,
    });

    debugPrint('[LlmRecommendationService] POST $url');

    final response = await http
        .post(url, headers: _headers, body: body)
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
        .map((item) => HealthRecommendation.fromJson(
              _toCamelCase(item as Map<String, dynamic>),
            ))
        .toList();
  }

  /// Maps [HealthSummary] camelCase fields → Python backend snake_case keys.
  Map<String, dynamic> _summaryToSnakeCase(HealthSummary summary) {
    return {
      'average_glucose': summary.averageGlucose,
      'glucose_std_dev': summary.glucoseStdDev,
      'hyper_events': summary.hyperEvents,
      'hypo_events': summary.hypoEvents,
      'time_in_range': summary.timeInRange,
      'estimated_a1c': summary.estimatedA1c,
      'total_meals': summary.totalMeals,
      'average_carbs': summary.averageCarbs,
      'total_activity_minutes': summary.totalActivityMinutes,
      'medication_adherence': summary.medicationAdherence,
      'average_sleep_hours': summary.averageSleepHours,
    };
  }

  /// Converts a snake_case recommendation JSON map from the backend into the
  /// camelCase keys expected by [HealthRecommendation.fromJson].
  Map<String, dynamic> _toCamelCase(Map<String, dynamic> raw) {
    final result = <String, dynamic>{
      'id': raw['id'],
      'category': raw['category'],
      'title': raw['title'],
      'description': raw['description'],
      'priority': raw['priority'],
      'status': raw['status'] ?? 'active',
      'generatedAt': raw['generated_at'],
      'expiresAt': raw['expires_at'],
      'actionItems': raw['action_items'],
      'dataSources': null,
    };

    final exp = raw['explanation'] as Map<String, dynamic>?;
    if (exp != null) {
      result['explanation'] = {
        'rationale': exp['rationale'],
        'expectedImpact': exp['expected_impact'],
        'evidenceLinks': exp['evidence_links'] ?? <String>[],
        'triggeringData': (exp['triggering_data'] as List<dynamic>? ?? [])
            .map((d) => {
                  'type': d['type'],
                  'description': d['description'],
                  'value': d['value'],
                  'timestamp': d['timestamp'],
                })
            .toList(),
      };
    }

    return result;
  }
}
