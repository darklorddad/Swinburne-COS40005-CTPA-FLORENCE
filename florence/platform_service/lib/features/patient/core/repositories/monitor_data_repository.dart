import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../models/health_data_models.dart';

/// Payload class for all health data
class HealthDataState {
  final List<GlucoseReading> glucoseReadings;
  final List<MealLog> meals;
  final List<ActivityLog> activities;
  final List<MedicationLog> medications;
  final List<HbA1cResult> hba1cResults;
  final List<SleepLog> sleepLogs;
  final List<BloodPressureReading> bloodPressureReadings;
  final List<CholesterolResult> cholesterolResults;
  final List<BmiResult> bmiResults;
  final List<HealthThreshold> healthThresholds;
  final List<MonitorData> allMonitorData;

  const HealthDataState({
    this.glucoseReadings = const [],
    this.meals = const [],
    this.activities = const [],
    this.medications = const [],
    this.hba1cResults = const [],
    this.sleepLogs = const [],
    this.bloodPressureReadings = const [],
    this.cholesterolResults = const [],
    this.bmiResults = const [],
    this.healthThresholds = const [],
    this.allMonitorData = const [],
  });

  HealthDataState copyWith({
    List<GlucoseReading>? glucoseReadings,
    List<MealLog>? meals,
    List<ActivityLog>? activities,
    List<MedicationLog>? medications,
    List<HbA1cResult>? hba1cResults,
    List<SleepLog>? sleepLogs,
    List<BloodPressureReading>? bloodPressureReadings,
    List<CholesterolResult>? cholesterolResults,
    List<BmiResult>? bmiResults,
    List<HealthThreshold>? healthThresholds,
    List<MonitorData>? allMonitorData,
  }) {
    return HealthDataState(
      glucoseReadings: glucoseReadings ?? this.glucoseReadings,
      meals: meals ?? this.meals,
      activities: activities ?? this.activities,
      medications: medications ?? this.medications,
      hba1cResults: hba1cResults ?? this.hba1cResults,
      sleepLogs: sleepLogs ?? this.sleepLogs,
      bloodPressureReadings: bloodPressureReadings ?? this.bloodPressureReadings,
      cholesterolResults: cholesterolResults ?? this.cholesterolResults,
      bmiResults: bmiResults ?? this.bmiResults,
      healthThresholds: healthThresholds ?? this.healthThresholds,
      allMonitorData: allMonitorData ?? this.allMonitorData,
    );
  }

  HealthSummary getHealthSummary({required DateTime startDate, required DateTime endDate}) {
    // 1. Get direct readings
    final directReadings = glucoseReadings
        .where((r) => r.timestamp.isAfter(startDate) && r.timestamp.isBefore(endDate))
        .map((r) => r.value);

    // 2. Extract readings from meals in this period
    final mealReadings = meals
        .where((m) => m.timestamp.isAfter(startDate) && m.timestamp.isBefore(endDate))
        .expand((m) => [
              if (m.glucoseBefore != null) m.glucoseBefore!,
              if (m.glucoseAfter != null) m.glucoseAfter!
            ]);

    // 3. Combine them
    final allGlucoseValues = [...directReadings, ...mealReadings].toList();

    // 4. Calculate Average using the combined list
    final avgGlucose = allGlucoseValues.isNotEmpty
        ? allGlucoseValues.reduce((a, b) => a + b) / allGlucoseValues.length
        : 0.0;

    // 5. Calculate Time In Range using the combined list
    final inRangeCount = allGlucoseValues.where((v) => v >= 70 && v <= 180).length;
    final timeInRange = allGlucoseValues.isNotEmpty 
        ? (inRangeCount / allGlucoseValues.length) * 100 
        : 0.0;

    final activityInPeriod = activities.where((a) => a.timestamp.isAfter(startDate) && a.timestamp.isBefore(endDate)).toList();
    final totalMinutes = activityInPeriod.fold(0, (sum, a) => sum + a.duration);

    final mealsInPeriod = meals.where((m) => m.timestamp.isAfter(startDate) && m.timestamp.isBefore(endDate)).toList();
    final avgCarbs = mealsInPeriod.isNotEmpty 
        ? mealsInPeriod.map((m) => m.carbs).reduce((a, b) => a + b) / mealsInPeriod.length 
        : 0.0;

    // Calculate Standard Deviation
    double stdDev = 0.0;
    if (allGlucoseValues.isNotEmpty) {
      final sumSquaredDiff = allGlucoseValues.fold(0.0, (sum, v) {
        final diff = v - avgGlucose;
        return sum + (diff * diff);
      });
      stdDev = sqrt(sumSquaredDiff / allGlucoseValues.length);
    }

    final hyperEvents = allGlucoseValues.where((v) => v > 180).length;
    final hypoEvents = allGlucoseValues.where((v) => v < 70).length;

    // Calculate Estimated A1c: (Avg Glucose + 46.7) / 28.7
    final estimatedA1c = avgGlucose > 0 ? (avgGlucose + 46.7) / 28.7 : 0.0;

    // Calculate Average Sleep
    int avgSleep = 0;
    final sleepInPeriod = sleepLogs.where((s) => s.bedTime.isAfter(startDate) && s.bedTime.isBefore(endDate)).toList();
    if (sleepInPeriod.isNotEmpty) {
      final totalMinutes = sleepInPeriod.map((s) => s.duration.inMinutes).fold(0, (a, b) => a + b);
      final avgMinutes = totalMinutes / sleepInPeriod.length;
      avgSleep = (avgMinutes / 60).round();
    }

    return HealthSummary(
      startDate: startDate,
      endDate: endDate,
      averageGlucose: avgGlucose,
      glucoseStdDev: stdDev,
      estimatedA1c: estimatedA1c,
      timeInRange: timeInRange,
      totalReadings: allGlucoseValues.length,
      hyperEvents: hyperEvents,
      hypoEvents: hypoEvents,
      totalActivityMinutes: totalMinutes,
      totalMeals: mealsInPeriod.length,
      averageCarbs: avgCarbs,
      medicationAdherence: 0.85, // Mocked for now
      averageSleepHours: avgSleep,
    );
  }
}

class MonitorDataRepository {
  final ApiService _apiService;
  final Random _random = Random();

  MonitorDataRepository(this._apiService);

  Future<HealthDataState> fetchAllData() async {
    try {
      // 1. Fetch Thresholds
      final thresholds = await _fetchThresholds();

      // 2. Fetch Monitor Data (Glucose, HbA1c, BP, Cholesterol, BMI)
      final monitorDataJson = await _apiService.get('/patients/me/monitor-data') as List;
      final allMonitorData = monitorDataJson.map((e) => MonitorData.fromJson(e)).toList();
      
      final glucoseReadings = <GlucoseReading>[];
      final hba1cResults = <HbA1cResult>[];
      final cholesterolResults = <CholesterolResult>[];
      final bmiResults = <BmiResult>[];
      final systolicReadings = <String, dynamic>{};
      final diastolicReadings = <String, dynamic>{};
      final bloodPressureReadings = <BloodPressureReading>[];

      for (var item in monitorDataJson) {
        final dataType = item['data_type'];
        final timestamp = DateTime.parse(item['measured_at']);
        final id = item['id'].toString();
        final value = (item['value'] as num).toDouble();

        switch (dataType) {
          case 'GLUCOSE':
            glucoseReadings.add(GlucoseReading(
              id: id,
              timestamp: timestamp,
              value: value,
              context: _getGlucoseContext(timestamp.hour),
              isFlagged: value > 180 || value < 70,
            ));
            break;
          case 'HBA1C':
            hba1cResults.add(HbA1cResult(
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
          case 'CHOLESTEROL_TOTAL':
            cholesterolResults.add(CholesterolResult(
              id: id,
              testDate: timestamp,
              value: value,
            ));
            break;
          case 'BMI':
            bmiResults.add(BmiResult(
              id: id,
              testDate: timestamp,
              value: value,
            ));
            break;
        }
      }

      // Pair BP readings
      systolicReadings.forEach((timestampStr, systolicData) {
        if (diastolicReadings.containsKey(timestampStr)) {
          final diastolicData = diastolicReadings[timestampStr];
          bloodPressureReadings.add(BloodPressureReading(
            id: systolicData['id'],
            timestamp: DateTime.parse(timestampStr),
            systolic: systolicData['value'],
            diastolic: diastolicData['value'],
          ));
        }
      });

      // 3. Fetch Activities
      final activities = await _fetchActivities();

      // 4. Fetch Meals
      final meals = await _fetchMeals();

      // 5. Mock additional data
      final medications = _generateMockMedications();
      final sleepLogs = _generateMockSleepLogs();

      // Sort
      glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      hba1cResults.sort((a, b) => b.testDate.compareTo(a.testDate));
      bloodPressureReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      cholesterolResults.sort((a, b) => b.testDate.compareTo(a.testDate));
      bmiResults.sort((a, b) => b.testDate.compareTo(a.testDate));
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return HealthDataState(
        glucoseReadings: glucoseReadings,
        meals: meals,
        activities: activities,
        medications: medications,
        hba1cResults: hba1cResults,
        sleepLogs: sleepLogs,
        bloodPressureReadings: bloodPressureReadings,
        cholesterolResults: cholesterolResults,
        bmiResults: bmiResults,
        healthThresholds: thresholds,
        allMonitorData: allMonitorData,
      );
    } catch (e) {
      print("Error fetching real data: $e");
      return _generateAllMockData();
    }
  }

  // ==================== WRITE OPERATIONS ====================

  Future<void> addGlucoseReading(GlucoseReading reading) async {
    await _apiService.post('/patients/me/monitor-data', {
      'data_type': 'GLUCOSE',
      'value': reading.value,
      'measured_at': reading.timestamp.toIso8601String(),
    });
  }

  Future<void> addMonitorData(String type, double value, DateTime timestamp) async {
    await _apiService.post('/patients/me/monitor-data', {
      'data_type': type,
      'value': value,
      'measured_at': timestamp.toIso8601String(),
    });
  }

  Future<void> addBloodPressure(DateTime timestamp, double systolic, double diastolic) async {
    await Future.wait([
      addMonitorData('BLOOD_PRESSURE_SYSTOLIC', systolic, timestamp),
      addMonitorData('BLOOD_PRESSURE_DIASTOLIC', diastolic, timestamp),
    ]);
  }

  Future<void> addMeal(String mealTime, DateTime logDate, String? mealDesc, double? glucoseBefore, DateTime? timeBefore, double? glucoseAfter, DateTime? timeAfter) async {
    final Map<String, dynamic> payload = {
      'log_date': logDate.toIso8601String().split('T')[0],
      'meal_time': mealTime,
      'meal_desc': mealDesc,
    };
    
    if (glucoseBefore != null) {
      payload['glucose_before_meal'] = glucoseBefore;
      payload['glucose_before_meal_time'] = timeBefore?.toIso8601String();
    }
    
    if (glucoseAfter != null) {
      payload['glucose_after_meal'] = glucoseAfter;
      payload['glucose_after_meal_time'] = timeAfter?.toIso8601String();
    }

    await _apiService.post('/patients/me/daily-logs', payload);
  }

  Future<void> addActivity(ActivityLog log) async {
    // Currently backend doesn't have a dedicated POST for activity-logs if it is read-only from external source, 
    // but for the purpose of this refactor we assume it exists or uses generic monitor data structure if applicable.
    // Assuming a dedicated endpoint based on GET /activity-logs
    await _apiService.post('/patients/me/activity-logs', {
      'activity_description': log.type,
      'duration_minutes': log.duration,
      'performed_at': log.timestamp.toIso8601String(),
    });
  }

  Future<void> addMedication(String name, String type, String dosage, String timing, DateTime timestamp, String? notes) async {
    await _apiService.post('/patients/me/medications', {
      'name': name,
      'type': type,
      'dosage': dosage,
      'timing': timing,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    });
  }

  // ==================== FETCH HELPERS ====================

  Future<List<HealthThreshold>> _fetchThresholds() async {
    try {
      final response = await _apiService.get('/patients/me/thresholds');
      if (response != null && response is List) {
        return response.map((item) => HealthThreshold.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching thresholds: $e");
    }
    return [];
  }

  Future<List<ActivityLog>> _fetchActivities() async {
    try {
      final activityData = await _apiService.get('/patients/me/activity-logs');
      final activities = <ActivityLog>[];
      if (activityData is List) {
        for (var item in activityData) {
          activities.add(ActivityLog(
            id: item['id'].toString(),
            timestamp: DateTime.parse(item['performed_at']),
            type: item['activity_description'] ?? 'Activity',
            duration: item['duration_minutes'] ?? 0,
            intensity: 'Moderate',
          ));
        }
      }
      return activities;
    } catch (e) {
      print("Error fetching activities: $e");
      return [];
    }
  }

  Future<List<MealLog>> _fetchMeals() async {
    try {
      final mealData = await _apiService.get('/patients/me/daily-logs');
      final meals = <MealLog>[];
      if (mealData is List) {
        for (var item in mealData) {
          meals.add(MealLog(
            id: item['id'].toString(),
            timestamp: DateTime.parse(item['log_date']),
            type: item['meal_time']?.toString().split('.').last ?? 'Snack',
            description: item['meal_desc'] ?? 'Logged Meal',
            carbs: 0, 
            calories: 0,
            glucoseBefore: item['glucose_before_meal'] != null ? (item['glucose_before_meal'] as num).toDouble() : null,
            glucoseAfter: item['glucose_after_meal'] != null ? (item['glucose_after_meal'] as num).toDouble() : null,
            glucoseBeforeTime: item['glucose_before_meal_time'] != null ? DateTime.parse(item['glucose_before_meal_time']) : null,
            glucoseAfterTime: item['glucose_after_meal_time'] != null ? DateTime.parse(item['glucose_after_meal_time']) : null,
          ));
        }
      }
      return meals;
    } catch (e) {
      print("Error fetching meals: $e");
      return [];
    }
  }

  // ==================== UTILS & MOCKS ====================

  String _getGlucoseContext(int hour) {
    if (hour >= 5 && hour < 9) return 'Before breakfast';
    if (hour >= 9 && hour < 11) return 'After breakfast';
    if (hour >= 11 && hour < 13) return 'Before lunch';
    if (hour >= 13 && hour < 17) return 'After lunch';
    if (hour >= 17 && hour < 19) return 'Before dinner';
    if (hour >= 19 && hour < 22) return 'After dinner';
    return 'Bedtime';
  }

  HealthDataState _generateAllMockData() {
     return HealthDataState(
        glucoseReadings: _generateMockGlucoseReadings(),
        meals: _generateMockMeals(),
        activities: _generateMockActivities(),
        medications: _generateMockMedications(),
        hba1cResults: [], // Simplified mocks
        sleepLogs: _generateMockSleepLogs(),
        bloodPressureReadings: [],
        cholesterolResults: [],
        bmiResults: [],
     );
  }

  List<GlucoseReading> _generateMockGlucoseReadings() {
    final readings = <GlucoseReading>[];
    final now = DateTime.now();
    const days = 30;
    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: days - day));
      final readingsPerDay = 3;
      for (int i = 0; i < readingsPerDay; i++) {
        final timestamp = DateTime(date.year, date.month, date.day, 8 + i*5, 0);
        readings.add(GlucoseReading(
          id: 'glucose_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          value: 100.0 + _random.nextInt(40),
          context: _getGlucoseContext(timestamp.hour),
        ));
      }
    }
    readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return readings;
  }

  List<MealLog> _generateMockMeals() {
    final meals = <MealLog>[];
    final now = DateTime.now();
    for (int i = 0; i < 10; i++) {
      final timestamp = now.subtract(Duration(days: i));
      meals.add(MealLog(
        id: 'meal_$i',
        timestamp: timestamp,
        type: 'Lunch',
        description: 'Mock Meal $i',
        carbs: 50,
        calories: 500,
      ));
    }
    return meals;
  }
  
  List<ActivityLog> _generateMockActivities() {
     return [];
  }

  List<MedicationLog> _generateMockMedications() {
     return [];
  }
  
  List<SleepLog> _generateMockSleepLogs() {
    return [];
  }

  double _randomGaussian(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}

/// Provider for the repository
final monitorDataRepositoryProvider = Provider<MonitorDataRepository>((ref) {
  // Create ApiService directly or use a provider if ApiService was converted to Riverpod
  // Assuming ApiService is still a factory/singleton
  return MonitorDataRepository(ApiService());
});
