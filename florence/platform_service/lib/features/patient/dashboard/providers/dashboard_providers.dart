import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core;
import 'package:florence/features/patient/core/repositories/medication_repository.dart';

// Adapters for Dashboard to use Centralized Data Layer

final monitorDataProvider = Provider<AsyncValue<List<MonitorData>>>((ref) {
  return ref.watch(core.monitorDataProvider).whenData((state) => state.allMonitorData);
}, isAutoDispose: true);

final latestActivityProvider = Provider<AsyncValue<ActivityLog?>>((ref) {
  return ref.watch(core.monitorDataProvider).whenData((state) => 
    state.activities.isNotEmpty ? state.activities.first : null // Repo sorts descending (Newest first)
  );
}, isAutoDispose: true);


final dailyPatientLogsProvider = Provider<AsyncValue<List<DailyPatientLog>>>((ref) {
  return ref.watch(core.monitorDataProvider).whenData((state) {
      return state.meals.map((m) => DailyPatientLog(
        id: int.tryParse(m.id) ?? 0,
        logDate: m.timestamp,
        mealTime: m.type.toUpperCase(),
        mealDesc: m.description,
        glucoseBeforeMeal: m.glucoseBefore,
        glucoseAfterMeal: m.glucoseAfter,
        glucoseBeforeMealTime: m.glucoseBeforeTime,
        glucoseAfterMealTime: m.glucoseAfterTime,
        calories: m.calories,
        photoUrl: m.photoUrl,
      )).toList();
  });
}, isAutoDispose: true);

/// Provider for the daily medication schedule and intake logs.
/// Updated to return List<dynamic> to match the repository's lean implementation.
final dailyMedicationScheduleProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getMedicationSchedule(DateTime.now());
}, isAutoDispose: true);
