import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/environment.dart';
import '../models/chat_message.dart';

class ChatbotService extends ChangeNotifier {
  // Singleton pattern to persist state across screen rebuilds
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  final String _baseUrl = Environment.chatbotServiceUrl;
  final SupabaseClient _supabase = Supabase.instance.client;

  // In-memory cache
  final List<ChatMessage> _messages = [];
  bool _hasLoadedHistory = false;
  
  // Operation states
  bool _isLoadingHistory = false;
  bool _isClearingHistory = false;

  /// Get read-only view of cached messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  /// Check if history has been fetched in this session
  bool get hasLoadedHistory => _hasLoadedHistory;
  
  /// Check if history is currently loading
  bool get isLoadingHistory => _isLoadingHistory;
  
  /// Check if history is currently being cleared
  bool get isClearingHistory => _isClearingHistory;

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
  Future<void> sendMessage(String message) async {
    // 1. Optimistically add user message to cache
    final userMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners(); // Update UI immediately

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
        notifyListeners(); // Update UI with response
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      // On failure, remove the optimistic message so the user knows it failed
      // (or in a more advanced app, mark it as 'error')
      _messages.remove(userMsg);
      notifyListeners(); // Update UI to remove failed message
      throw Exception('Error communicating with chatbot service: $e');
    }
  }

  /// Retrieve conversation history from the Python Chatbot Service
  /// Populates the local cache
  Future<void> loadHistory({int limit = 50}) async {
    // If we already loaded history, just notify listeners to ensure UI is synced
    if (_hasLoadedHistory) {
      notifyListeners();
      return;
    }
    
    // Prevent concurrent loads
    if (_isLoadingHistory) return;

    _isLoadingHistory = true;
    notifyListeners();

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
      } else {
        throw Exception('Failed to load history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading chat history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    if (_isClearingHistory) return;

    _isClearingHistory = true;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/history'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        _messages.clear();
      } else {
        throw Exception('Failed to clear history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error clearing history: $e');
    } finally {
      _isClearingHistory = false;
      notifyListeners();
    }
  }

  /// Reset session state (clears local cache without API call)
  void resetSession() {
    _messages.clear();
    _hasLoadedHistory = false;
    _isLoadingHistory = false;
    _isClearingHistory = false;
    notifyListeners();
  }

  /// Invalidate context (used by PatientProfileService)
  void invalidateContext() {
    resetSession();
  }
}
