import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/health_data_models.dart';
import '../../core/repositories/monitor_data_repository.dart';
import '../../core/services/data_ingestion_service.dart';

// Repository Provider
final monitorDataRepositoryProvider = Provider<MonitorDataRepository>((ref) {
  return MonitorDataRepository();
});

// Data Service Provider (for Activity)
final dataIngestionServiceProvider = Provider<DataIngestionService>((ref) {
  return DataIngestionService();
});

// Monitor Data Provider
final monitorDataProvider = FutureProvider<List<MonitorData>>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  return repository.getAllMonitorData();
});

// Latest Activity Provider
final latestActivityProvider = FutureProvider<ActivityLog?>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  final activities = await repository.getActivityLogs();
  if (activities.isNotEmpty) {
    return activities.first;
  }
  return null;
});

// Patient Thresholds Provider
final patientThresholdsProvider = FutureProvider<List<HealthThreshold>>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  return repository.getHealthThresholds();
});

// Daily Patient Logs Provider (Meals)
final dailyPatientLogsProvider = FutureProvider<List<DailyPatientLog>>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  return repository.getDailyPatientLogs();
});

// Activity Logs Provider
final activityLogsProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final repository = ref.watch(monitorDataRepositoryProvider);
  return repository.getActivityLogs();
});
