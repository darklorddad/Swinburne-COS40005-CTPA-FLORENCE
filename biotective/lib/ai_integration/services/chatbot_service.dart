import '../models/health_data.dart';
import 'deepseek_service.dart';

class ChatbotService {
  static final Map<String, List<ChatMessage>> _conversationHistory = {};

  /// Process user message and generate AI response
  static Future<ChatMessage> processMessage({
    required String patientId,
    required String userMessage,
    required PatientProfile patientProfile,
    required List<HealthData> recentData,
  }) async {
    // Create user message
    final userChatMessage = ChatMessage(
      id: _generateId(),
      patientId: patientId,
      timestamp: DateTime.now(),
      message: userMessage,
      isFromUser: true,
    );

    // Add to conversation history
    _addToHistory(patientId, userChatMessage);

    // Generate AI response
    final aiResponse = await _generateResponse(
      patientId: patientId,
      userMessage: userMessage,
      patientProfile: patientProfile,
      recentData: recentData,
    );

    // Create AI message
    final aiChatMessage = ChatMessage(
      id: _generateId(),
      patientId: patientId,
      timestamp: DateTime.now(),
      message: aiResponse,
      isFromUser: false,
      aiResponse: aiResponse,
      context: {
        'patientProfile': patientProfile.toJson(),
        'recentDataCount': recentData.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Add to conversation history
    _addToHistory(patientId, aiChatMessage);

    return aiChatMessage;
  }

  /// Generate AI response based on user message and context
  static Future<String> _generateResponse({
    required String patientId,
    required String userMessage,
    required PatientProfile patientProfile,
    required List<HealthData> recentData,
  }) async {
    try {
      // Prepare patient context
      final patientContext = _preparePatientContext(patientProfile, recentData);
      
      // Get conversation history
      final conversationHistory = _getConversationHistory(patientId);

      // Generate response using DeepSeek
      final response = await DeepSeekService.generateChatbotResponse(
        userMessage: userMessage,
        patientContext: patientContext,
        conversationHistory: conversationHistory,
      );

      return response;
    } catch (e) {
      return _getFallbackResponse(userMessage);
    }
  }

  /// Prepare patient context for AI processing
  static Map<String, dynamic> _preparePatientContext(
    PatientProfile patientProfile,
    List<HealthData> recentData,
  ) {
    // Calculate recent health metrics
    final glucoseReadings = recentData.where((d) => d.glucoseLevel != null).map((d) => d.glucoseLevel!).toList();
    final activityData = recentData.where((d) => d.steps != null).map((d) => d.steps!).toList();
    final sleepData = recentData.where((d) => d.sleepHours != null).map((d) => d.sleepHours!).toList();

    return {
      'patientProfile': {
        'name': patientProfile.name,
        'age': patientProfile.age,
        'gender': patientProfile.gender,
        'diabetesType': patientProfile.diabetesType,
        'medications': patientProfile.medications,
        'riskLevel': patientProfile.riskLevel,
      },
      'recentHealthMetrics': {
        'avgGlucose': glucoseReadings.isNotEmpty ? glucoseReadings.reduce((a, b) => a + b) / glucoseReadings.length : null,
        'maxGlucose': glucoseReadings.isNotEmpty ? glucoseReadings.reduce((a, b) => a > b ? a : b) : null,
        'minGlucose': glucoseReadings.isNotEmpty ? glucoseReadings.reduce((a, b) => a < b ? a : b) : null,
        'avgSteps': activityData.isNotEmpty ? activityData.reduce((a, b) => a + b) / activityData.length : null,
        'avgSleep': sleepData.isNotEmpty ? sleepData.reduce((a, b) => a + b) / sleepData.length : null,
        'dataPoints': recentData.length,
      },
      'lastUpdate': recentData.isNotEmpty ? recentData.last.timestamp.toIso8601String() : null,
    };
  }

  /// Get conversation history for context
  static String _getConversationHistory(String patientId) {
    final history = _conversationHistory[patientId] ?? [];
    
    if (history.isEmpty) return 'No previous conversation.';
    
    // Get last 5 messages for context
    final recentHistory = history.take(5).toList();
    
    return recentHistory.map((msg) {
      final role = msg.isFromUser ? 'Patient' : 'Assistant';
      return '$role: ${msg.message}';
    }).join('\n');
  }

  /// Add message to conversation history
  static void _addToHistory(String patientId, ChatMessage message) {
    _conversationHistory.putIfAbsent(patientId, () => []).add(message);
    
    // Keep only last 20 messages to prevent memory issues
    if (_conversationHistory[patientId]!.length > 20) {
      _conversationHistory[patientId]!.removeAt(0);
    }
  }

  /// Get fallback response when AI fails
  static String _getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('glucose') || message.contains('blood sugar')) {
      return 'I understand you\'re asking about glucose levels. For specific medical advice about your blood sugar, please consult with your healthcare provider. I can help you understand general diabetes management principles.';
    }
    
    if (message.contains('medication') || message.contains('medicine')) {
      return 'Medication questions are important. Please discuss any medication concerns with your doctor or pharmacist. They can provide the most accurate and personalized advice for your situation.';
    }
    
    if (message.contains('exercise') || message.contains('activity') || message.contains('walk')) {
      return 'Regular physical activity is great for diabetes management! The American Diabetes Association recommends at least 150 minutes of moderate exercise per week. Start slowly and gradually increase your activity level.';
    }
    
    if (message.contains('diet') || message.contains('food') || message.contains('eat')) {
      return 'A balanced diet is crucial for diabetes management. Focus on whole grains, lean proteins, vegetables, and limit processed foods and added sugars. Consider working with a dietitian for personalized meal planning.';
    }
    
    if (message.contains('sleep') || message.contains('tired')) {
      return 'Good sleep is important for overall health and blood sugar control. Aim for 7-9 hours of quality sleep per night. If you\'re having sleep issues, discuss this with your healthcare provider.';
    }
    
    if (message.contains('stress') || message.contains('anxiety')) {
      return 'Stress can affect blood sugar levels. Try relaxation techniques like deep breathing, meditation, or gentle exercise. If stress is significantly impacting your life, consider speaking with a mental health professional.';
    }
    
    if (message.contains('emergency') || message.contains('urgent') || message.contains('help')) {
      return 'If you\'re experiencing a medical emergency, please call emergency services immediately. For urgent but non-emergency concerns, contact your healthcare provider or go to the nearest urgent care center.';
    }
    
    return 'I\'m here to help with general diabetes management questions. For specific medical advice, please consult with your healthcare provider. How can I assist you today?';
  }

  /// Get conversation history for a patient
  static List<ChatMessage> getConversationHistory(String patientId) {
    return _conversationHistory[patientId] ?? [];
  }

  /// Clear conversation history for a patient
  static void clearConversationHistory(String patientId) {
    _conversationHistory.remove(patientId);
  }

  /// Get suggested questions based on patient profile
  static List<String> getSuggestedQuestions(PatientProfile patientProfile) {
    final suggestions = <String>[];
    
    switch (patientProfile.diabetesType) {
      case 'type1':
        suggestions.addAll([
          'How often should I check my blood glucose?',
          'What are the signs of low blood sugar?',
          'How do I adjust my insulin for exercise?',
          'What should I eat before exercising?',
        ]);
        break;
      case 'type2':
        suggestions.addAll([
          'How can I improve my blood sugar control?',
          'What foods should I avoid?',
          'How much exercise do I need?',
          'When should I take my medication?',
        ]);
        break;
      case 'prediabetes':
        suggestions.addAll([
          'How can I prevent diabetes?',
          'What lifestyle changes should I make?',
          'How often should I monitor my blood sugar?',
          'What are the warning signs of diabetes?',
        ]);
        break;
      default:
        suggestions.addAll([
          'What are the benefits of regular exercise?',
          'How can I maintain a healthy diet?',
          'What are the signs of diabetes?',
          'How can I improve my overall health?',
        ]);
    }
    
    return suggestions;
  }

  /// Generate unique ID
  static String _generateId() {
    return 'chat_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
