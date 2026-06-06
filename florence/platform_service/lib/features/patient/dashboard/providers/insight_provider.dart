import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core_data;
import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';
import 'package:florence/features/patient/dashboard/services/insight_service.dart';
import 'package:florence/features/patient/dashboard/models/insight_snapshot.dart';

/// Caches the insight generated from the unified daily LLM call
class DailyInsightNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void updateInsight(String? insight) {
    state = insight;
  }
}

final dailyInsightStateProvider = NotifierProvider<DailyInsightNotifier, String?>(DailyInsightNotifier.new);

/// The Insight Provider hits the LLM Engine to generate a fresh, 1-sentence
/// summary on the fly based on the current health snapshot AND active insights
/// (daily and weekly recommendations). It is not stored in the DB.
final insightProvider = FutureProvider<String>((ref) async {
  // 1. Check cache FIRST. If we have a cached insight, return it instantly.
  // By doing this before ref.watch(healthData), this provider won't needlessly
  // reload and flash the UI when health data is fetched in the background.
  final cached = ref.watch(dailyInsightStateProvider);
  if (cached != null) {
    return cached;
  }

  // 2. Otherwise, fetch data to generate on the fly
  final healthData = await ref.watch(core_data.monitorDataProvider.future);
  final recommendations = await ref.watch(recommendationProvider.future);
  
  bool hasDataToday = false;
  final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  
  hasDataToday = healthData.allMonitorData.any((d) => d.measuredAt.toLocal().isAfter(todayStart)) ||
                 healthData.meals.any((m) => m.timestamp.toLocal().isAfter(todayStart)) ||
                 healthData.activities.any((a) => a.startTime.toLocal().isAfter(todayStart));
                 
  if (!hasDataToday && recommendations.isEmpty) {
    return "You haven't logged any health data today. Start tracking your vitals to receive personalized insights!";
  }

  try {
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
