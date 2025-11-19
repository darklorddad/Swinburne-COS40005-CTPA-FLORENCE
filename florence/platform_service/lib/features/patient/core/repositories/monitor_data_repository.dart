import '../models/health_data_models.dart';
import '../services/data_ingestion_service.dart';

/// Repository to fetch and map health data to MonitorData
class MonitorDataRepository {
  final DataIngestionService _dataService = DataIngestionService();

  /// Get all monitor data for all available types
  Future<List<MonitorData>> getAllMonitorData() async {
    // Try to fetch real data first
    if (_dataService.allGlucoseReadings.isEmpty) {
      await _dataService.fetchRealData();
    }

    final data = <MonitorData>[];

    // Glucose
    final glucoseReadings = _dataService.allGlucoseReadings;
    for (var reading in glucoseReadings) {
      data.add(MonitorData(
        id: int.tryParse(reading.id) ?? 0,
        patientId: 1, // Default patient ID
        dataType: MonitorDataType.GLUCOSE,
        value: reading.value,
        measuredAt: reading.timestamp,
      ));
    }

    // Blood Pressure
    final bpReadings = _dataService.allBloodPressureReadings;
    for (var reading in bpReadings) {
      data.add(MonitorData(
        id: int.tryParse(reading.id) ?? 0,
        patientId: 1,
        dataType: MonitorDataType.BLOOD_PRESSURE_SYSTOLIC,
        value: reading.systolic,
        measuredAt: reading.timestamp,
      ));
      data.add(MonitorData(
        id: int.tryParse(reading.id) ?? 0,
        patientId: 1,
        dataType: MonitorDataType.BLOOD_PRESSURE_DIASTOLIC,
        value: reading.diastolic,
        measuredAt: reading.timestamp,
      ));
    }

    // HbA1c
    final hba1cResults = _dataService.allHbA1cResults;
    for (var result in hba1cResults) {
      data.add(MonitorData(
        id: int.tryParse(result.id) ?? 0,
        patientId: 1,
        dataType: MonitorDataType.HBA1C,
        value: result.value,
        measuredAt: result.testDate,
      ));
    }

    // Cholesterol
    final cholesterolResults = _dataService.allCholesterolResults;
    for (var result in cholesterolResults) {
      data.add(MonitorData(
        id: int.tryParse(result.id) ?? 0,
        patientId: 1,
        dataType: MonitorDataType.CHOLESTEROL_TOTAL,
        value: result.value,
        measuredAt: result.testDate,
      ));
    }

    // BMI
    final bmiResults = _dataService.allBmiResults;
    for (var result in bmiResults) {
      data.add(MonitorData(
        id: int.tryParse(result.id) ?? 0,
        patientId: 1,
        dataType: MonitorDataType.BMI,
        value: result.value,
        measuredAt: result.testDate,
      ));
    }

    return data;
  }

  /// Get daily patient logs (meals) for overlay
  Future<List<DailyPatientLog>> getDailyPatientLogs() async {
    final meals = _dataService.allMeals;
    return meals.map((meal) {
      // Map MealLog to DailyPatientLog
      // Determine meal time based on type or hour if needed, but MealLog has 'type'
      String mealTime = 'SNACK';
      final typeUpper = meal.type.toUpperCase();
      if (typeUpper.contains('BREAKFAST')) mealTime = 'BREAKFAST';
      else if (typeUpper.contains('LUNCH')) mealTime = 'LUNCH';
      else if (typeUpper.contains('DINNER')) mealTime = 'DINNER';

      return DailyPatientLog(
        id: meal.id.hashCode, // Use hash code as int ID for now
        logDate: meal.timestamp,
        mealTime: mealTime,
        mealDesc: meal.description,
        // We don't have glucose before/after in MealLog, so leave null for now
      );
    }).toList();
  }

  /// Get health thresholds
  Future<List<HealthThreshold>> getHealthThresholds() async {
    // Ensure thresholds are fetched if empty (though fetchRealData should have done it)
    if (_dataService.allHealthThresholds.isEmpty) {
      await _dataService.fetchThresholds();
    }
    return _dataService.allHealthThresholds;
  }
}
