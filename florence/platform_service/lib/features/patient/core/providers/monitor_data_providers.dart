import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/monitor_data_repository.dart';
import '../models/health_data_models.dart';

/// Main provider that fetches and holds all health data
final monitorDataProvider = AsyncNotifierProvider<MonitorDataNotifier, HealthDataState>(MonitorDataNotifier.new);

class MonitorDataNotifier extends AsyncNotifier<HealthDataState> {
  @override
  Future<HealthDataState> build() async {
    final repository = ref.read(monitorDataRepositoryProvider);
    return repository.fetchAllData();
  }
  
  /// Force refresh of data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
       final repository = ref.read(monitorDataRepositoryProvider);
       return repository.fetchAllData();
    });
  }
}

/// ================== DERIVED PROVIDERS ==================

final glucoseReadingsProvider = Provider<List<GlucoseReading>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.glucoseReadings ?? [];
});

final mealsProvider = Provider<List<MealLog>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.meals ?? [];
});

final activitiesProvider = Provider<List<ActivityLog>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.activities ?? [];
});

final medicationsProvider = Provider<List<MedicationLog>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.medications ?? [];
});

final hba1cResultsProvider = Provider<List<HbA1cResult>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.hba1cResults ?? [];
});

final sleepLogsProvider = Provider<List<SleepLog>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.sleepLogs ?? [];
});

final bloodPressureReadingsProvider = Provider<List<BloodPressureReading>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.bloodPressureReadings ?? [];
});

final cholesterolResultsProvider = Provider<List<CholesterolResult>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.cholesterolResults ?? [];
});

final bmiResultsProvider = Provider<List<BmiResult>>((ref) {
  return ref.watch(monitorDataProvider).valueOrNull?.bmiResults ?? [];
});

final latestGlucoseProvider = Provider<GlucoseReading?>((ref) {
  final readings = ref.watch(glucoseReadingsProvider);
  return readings.isNotEmpty ? readings.first : null;
});

/// ================== MUTATION PROVIDERS ==================

final addGlucoseProvider = AutoDisposeAsyncNotifierProvider<AddGlucoseNotifier, void>(AddGlucoseNotifier.new);

class AddGlucoseNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> add(GlucoseReading reading) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(monitorDataRepositoryProvider).addGlucoseReading(reading);
      // Invalidate the main provider to refetch data
      ref.invalidate(monitorDataProvider);
    });
  }
}

/// ================== AGGREGATION PROVIDERS ==================

final healthSummaryProvider = FutureProvider.family<HealthSummary, ({DateTime start, DateTime end})>((ref, range) async {
  final healthData = await ref.watch(monitorDataProvider.future);
  return healthData.getHealthSummary(startDate: range.start, endDate: range.end);
});
