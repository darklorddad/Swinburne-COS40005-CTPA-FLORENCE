import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _apiToken = "";
  static const String _apiUrl = "https://llm.chutes.ai/v1/chat/completions";
  static const String _model = "deepseek-ai/DeepSeek-V3.1";

  /// Generate personalized health recommendations using DeepSeek AI
  static Future<String> generateHealthRecommendation({
    required Map<String, dynamic> healthData,
    required String patientProfile,
    required String recommendationType,
  }) async {
    try {
      final prompt = _buildRecommendationPrompt(
        healthData: healthData,
        patientProfile: patientProfile,
        recommendationType: recommendationType,
      );

      final response = await _makeApiCall(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to generate health recommendation: $e');
    }
  }

  /// Generate AI explanation for health trends and anomalies
  static Future<String> explainHealthPattern({
    required Map<String, dynamic> healthData,
    required String patternType,
    required String patientProfile,
  }) async {
    try {
      final prompt = _buildExplanationPrompt(
        healthData: healthData,
        patternType: patternType,
        patientProfile: patientProfile,
      );

      final response = await _makeApiCall(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to generate health pattern explanation: $e');
    }
  }

  /// Generate chatbot response for patient questions
  static Future<String> generateChatbotResponse({
    required String userMessage,
    required Map<String, dynamic> patientContext,
    required String conversationHistory,
  }) async {
    try {
      final prompt = _buildChatbotPrompt(
        userMessage: userMessage,
        patientContext: patientContext,
        conversationHistory: conversationHistory,
      );

      final response = await _makeApiCall(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to generate chatbot response: $e');
    }
  }

  /// Generate weekly health summary
  static Future<String> generateWeeklySummary({
    required Map<String, dynamic> weeklyData,
    required String patientProfile,
  }) async {
    try {
      final prompt = _buildWeeklySummaryPrompt(
        weeklyData: weeklyData,
        patientProfile: patientProfile,
      );

      final response = await _makeApiCall(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to generate weekly summary: $e');
    }
  }

  /// Generate motivational messages based on patient activity
  static Future<String> generateMotivationalMessage({
    required Map<String, dynamic> activityData,
    required String patientProfile,
  }) async {
    try {
      final prompt = _buildMotivationalPrompt(
        activityData: activityData,
        patientProfile: patientProfile,
      );

      final response = await _makeApiCall(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to generate motivational message: $e');
    }
  }

  /// Make API call to DeepSeek
  static Future<String> _makeApiCall(String prompt) async {
    final headers = {
      'Authorization': 'Bearer $_apiToken',
      'Content-Type': 'application/json',
    };

    final body = {
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'max_tokens': 1024,
      'temperature': 0.7,
    };

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('API call failed with status: ${response.statusCode}');
    }
  }

  /// Build prompt for health recommendations
  static String _buildRecommendationPrompt({
    required Map<String, dynamic> healthData,
    required String patientProfile,
    required String recommendationType,
  }) {
    return '''
You are an AI health assistant specializing in diabetes and chronic disease management. 
Generate a personalized health recommendation based on the following data:

PATIENT PROFILE:
$patientProfile

CURRENT HEALTH DATA:
${json.encode(healthData)}

RECOMMENDATION TYPE: $recommendationType

Please provide:
1. A specific, actionable recommendation
2. A clear explanation of why this recommendation is important
3. Expected benefits
4. Any precautions or considerations

Keep the response concise (150-200 words) and encouraging. Focus on practical, achievable actions.
''';
  }

  /// Build prompt for health pattern explanations
  static String _buildExplanationPrompt({
    required Map<String, dynamic> healthData,
    required String patternType,
    required String patientProfile,
  }) {
    return '''
You are an AI health assistant. Explain the following health pattern in simple, understandable terms:

PATIENT PROFILE:
$patientProfile

HEALTH DATA:
${json.encode(healthData)}

PATTERN TYPE: $patternType

Provide:
1. What this pattern means
2. Why it might be happening
3. What the patient should know
4. When to seek medical attention

Use clear, non-technical language. Keep it under 150 words.
''';
  }

  /// Build prompt for chatbot responses
  static String _buildChatbotPrompt({
    required String userMessage,
    required Map<String, dynamic> patientContext,
    required String conversationHistory,
  }) {
    return '''
You are a helpful AI health assistant for diabetes and chronic disease management. 
Respond to the patient's question in a supportive, informative way.

PATIENT CONTEXT:
${json.encode(patientContext)}

CONVERSATION HISTORY:
$conversationHistory

PATIENT'S QUESTION: $userMessage

Guidelines:
- Be empathetic and supportive
- Provide accurate health information
- Encourage consulting healthcare providers for medical decisions
- Keep responses concise (100-150 words)
- Use encouraging language
- If unsure, recommend consulting their doctor
''';
  }

  /// Build prompt for weekly health summaries
  static String _buildWeeklySummaryPrompt({
    required Map<String, dynamic> weeklyData,
    required String patientProfile,
  }) {
    return '''
You are an AI health assistant. Create a personalized weekly health summary:

PATIENT PROFILE:
$patientProfile

WEEKLY DATA:
${json.encode(weeklyData)}

Provide:
1. Key highlights from the week
2. Areas of improvement
3. Areas that need attention
4. Encouragement and motivation
5. Goals for next week

Keep it positive and motivating (200-250 words). Focus on progress and actionable next steps.
''';
  }

  /// Build prompt for motivational messages
  static String _buildMotivationalPrompt({
    required Map<String, dynamic> activityData,
    required String patientProfile,
  }) {
    return '''
You are an AI health coach. Create a motivational message based on the patient's activity data:

PATIENT PROFILE:
$patientProfile

ACTIVITY DATA:
${json.encode(activityData)}

Create an encouraging message that:
1. Acknowledges their efforts
2. Provides gentle motivation
3. Suggests achievable next steps
4. Maintains a positive tone

Keep it brief (100-120 words) and personalized to their current activity level.
''';
  }
}
