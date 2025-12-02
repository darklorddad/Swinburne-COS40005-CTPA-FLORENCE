import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/environment.dart';
import '../models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoadingHistory;
  final bool isClearingHistory;

  const ChatState({
    this.messages = const [],
    this.isLoadingHistory = false,
    this.isClearingHistory = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingHistory,
    bool? isClearingHistory,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isClearingHistory: isClearingHistory ?? this.isClearingHistory,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  final String _baseUrl = Environment.chatbotServiceUrl;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _hasLoadedHistory = false;

  @override
  ChatState build() {
    return const ChatState();
  }

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

  /// Send a message to the Chatbot Service
  Future<void> sendMessage(String message) async {
    // 1. Optimistically add user message
    final userMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );
    
    final previousMessages = state.messages;
    state = state.copyWith(messages: [...previousMessages, userMsg]);

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
        
        // 2. Add AI response
        state = state.copyWith(messages: [...state.messages, aiMsg]);
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      // On failure, remove the optimistic message
      state = state.copyWith(messages: previousMessages);
      throw Exception('Error communicating with chatbot service: $e');
    }
  }

  /// Retrieve conversation history
  Future<void> loadHistory({int limit = 50}) async {
    if (_hasLoadedHistory || state.isLoadingHistory) return;

    state = state.copyWith(isLoadingHistory: true);

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history?limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'];
        
        final loadedMessages = messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
        
        state = state.copyWith(
          messages: loadedMessages,
          isLoadingHistory: false,
        );
        _hasLoadedHistory = true;
      } else {
        throw Exception('Failed to load history: ${response.body}');
      }
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false);
      throw Exception('Error loading chat history: $e');
    }
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    if (state.isClearingHistory) return;

    state = state.copyWith(isClearingHistory: true);

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/history'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          messages: [],
          isClearingHistory: false,
        );
      } else {
        throw Exception('Failed to clear history: ${response.body}');
      }
    } catch (e) {
      state = state.copyWith(isClearingHistory: false);
      throw Exception('Error clearing history: $e');
    }
  }

  /// Reset session state
  void resetSession() {
    state = const ChatState();
    _hasLoadedHistory = false;
  }
}

/// Singleton-like provider (global state)
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new, isAutoDispose: true);

/// Legacy compatibility (if needed, though discouraged)
class ChatbotService {
  // This class should be removed after full migration
  // Leaving it here empty/deprecated if any lingering references exist but plan is to remove usage.
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();
  
  void resetSession() {}
}
