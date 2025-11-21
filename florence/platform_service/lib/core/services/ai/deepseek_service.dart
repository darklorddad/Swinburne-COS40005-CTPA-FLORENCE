/// DeepSeek API Integration Service - DEPRECATED
/// 
/// This service has been replaced by the Python Chatbot Service.
/// This file is kept as a stub to prevent compilation errors in legacy code
/// that hasn't been refactored yet.
/// 
/// TODO: Remove this file once all references in HealthDataProvider are removed.
library;

class ChatMessage {
  final dynamic role;
  final String content;
  const ChatMessage({required this.role, required this.content});
  Map<String, dynamic> toJson() => {};
}

class DeepSeekResponse {
  final String content;
  const DeepSeekResponse({required this.content});
}

class DeepSeekService {
  static final DeepSeekService _instance = DeepSeekService._internal();
  factory DeepSeekService() => _instance;
  DeepSeekService._internal();

  Future<DeepSeekResponse> chat({
    required List<ChatMessage> messages,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    return const DeepSeekResponse(content: "AI Service is migrating. Please update your app.");
  }

  Future<String> complete({
    required String prompt,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    return "AI Service is migrating. Please update your app.";
  }

  Future<String> generateRecommendations({
    required Map<String, dynamic> healthContext,
  }) async {
    return "Recommendations are currently unavailable during system upgrade.";
  }

  Future<String> analyzePatterns({
    required Map<String, dynamic> healthData,
  }) async {
    return "Pattern analysis is currently unavailable during system upgrade.";
  }

  Future<String> generateHealthSummary({
    required Map<String, dynamic> summaryData,
    required String period,
  }) async {
    return "Health summary is currently unavailable during system upgrade.";
  }

  Future<String> chatbot({
    required String userMessage,
    required Map<String, dynamic> healthContext,
    List<ChatMessage>? conversationHistory,
  }) async {
    return "I am currently undergoing maintenance. Please try again later.";
  }

  Future<String> explainRecommendation({
    required String recommendation,
    required Map<String, dynamic> dataPoints,
  }) async {
    return "Explanation unavailable.";
  }

  Future<bool> testConnection() async {
    return false;
  }
}
