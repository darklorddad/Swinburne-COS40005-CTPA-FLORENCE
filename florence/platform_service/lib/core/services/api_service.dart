import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'apikey': Environment.supabaseAnonKey,
    };

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}$endpoint'),
        headers: await _getHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('API GET Error ($endpoint): $e');
      throw Exception('Failed to connect to the server.');
    }
  }

  dynamic _processResponse(http.Response response) {
    debugPrint('API Response (${response.request?.method} ${response.request?.url.path}): ${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if(response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['detail'] ?? 'An API error occurred.';
      debugPrint('API Error Body: ${response.body}');
      throw Exception(errorMessage);
    }
  }
}
