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
  final String name;
  final String dosage; // e.g., "500 mg"
  final String frequency; // e.g., "Twice daily"
  final String route; // e.g., "Oral"
  final String? notes;
  final DateTime? startDate;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.route,
    this.notes,
    this.startDate,
  });
}

class PatientHealthData {
  final String patientId;
  final List<GlucoseReading> glucoseReadings;
  final List<HbA1cReading> hbA1cReadings;
  final List<ActivityData> activityData;
  final List<MealEntry> mealEntries;
  final List<AutomatedAction> automatedActions;
  final List<Medication> medications;
  final String aiGeneratedSummary;
  final List<String> detectedPatterns;
  final List<String> recommendations;
  
  PatientHealthData({
    required this.patientId,
    required this.glucoseReadings,
    required this.hbA1cReadings,
    required this.activityData,
    required this.mealEntries,
    required this.automatedActions,
    required this.medications,
    required this.aiGeneratedSummary,
    required this.detectedPatterns,
    required this.recommendations,
  });
}
