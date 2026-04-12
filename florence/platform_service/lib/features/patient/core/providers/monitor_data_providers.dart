import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';

/// Main provider that fetches and holds all health data
final monitorDataProvider = AsyncNotifierProvider<MonitorDataNotifier, HealthDataState>(MonitorDataNotifier.new, isAutoDispose: true);

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
  return ref.watch(monitorDataProvider).asData?.value.glucoseReadings ?? [];
}, isAutoDispose: true);

final mealsProvider = Provider<List<MealLog>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.meals ?? [];
}, isAutoDispose: true);

final activitiesProvider = Provider<List<ActivityLog>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.activities ?? [];
}, isAutoDispose: true);

final medicationsProvider = Provider<List<MedicationLog>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.medications ?? [];
}, isAutoDispose: true);

final hba1cResultsProvider = Provider<List<HbA1cResult>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.hba1cResults ?? [];
}, isAutoDispose: true);

final sleepLogsProvider = Provider<List<SleepLog>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.sleepLogs ?? [];
}, isAutoDispose: true);

final bloodPressureReadingsProvider = Provider<List<BloodPressureReading>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.bloodPressureReadings ?? [];
}, isAutoDispose: true);

final cholesterolResultsProvider = Provider<List<CholesterolResult>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.cholesterolResults ?? [];
}, isAutoDispose: true);

final bmiResultsProvider = Provider<List<BmiResult>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.bmiResults ?? [];
}, isAutoDispose: true);

final latestGlucoseProvider = Provider<GlucoseReading?>((ref) {
  final readings = ref.watch(glucoseReadingsProvider);
  return readings.isNotEmpty ? readings.first : null;
}, isAutoDispose: true);

/// ================== MUTATION PROVIDERS ==================

final addGlucoseProvider = AsyncNotifierProvider<AddGlucoseNotifier, void>(AddGlucoseNotifier.new, isAutoDispose: true);

class AddGlucoseNotifier extends AsyncNotifier<void> {
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
}, isAutoDispose: true);
