import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import '../../main.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'apikey': Environment.supabaseAnonKey,
    };

    // Get the token directly from the current Supabase session
    final currentToken = supabase.auth.currentSession?.accessToken;

    if (currentToken != null) {
      headers['Authorization'] = 'Bearer $currentToken';
    }

    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    try {
      var response = await http.get(
        Uri.parse('${Environment.apiUrl}$endpoint'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 401) {
        try {
          await supabase.auth.refreshSession();
          response = await http.get(
            Uri.parse('${Environment.apiUrl}$endpoint'),
            headers: await _getHeaders(),
          );
        } catch (refreshError) {
          debugPrint('Session refresh failed: $refreshError');
        }
      }

      // Retry on 403 (Transient backend issue)
      if (response.statusCode == 403) {
        debugPrint('API 403 Error ($endpoint). Retrying once...');
        await Future.delayed(const Duration(milliseconds: 500));
        response = await http.get(
          Uri.parse('${Environment.apiUrl}$endpoint'),
          headers: await _getHeaders(),
        );
      }

      return _processResponse(response);
    } catch (e) {
      debugPrint('API GET Error ($endpoint): $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      var response = await http.post(
        Uri.parse('${Environment.apiUrl}$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 401) {
        try {
          await supabase.auth.refreshSession();
          response = await http.post(
            Uri.parse('${Environment.apiUrl}$endpoint'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          );
        } catch (refreshError) {
          debugPrint('Session refresh failed: $refreshError');
        }
      }

      return _processResponse(response);
    } catch (e) {
      debugPrint('API POST Error ($endpoint): $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      var response = await http.put(
        Uri.parse('${Environment.apiUrl}$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 401) {
        try {
          await supabase.auth.refreshSession();
          response = await http.put(
            Uri.parse('${Environment.apiUrl}$endpoint'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          );
        } catch (refreshError) {
          debugPrint('Session refresh failed: $refreshError');
        }
      }

      return _processResponse(response);
    } catch (e) {
      debugPrint('API PUT Error ($endpoint): $e');
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('${Environment.apiUrl}$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('API PATCH Error ($endpoint): $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiUrl}$endpoint'),
        headers: await _getHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('API DELETE Error ($endpoint): $e');
      rethrow;
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
