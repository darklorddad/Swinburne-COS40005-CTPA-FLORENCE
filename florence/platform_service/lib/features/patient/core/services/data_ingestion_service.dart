/// Data Ingestion Service for FLORENCE Digital Health Platform
/// Handles in-memory data management for health records

import '../../../../core/services/api_service.dart';
import 'dart:math';
import '../models/health_data_models.dart';

/// Service for managing health data in memory
/// This service acts as a data layer that can later be connected to Supabase
class DataIngestionService {
  // In-memory data stores
  final ApiService _apiService = ApiService();
  final List<GlucoseReading> _glucoseReadings = [];
  final List<MealLog> _meals = [];
  final List<ActivityLog> _activities = [];
  final List<MedicationLog> _medications = [];
  final List<HbA1cResult> _hba1cResults = [];
  final List<SleepLog> _sleepLogs = [];
  final List<BloodPressureReading> _bloodPressureReadings = [];
  final List<CholesterolResult> _cholesterolResults = [];
  final List<BmiResult> _bmiResults = [];
  final List<HealthThreshold> _healthThresholds = [];

  final Random _random = Random();

  // Singleton instance
  static final DataIngestionService _instance = DataIngestionService._internal();
  factory DataIngestionService() => _instance;
  DataIngestionService._internal();

  /// Fetch real data from the backend
  Future<void> fetchRealData() async {
    clearAllData();
    try {
      await fetchThresholds(); // Fetch thresholds first

      // The backend returns monitor data which contains glucose, hba1c etc.
      final monitorData = await _apiService.get('/patients/me/monitor-data') as List;
      
      final systolicReadings = <String, dynamic>{};
      final diastolicReadings = <String, dynamic>{};

      for (var item in monitorData) {
        final dataType = item['data_type'];
        final timestamp = DateTime.parse(item['measured_at']);
        final id = item['id'].toString();
        final value = (item['value'] as num).toDouble();

        switch (dataType) {
          case 'GLUCOSE':
            _glucoseReadings.add(GlucoseReading(
              id: id,
              timestamp: timestamp,
              value: value,
              context: _getGlucoseContext(timestamp.hour),
            ));
            break;
          case 'HBA1C':
            _hba1cResults.add(HbA1cResult(
              id: id,
              testDate: timestamp,
              value: value,
            ));
            break;
          case 'BLOOD_PRESSURE_SYSTOLIC':
            systolicReadings[timestamp.toIso8601String()] = {'id': id, 'value': value};
            break;
          case 'BLOOD_PRESSURE_DIASTOLIC':
            diastolicReadings[timestamp.toIso8601String()] = {'id': id, 'value': value};
            break;
          case 'CHOLESTEROL':
            _cholesterolResults.add(CholesterolResult(
              id: id,
              testDate: timestamp,
              value: value,
            ));
            break;
          case 'BMI':
            _bmiResults.add(BmiResult(
              id: id,
              testDate: timestamp,
              value: value,
            ));
            break;
        }
      }

      // Pair up blood pressure readings
      systolicReadings.forEach((timestampStr, systolicData) {
        if (diastolicReadings.containsKey(timestampStr)) {
          final diastolicData = diastolicReadings[timestampStr];
          _bloodPressureReadings.add(BloodPressureReading(
            id: systolicData['id'], // Use systolic ID as primary
            timestamp: DateTime.parse(timestampStr),
            systolic: systolicData['value'],
            diastolic: diastolicData['value'],
          ));
        }
      });
      
      // TODO: Fetch other data types (meals, activities, sleep, medications) from their respective endpoints if they exist.

      // Sort data after fetching
      _glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _hba1cResults.sort((a, b) => b.testDate.compareTo(a.testDate));
      _bloodPressureReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _cholesterolResults.sort((a, b) => b.testDate.compareTo(a.testDate));
      _bmiResults.sort((a, b) => b.testDate.compareTo(a.testDate));

    } catch (e) {
      print("Error fetching real data: $e");
      clearAllData();
    }
  }

  /// Fetch health thresholds
  Future<void> fetchThresholds() async {
    _healthThresholds.clear();
    try {
      final response = await _apiService.get('/patients/me/thresholds');
      if (response != null && response is List) {
        for (var item in response) {
          _healthThresholds.add(HealthThreshold.fromJson(item));
        }
      }
    } catch (e) {
      print("Error fetching thresholds: $e");
      // Fallback to standard medical defaults if API fails (NOT mock data, but standard guidelines)
      _loadDefaultThresholds();
    }
  }

  void _loadDefaultThresholds() {
    _healthThresholds.addAll([
      const HealthThreshold(dataType: MonitorDataType.GLUCOSE, minValue: 70, maxValue: 180),
      const HealthThreshold(dataType: MonitorDataType.BLOOD_PRESSURE_SYSTOLIC, minValue: 90, maxValue: 120),
      const HealthThreshold(dataType: MonitorDataType.BLOOD_PRESSURE_DIASTOLIC, minValue: 60, maxValue: 80),
      const HealthThreshold(dataType: MonitorDataType.HBA1C, minValue: 0, maxValue: 6.5),
      const HealthThreshold(dataType: MonitorDataType.CHOLESTEROL_TOTAL, minValue: 0, maxValue: 200),
      const HealthThreshold(dataType: MonitorDataType.BMI, minValue: 18.5, maxValue: 24.9),
    ]);
  }

  /// Initialize with realistic mock data
  void generateAndLoadMockData() {
    clearAllData();
    _generateMockGlucoseReadings();
    _generateMockMeals();
    _generateMockActivities();
    _generateMockMedications();
    _generateMockHbA1cResults();
    _generateMockSleepLogs();
    _generateMockBloodPressureReadings();
    _generateMockCholesterolResults();
    _generateMockBmiResults();
  }

  // ==================== GLUCOSE READINGS ====================

  List<HealthThreshold> get allHealthThresholds => List.unmodifiable(_healthThresholds);

  List<GlucoseReading> get allGlucoseReadings =>
      List.unmodifiable(_glucoseReadings);

  List<GlucoseReading> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var readings = _glucoseReadings;

    if (startDate != null) {
      readings = readings.where((r) => r.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      readings = readings.where((r) => r.timestamp.isBefore(endDate)).toList();
    }

    return List.unmodifiable(readings);
  }

  Future<GlucoseReading> addGlucoseReading(GlucoseReading reading) async {
    _glucoseReadings.add(reading);
    _glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return reading;
  }

  Future<void> deleteGlucoseReading(String id) async {
    _glucoseReadings.removeWhere((r) => r.id == id);
  }

  Future<GlucoseReading> updateGlucoseReading(GlucoseReading reading) async {
    final index = _glucoseReadings.indexWhere((r) => r.id == reading.id);
    if (index != -1) {
      _glucoseReadings[index] = reading;
    }
    return reading;
  }

  // ==================== MEALS ====================

  List<MealLog> get allMeals => List.unmodifiable(_meals);

  List<MealLog> getMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var meals = _meals;

    if (startDate != null) {
      meals = meals.where((m) => m.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      meals = meals.where((m) => m.timestamp.isBefore(endDate)).toList();
    }

    return List.unmodifiable(meals);
  }

  Future<MealLog> addMeal(MealLog meal) async {
    _meals.add(meal);
    _meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return meal;
  }

  Future<void> deleteMeal(String id) async {
    _meals.removeWhere((m) => m.id == id);
  }

  Future<MealLog> updateMeal(MealLog meal) async {
    final index = _meals.indexWhere((m) => m.id == meal.id);
    if (index != -1) {
      _meals[index] = meal;
    }
    return meal;
  }

  // ==================== ACTIVITIES ====================

  List<ActivityLog> get allActivities => List.unmodifiable(_activities);

  List<ActivityLog> getActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var activities = _activities;

    if (startDate != null) {
      activities = activities.where((a) => a.timestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      activities = activities.where((a) => a.timestamp.isBefore(endDate)).toList();
    }

    return List.unmodifiable(activities);
  }

  Future<ActivityLog> addActivity(ActivityLog activity) async {
    _activities.add(activity);
    _activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activity;
  }

  Future<void> deleteActivity(String id) async {
    _activities.removeWhere((a) => a.id == id);
  }

  Future<ActivityLog> updateActivity(ActivityLog activity) async {
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
    }
    return activity;
  }

  // ==================== MEDICATIONS ====================

  List<MedicationLog> get allMedications => List.unmodifiable(_medications);

  Future<MedicationLog> addMedication(MedicationLog medication) async {
    _medications.add(medication);
    return medication;
  }

  Future<void> deleteMedication(String id) async {
    _medications.removeWhere((m) => m.id == id);
  }

  Future<MedicationLog> updateMedication(MedicationLog medication) async {
    final index = _medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
    }
    return medication;
  }

  Future<MedicationLog> markDoseTaken(String medicationId, String doseId) async {
    final medIndex = _medications.indexWhere((m) => m.id == medicationId);
    if (medIndex != -1) {
      final medication = _medications[medIndex];
      final updatedDoses = medication.doses.map((dose) {
        if (dose.id == doseId) {
          return dose.copyWith(
            taken: true,
            takenTime: DateTime.now(),
          );
        }
        return dose;
      }).toList();

      _medications[medIndex] = medication.copyWith(doses: updatedDoses);
      return _medications[medIndex];
    }
    throw Exception('Medication not found');
  }

  // ==================== HbA1c RESULTS ====================

  List<HbA1cResult> get allHbA1cResults => List.unmodifiable(_hba1cResults);

  Future<HbA1cResult> addHbA1cResult(HbA1cResult result) async {
    _hba1cResults.add(result);
    _hba1cResults.sort((a, b) => b.testDate.compareTo(a.testDate));
    return result;
  }

  HbA1cResult? get latestHbA1c =>
      _hba1cResults.isNotEmpty ? _hba1cResults.first : null;

  // ==================== BLOOD PRESSURE ====================

  List<BloodPressureReading> get allBloodPressureReadings =>
      List.unmodifiable(_bloodPressureReadings);

  BloodPressureReading? get latestBloodPressure =>
      _bloodPressureReadings.isNotEmpty ? _bloodPressureReadings.first : null;

  // ==================== CHOLESTEROL ====================

  List<CholesterolResult> get allCholesterolResults =>
      List.unmodifiable(_cholesterolResults);

  CholesterolResult? get latestCholesterol =>
      _cholesterolResults.isNotEmpty ? _cholesterolResults.first : null;

  // ==================== BMI ====================

  List<BmiResult> get allBmiResults => List.unmodifiable(_bmiResults);

  BmiResult? get latestBmi => _bmiResults.isNotEmpty ? _bmiResults.first : null;

  // ==================== SLEEP LOGS ====================

  List<SleepLog> get allSleepLogs => List.unmodifiable(_sleepLogs);

  List<SleepLog> getSleepLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var logs = _sleepLogs;

    if (startDate != null) {
      logs = logs.where((s) => s.bedTime.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      logs = logs.where((s) => s.bedTime.isBefore(endDate)).toList();
    }

    return List.unmodifiable(logs);
  }

  Future<SleepLog> addSleepLog(SleepLog log) async {
    _sleepLogs.add(log);
    _sleepLogs.sort((a, b) => b.bedTime.compareTo(a.bedTime));
    return log;
  }

  // ==================== HEALTH SUMMARY ====================

  HealthSummary getHealthSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final glucoseInRange = getGlucoseReadings(
      startDate: startDate,
      endDate: endDate,
    );

    final mealsInRange = getMeals(
      startDate: startDate,
      endDate: endDate,
    );

    final activitiesInRange = getActivities(
      startDate: startDate,
      endDate: endDate,
    );

    final sleepInRange = getSleepLogs(
      startDate: startDate,
      endDate: endDate,
    );

    // Calculate glucose statistics
    final glucoseValues = glucoseInRange.map((r) => r.value).toList();
    final averageGlucose = glucoseValues.isNotEmpty
        ? glucoseValues.reduce((a, b) => a + b) / glucoseValues.length
        : 0.0;

    final glucoseStdDev = glucoseValues.isNotEmpty
        ? _calculateStdDev(glucoseValues)
        : 0.0;

    final hyperEvents = glucoseInRange.where((r) => r.isHigh).length;
    final hypoEvents = glucoseInRange.where((r) => r.isLow).length;
    final normalReadings = glucoseInRange.where((r) => r.isNormal).length;
    final timeInRange = glucoseInRange.isNotEmpty
        ? (normalReadings / glucoseInRange.length) * 100
        : 0.0;

    // Estimated A1c from average glucose: eA1c = (avg_glucose + 46.7) / 28.7
    final estimatedA1c = (averageGlucose + 46.7) / 28.7;

    // Calculate meal statistics
    final averageCarbs = mealsInRange.isNotEmpty
        ? mealsInRange.map((m) => m.carbs).reduce((a, b) => a + b) / mealsInRange.length
        : 0.0;

    // Calculate activity statistics
    final totalActivityMinutes = activitiesInRange.isNotEmpty
        ? activitiesInRange.map((a) => a.duration).reduce((a, b) => a + b)
        : 0;

    // Calculate medication adherence
    final medicationAdherence = _medications.isNotEmpty
        ? _medications.map((m) => m.adherenceRate).reduce((a, b) => a + b) / _medications.length
        : 0.0;

    // Calculate average sleep
    final averageSleepHours = sleepInRange.isNotEmpty
        ? (sleepInRange.map((s) => s.hoursSlept).reduce((a, b) => a + b) / sleepInRange.length).round()
        : 0;

    return HealthSummary(
      startDate: startDate,
      endDate: endDate,
      averageGlucose: averageGlucose,
      glucoseStdDev: glucoseStdDev,
      totalReadings: glucoseInRange.length,
      hyperEvents: hyperEvents,
      hypoEvents: hypoEvents,
      timeInRange: timeInRange,
      estimatedA1c: estimatedA1c,
      totalMeals: mealsInRange.length,
      averageCarbs: averageCarbs,
      totalActivityMinutes: totalActivityMinutes,
      medicationAdherence: medicationAdherence,
      averageSleepHours: averageSleepHours,
    );
  }

  // ==================== MOCK DATA GENERATION ====================

  void _generateMockGlucoseReadings() {
    final now = DateTime.now();
    const days = 30;

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final readingsPerDay = 4 + _random.nextInt(5);

      for (int i = 0; i < readingsPerDay; i++) {
        final hour = (i * 24 / readingsPerDay).floor();
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        double baseValue = 140 + _randomGaussian(-20, 20);
        if (hour >= 6 && hour <= 9) baseValue += 15;
        else if (hour >= 12 && hour <= 14) baseValue += 20;
        else if (hour >= 18 && hour <= 20) baseValue += 18;

        _glucoseReadings.add(GlucoseReading(
          id: 'glucose_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          value: baseValue.clamp(70, 300),
          context: _getGlucoseContext(hour),
          isFlagged: baseValue > 200 || baseValue < 70,
        ));
      }
    }
  }

  void _generateMockMeals() {
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

        _meals.add(MealLog(
          id: 'meal_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          type: mealType,
          description: _getMealDescription(mealType),
          carbs: 20.0 + _random.nextInt(60).toDouble(),
          calories: 200 + _random.nextInt(600),
          protein: 5.0 + _random.nextInt(30).toDouble(),
          fat: 5.0 + _random.nextInt(25).toDouble(),
        ));
      }
    }
  }

  void _generateMockActivities() {
    final now = DateTime.now();
    const days = 30;
    final activityTypes = ['Walking', 'Running', 'Cycling', 'Swimming', 'Gym', 'Yoga'];
    final intensities = ['Low', 'Moderate', 'High'];

    for (int day = 0; day < days; day++) {
      if (_random.nextDouble() > 0.4) {
        final date = now.subtract(Duration(days: days - day));
        final hour = 6 + _random.nextInt(14);
        final timestamp = DateTime(date.year, date.month, date.day, hour, _random.nextInt(60));

        final duration = 15 + _random.nextInt(75);
        final intensity = intensities[_random.nextInt(intensities.length)];

        _activities.add(ActivityLog(
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

  void _generateMockMedications() {
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
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}_morning',
            scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
            taken: _random.nextDouble() > 0.2,
            takenTime: _random.nextDouble() > 0.2
                ? DateTime(date.year, date.month, date.day, 8, _random.nextInt(60))
                : null,
          ));
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}_evening',
            scheduledTime: DateTime(date.year, date.month, date.day, 20, 0),
            taken: _random.nextDouble() > 0.2,
            takenTime: _random.nextDouble() > 0.2
                ? DateTime(date.year, date.month, date.day, 20, _random.nextInt(60))
                : null,
          ));
        } else {
          doses.add(MedicationDose(
            id: 'dose_${date.millisecondsSinceEpoch}',
            scheduledTime: DateTime(date.year, date.month, date.day, 8, 0),
            taken: _random.nextDouble() > 0.15,
            takenTime: _random.nextDouble() > 0.15
                ? DateTime(date.year, date.month, date.day, 8, _random.nextInt(60))
                : null,
          ));
        }
      }

      _medications.add(MedicationLog(
        id: 'med_${med.$1.hashCode}',
        medicationName: med.$1,
        dosage: med.$2,
        frequency: med.$3,
        prescribedDate: DateTime.now().subtract(const Duration(days: 90)),
        doses: doses,
      ));
    }
  }

  void _generateMockBloodPressureReadings() {
    final now = DateTime.now();
    const days = 30;
    for (int day = 0; day < days; day++) {
      if (_random.nextBool()) { // Not every day
        final date = now.subtract(Duration(days: days - day));
        final timestamp = DateTime(date.year, date.month, date.day, 7 + _random.nextInt(2), _random.nextInt(60));
        _bloodPressureReadings.add(BloodPressureReading(
          id: 'bp_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          systolic: 110 + _random.nextInt(20).toDouble(),
          diastolic: 70 + _random.nextInt(15).toDouble(),
        ));
      }
    }
  }

  void _generateMockCholesterolResults() {
    final now = DateTime.now();
    final testDates = [
      now.subtract(const Duration(days: 120)),
      now.subtract(const Duration(days: 240)),
    ];
    for (var testDate in testDates) {
      _cholesterolResults.add(CholesterolResult(
        id: 'chol_${testDate.millisecondsSinceEpoch}',
        testDate: testDate,
        value: 180 + _random.nextDouble() * 40, // 180-220
      ));
    }
  }

  void _generateMockBmiResults() {
    final now = DateTime.now();
    final testDates = [
      now.subtract(const Duration(days: 100)),
      now.subtract(const Duration(days: 200)),
    ];
    for (var testDate in testDates) {
      _bmiResults.add(BmiResult(
        id: 'bmi_${testDate.millisecondsSinceEpoch}',
        testDate: testDate,
        value: 22 + _random.nextDouble() * 5, // 22-27
      ));
    }
  }

  void _generateMockHbA1cResults() {
    final now = DateTime.now();
    final testDates = [
      now.subtract(const Duration(days: 90)),
      now.subtract(const Duration(days: 180)),
      now.subtract(const Duration(days: 270)),
    ];

    for (var testDate in testDates) {
      _hba1cResults.add(HbA1cResult(
        id: 'hba1c_${testDate.millisecondsSinceEpoch}',
        testDate: testDate,
        value: 6.5 + _random.nextDouble() * 1.5,
        labName: 'BioTective Labs',
      ));
    }
  }

  void _generateMockSleepLogs() {
    final now = DateTime.now();
    const days = 30;

    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final bedTime = DateTime(date.year, date.month, date.day, 22 + _random.nextInt(3), _random.nextInt(60));
      final sleepDuration = 6 + _random.nextInt(4); // 6-10 hours
      final wakeTime = bedTime.add(Duration(hours: sleepDuration));

      _sleepLogs.add(SleepLog(
        id: 'sleep_${bedTime.millisecondsSinceEpoch}',
        bedTime: bedTime,
        wakeTime: wakeTime,
        quality: 4 + _random.nextInt(7), // 4-10
      ));
    }
  }

  // ==================== UTILITY METHODS ====================

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

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  /// Clear all data (for testing)
  void clearAllData() {
    _glucoseReadings.clear();
    _meals.clear();
    _activities.clear();
    _medications.clear();
    _hba1cResults.clear();
    _sleepLogs.clear();
    _bloodPressureReadings.clear();
    _cholesterolResults.clear();
    _bmiResults.clear();
  }

  /// Refresh mock data
  void refreshMockData() { // Renamed for clarity, called by provider
    clearAllData();
    generateAndLoadMockData();
  }
}
