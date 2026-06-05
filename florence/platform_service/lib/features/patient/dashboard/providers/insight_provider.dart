import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core_data;
import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';
import 'package:florence/features/patient/dashboard/services/insight_service.dart';
import 'package:florence/features/patient/dashboard/models/insight_snapshot.dart';

/// The Insight Provider hits the LLM Engine to generate a fresh, 1-sentence
/// summary on the fly based on the current health snapshot AND active insights
/// (daily and weekly recommendations). It is not stored in the DB.
final insightProvider = FutureProvider.autoDispose<String>((ref) async {
  final healthData = await ref.watch(core_data.monitorDataProvider.future);
  final recommendations = await ref.watch(recommendationProvider.future);
  
  bool hasDataToday = false;
  final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  
  hasDataToday = healthData.allMonitorData.any((d) => d.measuredAt.toLocal().isAfter(todayStart)) ||
                 healthData.meals.any((m) => m.timestamp.toLocal().isAfter(todayStart)) ||
                 healthData.activities.any((a) => a.startTime.toLocal().isAfter(todayStart));
                 
  if (!hasDataToday && recommendations.isEmpty) {
    return "You haven't logged any health data today. Tap a quick action below to start!";
  }

  try {
    // Collect active recommendations/insights to summarise
    final activeInsights = recommendations
        .where((r) => r.isActive)
        .map((r) => "${r.title}: ${r.description}")
        .toList();

    final settings = ref.watch(patientSettingsProvider);
    final snapshot = InsightSnapshot.fromData(healthData, activeInsights, settings.glucoseUnit);
    final service = InsightService();
    return await service.generate(snapshot);
  } catch (e) {
    return "Your health data is being monitored. Keep logging to get personalized insights!";
  }
});
