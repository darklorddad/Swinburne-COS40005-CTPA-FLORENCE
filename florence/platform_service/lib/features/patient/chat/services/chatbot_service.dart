import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/environment.dart';
import '../models/chat_message.dart';

class ChatbotService {
  final String _baseUrl = Environment.chatbotServiceUrl;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get headers with the current user's JWT
  Map<String, String> _getHeaders() {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('User not authenticated');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  /// Send a message to the Python Chatbot Service
  Future<ChatMessage> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/message'),
        headers: _getHeaders(),
        body: jsonEncode({
          'message': message,
          'include_history': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage.fromJson(data);
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error communicating with chatbot service: $e');
    }
  }

  /// Retrieve conversation history from the Python Chatbot Service
  Future<List<ChatMessage>> getHistory({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history?limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'];
        return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading chat history: $e');
    }
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/history'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to clear history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error clearing history: $e');
    }
  }
}
