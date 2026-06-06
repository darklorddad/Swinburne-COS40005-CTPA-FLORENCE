import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:florence/main.dart';
import 'package:florence/core/config/environment.dart';

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
    final headers = await _getHeaders();
    if (!headers.containsKey('Authorization') && !endpoint.contains('/auth/')) {
      debugPrint('[ApiService] Short-circuiting GET to $endpoint: No token found.');
      if (endpoint.contains('logs') || 
          endpoint.contains('schedule') || 
          endpoint.contains('thresholds') || 
          endpoint.contains('medications') || 
          endpoint.contains('monitor-data')) {
        return [];
      }
      return {};
    }
    try {
      var response = await http.get(
        Uri.parse('${Environment.dataServiceUrl}$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        try {
          await supabase.auth.refreshSession();
          response = await http.get(
            Uri.parse('${Environment.dataServiceUrl}$endpoint'),
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
          Uri.parse('${Environment.dataServiceUrl}$endpoint'),
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
    final headers = await _getHeaders();
    if (!headers.containsKey('Authorization') && !endpoint.contains('/auth/')) {
      debugPrint('ℹ️ Short-circuiting Patient POST to $endpoint: No token found (User logging out).');
      return {};
    }
    try {
      var response = await http.post(
        Uri.parse('${Environment.dataServiceUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 401) {
        try {
          await supabase.auth.refreshSession();
          response = await http.post(
            Uri.parse('${Environment.dataServiceUrl}$endpoint'),
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
    final headers = await _getHeaders();
    if (!headers.containsKey('Authorization') && !endpoint.contains('/auth/')) {
      debugPrint('ℹ️ Short-circuiting Patient PUT to $endpoint: No token found (User logging out).');
      return {};
    }
    try {
      var response = await http.put(
        Uri.parse('${Environment.dataServiceUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 401) {
        try {
          await supabase.auth.refreshSession();
          response = await http.put(
            Uri.parse('${Environment.dataServiceUrl}$endpoint'),
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
    final headers = await _getHeaders();
    if (!headers.containsKey('Authorization') && !endpoint.contains('/auth/')) {
      debugPrint('ℹ️ Short-circuiting Patient PATCH to $endpoint: No token found (User logging out).');
      return {};
    }
    try {
      final response = await http.patch(
        Uri.parse('${Environment.dataServiceUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('API PATCH Error ($endpoint): $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    if (!headers.containsKey('Authorization') && !endpoint.contains('/auth/')) {
      debugPrint('ℹ️ Short-circuiting Patient DELETE to $endpoint: No token found (User logging out).');
      return {};
    }
    try {
      final response = await http.delete(
        Uri.parse('${Environment.dataServiceUrl}$endpoint'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('API DELETE Error ($endpoint): $e');
      rethrow;
    }
  }

  
  /// Upload a file via Multipart Request
  Future<dynamic> uploadFile(
    String endpoint,
    String fieldName,
    List<int> fileBytes,
    String filename, {
    Map<String, String>? additionalFields,
    String? baseUrlOverride,
  }) async {
    try {
      final baseUrl = baseUrlOverride ?? Environment.dataServiceUrl;
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add Headers (Auth)
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      // Remove Content-Type as MultipartRequest sets it automatically
      request.headers.remove('Content-Type');

      // Add additional form fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Add File
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _processResponse(response);
    } catch (e) {
      debugPrint('API UPLOAD Error ($endpoint): $e');
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
