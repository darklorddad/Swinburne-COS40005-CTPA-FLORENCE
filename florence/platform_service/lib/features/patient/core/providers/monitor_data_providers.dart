import 'package:florence/core/models/medication_models.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/disease_providers.dart';
import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main provider that fetches and holds all health data
final monitorDataProvider = AsyncNotifierProvider<MonitorDataNotifier, HealthDataState>(MonitorDataNotifier.new, isAutoDispose: true);

class MonitorDataNotifier extends AsyncNotifier<HealthDataState> {
  int _offset = 0;
  final int _limit = 20;
  bool _hasReachedMax = false;

  @override
  Future<HealthDataState> build() async {
    _offset = 0;
    _hasReachedMax = false;
    final repository = ref.read(monitorDataRepositoryProvider);
    return repository.fetchAllData(limit: _limit, offset: _offset);
  }

  /// Force refresh of data
  Future<void> refresh() async {
    _offset = 0;
    _hasReachedMax = false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(monitorDataRepositoryProvider);
      return repository.fetchAllData(limit: _limit, offset: _offset);
    });
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || _hasReachedMax) return;

    debugPrint('🔥 SWIPE DETECTED: Fetching older data! Current offset: $_offset');

    final repository = ref.read(monitorDataRepositoryProvider);
    final currentState = state.value;
    if (currentState == null) return;

    _offset += _limit;

    // We don't set state to loading here to keep the UI stable while fetching
    try {
      final newMonitorData = await repository.fetchMonitorDataPage(
        limit: _limit,
        offset: _offset,
      );

      debugPrint('✅ SUCCESS: Fetched ${newMonitorData.length} older logs!');

      if (newMonitorData.length < _limit) {
        _hasReachedMax = true;
        debugPrint('🏁 REACHED END: No more data to fetch.');
      }

      // We need to re-process the HealthDataState with the appended monitor data
      // For simplicity in this implementation, we append to allMonitorData 
      // and let the UI logic handle the filtering/sorting as it already does.
      state = AsyncValue.data(currentState.copyWith(
        allMonitorData: [...currentState.allMonitorData, ...newMonitorData],
      ));
    } catch (e, stack) {
      _offset -= _limit; // Rollback offset on error
      debugPrint('❌ ERROR fetching next page: $e');
    }
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

final patientMedicationsFromStateProvider = Provider<List<PatientMedication>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.patientMedications ?? [];
}, isAutoDispose: true);

final diseaseLogsFromStateProvider = Provider<List<DiseaseLog>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.diseaseLogs ?? [];
}, isAutoDispose: true);

final hba1cResultsProvider = Provider<List<HbA1cResult>>((ref) {
  return ref.watch(monitorDataProvider).asData?.value.hba1cResults ?? [];
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
