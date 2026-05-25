/// Recommendation Models for FLORENCE Digital Health Platform
/// AI-generated health recommendations with explainability
library;

import 'package:flutter/foundation.dart';

/// Recommendation category
enum RecommendationCategory {
  meal,
  activity,
  sleep,
  medication,
  lifestyle,
  timing,
}

/// Recommendation priority
enum RecommendationPriority {
  urgent,
  high,
  medium,
  low,
}

/// Recommendation status
enum RecommendationStatus {
  active,
  completed,
  dismissed,
}

/// Health Recommendation Model
@immutable
class HealthRecommendation {
  final String id;
  final String timeframe; // 'daily' or 'weekly'
  final RecommendationCategory category;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final RecommendationStatus status;
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final RecommendationExplanation? explanation;
  final List<String> actionItems;
  final Map<String, dynamic>? dataSources; // References to triggering data

  const HealthRecommendation({
    required this.id,
    required this.timeframe,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.generatedAt,
    this.expiresAt,
    this.explanation,
    this.actionItems = const [],
    this.dataSources,
  });

  String get categoryLabel {
    switch (category) {
      case RecommendationCategory.meal:
        return 'Meal';
      case RecommendationCategory.activity:
        return 'Activity';
      case RecommendationCategory.sleep:
        return 'Sleep';
      case RecommendationCategory.medication:
        return 'Medication';
      case RecommendationCategory.lifestyle:
        return 'Lifestyle';
      case RecommendationCategory.timing:
        return 'Timing';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case RecommendationPriority.urgent:
        return 'Urgent';
      case RecommendationPriority.high:
        return 'High';
      case RecommendationPriority.medium:
        return 'Medium';
      case RecommendationPriority.low:
        return 'Low';
    }
  }

  String get statusLabel {
    switch (status) {
      case RecommendationStatus.active:
        return 'Active';
      case RecommendationStatus.completed:
        return 'Completed';
      case RecommendationStatus.dismissed:
        return 'Dismissed';
    }
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActive => status == RecommendationStatus.active && !isExpired;

  HealthRecommendation copyWith({
    String? id,
    String? timeframe,
    RecommendationCategory? category,
    String? title,
    String? description,
    RecommendationPriority? priority,
    RecommendationStatus? status,
    DateTime? generatedAt,
    DateTime? expiresAt,
    RecommendationExplanation? explanation,
    List<String>? actionItems,
    Map<String, dynamic>? dataSources,
  }) {
    return HealthRecommendation(
      id: id ?? this.id,
      timeframe: timeframe ?? this.timeframe,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      explanation: explanation ?? this.explanation,
      actionItems: actionItems ?? this.actionItems,
      dataSources: dataSources ?? this.dataSources,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeframe': timeframe,
      'category': category.name,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'explanation': explanation?.toJson(),
      'actionItems': actionItems,
      'dataSources': dataSources,
    };
  }

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) {
    return HealthRecommendation(
      id: json['id'] as String,
      timeframe: json['timeframe'] as String? ?? 'weekly',
      category: RecommendationCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: RecommendationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      status: RecommendationStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      explanation: json['explanation'] != null
          ? RecommendationExplanation.fromJson(json['explanation'])
          : null,
      actionItems: (json['actionItems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dataSources: json['dataSources'] as Map<String, dynamic>?,
    );
  }
}

/// Explanation for why a recommendation was generated
@immutable
class RecommendationExplanation {
  final String rationale; // Why this recommendation
  final List<DataPoint> triggeringData; // What data triggered it
  final List<String> evidenceLinks; // Links to relevant patterns
  final String expectedImpact; // What will improve if followed

  const RecommendationExplanation({
    required this.rationale,
    required this.triggeringData,
    this.evidenceLinks = const [],
    required this.expectedImpact,
  });

  Map<String, dynamic> toJson() {
    return {
      'rationale': rationale,
      'triggeringData': triggeringData.map((d) => d.toJson()).toList(),
      'evidenceLinks': evidenceLinks,
      'expectedImpact': expectedImpact,
    };
  }

  factory RecommendationExplanation.fromJson(Map<String, dynamic> json) {
    return RecommendationExplanation(
      rationale: json['rationale'] as String,
      triggeringData: (json['triggeringData'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      evidenceLinks: (json['evidenceLinks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      expectedImpact: json['expectedImpact'] as String,
    );
  }
}

/// Data point that triggered a recommendation
@immutable
class DataPoint {
  final String type; // e.g., "glucose_reading", "meal", "activity"
  final String description; // Human-readable description
  final String value; // The actual value
  final DateTime timestamp;

  const DataPoint({
    required this.type,
    required this.description,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      type: json['type'] as String,
      description: json['description'] as String,
      value: json['value'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Recommendation generation context
class RecommendationContext {
  final List<Map<String, dynamic>> glucoseReadings;
  final List<Map<String, dynamic>> meals;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic> summary;
  final DateTime analysisStart;
  final DateTime analysisEnd;

  RecommendationContext({
    required this.glucoseReadings,
    required this.meals,
    required this.activities,
    required this.summary,
    required this.analysisStart,
    required this.analysisEnd,
  });

  Map<String, dynamic> toJson() {
    return {
      'glucoseReadings': glucoseReadings,
      'meals': meals,
      'activities': activities,
      'summary': summary,
      'analysisStart': analysisStart.toIso8601String(),
      'analysisEnd': analysisEnd.toIso8601String(),
    };
  }
}
