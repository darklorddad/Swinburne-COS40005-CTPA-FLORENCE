import 'package:clinician_dashboard/models/patient.dart';
import 'package:clinician_dashboard/models/alert.dart';
import 'package:clinician_dashboard/models/health_data.dart';
import 'package:clinician_dashboard/models/clinician_note.dart';

class MockDataService {
  // Get list of patients
  List<Patient> getPatients() {
    return [
      Patient(
        id: 'P001',
        name: 'Malaysia',
        age: 54,
        gender: 'Male',
        condition: ChronicCondition.type2Diabetes,
        riskLevel: RiskLevel.high,
        lastSync: DateTime.now().subtract(const Duration(hours: 2)),
        contactInfo: '+601234567890',
      ),
      Patient(
        id: 'P002',
        name: 'Paris',
        age: 62,
        gender: 'Female',
        condition: ChronicCondition.type2Diabetes,
        riskLevel: RiskLevel.medium,
        lastSync: DateTime.now().subtract(const Duration(days: 1)),
        contactInfo: '+601234567891',
      ),
      Patient(
        id: 'P003',
        name: 'Dubai',
        age: 45,
        gender: 'Male',
        condition: ChronicCondition.type1Diabetes,
        riskLevel: RiskLevel.low,
        lastSync: DateTime.now().subtract(const Duration(minutes: 30)),
        contactInfo: '+601234567892',
      ),
      Patient(
        id: 'P004',
        name: 'Sydney',
        age: 38,
        gender: 'Female',
        condition: ChronicCondition.hypertension,
        riskLevel: RiskLevel.high,
        lastSync: DateTime.now().subtract(const Duration(days: 3)),
        contactInfo: '+601234567893',
      ),
      Patient(
        id: 'P005',
        name: 'Germany',
        age: 71,
        gender: 'Male',
        condition: ChronicCondition.type2Diabetes,
        riskLevel: RiskLevel.medium,
        lastSync: DateTime.now().subtract(const Duration(hours: 6)),
        contactInfo: '+601234567894',
      ),
    ];
  }

  // Get alerts
  List<Alert> getAlerts() {
    return [
      Alert(
        id: 'A001',
        patientId: 'P001',
        patientName: 'Malaysia',
        type: AlertType.highGlucose,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        description: 'Post-meal glucose reading of 250 mg/dL',
        dataPointRef: 'glucose/P001/20250924-1200',
      ),
      Alert(
        id: 'A002',
        patientId: 'P004',
        patientName: 'Sydney',
        type: AlertType.highBloodPressure,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Blood pressure reading of 160/95 mmHg',
        dataPointRef: 'bp/P004/20250922-0800',
      ),
      Alert(
        id: 'A003',
        patientId: 'P001',
        patientName: 'Malaysia',
        type: AlertType.lowPhysicalActivity,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        description: 'No recorded physical activity for 5 consecutive days',
        dataPointRef: 'activity/P001/20250923',
      ),
      Alert(
        id: 'A004',
        patientId: 'P005',
        patientName: 'Germany',
        type: AlertType.highHbA1c,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        description: 'Latest HbA1c reading of 9.2%',
        dataPointRef: 'hba1c/P005/20250924',
      ),
    ];
  }

  // Get health data for a specific patient
  PatientHealthData getPatientHealthData(String patientId) {
    // Generate some sample data based on patientId
    final List<GlucoseReading> glucoseReadings = [];
    final List<HbA1cReading> hbA1cReadings = [];
    final List<ActivityData> activityData = [];
    final List<MealEntry> mealEntries = [];
    final List<AutomatedAction> automatedActions = [];
    final List<Medication> medications = [];

    // Generate 7 days of glucose readings (3 per day)
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      
      // Breakfast reading
      glucoseReadings.add(GlucoseReading(
        timestamp: DateTime(day.year, day.month, day.day, 8, 0),
        value: 120 + (patientId == 'P001' ? 60 : 0) + (i % 2 == 0 ? 15 : -15),
        context: 'Before Breakfast',
      ));
      
      // Lunch reading
      glucoseReadings.add(GlucoseReading(
        timestamp: DateTime(day.year, day.month, day.day, 13, 0),
        value: 150 + (patientId == 'P001' ? 80 : 0) + (i % 3 == 0 ? 25 : -10),
        context: 'After Lunch',
      ));
      
      // Dinner reading
      glucoseReadings.add(GlucoseReading(
        timestamp: DateTime(day.year, day.month, day.day, 19, 0),
        value: 140 + (patientId == 'P001' ? 70 : 0) + (i % 2 == 1 ? 20 : -20),
        context: 'After Dinner',
      ));
      
      // Activity data
      activityData.add(ActivityData(
        date: day,
        steps: 8000 - (patientId == 'P001' ? 4000 : 0) + (i * 500),
        activeMinutes: 45 - (patientId == 'P001' ? 30 : 0) + (i * 5),
        caloriesBurned: 300 - (patientId == 'P001' ? 150 : 0) + (i * 30),
      ));
    }

    // Add HbA1c readings (every 3 months)
    hbA1cReadings.add(HbA1cReading(
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      value: patientId == 'P001' ? 8.2 : (patientId == 'P005' ? 9.2 : 6.8),
    ));
    hbA1cReadings.add(HbA1cReading(
      timestamp: DateTime.now().subtract(const Duration(days: 90)),
      value: patientId == 'P001' ? 8.0 : (patientId == 'P005' ? 8.9 : 6.7),
    ));
    hbA1cReadings.add(HbA1cReading(
      timestamp: DateTime.now().subtract(const Duration(days: 180)),
      value: patientId == 'P001' ? 7.9 : (patientId == 'P005' ? 8.5 : 6.9),
    ));

    // Create sample meal entries
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    for (int i = 3; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      
      for (int j = 0; j < 3; j++) {
        final foodItems = <FoodItem>[
          FoodItem(
            name: j == 0 ? 'Bread' : (j == 1 ? 'Rice' : 'Chicken'),
            quantity: j == 0 ? 2 : (j == 1 ? 1 : 0.5),
            unit: j == 0 ? 'slice' : (j == 1 ? 'cup' : 'serving'),
            nutrition: {
              'carbs': j == 0 ? 30 : (j == 1 ? 45 : 0),
              'protein': j == 0 ? 4 : (j == 1 ? 4 : 25),
              'fat': j == 0 ? 2 : (j == 1 ? 0 : 15),
            },
          ),
        ];
        
        mealEntries.add(MealEntry(
          timestamp: DateTime(day.year, day.month, day.day, 8 + (j * 5), 0),
          mealType: mealTypes[j],
          foodItems: foodItems,
          nutritionSummary: {
            'carbs': foodItems.fold(0.0, (prev, item) => prev + item.nutrition['carbs']!),
            'protein': foodItems.fold(0.0, (prev, item) => prev + item.nutrition['protein']!),
            'fat': foodItems.fold(0.0, (prev, item) => prev + item.nutrition['fat']!),
          },
        ));
      }
    }

    // Add automated actions
    automatedActions.add(AutomatedAction(
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      type: 'Reminder',
      description: 'Reminder to check glucose after high-carb meal',
    ));
    
    automatedActions.add(AutomatedAction(
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 10)),
      type: 'Educational Tip',
      description: 'Tip about managing glucose levels after meals',
    ));
    
    automatedActions.add(AutomatedAction(
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      type: 'Weekly Summary',
      description: 'Weekly health summary generated and sent to patient',
    ));

    // Sample medications
    medications.addAll([
      Medication(
        name: 'Metformin',
        dosage: '500 mg',
        frequency: 'Twice daily',
        route: 'Oral',
        notes: 'Take with meals to reduce GI upset',
        startDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Medication(
        name: patientId == 'P001' ? 'Insulin Glargine' : 'Atorvastatin',
        dosage: patientId == 'P001' ? '18 units' : '20 mg',
        frequency: patientId == 'P001' ? 'Nightly' : 'Once daily',
        route: patientId == 'P001' ? 'Subcutaneous' : 'Oral',
        notes: patientId == 'P001' ? 'Rotate injection sites' : 'Take in the evening',
        startDate: DateTime.now().subtract(const Duration(days: 200)),
      ),
    ]);

    return PatientHealthData(
      patientId: patientId,
      glucoseReadings: glucoseReadings,
      hbA1cReadings: hbA1cReadings,
      activityData: activityData,
      mealEntries: mealEntries,
      automatedActions: automatedActions,
      medications: medications,
      aiGeneratedSummary: _getAiSummary(patientId),
      detectedPatterns: _getDetectedPatterns(patientId),
      recommendations: _getRecommendations(patientId),
    );
  }

  // Get clinician notes for a patient
  List<ClinicianNote> getClinicianNotes(String patientId) {
    return [
      ClinicianNote(
        id: 'N001',
        patientId: patientId,
        timestamp: DateTime.now().subtract(const Duration(days: 14)),
        content: 'Patient reported increased thirst and frequent urination. Advised to monitor glucose more frequently.',
      ),
      ClinicianNote(
        id: 'N002',
        patientId: patientId,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        content: 'Follow-up on medication adjustment. Patient reports improved symptoms.',
      ),
    ];
  }

  // Helper methods for AI-generated content
  String _getAiSummary(String patientId) {
    if (patientId == 'P001') {
      return 'Patient shows consistent post-meal glucose spikes, particularly after lunch. Physical activity is below recommended levels. Recent HbA1c shows poor control at 8.2%. Recommend lifestyle modification and potential medication adjustment.';
    } else if (patientId == 'P005') {
      return 'Patient HbA1c trending upward over the past 6 months, now at 9.2%. Daily glucose patterns show morning fasting hyperglycemia. Physical activity has decreased in the past week.';
    } else {
      return 'Patient\'s glucose levels are mostly within target range. Regular physical activity observed. HbA1c stable at 6.8%. Continue current management plan.';
    }
  }

  List<String> _getDetectedPatterns(String patientId) {
    if (patientId == 'P001') {
      return [
        'Post-meal glucose spikes, particularly after carb-heavy lunches',
        'Consistently low physical activity on weekdays',
        'Poor medication adherence in the evening doses',
      ];
    } else if (patientId == 'P005') {
      return [
        'Dawn phenomenon: elevated fasting glucose in early morning',
        'HbA1c steadily increasing over past 3 readings',
        'Decreased physical activity in the past week',
      ];
    } else {
      return [
        'Stable glucose patterns throughout the day',
        'Consistent physical activity pattern',
        'Good medication adherence',
      ];
    }
  }

  List<String> _getRecommendations(String patientId) {
    if (patientId == 'P001') {
      return [
        'Reduce carbohydrate intake at lunch',
        'Incorporate 15-minute walks after meals',
        'Set medication reminders for evening doses',
      ];
    } else if (patientId == 'P005') {
      return [
        'Consider adjusting evening basal insulin dose',
        'Schedule follow-up appointment to discuss HbA1c trend',
        'Gradually increase daily step count by 1000 steps per day',
      ];
    } else {
      return [
        'Continue current management plan',
        'Next routine follow-up in 3 months',
      ];
    }
  }
}
