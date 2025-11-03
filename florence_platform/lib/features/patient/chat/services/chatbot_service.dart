/// AI Chatbot Service for FLORENCE Digital Health Platform
/// Context-aware health chatbot using DeepSeek AI

import '../../../../core/services/ai/deepseek_service.dart';
import '../../../../core/config/environment.dart';
import '../../../patient/core/services/data_ingestion_service.dart';

/// Chat message model
class ChatMessageModel {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? context; // Health data context used

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.context,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: json['context'] as Map<String, dynamic>?,
    );
  }
}

/// Service for AI-powered health chatbot
class ChatbotService {
  final DeepSeekService _deepseek = DeepSeekService();
  final DataIngestionService _dataService = DataIngestionService();

  // Singleton pattern
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  // Conversation history
  final List<ChatMessageModel> _conversationHistory = [];

  // Cached health context (cleared on data refresh)
  Map<String, dynamic>? _cachedHealthContext;
  DateTime? _contextTimestamp;

  List<ChatMessageModel> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Send a message to the chatbot
  Future<ChatMessageModel> sendMessage(String userMessage) async {
    // Add user message to history
    final userChatMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_user',
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    );
    _conversationHistory.add(userChatMessage);

    // Get health context
    final healthContext = _buildHealthContext();

    String response;

    if (Environment.enableAI) {
      try {
        // Get AI response
        response = await _deepseek.chatbot(
          userMessage: userMessage,
          healthContext: healthContext,
          conversationHistory: _conversationHistory
              .take(_conversationHistory.length - 1) // Exclude the just-added user message
              .map((m) => ChatMessage(
                    role: m.role == 'user' ? MessageRole.user : MessageRole.assistant,
                    content: m.content,
                  ))
              .toList(),
        );
      } catch (e) {
        print('AI chatbot error: $e');
        response = _generateFallbackResponse(userMessage, healthContext);
      }
    } else {
      response = _generateFallbackResponse(userMessage, healthContext);
    }

    // Add assistant response to history
    final assistantMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: 'assistant',
      content: response,
      timestamp: DateTime.now(),
      context: healthContext,
    );
    _conversationHistory.add(assistantMessage);

    return assistantMessage;
  }

  /// Build health context for AI
  /// Always fetches fresh data from DataIngestionService
  Map<String, dynamic> _buildHealthContext() {
    // Always rebuild context to ensure we have the latest data
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));

    // Fetch fresh summary (this calls the service which has the latest data)
    final summary = _dataService.getHealthSummary(
      startDate: startDate,
      endDate: endDate,
    );

    // Get the absolute latest glucose reading
    final latestGlucose = _dataService.allGlucoseReadings.isNotEmpty
        ? _dataService.allGlucoseReadings.first
        : null;

    // Build context with current timestamp
    final context = {
      'latestGlucose': latestGlucose?.value,
      'latestGlucoseTime': latestGlucose?.timestamp.toString(),
      'latestGlucoseContext': latestGlucose?.context,
      'averageGlucose7d': summary.averageGlucose,
      'timeInRange7d': summary.timeInRange,
      'hyperEvents7d': summary.hyperEvents,
      'hypoEvents7d': summary.hypoEvents,
      'totalActivityMinutes7d': summary.totalActivityMinutes,
      'medicationAdherence': summary.medicationAdherence * 100,
      'averageSleepHours': summary.averageSleepHours,
      'dataTimestamp': DateTime.now().toString(), // Track when context was built
    };

    // Cache the context with timestamp
    _cachedHealthContext = context;
    _contextTimestamp = DateTime.now();

    return context;
  }

  /// Invalidate cached health context (call this when data is refreshed)
  void invalidateContext() {
    _cachedHealthContext = null;
    _contextTimestamp = null;
    print('ChatbotService: Health context invalidated - will fetch fresh data on next query');
  }

  /// Get the timestamp of the last context build
  DateTime? get contextTimestamp => _contextTimestamp;

  /// Generate fallback response (rule-based)
  String _generateFallbackResponse(String userMessage, Map<String, dynamic> context) {
    final message = userMessage.toLowerCase();

    // Greeting
    if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return 'Hello! I\'m FLORENCE, your health assistant. I can help you understand your glucose patterns, activity, and provide personalized tips. What would you like to know?';
    }

    // Glucose questions
    if (message.contains('glucose') || message.contains('sugar') || message.contains('blood')) {
      final latestGlucose = context['latestGlucose'];
      final avgGlucose = context['averageGlucose7d'];
      final timeInRange = context['timeInRange7d'];

      if (latestGlucose != null) {
        return 'Your latest glucose reading is ${latestGlucose.toStringAsFixed(0)} mg/dL. '
            'Over the past week, your average has been ${avgGlucose.toStringAsFixed(0)} mg/dL '
            'with ${timeInRange.toStringAsFixed(0)}% time in range (70-180 mg/dL). '
            '${timeInRange < 70 ? "Let's work on improving your time in range!" : "Great job staying in range!"}';
      }
    }

    // Activity questions
    if (message.contains('activity') || message.contains('exercise') || message.contains('walk')) {
      final activityMinutes = context['totalActivityMinutes7d'] ?? 0;
      return 'This week you\'ve logged $activityMinutes minutes of physical activity. '
          '${activityMinutes >= Environment.activityTargetWeekly ? "Excellent work meeting your activity goal!" : "Try to aim for ${Environment.activityTargetWeekly} minutes per week. Even short walks after meals help!"}';
    }

    // Meal questions
    if (message.contains('meal') || message.contains('food') || message.contains('eat') || message.contains('carb')) {
      return 'For better glucose control:\n'
          '• Choose complex carbs (whole grains, vegetables)\n'
          '• Pair carbs with protein and healthy fats\n'
          '• Watch portion sizes\n'
          '• A 10-minute walk after meals can reduce spikes by 10-15%';
    }

    // Sleep questions
    if (message.contains('sleep')) {
      final avgSleep = context['averageSleepHours'] ?? 0;
      return 'You\'re averaging $avgSleep hours of sleep. '
          'Aim for 7-9 hours nightly - good sleep improves glucose control and reduces morning spikes.';
    }

    // Medication questions
    if (message.contains('medication') || message.contains('medicine') || message.contains('pill')) {
      final adherence = context['medicationAdherence'] ?? 0;
      return 'Your medication adherence is ${adherence.toStringAsFixed(0)}%. '
          '${adherence >= 80 ? "Great job staying consistent!" : "Try setting daily reminders to improve consistency. Taking medications as prescribed is crucial for glucose control."}';
    }

    // High/low questions
    if (message.contains('high') || message.contains('spike')) {
      return 'Common causes of glucose spikes:\n'
          '• High carb meals\n'
          '• Lack of physical activity\n'
          '• Stress or illness\n'
          '• Missed medications\n\n'
          'Try tracking your meals and testing 2 hours after eating to identify patterns.';
    }

    if (message.contains('low') || message.contains('hypo')) {
      return 'If experiencing low glucose (< 70 mg/dL):\n'
          '1. Eat 15g fast-acting carbs (glucose tablets, juice)\n'
          '2. Wait 15 minutes and retest\n'
          '3. Repeat if still low\n'
          '4. Have a snack with protein\n\n'
          'Contact your doctor if lows are frequent.';
    }

    // Default response
    return 'I can help you with:\n'
        '• Understanding your glucose patterns\n'
        '• Activity and exercise tips\n'
        '• Meal planning guidance\n'
        '• Medication reminders\n'
        '• Sleep and lifestyle advice\n\n'
        'What would you like to know more about?';
  }

  /// Get suggested questions based on current health context
  /// Always rebuilds context to ensure suggestions are based on latest data
  List<String> getSuggestedQuestions() {
    // Always fetch fresh context
    final context = _buildHealthContext();
    final suggestions = <String>[];

    final latestGlucose = context['latestGlucose'];
    if (latestGlucose != null) {
      if (latestGlucose > 180) {
        suggestions.add('Why is my glucose high?');
      } else if (latestGlucose < 70) {
        suggestions.add('What should I do about low glucose?');
      }
    }

    final timeInRange = context['timeInRange7d'];
    if (timeInRange != null && timeInRange < 70) {
      suggestions.add('How can I improve my time in range?');
    }

    final activityMinutes = context['totalActivityMinutes7d'] ?? 0;
    if (activityMinutes < Environment.activityTargetWeekly) {
      suggestions.add('What exercises are best for diabetes?');
    }

    // Always offer these
    suggestions.addAll([
      'What foods should I eat?',
      'Tell me about my recent glucose trends',
      'How does exercise affect my glucose?',
    ]);

    return suggestions.take(4).toList();
  }

  /// Clear conversation history and invalidate cached context
  void clearHistory() {
    _conversationHistory.clear();
    invalidateContext();
    print('ChatbotService: Conversation history cleared and context invalidated');
  }

  /// Export conversation
  List<Map<String, dynamic>> exportConversation() {
    return _conversationHistory.map((m) => m.toJson()).toList();
  }
}
