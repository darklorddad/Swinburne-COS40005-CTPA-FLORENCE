/// Health Data Models for FLORENCE Digital Health Platform
/// Comprehensive data models for patient health tracking
library;

import 'package:flutter/foundation.dart';

/// Glucose Reading Model
@immutable
class GlucoseReading {
  final String id;
  final DateTime timestamp;
  final double value; // mg/dL
  final String context; // e.g., "Before breakfast", "After lunch"
  final String? notes;
  final bool isFlagged; // For abnormal readings

  const GlucoseReading({
    required this.id,
    required this.timestamp,
    required this.value,
    required this.context,
    this.notes,
    this.isFlagged = false,
  });

  bool get isHigh => value > 180;
  bool get isLow => value < 70;
  bool get isNormal => value >= 70 && value <= 180;

  String get status {
    if (isLow) return 'Low';
    if (isHigh) return 'High';
    return 'Normal';
  }

  GlucoseReading copyWith({
    String? id,
    DateTime? timestamp,
    double? value,
    String? context,
    String? notes,
    bool? isFlagged,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      value: value ?? this.value,
      context: context ?? this.context,
      notes: notes ?? this.notes,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'context': context,
      'notes': notes,
      'isFlagged': isFlagged,
    };
  }

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      context: json['context'] as String,
      notes: json['notes'] as String?,
      isFlagged: json['isFlagged'] as bool? ?? false,
    );
  }
}

/// Meal Log Model
@immutable
class MealLog {
  final String id;
  final DateTime timestamp;
  final String type; // Breakfast, Lunch, Dinner, Snack
  final String description;
  final double carbs; // grams
  final int calories;
  final double? protein; // grams
  final double? fat; // grams
  final String? photoUrl;
  final String? notes;
  final List<String> tags; // e.g., ["high-carb", "vegetarian"]

  const MealLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.description,
    required this.carbs,
    required this.calories,
    this.protein,
    this.fat,
    this.photoUrl,
    this.notes,
    this.tags = const [],
  });

  bool get isHighCarb => carbs > 60;
  bool get isLowCarb => carbs < 30;

  MealLog copyWith({
    String? id,
    DateTime? timestamp,
    String? type,
    String? description,
    double? carbs,
    int? calories,
    double? protein,
    double? fat,
    String? photoUrl,
    String? notes,
    List<String>? tags,
  }) {
    return MealLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      description: description ?? this.description,
      carbs: carbs ?? this.carbs,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'description': description,
      'carbs': carbs,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'photoUrl': photoUrl,
      'notes': notes,
      'tags': tags,
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      description: json['description'] as String,
      carbs: (json['carbs'] as num).toDouble(),
      calories: json['calories'] as int,
      protein: json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      fat: json['fat'] != null ? (json['fat'] as num).toDouble() : null,
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

/// Activity Log Model
@immutable
class ActivityLog {
  final String id;
  final DateTime timestamp;
  final String type; // Walking, Running, Cycling, etc.
  final int duration; // minutes
  final String intensity; // Low, Moderate, High
  final int? caloriesBurned;
  final double? distance; // km
  final int? steps;
  final String? notes;

  const ActivityLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.duration,
    required this.intensity,
    this.caloriesBurned,
    this.distance,
    this.steps,
    this.notes,
  });

  bool get isHighIntensity => intensity == 'High';
  bool get isLowIntensity => intensity == 'Low';

  ActivityLog copyWith({
    String? id,
    DateTime? timestamp,
    String? type,
    int? duration,
    String? intensity,
    int? caloriesBurned,
    double? distance,
    int? steps,
    String? notes,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      intensity: intensity ?? this.intensity,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distance: distance ?? this.distance,
      steps: steps ?? this.steps,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'duration': duration,
      'intensity': intensity,
      'caloriesBurned': caloriesBurned,
      'distance': distance,
      'steps': steps,
      'notes': notes,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      duration: json['duration'] as int,
      intensity: json['intensity'] as String,
      caloriesBurned: json['caloriesBurned'] as int?,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      steps: json['steps'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

/// Medication Log Model
@immutable
class MedicationLog {
  final String id;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime prescribedDate;
  final List<MedicationDose> doses;
  final String? notes;

  const MedicationLog({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.prescribedDate,
    required this.doses,
    this.notes,
  });

  double get adherenceRate {
    if (doses.isEmpty) return 0;
    final takenDoses = doses.where((d) => d.taken).length;
    return takenDoses / doses.length;
  }

  MedicationLog copyWith({
    String? id,
    String? medicationName,
    String? dosage,
    String? frequency,
    DateTime? prescribedDate,
    List<MedicationDose>? doses,
    String? notes,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      doses: doses ?? this.doses,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'prescribedDate': prescribedDate.toIso8601String(),
      'doses': doses.map((d) => d.toJson()).toList(),
      'notes': notes,
    };
  }

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      medicationName: json['medicationName'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      prescribedDate: DateTime.parse(json['prescribedDate'] as String),
      doses: (json['doses'] as List<dynamic>)
          .map((e) => MedicationDose.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }
}

/// Individual Medication Dose
@immutable
class MedicationDose {
  final String id;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool taken;
  final bool skipped;
  final String? skipReason;

  const MedicationDose({
    required this.id,
    required this.scheduledTime,
    this.takenTime,
    this.taken = false,
    this.skipped = false,
    this.skipReason,
  });

  bool get isOverdue => !taken && !skipped && DateTime.now().isAfter(scheduledTime);

  MedicationDose copyWith({
    String? id,
    DateTime? scheduledTime,
    DateTime? takenTime,
    bool? taken,
    bool? skipped,
    String? skipReason,
  }) {
    return MedicationDose(
      id: id ?? this.id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      taken: taken ?? this.taken,
      skipped: skipped ?? this.skipped,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'taken': taken,
      'skipped': skipped,
      'skipReason': skipReason,
    };
  }

  factory MedicationDose.fromJson(Map<String, dynamic> json) {
    return MedicationDose(
      id: json['id'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      takenTime: json['takenTime'] != null ? DateTime.parse(json['takenTime'] as String) : null,
      taken: json['taken'] as bool? ?? false,
      skipped: json['skipped'] as bool? ?? false,
      skipReason: json['skipReason'] as String?,
    );
  }
}

/// HbA1c Test Result Model
@immutable
class HbA1cResult {
  final String id;
  final DateTime testDate;
  final double value; // percentage
  final String? notes;
  final String? labName;

  const HbA1cResult({
    required this.id,
    required this.testDate,
    required this.value,
    this.notes,
    this.labName,
  });

  String get interpretation {
    if (value < 5.7) return 'Normal';
    if (value < 6.5) return 'Pre-diabetes';
    return 'Diabetes';
  }

  bool get isControlled => value < 7.0;

  HbA1cResult copyWith({
    String? id,
    DateTime? testDate,
    double? value,
    String? notes,
    String? labName,
  }) {
    return HbA1cResult(
      id: id ?? this.id,
      testDate: testDate ?? this.testDate,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      labName: labName ?? this.labName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testDate': testDate.toIso8601String(),
      'value': value,
      'notes': notes,
      'labName': labName,
    };
  }

  factory HbA1cResult.fromJson(Map<String, dynamic> json) {
    return HbA1cResult(
      id: json['id'] as String,
      testDate: DateTime.parse(json['testDate'] as String),
      value: (json['value'] as num).toDouble(),
      notes: json['notes'] as String?,
      labName: json['labName'] as String?,
    );
  }
}

/// Sleep Log Model
@immutable
class SleepLog {
  final String id;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int? quality; // 1-10 scale
  final String? notes;

  const SleepLog({
    required this.id,
    required this.bedTime,
    required this.wakeTime,
    this.quality,
    this.notes,
  });

  Duration get duration => wakeTime.difference(bedTime);
  int get hoursSlept => duration.inHours;

  bool get isAdequate => hoursSlept >= 7 && hoursSlept <= 9;

  SleepLog copyWith({
    String? id,
    DateTime? bedTime,
    DateTime? wakeTime,
    int? quality,
    String? notes,
  }) {
    return SleepLog(
      id: id ?? this.id,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bedTime': bedTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'quality': quality,
      'notes': notes,
    };
  }

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['id'] as String,
      bedTime: DateTime.parse(json['bedTime'] as String),
      wakeTime: DateTime.parse(json['wakeTime'] as String),
      quality: json['quality'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

/// Health Summary Aggregation
@immutable
class HealthSummary {
  final DateTime startDate;
  final DateTime endDate;
  final double averageGlucose;
  final double glucoseStdDev;
  final int totalReadings;
  final int hyperEvents; // > 180 mg/dL
  final int hypoEvents; // < 70 mg/dL
  final double timeInRange; // percentage 70-180 mg/dL
  final double estimatedA1c;
  final int totalMeals;
  final double averageCarbs;
  final int totalActivityMinutes;
  final double medicationAdherence;
  final int averageSleepHours;

  const HealthSummary({
    required this.startDate,
    required this.endDate,
    required this.averageGlucose,
    required this.glucoseStdDev,
    required this.totalReadings,
    required this.hyperEvents,
    required this.hypoEvents,
    required this.timeInRange,
    required this.estimatedA1c,
    required this.totalMeals,
    required this.averageCarbs,
    required this.totalActivityMinutes,
    required this.medicationAdherence,
    required this.averageSleepHours,
  });

  bool get isWellControlled => timeInRange >= 70 && hypoEvents < 4;

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'averageGlucose': averageGlucose,
      'glucoseStdDev': glucoseStdDev,
      'totalReadings': totalReadings,
      'hyperEvents': hyperEvents,
      'hypoEvents': hypoEvents,
      'timeInRange': timeInRange,
      'estimatedA1c': estimatedA1c,
      'totalMeals': totalMeals,
      'averageCarbs': averageCarbs,
      'totalActivityMinutes': totalActivityMinutes,
      'medicationAdherence': medicationAdherence,
      'averageSleepHours': averageSleepHours,
    };
  }

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      averageGlucose: (json['averageGlucose'] as num).toDouble(),
      glucoseStdDev: (json['glucoseStdDev'] as num).toDouble(),
      totalReadings: json['totalReadings'] as int,
      hyperEvents: json['hyperEvents'] as int,
      hypoEvents: json['hypoEvents'] as int,
      timeInRange: (json['timeInRange'] as num).toDouble(),
      estimatedA1c: (json['estimatedA1c'] as num).toDouble(),
      totalMeals: json['totalMeals'] as int,
      averageCarbs: (json['averageCarbs'] as num).toDouble(),
      totalActivityMinutes: json['totalActivityMinutes'] as int,
      medicationAdherence: (json['medicationAdherence'] as num).toDouble(),
      averageSleepHours: json['averageSleepHours'] as int,
    );
  }
}
