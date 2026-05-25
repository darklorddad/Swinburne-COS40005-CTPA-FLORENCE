class GlucoseReading {
  final DateTime timestamp;
  final double value; // mg/dL
  final String context; // e.g., "Before Meal", "After Meal", "Fasting"
  
  GlucoseReading({
    required this.timestamp,
    required this.value,
    required this.context,
  });
  
  bool get isHigh => value > 180;
  bool get isLow => value < 70;
}

class HbA1cReading {
  final DateTime timestamp;
  final double value; // percentage
  
  HbA1cReading({
    required this.timestamp,
    required this.value,
  });
  
  bool get isHigh => value > 7.0;
}

class BloodPressureReading {
  final DateTime timestamp;
  final double systolic;
  final double diastolic;
  
  BloodPressureReading({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
  });
}

class CholesterolReading {
  final DateTime timestamp;
  final double total;
  final double ldl;
  final double hdl;
  final double triglycerides;

  CholesterolReading({
    required this.timestamp,
    required this.total,
    required this.ldl,
    required this.hdl,
    required this.triglycerides,
  });
}

class ActivityData {
  final DateTime date;
  final int steps;
  final int activeMinutes;
  final int caloriesBurned;
  
  ActivityData({
    required this.date,
    required this.steps,
    required this.activeMinutes,
    required this.caloriesBurned,
  });
}

class BmiReading {
  final DateTime timestamp;
  final double value; // BMI value
  final double weight; // kg
  final double height; // cm
  
  BmiReading({
    required this.timestamp,
    required this.value,
    required this.weight,
    required this.height,
  });
}

class MealEntry {
  final DateTime timestamp;
  final String mealType; // e.g., "Breakfast", "Lunch", "Dinner", "Snack"
  final List<FoodItem> foodItems;
  final Map<String, double> nutritionSummary; // e.g., {"carbs": 45, "protein": 20}
  
  MealEntry({
    required this.timestamp,
    required this.mealType,
    required this.foodItems,
    required this.nutritionSummary,
  });
}

class FoodItem {
  final String name;
  final double quantity;
  final String unit;
  final Map<String, double> nutrition; // e.g., {"carbs": 15, "protein": 5}
  
  FoodItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.nutrition,
  });
}

class AutomatedAction {
  final DateTime timestamp;
  final String type; // e.g., "Reminder", "Educational Tip", "Motivational Prompt"
  final String description;
  final String? response; // Patient's response if any
  
  AutomatedAction({
    required this.timestamp,
    required this.type,
    required this.description,
    this.response,
  });
}

class Medication {
  final int? id;
  final String name;
  final String dosage; // e.g., "500 mg"
  final String frequency; // e.g., "Twice daily"
  final int? frequencyId;
  final String route; // e.g., "Oral"
  final List<String> timingInstructions;
  final String? notes;
  final DateTime? startDate;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.frequencyId,
    required this.route,
    required this.timingInstructions,
    this.notes,
    this.startDate,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    // 1. Safe extraction of timing instructions array
    List<String> timings = [];
    if (json['timing_instructions'] != null) {
      try {
        timings = List<String>.from(json['timing_instructions']);
      } catch (_) {}
    }
    if (timings.isEmpty) {
      timings = ['ANYTIME'];
    }

    // 2. Safe extraction of medication name supporting all custom/dictionary key mutations
    String resolvedName = 'Unknown Medication';
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      resolvedName = json['name'].toString();
    } else if (json['custom_medication_name'] != null &&
        json['custom_medication_name'].toString().isNotEmpty) {
      resolvedName = json['custom_medication_name'].toString();
    } else if (json['medication'] != null &&
        json['medication']['brand_name'] != null) {
      resolvedName = json['medication']['brand_name'].toString();
    } else if (json['medication_dictionary'] != null &&
        json['medication_dictionary']['brand_name'] != null) {
      resolvedName = json['medication_dictionary']['brand_name'].toString();
    }

    return Medication(
      id: json['id'] as int?,
      name: resolvedName,
      dosage: (json['dosage'] ?? json['amount'] ?? '1').toString(),
      frequency: json['frequency'] ??
          json['dosage_frequencies']?['patient_text'] ??
          '',
      frequencyId: json['frequency_id'] as int?,
      route: json['route'] ?? json['medication_type'] ?? 'Tablet',
      timingInstructions: timings,
      notes: json['notes'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'frequency_id': frequencyId,
      'route': route,
      'timing_instructions': timingInstructions,
      'notes': notes,
      'start_date': startDate?.toIso8601String(),
    };
  }
}

class PatientHealthData {
  final String patientId;
  final double weight; // kg
  final double height; // cm
  final List<GlucoseReading> glucoseReadings;
  final List<HbA1cReading> hbA1cReadings;
  final List<BloodPressureReading> bloodPressureReadings;
  final List<CholesterolReading> cholesterolReadings;
  final List<BmiReading> bmiReadings;
  final List<ActivityData> activityData;
  final List<MealEntry> mealEntries;
  final List<AutomatedAction> automatedActions;
  final List<Medication> medications;
  final String aiGeneratedSummary;
  final List<String> detectedPatterns;
  final List<String> recommendations;
  
  PatientHealthData({
    required this.patientId,
    required this.weight,
    required this.height,
    required this.glucoseReadings,
    required this.hbA1cReadings,
    required this.bloodPressureReadings,
    required this.cholesterolReadings,
    required this.bmiReadings,
    required this.activityData,
    required this.mealEntries,
    required this.automatedActions,
    required this.medications,
    required this.aiGeneratedSummary,
    required this.detectedPatterns,
    required this.recommendations,
  });
}
