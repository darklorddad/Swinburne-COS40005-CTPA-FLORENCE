import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:florence/features/patient/profile/providers/user_profile_provider.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core_data;

/// Caches the insight generated from the unified daily LLM call
class DailyInsightNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('cached_daily_insight');
  }

  Future<void> updateInsight(String? insight) async {
    state = insight;
    final prefs = await SharedPreferences.getInstance();
    if (insight != null) {
      await prefs.setString('cached_daily_insight', insight);
    } else {
      await prefs.remove('cached_daily_insight');
    }
  }
}

final dailyInsightStateProvider = NotifierProvider<DailyInsightNotifier, String?>(DailyInsightNotifier.new);

/// Exposes the cached insight to the UI smoothly
final insightProvider = Provider<String?>((ref) {
  // 1. Force the scanning animation if the AI is running
  final isGeneratingRecs = ref.watch(isGeneratingRecommendationsProvider);
  if (isGeneratingRecs) return null;

  // 2. Check local fast-cache first
  final cached = ref.watch(dailyInsightStateProvider);
  if (cached != null) return cached;

  // 3. Fallback to Database Profile (Survives device switches!)
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final dbInsight = profile?['daily_insight'] as String?;
  if (dbInsight != null && dbInsight.isNotEmpty) return dbInsight;

  // 4. Ultimate Fallback
  final healthData = ref.watch(core_data.monitorDataProvider).valueOrNull;
  if (healthData == null) return null;
  
  final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  final hasDataToday = healthData.allMonitorData.any((d) => d.measuredAt.toLocal().isAfter(todayStart)) ||
                       healthData.meals.any((m) => m.timestamp.toLocal().isAfter(todayStart)) ||
                       healthData.activities.any((a) => a.startTime.toLocal().isAfter(todayStart));
                 
  if (!hasDataToday) {
    return "You haven't logged any health data today. Start tracking your vitals to receive personalised insights!";
  }

  return "Great job keeping up with your health tracking today!";
});
