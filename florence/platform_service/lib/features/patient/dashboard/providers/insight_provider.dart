import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  return ref.watch(dailyInsightStateProvider);
});
