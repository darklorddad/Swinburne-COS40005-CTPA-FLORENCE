import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart' as core;

// Adapters for Dashboard to use Centralized Data Layer

final monitorDataProvider = Provider<AsyncValue<List<MonitorData>>>((ref) {
  return ref.watch(core.monitorDataProvider).whenData((state) => state.allMonitorData);
}, isAutoDispose: true);

final latestActivityProvider = Provider<AsyncValue<ActivityLog?>>((ref) {
  return ref.watch(core.monitorDataProvider).whenData((state) => 
    state.activities.isNotEmpty ? state.activities.first : null // Repo sorts descending (Newest first)
  );
}, isAutoDispose: true);

final patientThresholdsProvider = Provider<AsyncValue<List<HealthThreshold>>>((ref) {
  return ref.watch(core.monitorDataProvider).whenData((state) => state.healthThresholds);
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
      )).toList();
  });
}, isAutoDispose: true);
