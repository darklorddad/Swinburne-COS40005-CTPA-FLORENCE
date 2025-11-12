import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/environment.dart';

class AuthService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  AuthService() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final storedToken = await _storage.read(key: 'auth_token');
    if (storedToken != null) {
      _token = storedToken;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Environment.apiUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];
      await _storage.write(key: 'auth_token', value: _token);
      notifyListeners();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  Future<void> exchangeToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('${Environment.apiUrl}/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
     if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];
      await _storage.write(key: 'auth_token', value: _token);
      notifyListeners();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Token exchange failed');
    }
  }
  
  Future<Map<String, dynamic>> getMe() async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('${Environment.apiUrl}/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch user profile');
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }
}
