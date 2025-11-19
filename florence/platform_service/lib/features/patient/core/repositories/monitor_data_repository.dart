import '../../../../core/services/api_service.dart';
import '../models/health_data_models.dart';

/// Repository to fetch and map health data to MonitorData
class MonitorDataRepository {
  final ApiService _apiService = ApiService();

  /// Get all monitor data for all available types directly from API
  Future<List<MonitorData>> getAllMonitorData() async {
    try {
      final response = await _apiService.get('/patients/me/monitor-data');
      if (response is List) {
        return response.map((json) => MonitorData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching monitor data: $e');
      // Return empty list on error instead of mock data
      return [];
    }
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

  /// Get health thresholds directly from API
  Future<List<HealthThreshold>> getHealthThresholds() async {
    try {
      final response = await _apiService.get('/patients/me/thresholds');
      if (response is List) {
        return response.map((json) => HealthThreshold.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching thresholds: $e');
      // Return basic defaults if API fails, or empty
      return [
        const HealthThreshold(dataType: MonitorDataType.GLUCOSE, minValue: 70, maxValue: 180),
      ];
    }
  }
}
