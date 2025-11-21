import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/environment.dart';
import '../models/chat_message.dart';

class ChatbotService {
  // Singleton pattern to persist state across screen rebuilds
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  final String _baseUrl = Environment.chatbotServiceUrl;
  final SupabaseClient _supabase = Supabase.instance.client;

  // In-memory cache
  final List<ChatMessage> _messages = [];
  bool _hasLoadedHistory = false;

  /// Get read-only view of cached messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  /// Check if history has been fetched in this session
  bool get hasLoadedHistory => _hasLoadedHistory;

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
  /// Updates the local cache with both the user's message and the AI's response
  Future<ChatMessage> sendMessage(String message) async {
    // 1. Optimistically add user message to cache
    // We use a temporary ID; the DB will assign a real one, but for cache it's fine
    final userMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

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
        final aiMsg = ChatMessage.fromJson(data);
        
        // 2. Add AI response to cache
        _messages.add(aiMsg);
        return aiMsg;
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      // Note: In a more complex app, we might want to mark the userMsg as "failed" in the cache
      throw Exception('Error communicating with chatbot service: $e');
    }
  }

  /// Retrieve conversation history from the Python Chatbot Service
  /// Populates the local cache
  Future<List<ChatMessage>> loadHistory({int limit = 50}) async {
    // If we already loaded history, return the cache to avoid race conditions and redundant calls
    if (_hasLoadedHistory) {
      return messages;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history?limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'];
        
        _messages.clear();
        _messages.addAll(
          messagesJson.map((json) => ChatMessage.fromJson(json)).toList(),
        );
        
        _hasLoadedHistory = true;
        return messages;
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

      if (response.statusCode == 200) {
        _messages.clear();
        // We keep _hasLoadedHistory = true because we know the state is accurate (empty)
      } else {
        throw Exception('Failed to clear history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error clearing history: $e');
    }
  }
}
