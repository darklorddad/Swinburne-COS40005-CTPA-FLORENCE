class HealthData {
  final String patientId;
  final DateTime timestamp;
  final double? glucoseLevel;
  final double? hba1cLevel;
  final int? steps;
  final double? heartRate;
  final double? bloodPressure;
  final String? mealType;
  final String? medicationTaken;
  final double? sleepHours;
  final String? stressLevel;
  final double? weight;
  final String? notes;

  HealthData({
    required this.patientId,
    required this.timestamp,
    this.glucoseLevel,
    this.hba1cLevel,
    this.steps,
    this.heartRate,
    this.bloodPressure,
    this.mealType,
    this.medicationTaken,
    this.sleepHours,
    this.stressLevel,
    this.weight,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'timestamp': timestamp.toIso8601String(),
      'glucoseLevel': glucoseLevel,
      'hba1cLevel': hba1cLevel,
      'steps': steps,
      'heartRate': heartRate,
      'bloodPressure': bloodPressure,
      'mealType': mealType,
      'medicationTaken': medicationTaken,
      'sleepHours': sleepHours,
      'stressLevel': stressLevel,
      'weight': weight,
      'notes': notes,
    };
  }

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      patientId: json['patientId'],
      timestamp: DateTime.parse(json['timestamp']),
      glucoseLevel: json['glucoseLevel']?.toDouble(),
      hba1cLevel: json['hba1cLevel']?.toDouble(),
      steps: json['steps'],
      heartRate: json['heartRate']?.toDouble(),
      bloodPressure: json['bloodPressure']?.toDouble(),
      mealType: json['mealType'],
      medicationTaken: json['medicationTaken'],
      sleepHours: json['sleepHours']?.toDouble(),
      stressLevel: json['stressLevel'],
      weight: json['weight']?.toDouble(),
      notes: json['notes'],
    );
  }
}

class HealthTrend {
  final String patientId;
  final DateTime startDate;
  final DateTime endDate;
  final List<HealthData> dataPoints;
  final String trendType; // 'glucose', 'activity', 'sleep', 'weight'
  final String trendDirection; // 'increasing', 'decreasing', 'stable'
  final double trendValue;
  final String riskLevel; // 'low', 'moderate', 'high', 'critical'

  HealthTrend({
    required this.patientId,
    required this.startDate,
    required this.endDate,
    required this.dataPoints,
    required this.trendType,
    required this.trendDirection,
    required this.trendValue,
    required this.riskLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dataPoints': dataPoints.map((dp) => dp.toJson()).toList(),
      'trendType': trendType,
      'trendDirection': trendDirection,
      'trendValue': trendValue,
      'riskLevel': riskLevel,
    };
  }
}

class Anomaly {
  final String id;
  final String patientId;
  final DateTime detectedAt;
  final String anomalyType; // 'glucose_spike', 'glucose_low', 'inactivity', 'missed_medication'
  final String severity; // 'low', 'moderate', 'high', 'critical'
  final String description;
  final Map<String, dynamic> context;
  bool isResolved;
  DateTime? resolvedAt;

  Anomaly({
    required this.id,
    required this.patientId,
    required this.detectedAt,
    required this.anomalyType,
    required this.severity,
    required this.description,
    required this.context,
    this.isResolved = false,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'detectedAt': detectedAt.toIso8601String(),
      'anomalyType': anomalyType,
      'severity': severity,
      'description': description,
      'context': context,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}

class Recommendation {
  final String id;
  final String patientId;
  final DateTime createdAt;
  final String category; // 'meal_suggestions', 'activity_reminders', etc.
  final String title;
  final String description;
  final String explanation; // AI explanation for why this recommendation was made
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final Map<String, dynamic> metadata;
  bool isRead;
  bool isActedUpon;
  DateTime? actedUponAt;

  Recommendation({
    required this.id,
    required this.patientId,
    required this.createdAt,
    required this.category,
    required this.title,
    required this.description,
    required this.explanation,
    required this.priority,
    required this.metadata,
    this.isRead = false,
    this.isActedUpon = false,
    this.actedUponAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'title': title,
      'description': description,
      'explanation': explanation,
      'priority': priority,
      'metadata': metadata,
      'isRead': isRead,
      'isActedUpon': isActedUpon,
      'actedUponAt': actedUponAt?.toIso8601String(),
    };
  }
}

class ChatMessage {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final String message;
  final bool isFromUser;
  final String? aiResponse;
  final Map<String, dynamic>? context;

  ChatMessage({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.message,
    required this.isFromUser,
    this.aiResponse,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'isFromUser': isFromUser,
      'aiResponse': aiResponse,
      'context': context,
    };
  }
}

class PatientProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String diabetesType; // 'type1', 'type2', 'prediabetes', 'none'
  final List<String> medications;
  final Map<String, dynamic> preferences;
  final String riskLevel;
  final DateTime lastUpdated;

  PatientProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.diabetesType,
    required this.medications,
    required this.preferences,
    required this.riskLevel,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'diabetesType': diabetesType,
      'medications': medications,
      'preferences': preferences,
      'riskLevel': riskLevel,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
