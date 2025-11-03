/// Patient Profile Service for FLORENCE Digital Health Platform
/// Manages multiple patient profiles for testing and demonstration
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/health_data_models.dart';
import 'data_ingestion_service.dart';
import '../../chat/services/chatbot_service.dart';

/// Patient profile types
enum PatientProfileType {
  wellControlled,
  highRisk,
  variable,
}

/// Patient profile metadata
class PatientProfile {
  final PatientProfileType type;
  final String name;
  final String description;
  final double baselineGlucose;
  final double targetHbA1c;
  final double activityLevel; // 0.0-1.0
  final double medicationAdherence; // 0.0-1.0

  const PatientProfile({
    required this.type,
    required this.name,
    required this.description,
    required this.baselineGlucose,
    required this.targetHbA1c,
    required this.activityLevel,
    required this.medicationAdherence,
  });
}

/// Service for managing patient profiles
class PatientProfileService with ChangeNotifier {
  final DataIngestionService _dataService = DataIngestionService();
  final ChatbotService _chatbotService = ChatbotService();
  final Random _random = Random();

  // Singleton pattern
  static final PatientProfileService _instance = PatientProfileService._internal();
  factory PatientProfileService() => _instance;
  PatientProfileService._internal();

  PatientProfileType _currentProfile = PatientProfileType.wellControlled;
  DateTime _lastRefresh = DateTime.now();

  PatientProfileType get currentProfileType => _currentProfile;
  DateTime get lastRefresh => _lastRefresh;

  /// Available patient profiles
  static const List<PatientProfile> availableProfiles = [
    PatientProfile(
      type: PatientProfileType.wellControlled,
      name: 'Well-Controlled Patient',
      description: 'Good glucose control, active lifestyle, consistent medication',
      baselineGlucose: 120.0,
      targetHbA1c: 6.5,
      activityLevel: 0.8,
      medicationAdherence: 0.95,
    ),
    PatientProfile(
      type: PatientProfileType.highRisk,
      name: 'High-Risk Patient',
      description: 'Poor glucose control, low activity, inconsistent medication',
      baselineGlucose: 180.0,
      targetHbA1c: 8.5,
      activityLevel: 0.3,
      medicationAdherence: 0.65,
    ),
    PatientProfile(
      type: PatientProfileType.variable,
      name: 'Variable Patient',
      description: 'Inconsistent patterns, glucose sensitive to activity',
      baselineGlucose: 145.0,
      targetHbA1c: 7.2,
      activityLevel: 0.6,
      medicationAdherence: 0.80,
    ),
  ];

  /// Get current profile
  PatientProfile get currentProfile {
    return availableProfiles.firstWhere((p) => p.type == _currentProfile);
  }

  /// Switch to a different patient profile
  Future<void> switchProfile(PatientProfileType type) async {
    if (_currentProfile == type) return;

    _currentProfile = type;
    await _generateProfileData();
    _lastRefresh = DateTime.now();

    // CRITICAL: Invalidate chatbot context so it uses new profile data
    _chatbotService.invalidateContext();
    print('PatientProfileService: Profile switched to $type, chatbot context invalidated');

    notifyListeners();
  }

  /// Refresh current profile data
  Future<void> refreshCurrentProfile() async {
    await _generateProfileData();
    _lastRefresh = DateTime.now();

    // CRITICAL: Invalidate chatbot context so it fetches fresh data
    _chatbotService.invalidateContext();
    print('PatientProfileService: Profile refreshed, chatbot context invalidated');

    notifyListeners();
  }

  /// Generate data for current profile
  Future<void> _generateProfileData() async {
    // Clear existing data
    _dataService.clearAllData();

    final profile = currentProfile;

    // Generate glucose readings
    await _generateGlucoseData(profile);

    // Generate meals
    await _generateMealsData(profile);

    // Generate activities
    await _generateActivitiesData(profile);

    // Generate medications
    await _generateMedicationsData(profile);

    // Generate HbA1c
    await _generateHbA1cData(profile);

    // Generate sleep
    await _generateSleepData(profile);
  }

  /// Generate glucose readings for profile
  Future<void> _generateGlucoseData(PatientProfile profile) async {
    final now = DateTime.now();
    const days = 30;

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final readingsPerDay = 4 + _random.nextInt(5);

      for (int i = 0; i < readingsPerDay; i++) {
        final hour = (i * 24 / readingsPerDay).floor();
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        // Base value with profile-specific variance
        double value = profile.baselineGlucose;

        // Time-based variations
        if (hour >= 6 && hour <= 9) value += 15; // Morning
        else if (hour >= 12 && hour <= 14) value += 20; // Lunch
        else if (hour >= 18 && hour <= 20) value += 18; // Dinner

        // Profile-specific variability
        double variance = 0;
        if (profile.type == PatientProfileType.wellControlled) {
          variance = _randomGaussian(-15, 15);
        } else if (profile.type == PatientProfileType.highRisk) {
          variance = _randomGaussian(-40, 40);
        } else {
          // Variable - sometimes good, sometimes bad
          variance = _random.nextBool()
              ? _randomGaussian(-15, 15)
              : _randomGaussian(-35, 35);
        }

        final glucoseValue = (value + variance).clamp(70, 350);

        await _dataService.addGlucoseReading(GlucoseReading(
          id: 'glucose_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          value: glucoseValue.toDouble(),
          context: _getGlucoseContext(hour),
          isFlagged: glucoseValue > 200 || glucoseValue < 70,
        ));
      }
    }
  }

  /// Generate meals for profile
  Future<void> _generateMealsData(PatientProfile profile) async {
    final now = DateTime.now();
    const days = 30;
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final mealsPerDay = 3 + _random.nextInt(2);

      for (int i = 0; i < mealsPerDay; i++) {
        final mealType = i < 3 ? mealTypes[i] : 'Snack';
        final hour = i == 0 ? 7 : i == 1 ? 12 : i == 2 ? 19 : 15;
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        // Carbs based on profile
        double baseCarbs = 40.0;
        if (profile.type == PatientProfileType.wellControlled) {
          baseCarbs = 30.0 + _random.nextInt(30); // 30-60g
        } else if (profile.type == PatientProfileType.highRisk) {
          baseCarbs = 50.0 + _random.nextInt(50); // 50-100g
        } else {
          baseCarbs = 25.0 + _random.nextInt(60); // 25-85g
        }

        await _dataService.addMeal(MealLog(
          id: 'meal_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          type: mealType,
          description: _getMealDescription(mealType),
          carbs: baseCarbs,
          calories: (baseCarbs * 4 + 200).toInt(),
          protein: 10.0 + _random.nextInt(25).toDouble(),
          fat: 8.0 + _random.nextInt(20).toDouble(),
        ));
      }
    }
  }

  /// Generate activities for profile
  Future<void> _generateActivitiesData(PatientProfile profile) async {
    final now = DateTime.now();
    const days = 30;
    final activityTypes = ['Walking', 'Running', 'Cycling', 'Swimming', 'Gym', 'Yoga'];
    final intensities = ['Low', 'Moderate', 'High'];

    for (int day = 0; day < days; day++) {
      // Activity frequency based on profile
      final shouldHaveActivity = _random.nextDouble() < profile.activityLevel;

      if (shouldHaveActivity) {
        final date = now.subtract(Duration(days: days - day));
        final hour = 6 + _random.nextInt(14);
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        final duration = profile.type == PatientProfileType.wellControlled
            ? 30 + _random.nextInt(45) // 30-75 min
            : 15 + _random.nextInt(30); // 15-45 min

        final intensity = profile.type == PatientProfileType.wellControlled
            ? intensities[1 + _random.nextInt(2)] // Moderate or High
            : intensities[_random.nextInt(2)]; // Low or Moderate

        await _dataService.addActivity(ActivityLog(
          id: 'activity_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          type: activityTypes[_random.nextInt(activityTypes.length)],
          duration: duration,
          intensity: intensity,
          caloriesBurned: duration * (intensity == 'High' ? 8 : intensity == 'Moderate' ? 5 : 3),
        ));
      }
    }
  }

  /// Generate medications for profile
  Future<void> _generateMedicationsData(PatientProfile profile) async {
    final medications = [
      ('Metformin', '500 mg', 'Twice daily'),
      ('Insulin Glargine', '20 units', 'Once daily'),
    ];

    for (var med in medications) {
      final doses = <MedicationDose>[];
      final now = DateTime.now();

      for (int day = 0; day < 30; day++) {
        final date = now.subtract(Duration(days: 30 - day));

        if (med.$3 == 'Twice daily') {
          // Morning dose
          final shouldTakeMorning = _random.nextDouble() < profile.medicationAdherence;
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}_morning',
            scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
            taken: shouldTakeMorning,
            takenTime: shouldTakeMorning
                ? DateTime(date.year, date.month, date.day, 8, _random.nextInt(60))
                : null,
          ));

          // Evening dose
          final shouldTakeEvening = _random.nextDouble() < profile.medicationAdherence;
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}_evening',
            scheduledTime: DateTime(date.year, date.month, date.day, 20, 0),
            taken: shouldTakeEvening,
            takenTime: shouldTakeEvening
                ? DateTime(date.year, date.month, date.day, 20, _random.nextInt(60))
                : null,
          ));
        } else {
          final shouldTake = _random.nextDouble() < profile.medicationAdherence;
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}',
            scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
            taken: shouldTake,
            takenTime: shouldTake
                ? DateTime(date.year, date.month, date.day, 8, _random.nextInt(60))
                : null,
          ));
        }
      }

      await _dataService.addMedication(MedicationLog(
        id: 'med_${med.$1.hashCode}',
        medicationName: med.$1,
        dosage: med.$2,
        frequency: med.$3,
        prescribedDate: DateTime.now().subtract(const Duration(days: 90)),
        doses: doses,
      ));
    }
  }

  /// Generate HbA1c for profile
  Future<void> _generateHbA1cData(PatientProfile profile) async {
    final now = DateTime.now();
    final testDates = [
      now.subtract(const Duration(days: 90)),
      now.subtract(const Duration(days: 180)),
      now.subtract(const Duration(days: 270)),
    ];

    for (var testDate in testDates) {
      await _dataService.addHbA1cResult(HbA1cResult(
        id: 'hba1c_${testDate.millisecondsSinceEpoch}',
        testDate: testDate,
        value: profile.targetHbA1c + _randomGaussian(-0.3, 0.3),
        labName: 'BioTective Labs',
      ));
    }
  }

  /// Generate sleep for profile
  Future<void> _generateSleepData(PatientProfile profile) async {
    final now = DateTime.now();
    const days = 30;

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));

      int sleepHours;
      if (profile.type == PatientProfileType.wellControlled) {
        sleepHours = 7 + _random.nextInt(2); // 7-9 hours
      } else if (profile.type == PatientProfileType.highRisk) {
        sleepHours = 5 + _random.nextInt(3); // 5-8 hours
      } else {
        sleepHours = 6 + _random.nextInt(3); // 6-9 hours
      }

      final bedTime = DateTime(date.year, date.month, date.day, 22 + _random.nextInt(2), _random.nextInt(60));
      final wakeTime = bedTime.add(Duration(hours: sleepHours));

      await _dataService.addSleepLog(SleepLog(
        id: 'sleep_${bedTime.millisecondsSinceEpoch}',
        bedTime: bedTime,
        wakeTime: wakeTime,
        quality: sleepHours >= 7 ? 6 + _random.nextInt(5) : 3 + _random.nextInt(5),
      ));
    }
  }

  // Helper methods
  String _getGlucoseContext(int hour) {
    if (hour >= 5 && hour < 9) return 'Before breakfast';
    if (hour >= 9 && hour < 11) return 'After breakfast';
    if (hour >= 11 && hour < 13) return 'Before lunch';
    if (hour >= 13 && hour < 17) return 'After lunch';
    if (hour >= 17 && hour < 19) return 'Before dinner';
    if (hour >= 19 && hour < 22) return 'After dinner';
    return 'Bedtime';
  }

  String _getMealDescription(String mealType) {
    final breakfasts = ['Oatmeal with berries', 'Eggs and whole wheat toast', 'Greek yogurt with nuts'];
    final lunches = ['Grilled chicken salad', 'Brown rice with vegetables', 'Turkey sandwich'];
    final dinners = ['Salmon with broccoli', 'Lean beef stir-fry', 'Grilled chicken with quinoa'];
    final snacks = ['Apple with peanut butter', 'Mixed nuts', 'String cheese'];

    switch (mealType) {
      case 'Breakfast':
        return breakfasts[_random.nextInt(breakfasts.length)];
      case 'Lunch':
        return lunches[_random.nextInt(lunches.length)];
      case 'Dinner':
        return dinners[_random.nextInt(dinners.length)];
      default:
        return snacks[_random.nextInt(snacks.length)];
    }
  }

  double _randomGaussian(double min, double max) {
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final randStdNormal = sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2);
    final mean = (min + max) / 2;
    final stdDev = (max - min) / 6;
    return mean + stdDev * randStdNormal;
  }
}
