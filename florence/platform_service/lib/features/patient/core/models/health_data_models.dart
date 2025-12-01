/// Health Data Models for FLORENCE Digital Health Platform
/// Comprehensive data models for patient health tracking

import 'package:flutter/foundation.dart';

// ============================================================================
// NEW MODELS (MATCHING PYTHON BACKEND)
// ============================================================================

/// Monitor Data Type Enum (Strictly matching Supabase)
enum MonitorDataType {
  BLOOD_PRESSURE_SYSTOLIC,
  BLOOD_PRESSURE_DIASTOLIC,
  GLUCOSE,
  BMI,
  HBA1C,
  ECG,
  CHOLESTEROL_TOTAL,
  CHOLESTEROL_LDL,
  CHOLESTEROL_HDL,
  CHOLESTEROL_TRIGLYCERIDES,
  UNKNOWN, // Safety fallback
}

/// Health Status Enum
enum HealthStatus {
  safe,
  warning,
  critical,
  unknown,
}

/// Monitor Data Model
@immutable
class MonitorData {
  final int id;
  final int patientId;
  final MonitorDataType dataType;
  final double value;
  final DateTime measuredAt;

  const MonitorData({
    required this.id,
    required this.patientId,
    required this.dataType,
    required this.value,
    required this.measuredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'data_type': dataType.name,
      'value': value,
      'measured_at': measuredAt.toIso8601String(),
    };
  }

  factory MonitorData.fromJson(Map<String, dynamic> json) {
    return MonitorData(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      dataType: MonitorDataType.values.firstWhere(
        (e) => e.name == json['data_type'],
        orElse: () => MonitorDataType.UNKNOWN, // Fixes crash if type not found
      ),
      value: (json['value'] as num).toDouble(),
      measuredAt: DateTime.parse(json['measured_at'] as String),
    );
  }
}

/// Patient Activity Log Model
@immutable
class PatientActivityLog {
  final int id;
  final String activityDescription;
  final int durationMinutes;
  final DateTime performedAt;

  const PatientActivityLog({
    required this.id,
    required this.activityDescription,
    required this.durationMinutes,
    required this.performedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_description': activityDescription,
      'duration_minutes': durationMinutes,
      'performed_at': performedAt.toIso8601String(),
    };
  }

  factory PatientActivityLog.fromJson(Map<String, dynamic> json) {
    return PatientActivityLog(
      id: json['id'] as int,
      activityDescription: json['activity_description'] as String,
      durationMinutes: json['duration_minutes'] as int,
      performedAt: DateTime.parse(json['performed_at'] as String),
    );
  }
}

/// Daily Patient Log Model (For Diet Overlay)
@immutable
class DailyPatientLog {
  final int id;
  final String? mealDesc;
  final double? glucoseBeforeMeal;
  final double? glucoseAfterMeal;
  final DateTime? glucoseBeforeMealTime;
  final DateTime? glucoseAfterMealTime;
  final DateTime logDate;
  final String mealTime; // 'BREAKFAST', 'LUNCH', 'DINNER'

  DateTime get effectiveTime => glucoseBeforeMealTime ?? glucoseAfterMealTime ?? logDate;

  const DailyPatientLog({
    required this.id,
    required this.logDate,
    required this.mealTime,
    this.mealDesc,
    this.glucoseBeforeMeal,
    this.glucoseAfterMeal,
    this.glucoseBeforeMealTime,
    this.glucoseAfterMealTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_desc': mealDesc,
      'glucose_before_meal': glucoseBeforeMeal,
      'glucose_after_meal': glucoseAfterMeal,
      'glucose_before_meal_time': glucoseBeforeMealTime?.toIso8601String(),
      'glucose_after_meal_time': glucoseAfterMealTime?.toIso8601String(),
      'log_date': logDate.toIso8601String(),
      'meal_time': mealTime,
    };
  }

  factory DailyPatientLog.fromJson(Map<String, dynamic> json) {
    return DailyPatientLog(
      id: json['id'] as int,
      logDate: DateTime.parse(json['log_date'] as String),
      mealTime: json['meal_time'] as String,
      mealDesc: json['meal_desc'] as String?,
      glucoseBeforeMeal: json['glucose_before_meal'] != null ? (json['glucose_before_meal'] as num).toDouble() : null,
      glucoseAfterMeal: json['glucose_after_meal'] != null ? (json['glucose_after_meal'] as num).toDouble() : null,
      glucoseBeforeMealTime: json['glucose_before_meal_time'] != null ? DateTime.parse(json['glucose_before_meal_time'] as String) : null,
      glucoseAfterMealTime: json['glucose_after_meal_time'] != null ? DateTime.parse(json['glucose_after_meal_time'] as String) : null,
    );
  }
}

/// Health Threshold Model
@immutable
class HealthThreshold {
  final MonitorDataType dataType;
  final double minValue;
  final double maxValue;

  const HealthThreshold({
    required this.dataType,
    required this.minValue,
    required this.maxValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'data_type': dataType.name,
      'min_value': minValue,
      'max_value': maxValue,
    };
  }

  factory HealthThreshold.fromJson(Map<String, dynamic> json) {
    return HealthThreshold(
      dataType: MonitorDataType.values.firstWhere(
        (e) => e.name == json['data_type'],
        orElse: () => MonitorDataType.UNKNOWN, // Fixes crash here too
      ),
      minValue: (json['min_value'] as num).toDouble(),
      maxValue: (json['max_value'] as num).toDouble(),
    );
  }
}

/// Health Status Evaluator Helper
class HealthStatusEvaluator {
  static HealthStatus evaluate(
    double value,
    MonitorDataType type,
    List<HealthThreshold> thresholds,
  ) {
    // BMI Specific Logic
    if (type == MonitorDataType.BMI) {
      if (value < 18.5) return HealthStatus.warning; // Underweight
      if (value >= 18.5 && value <= 24.9) return HealthStatus.safe; // Normal
      if (value >= 25.0 && value <= 29.9) return HealthStatus.warning; // Overweight
      if (value >= 30.0) return HealthStatus.critical; // Obese
      return HealthStatus.unknown;
    }

    // Find specific threshold
    try {
      final threshold = thresholds.firstWhere((t) => t.dataType == type);
      
      // Cholesterol Logic (Prioritize LDL if passed as type, but here we evaluate per type)
      // If type is LDL, we just check against LDL threshold.
      
      if (value < threshold.minValue) return HealthStatus.warning; // Too low
      if (value > threshold.maxValue) return HealthStatus.critical; // Too high (or warning depending on context, but usually critical for max)
      
      // Refined logic: usually min/max define the SAFE range.
      // So if within [min, max], it is safe.
      if (value >= threshold.minValue && value <= threshold.maxValue) {
        return HealthStatus.safe;
      }
      
      // If outside, determine severity. 
      // For simplicity and based on "min_value, max_value" usually defining the normal range:
      return HealthStatus.warning; 
      
    } catch (e) {
      // No threshold found
      return HealthStatus.unknown;
    }
  }
}

// ============================================================================
// DEPRECATED MODELS (LEGACY)
// ============================================================================

/// Glucose Reading Model
@Deprecated('Use MonitorData instead')
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
  final double? glucoseBefore;
  final double? glucoseAfter;
  final DateTime? glucoseBeforeTime;
  final DateTime? glucoseAfterTime;

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
    this.glucoseBefore,
    this.glucoseAfter,
    this.glucoseBeforeTime,
    this.glucoseAfterTime,
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
    double? glucoseBefore,
    double? glucoseAfter,
    DateTime? glucoseBeforeTime,
    DateTime? glucoseAfterTime,
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
      glucoseBefore: glucoseBefore ?? this.glucoseBefore,
      glucoseAfter: glucoseAfter ?? this.glucoseAfter,
      glucoseBeforeTime: glucoseBeforeTime ?? this.glucoseBeforeTime,
      glucoseAfterTime: glucoseAfterTime ?? this.glucoseAfterTime,
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
      glucoseBefore: json['glucose_before_meal'] != null ? (json['glucose_before_meal'] as num).toDouble() : null,
      glucoseAfter: json['glucose_after_meal'] != null ? (json['glucose_after_meal'] as num).toDouble() : null,
      glucoseBeforeTime: json['glucose_before_meal_time'] != null ? DateTime.parse(json['glucose_before_meal_time'] as String) : null,
      glucoseAfterTime: json['glucose_after_meal_time'] != null ? DateTime.parse(json['glucose_after_meal_time'] as String) : null,
    );
  }
}

/// Activity Log Model
@Deprecated('Use PatientActivityLog instead')
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

/// Blood Pressure Reading Model
@Deprecated('Use MonitorData instead')
@immutable
class BloodPressureReading {
  final String id;
  final DateTime timestamp;
  final double systolic;
  final double diastolic;
  final String? notes;

  const BloodPressureReading({
    required this.id,
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    this.notes,
  });

  String get value => '${systolic.toStringAsFixed(0)}/${diastolic.toStringAsFixed(0)}';

  BloodPressureReading copyWith({
    String? id,
    DateTime? timestamp,
    double? systolic,
    double? diastolic,
    String? notes,
  }) {
    return BloodPressureReading(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'notes': notes,
    };
  }

  factory BloodPressureReading.fromJson(Map<String, dynamic> json) {
    return BloodPressureReading(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      systolic: (json['systolic'] as num).toDouble(),
      diastolic: (json['diastolic'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// Cholesterol Test Result Model
@Deprecated('Use MonitorData instead')
@immutable
class CholesterolResult {
  final String id;
  final DateTime testDate;
  final double value; // mg/dL
  final String? notes;

  const CholesterolResult({
    required this.id,
    required this.testDate,
    required this.value,
    this.notes,
  });

  CholesterolResult copyWith({
    String? id,
    DateTime? testDate,
    double? value,
    String? notes,
  }) {
    return CholesterolResult(
      id: id ?? this.id,
      testDate: testDate ?? this.testDate,
      value: value ?? this.value,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testDate': testDate.toIso8601String(),
      'value': value,
      'notes': notes,
    };
  }

  factory CholesterolResult.fromJson(Map<String, dynamic> json) {
    return CholesterolResult(
      id: json['id'] as String,
      testDate: DateTime.parse(json['testDate'] as String),
      value: (json['value'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// BMI Result Model
@Deprecated('Use MonitorData instead')
@immutable
class BmiResult {
  final String id;
  final DateTime testDate;
  final double value;
  final String? notes;

  const BmiResult({
    required this.id,
    required this.testDate,
    required this.value,
    this.notes,
  });

  BmiResult copyWith({
    String? id,
    DateTime? testDate,
    double? value,
    String? notes,
  }) {
    return BmiResult(
      id: id ?? this.id,
      testDate: testDate ?? this.testDate,
      value: value ?? this.value,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testDate': testDate.toIso8601String(),
      'value': value,
      'notes': notes,
    };
  }

  factory BmiResult.fromJson(Map<String, dynamic> json) {
    return BmiResult(
      id: json['id'] as String,
      testDate: DateTime.parse(json['testDate'] as String),
      value: (json['value'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// HbA1c Test Result Model
@Deprecated('Use MonitorData instead')
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
