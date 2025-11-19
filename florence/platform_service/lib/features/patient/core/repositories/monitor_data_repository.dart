import '../../../../core/services/api_service.dart';
import '../models/health_data_models.dart';
import '../services/data_ingestion_service.dart';

/// Repository to fetch and map health data to MonitorData
class MonitorDataRepository {
  final DataIngestionService _dataService = DataIngestionService();
  final ApiService _apiService = ApiService();

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
    try {
      final response = await _apiService.get('/patients/me/daily-logs');
      if (response is List) {
        return response.map((json) => DailyPatientLog.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching daily logs: $e');
      return [];
    }
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
