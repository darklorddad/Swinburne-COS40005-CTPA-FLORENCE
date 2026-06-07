import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:florence/core/config/environment.dart';
import 'package:florence/features/patient/dashboard/models/insight_snapshot.dart';

/// Calls the backend to generate a single AI health insight for the dashboard card.
///
/// ── Service URL ──────────────────────────────────────────────────────────────
/// PRIMARY: LLM Engine service (same Vercel deployment as recommendations & meal analysis)
const String _baseUrl = Environment.llmEngineServiceUrl;

/// FALLBACK: Chatbot service (if the engine service is unavailable)
/// Swap to this if the engine service is returning errors.
/// const String _baseUrl = Environment.llmChatbotServiceUrl;
/// ─────────────────────────────────────────────────────────────────────────────

class InsightService {
  static const _timeout = Duration(seconds: 30);

  /// Generates a single insight string from the patient's [snapshot].
  ///
  /// Throws on auth failure, network error, timeout, or non-2xx response
  /// so the caller (provider) can apply the fallback chain.
  Future<String> generate(InsightSnapshot snapshot) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    final url = Uri.parse('$_baseUrl/insights/generate');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
    final body = jsonEncode({
      'health_snapshot': snapshot.toJson(),
      'timezone_offset': DateTime.now().timeZoneOffset.inHours,
    });

    debugPrint('[InsightService] POST $url');

    final response = await http
        .post(url, headers: headers, body: body)
        .timeout(_timeout);

    debugPrint('[InsightService] Status: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Insight service returned ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final insight = data['insight'] as String?;
    if (insight == null || insight.trim().isEmpty) {
      throw Exception('Insight service returned empty insight');
    }

    return insight.trim();
  }
}
