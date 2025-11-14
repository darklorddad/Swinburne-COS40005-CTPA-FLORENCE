/// AI-Powered Recommendation Engine for FLORENCE Digital Health Platform
/// Generates personalized health recommendations using DeepSeek AI

import 'dart:convert';
import '../../../../core/services/ai/deepseek_service.dart';
import '../../../../core/config/environment.dart';
import '../../../patient/core/models/health_data_models.dart';
import '../../../patient/core/services/data_ingestion_service.dart';
import '../models/recommendation_models.dart';

/// Service for generating AI-powered health recommendations
class RecommendationEngine {
  final DeepSeekService _deepseek = DeepSeekService();
  final DataIngestionService _dataService = DataIngestionService();

  // Singleton pattern
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  // Cache of generated recommendations
  final List<HealthRecommendation> _recommendations = [];

  List<HealthRecommendation> get allRecommendations =>
      List.unmodifiable(_recommendations);

  List<HealthRecommendation> get activeRecommendations =>
      _recommendations.where((r) => r.isActive).toList();

  /// Generate new recommendations based on recent health data
  Future<List<HealthRecommendation>> generateRecommendations({
    int daysToAnalyze = 7,
  }) async {
    if (!Environment.enableAI) {
      return _generateRuleBasedRecommendations();
    }

    try {
      // Gather health data for analysis
      final context = _buildRecommendationContext(daysToAnalyze);

      // Generate AI recommendations
      final aiRecommendations = await _generateAIRecommendations(context);

      // Save to cache
      _recommendations.addAll(aiRecommendations);

      return aiRecommendations;
    } catch (e) {
      print('Error generating AI recommendations: $e');
      // Fallback to rule-based recommendations
      return _generateRuleBasedRecommendations();
    }
  }

  /// Build context for AI recommendation generation
  RecommendationContext _buildRecommendationContext(int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final glucose = _dataService.getGlucoseReadings(
      startDate: startDate,
      endDate: endDate,
    );

    final meals = _dataService.getMeals(
      startDate: startDate,
      endDate: endDate,
    );

    final activities = _dataService.getActivities(
      startDate: startDate,
      endDate: endDate,
    );

    final summary = _dataService.getHealthSummary(
      startDate: startDate,
      endDate: endDate,
    );

    return RecommendationContext(
      glucoseReadings: glucose.map((g) => g.toJson()).toList(),
      meals: meals.map((m) => m.toJson()).toList(),
      activities: activities.map((a) => a.toJson()).toList(),
      summary: summary.toJson(),
      analysisStart: startDate,
      analysisEnd: endDate,
    );
  }

  /// Generate AI-powered recommendations
  Future<List<HealthRecommendation>> _generateAIRecommendations(
    RecommendationContext context,
  ) async {
    final healthContext = {
      'period': '${context.analysisStart.day}/${context.analysisStart.month} - ${context.analysisEnd.day}/${context.analysisEnd.month}',
      'averageGlucose': context.summary['averageGlucose'],
      'timeInRange': context.summary['timeInRange'],
      'hyperEvents': context.summary['hyperEvents'],
      'hypoEvents': context.summary['hypoEvents'],
      'glucoseVariability': context.summary['glucoseStdDev'],
      'totalMeals': context.meals.length,
      'averageCarbs': context.summary['averageCarbs'],
      'totalActivityMinutes': context.summary['totalActivityMinutes'],
      'medicationAdherence': context.summary['medicationAdherence'],
      'averageSleep': context.summary['averageSleepHours'],
    };

    // Get AI recommendations
    final aiResponse = await _deepseek.generateRecommendations(
      healthContext: healthContext,
    );

    // Parse AI response into structured recommendations
    return _parseAIRecommendations(aiResponse, context);
  }

  /// Parse AI response into structured recommendation objects
  List<HealthRecommendation> _parseAIRecommendations(
    String aiResponse,
    RecommendationContext context,
  ) {
    final recommendations = <HealthRecommendation>[];
    final summary = context.summary;

    // Analyze AI response and create structured recommendations
    // This is a simplified parser - in production, you might use more sophisticated NLP

    final lines = aiResponse.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // Extract key insights from AI response
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Meal recommendations
      if (line.contains('carb') || line.contains('meal') || line.contains('food')) {
        recommendations.add(_createMealRecommendation(
          aiResponse,
          summary,
          context,
        ));
      }

      // Activity recommendations
      if (line.contains('activity') || line.contains('exercise') || line.contains('walk')) {
        recommendations.add(_createActivityRecommendation(
          aiResponse,
          summary,
          context,
        ));
      }

      // Sleep recommendations
      if (line.contains('sleep')) {
        recommendations.add(_createSleepRecommendation(
          aiResponse,
          summary,
          context,
        ));
      }

      // Medication recommendations
      if (line.contains('medication') || line.contains('adherence')) {
        recommendations.add(_createMedicationRecommendation(
          aiResponse,
          summary,
          context,
        ));
      }
    }

    // If no specific recommendations found, create general one
    if (recommendations.isEmpty) {
      recommendations.add(_createGeneralRecommendation(aiResponse, context));
    }

    return recommendations.take(5).toList(); // Limit to top 5
  }

  /// Create meal recommendation
  HealthRecommendation _createMealRecommendation(
    String aiResponse,
    Map<String, dynamic> summary,
    RecommendationContext context,
  ) {
    final avgCarbs = summary['averageCarbs'] as double;
    final priority = avgCarbs > 80 ? RecommendationPriority.high : RecommendationPriority.medium;

    return HealthRecommendation(
      id: 'rec_meal_${DateTime.now().millisecondsSinceEpoch}',
      category: RecommendationCategory.meal,
      title: 'Optimize Carbohydrate Intake',
      description: _extractRelevantSection(aiResponse, ['carb', 'meal', 'food']),
      priority: priority,
      status: RecommendationStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      actionItems: [
        'Track carbs at each meal',
        'Choose low-glycemic foods',
        'Spread carbs throughout the day',
      ],
      explanation: RecommendationExplanation(
        rationale: 'Your average daily carb intake is ${avgCarbs.toStringAsFixed(0)}g, which impacts glucose levels.',
        triggeringData: [
          DataPoint(
            type: 'carb_average',
            description: 'Average daily carbs',
            value: '${avgCarbs.toStringAsFixed(0)}g',
            timestamp: DateTime.now(),
          ),
        ],
        evidenceLinks: ['meal_logs', 'glucose_spikes'],
        expectedImpact: 'Better carb management can improve time-in-range by 10-15%',
      ),
    );
  }

  /// Create activity recommendation
  HealthRecommendation _createActivityRecommendation(
    String aiResponse,
    Map<String, dynamic> summary,
    RecommendationContext context,
  ) {
    final activityMinutes = summary['totalActivityMinutes'] as int;
    final weeklyTarget = Environment.activityTargetWeekly;
    final priority = activityMinutes < weeklyTarget / 2
        ? RecommendationPriority.high
        : RecommendationPriority.medium;

    return HealthRecommendation(
      id: 'rec_activity_${DateTime.now().millisecondsSinceEpoch}',
      category: RecommendationCategory.activity,
      title: 'Increase Physical Activity',
      description: _extractRelevantSection(aiResponse, ['activity', 'exercise', 'walk']),
      priority: priority,
      status: RecommendationStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      actionItems: [
        '30 minutes of moderate activity daily',
        'Walk after meals to lower glucose',
        'Track your activity consistently',
      ],
      explanation: RecommendationExplanation(
        rationale: 'You logged $activityMinutes minutes of activity this week. Target is $weeklyTarget minutes/week.',
        triggeringData: [
          DataPoint(
            type: 'activity_total',
            description: 'Weekly activity',
            value: '$activityMinutes minutes',
            timestamp: DateTime.now(),
          ),
        ],
        evidenceLinks: ['activity_logs', 'glucose_response'],
        expectedImpact: 'Regular activity can lower average glucose by 15-20 mg/dL',
      ),
    );
  }

  /// Create sleep recommendation
  HealthRecommendation _createSleepRecommendation(
    String aiResponse,
    Map<String, dynamic> summary,
    RecommendationContext context,
  ) {
    final avgSleep = summary['averageSleepHours'] as int;
    final priority = avgSleep < 6
        ? RecommendationPriority.high
        : RecommendationPriority.low;

    return HealthRecommendation(
      id: 'rec_sleep_${DateTime.now().millisecondsSinceEpoch}',
      category: RecommendationCategory.sleep,
      title: 'Improve Sleep Quality',
      description: _extractRelevantSection(aiResponse, ['sleep']),
      priority: priority,
      status: RecommendationStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      actionItems: [
        'Aim for 7-9 hours per night',
        'Maintain consistent sleep schedule',
        'Avoid screens before bedtime',
      ],
      explanation: RecommendationExplanation(
        rationale: 'You\'re averaging $avgSleep hours of sleep. Poor sleep affects glucose control.',
        triggeringData: [
          DataPoint(
            type: 'sleep_average',
            description: 'Average sleep duration',
            value: '$avgSleep hours',
            timestamp: DateTime.now(),
          ),
        ],
        evidenceLinks: ['sleep_logs', 'morning_glucose'],
        expectedImpact: 'Better sleep can reduce morning glucose spikes by 10-15%',
      ),
    );
  }

  /// Create medication recommendation
  HealthRecommendation _createMedicationRecommendation(
    String aiResponse,
    Map<String, dynamic> summary,
    RecommendationContext context,
  ) {
    final adherence = (summary['medicationAdherence'] as double) * 100;
    final priority = adherence < 80
        ? RecommendationPriority.urgent
        : RecommendationPriority.medium;

    return HealthRecommendation(
      id: 'rec_medication_${DateTime.now().millisecondsSinceEpoch}',
      category: RecommendationCategory.medication,
      title: 'Improve Medication Adherence',
      description: _extractRelevantSection(aiResponse, ['medication', 'adherence']),
      priority: priority,
      status: RecommendationStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      actionItems: [
        'Set medication reminders',
        'Use a pill organizer',
        'Take at the same time daily',
      ],
      explanation: RecommendationExplanation(
        rationale: 'Your medication adherence is ${adherence.toStringAsFixed(0)}%. Consistent medication is crucial.',
        triggeringData: [
          DataPoint(
            type: 'medication_adherence',
            description: 'Adherence rate',
            value: '${adherence.toStringAsFixed(0)}%',
            timestamp: DateTime.now(),
          ),
        ],
        evidenceLinks: ['medication_logs', 'glucose_control'],
        expectedImpact: 'Consistent medication can improve HbA1c by 0.5-1.0%',
      ),
    );
  }

  /// Create general recommendation
  HealthRecommendation _createGeneralRecommendation(
    String aiResponse,
    RecommendationContext context,
  ) {
    return HealthRecommendation(
      id: 'rec_general_${DateTime.now().millisecondsSinceEpoch}',
      category: RecommendationCategory.lifestyle,
      title: 'Continue Your Great Progress',
      description: aiResponse.length > 200 ? aiResponse.substring(0, 200) : aiResponse,
      priority: RecommendationPriority.medium,
      status: RecommendationStatus.active,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      actionItems: [
        'Keep tracking your health data',
        'Maintain healthy habits',
        'Review your trends regularly',
      ],
    );
  }

  /// Extract relevant section from AI response
  String _extractRelevantSection(String response, List<String> keywords) {
    final sentences = response.split('.');
    for (var sentence in sentences) {
      for (var keyword in keywords) {
        if (sentence.toLowerCase().contains(keyword)) {
          return sentence.trim() + '.';
        }
      }
    }
    // Return first sentence if no keyword match
    return sentences.isNotEmpty ? sentences.first.trim() + '.' : response;
  }

  /// Generate rule-based recommendations (fallback)
  List<HealthRecommendation> _generateRuleBasedRecommendations() {
    final recommendations = <HealthRecommendation>[];
    final summary = _dataService.getHealthSummary(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    );

    // High glucose
    if (summary.averageGlucose > Environment.glucoseHigh) {
      recommendations.add(HealthRecommendation(
        id: 'rec_glucose_high_${DateTime.now().millisecondsSinceEpoch}',
        category: RecommendationCategory.meal,
        title: 'Reduce Average Glucose',
        description: 'Your average glucose is ${summary.averageGlucose.toStringAsFixed(0)} mg/dL. Let\'s work on bringing it down.',
        priority: RecommendationPriority.high,
        status: RecommendationStatus.active,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        actionItems: [
          'Monitor carb portions',
          'Increase fiber intake',
          'Walk 10 mins after meals',
        ],
      ));
    }

    // Low activity
    if (summary.totalActivityMinutes < 150) {
      recommendations.add(HealthRecommendation(
        id: 'rec_activity_low_${DateTime.now().millisecondsSinceEpoch}',
        category: RecommendationCategory.activity,
        title: 'Increase Physical Activity',
        description: 'You logged ${summary.totalActivityMinutes} minutes this week. Aim for 150 minutes.',
        priority: RecommendationPriority.medium,
        status: RecommendationStatus.active,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        actionItems: [
          'Start with 10-minute walks',
          'Try post-meal walking',
          'Gradually increase duration',
        ],
      ));
    }

    _recommendations.addAll(recommendations);
    return recommendations;
  }

  /// Explain a specific recommendation
  Future<String> explainRecommendation(HealthRecommendation recommendation) async {
    if (!Environment.enableAI) {
      return recommendation.explanation?.rationale ?? 'No explanation available';
    }

    try {
      final dataPoints = {
        'recommendation': recommendation.title,
        'category': recommendation.categoryLabel,
        'triggeringData': recommendation.explanation?.triggeringData
            .map((d) => '${d.description}: ${d.value}')
            .join(', '),
      };

      return await _deepseek.explainRecommendation(
        recommendation: recommendation.description,
        dataPoints: dataPoints,
      );
    } catch (e) {
      return recommendation.explanation?.rationale ?? 'Unable to generate explanation';
    }
  }

  /// Mark recommendation as completed
  void completeRecommendation(String id) {
    final index = _recommendations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recommendations[index] = _recommendations[index].copyWith(
        status: RecommendationStatus.completed,
      );
    }
  }

  /// Dismiss recommendation
  void dismissRecommendation(String id) {
    final index = _recommendations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recommendations[index] = _recommendations[index].copyWith(
        status: RecommendationStatus.dismissed,
      );
    }
  }

  /// Clear all recommendations
  void clearRecommendations() {
    _recommendations.clear();
  }
}
