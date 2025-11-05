/// DeepSeek API Integration Service for FLORENCE Digital Health Platform
/// Provides AI-powered features using DeepSeek's Chat API
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/environment.dart';

/// Message role in conversation
enum MessageRole {
  system,
  user,
  assistant,
}

/// A single message in the conversation
class ChatMessage {
  final MessageRole role;
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'content': content,
    };
  }
}

/// Response from DeepSeek API
class DeepSeekResponse {
  final String content;
  final int tokensUsed;
  final String model;
  final String? finishReason;

  const DeepSeekResponse({
    required this.content,
    required this.tokensUsed,
    required this.model,
    this.finishReason,
  });

  factory DeepSeekResponse.fromJson(Map<String, dynamic> json) {
    final choice = json['choices'][0];
    return DeepSeekResponse(
      content: choice['message']['content'],
      tokensUsed: json['usage']['total_tokens'],
      model: json['model'],
      finishReason: choice['finish_reason'],
    );
  }
}

/// Service for DeepSeek API integration
class DeepSeekService {
  // Singleton pattern
  static final DeepSeekService _instance = DeepSeekService._internal();
  factory DeepSeekService() => _instance;
  DeepSeekService._internal();

  final String _apiKey = Environment.deepSeekApiKey;
  final String _baseUrl = Environment.deepSeekBaseUrl;

  /// Send a chat completion request to DeepSeek
  Future<DeepSeekResponse> chat({
    required List<ChatMessage> messages,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!Environment.enableAI) {
      throw Exception('AI features are disabled in environment configuration');
    }

    final url = Uri.parse('$_baseUrl/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model ?? Environment.aiModelChatbot,
          'messages': messages.map((m) => m.toJson()).toList(),
          'temperature': temperature ?? Environment.aiTemperature,
          'max_tokens': maxTokens ?? Environment.maxTokens,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return DeepSeekResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          'DeepSeek API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to DeepSeek API: $e');
    }
  }

  /// Generate a single-shot completion (simplified interface)
  Future<String> complete({
    required String prompt,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    final messages = <ChatMessage>[];

    if (systemPrompt != null) {
      messages.add(ChatMessage(
        role: MessageRole.system,
        content: systemPrompt,
      ));
    }

    messages.add(ChatMessage(
      role: MessageRole.user,
      content: prompt,
    ));

    final response = await chat(
      messages: messages,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    return response.content;
  }

  /// Generate health recommendations
  Future<String> generateRecommendations({
    required Map<String, dynamic> healthContext,
  }) async {
    final systemPrompt = '''
You are FLORENCE, an AI health assistant specialized in diabetes management.
Your role is to provide personalized, evidence-based recommendations to help patients manage their condition.

Guidelines:
- Be empathetic and supportive
- Provide specific, actionable advice
- Reference the patient's actual data
- Explain the "why" behind recommendations
- Prioritize safety (never replace medical advice)
- Use clear, non-technical language

Format your response as:
1. Brief observation about their recent patterns
2. 2-3 specific recommendations
3. Explanation of why these recommendations matter
''';

    final prompt = '''
Based on this patient's recent health data, provide personalized recommendations:

${_formatHealthContext(healthContext)}

Focus on the most impactful areas for improvement.
''';

    return await complete(
      prompt: prompt,
      systemPrompt: systemPrompt,
      model: Environment.aiModelRecommendations,
      temperature: 0.7,
    );
  }

  /// Analyze patterns in health data
  Future<String> analyzePatterns({
    required Map<String, dynamic> healthData,
  }) async {
    final systemPrompt = '''
You are a clinical data analyst AI specializing in diabetes pattern recognition.
Analyze health data to identify trends, anomalies, and risk factors.

Focus on:
- Glucose variability and trends
- Correlation between meals and glucose spikes
- Activity impact on glucose control
- Medication adherence patterns
- Sleep quality effects

Provide:
1. Key patterns identified
2. Risk factors
3. Positive trends to reinforce
''';

    final prompt = '''
Analyze this patient's health data for patterns and insights:

${_formatHealthContext(healthData)}

What patterns, risks, and opportunities do you see?
''';

    return await complete(
      prompt: prompt,
      systemPrompt: systemPrompt,
      model: Environment.aiModelPatternAnalysis,
      temperature: 0.3, // Lower temperature for more factual analysis
    );
  }

  /// Generate health summary
  Future<String> generateHealthSummary({
    required Map<String, dynamic> summaryData,
    required String period,
  }) async {
    final systemPrompt = '''
You are FLORENCE, a health data analyst AI.
Generate clear, concise health summaries for patients with diabetes.

Guidelines:
- Start with overall assessment (doing well, needs attention, etc.)
- Highlight key metrics and what they mean
- Note improvements or concerns
- End with encouragement and next steps
- Use patient-friendly language
''';

    final prompt = '''
Generate a $period health summary based on this data:

${_formatHealthContext(summaryData)}

Provide an encouraging yet honest assessment.
''';

    return await complete(
      prompt: prompt,
      systemPrompt: systemPrompt,
      model: Environment.aiModelRecommendations,
      temperature: 0.6,
    );
  }

  /// Chatbot conversation
  Future<String> chatbot({
    required String userMessage,
    required Map<String, dynamic> healthContext,
    List<ChatMessage>? conversationHistory,
  }) async {
    final systemPrompt = '''
You are FLORENCE, a friendly AI health assistant for diabetes management.

Patient's recent health context:
${_formatHealthContext(healthContext)}

Your role:
- Answer questions about their health data
- Provide guidance and support
- Explain diabetes management concepts
- Offer personalized tips based on their data
- Be warm, encouraging, and non-judgmental

Important:
- Never diagnose or provide medical advice
- Encourage them to consult healthcare providers for concerns
- Reference their actual data when relevant
- Keep responses concise and clear
''';

    final messages = <ChatMessage>[
      ChatMessage(role: MessageRole.system, content: systemPrompt),
    ];

    if (conversationHistory != null) {
      messages.addAll(conversationHistory);
    }

    messages.add(ChatMessage(
      role: MessageRole.user,
      content: userMessage,
    ));

    final response = await chat(
      messages: messages,
      model: Environment.aiModelChatbot,
      temperature: 0.8, // Higher temperature for more conversational tone
    );

    return response.content;
  }

  /// Generate explanation for a recommendation
  Future<String> explainRecommendation({
    required String recommendation,
    required Map<String, dynamic> dataPoints,
  }) async {
    final systemPrompt = '''
You are an AI explainer for health recommendations.
Your job is to clearly explain WHY a recommendation was made based on the patient's data.

Guidelines:
- Reference specific data points
- Explain cause and effect
- Use analogies if helpful
- Be clear and concise
- Empower the patient with understanding
''';

    final prompt = '''
Explain why this recommendation was made:

Recommendation: $recommendation

Based on this data:
${_formatHealthContext(dataPoints)}

Provide a clear, evidence-based explanation.
''';

    return await complete(
      prompt: prompt,
      systemPrompt: systemPrompt,
      temperature: 0.5,
    );
  }

  // ==================== HELPER METHODS ====================

  /// Format health context for AI prompts
  String _formatHealthContext(Map<String, dynamic> context) {
    final buffer = StringBuffer();

    context.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          buffer.writeln('$key: ${value.length} entries');
          // Show summary of list data if available
          if (value.isNotEmpty && value.first is Map) {
            buffer.writeln('  Latest: ${_summarizeItem(value.first)}');
          }
        } else if (value is Map) {
          buffer.writeln('$key:');
          value.forEach((k, v) => buffer.writeln('  $k: $v'));
        } else {
          buffer.writeln('$key: $value');
        }
      }
    });

    return buffer.toString();
  }

  String _summarizeItem(dynamic item) {
    if (item is Map) {
      return item.entries
          .take(3)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }
    return item.toString();
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      await complete(
        prompt: 'Hello, this is a connection test. Respond with "OK".',
        maxTokens: 10,
      );
      return true;
    } catch (e) {
      print('DeepSeek connection test failed: $e');
      return false;
    }
  }
}

/// Example usage:
/// ```dart
/// final deepseek = DeepSeekService();
///
/// // Simple completion
/// final response = await deepseek.complete(
///   prompt: 'What is diabetes?',
/// );
///
/// // Generate recommendations
/// final recommendations = await deepseek.generateRecommendations(
///   healthContext: {
///     'averageGlucose': 165,
///     'timeInRange': 45,
///     'recentSpikes': 8,
///   },
/// );
///
/// // Chatbot
/// final reply = await deepseek.chatbot(
///   userMessage: 'Why is my glucose high in the morning?',
///   healthContext: {...},
/// );
/// ```
