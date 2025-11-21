/// Health Summary Service for FLORENCE Digital Health Platform
/// Generates AI-powered health summaries

import '../../../../core/config/environment.dart';
import '../../../patient/core/services/data_ingestion_service.dart';
import '../../../patient/core/models/health_data_models.dart';

/// Health summary period
enum SummaryPeriod {
  daily,
  weekly,
  monthly,
  custom,
}

/// AI-generated health summary
class AISummary {
  final String id;
  final SummaryPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final String narrative; // AI-generated summary
  final HealthSummary statistics;
  final List<String> insights;
  final List<String> achievements;
  final List<String> areasForImprovement;
  final DateTime generatedAt;

  const AISummary({
    required this.id,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.narrative,
    required this.statistics,
    required this.insights,
    this.achievements = const [],
    this.areasForImprovement = const [],
    required this.generatedAt,
  });

  String get periodLabel {
    switch (period) {
      case SummaryPeriod.daily:
        return 'Daily';
      case SummaryPeriod.weekly:
        return 'Weekly';
      case SummaryPeriod.monthly:
        return 'Monthly';
      case SummaryPeriod.custom:
        return 'Custom';
    }
  }
}

/// Service for generating health summaries
class HealthSummaryService {
  final DataIngestionService _dataService = DataIngestionService();

  // Singleton pattern
  static final HealthSummaryService _instance = HealthSummaryService._internal();
  factory HealthSummaryService() => _instance;
  HealthSummaryService._internal();

  /// Generate AI-powered health summary
  Future<AISummary> generateSummary({
    required DateTime startDate,
    required DateTime endDate,
    SummaryPeriod period = SummaryPeriod.weekly,
  }) async {
    // Get health statistics
    final statistics = _dataService.getHealthSummary(
      startDate: startDate,
      endDate: endDate,
    );

    // Extract insights
    final insights = _extractInsights(statistics);
    final achievements = _extractAchievements(statistics);
    final improvements = _extractImprovements(statistics);

    String narrative;

    // AI Summary generation temporarily disabled as DeepSeekService is removed
    narrative = _generateRuleBasedNarrative(statistics, period);

    return AISummary(
      id: 'summary_${DateTime.now().millisecondsSinceEpoch}',
      period: period,
      startDate: startDate,
      endDate: endDate,
      narrative: narrative,
      statistics: statistics,
      insights: insights,
      achievements: achievements,
      areasForImprovement: improvements,
      generatedAt: DateTime.now(),
    );
  }

  /// Generate weekly summary (convenience method)
  Future<AISummary> generateWeeklySummary() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    return generateSummary(
      startDate: startDate,
      endDate: endDate,
      period: SummaryPeriod.weekly,
    );
  }

  /// Generate monthly summary
  Future<AISummary> generateMonthlySummary() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    return generateSummary(
      startDate: startDate,
      endDate: endDate,
      period: SummaryPeriod.monthly,
    );
  }

  /// Generate rule-based narrative
  String _generateRuleBasedNarrative(HealthSummary stats, SummaryPeriod period) {
    final buffer = StringBuffer();

    // Overall assessment
    final overallScore = _calculateOverallScore(stats);
    if (overallScore >= 80) {
      buffer.writeln('Great ${period.name} performance! Your diabetes management is on track.');
    } else if (overallScore >= 60) {
      buffer.writeln('Good ${period.name} progress with room for improvement.');
    } else {
      buffer.writeln('This ${period.name} shows areas that need attention.');
    }

    buffer.writeln();

    // Glucose control
    if (stats.timeInRange >= 70) {
      buffer.writeln('✓ Excellent glucose control with ${stats.timeInRange.toStringAsFixed(0)}% time in range.');
    } else if (stats.timeInRange >= 50) {
      buffer.writeln('• Time in range at ${stats.timeInRange.toStringAsFixed(0)}% - working towards 70% goal.');
    } else {
      buffer.writeln('⚠ Time in range is ${stats.timeInRange.toStringAsFixed(0)}%. Focus on consistent carb portions and timing.');
    }

    // Activity
    if (stats.totalActivityMinutes >= 150) {
      buffer.writeln('✓ Met activity goal with ${stats.totalActivityMinutes} minutes!');
    } else {
      buffer.writeln('• Activity: ${stats.totalActivityMinutes} minutes. Aim for 150 minutes/week.');
    }

    // Medication adherence
    if (stats.medicationAdherence >= 0.9) {
      buffer.writeln('✓ Excellent medication adherence.');
    } else if (stats.medicationAdherence >= 0.8) {
      buffer.writeln('• Good medication adherence. Stay consistent!');
    } else {
      buffer.writeln('⚠ Medication adherence needs attention. Consider setting reminders.');
    }

    return buffer.toString();
  }

  /// Extract insights from data
  List<String> _extractInsights(HealthSummary stats) {
    final insights = <String>[];

    // Glucose patterns
    if (stats.hyperEvents > stats.hypoEvents * 2) {
      insights.add('More high than low events - consider reducing carb portions');
    } else if (stats.hypoEvents > 3) {
      insights.add('Frequent low glucose - discuss medication timing with doctor');
    }

    // Variability
    if (stats.glucoseStdDev > 50) {
      insights.add('High glucose variability - more consistent meal timing may help');
    } else {
      insights.add('Good glucose stability');
    }

    // Activity correlation
    if (stats.totalActivityMinutes > Environment.activityTargetWeekly &&
        stats.timeInRange > 70) {
      insights.add('Your activity is positively impacting glucose control');
    }

    // Estimated A1c
    if (stats.estimatedA1c < 7.0) {
      insights.add('Estimated A1c (${stats.estimatedA1c.toStringAsFixed(1)}%) is at target!');
    } else {
      insights.add('Estimated A1c is ${stats.estimatedA1c.toStringAsFixed(1)}% - room for improvement');
    }

    return insights;
  }

  /// Extract achievements
  List<String> _extractAchievements(HealthSummary stats) {
    final achievements = <String>[];

    if (stats.timeInRange >= 70) {
      achievements.add('70%+ Time in Range');
    }

    if (stats.hypoEvents == 0) {
      achievements.add('Zero Hypoglycemia Events');
    }

    if (stats.medicationAdherence >= 0.95) {
      achievements.add('Outstanding Medication Adherence');
    }

    if (stats.totalActivityMinutes >= 150) {
      achievements.add('Met Weekly Activity Goal');
    }

    if (stats.averageSleepHours >= 7 && stats.averageSleepHours <= 9) {
      achievements.add('Healthy Sleep Duration');
    }

    return achievements;
  }

  /// Extract areas for improvement
  List<String> _extractImprovements(HealthSummary stats) {
    final improvements = <String>[];

    if (stats.timeInRange < 70) {
      improvements.add('Increase time in range (currently ${stats.timeInRange.toStringAsFixed(0)}%)');
    }

    if (stats.totalActivityMinutes < 150) {
      improvements.add('Add ${150 - stats.totalActivityMinutes} more minutes of activity');
    }

    if (stats.medicationAdherence < 0.8) {
      improvements.add('Improve medication consistency');
    }

    if (stats.glucoseStdDev > 50) {
      improvements.add('Reduce glucose variability through consistent timing');
    }

    if (stats.averageSleepHours < 7) {
      improvements.add('Increase sleep to 7-9 hours nightly');
    }

    return improvements;
  }

  /// Calculate overall performance score
  int _calculateOverallScore(HealthSummary stats) {
    int score = 0;

    // Time in range (0-30 points)
    if (stats.timeInRange >= 70) score += 30;
    else if (stats.timeInRange >= 50) score += 20;
    else score += 10;

    // Hypo events (0-20 points)
    if (stats.hypoEvents == 0) score += 20;
    else if (stats.hypoEvents <= 2) score += 15;
    else if (stats.hypoEvents <= 5) score += 10;

    // Activity (0-20 points)
    if (stats.totalActivityMinutes >= 150) score += 20;
    else if (stats.totalActivityMinutes >= 150 * 0.7) score += 15;
    else score += 5;

    // Medication adherence (0-20 points)
    if (stats.medicationAdherence >= 0.9) score += 20;
    else if (stats.medicationAdherence >= 0.8) score += 15;
    else if (stats.medicationAdherence >= 0.7) score += 10;

    // Variability (0-10 points)
    if (stats.glucoseStdDev <= 40) score += 10;
    else if (stats.glucoseStdDev <= 50) score += 7;
    else score += 3;

    return score;
  }
}
