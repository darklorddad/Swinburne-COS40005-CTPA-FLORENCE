import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core_data;
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';

/// The Insight Provider is now a fast, synchronous observer.
/// It reads the active Daily Recommendations and displays the most urgent one.
/// If the LLM determined the patient is perfectly healthy and returned 0 daily
/// recommendations, it praises them!
final insightProvider = Provider.autoDispose<AsyncValue<String>>((ref) {
  final recsAsync = ref.watch(recommendationProvider);
  final healthData = ref.watch(core_data.monitorDataProvider).value;
  
  return recsAsync.whenData((recs) {
    // Find active daily recommendations
    final activeDailies = recs.where((r) => r.isActive && r.timeframe == 'daily').toList();
    
    // If the LLM returned 0 tasks for today, check if they actually logged anything!
    if (activeDailies.isEmpty) {
      bool hasDataToday = false;
      if (healthData != null) {
        final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
        hasDataToday = healthData.allMonitorData.any((d) => d.measuredAt.toLocal().isAfter(todayStart)) ||
                       healthData.meals.any((m) => m.timestamp.toLocal().isAfter(todayStart)) ||
                       healthData.activities.any((a) => a.startTime.toLocal().isAfter(todayStart));
      }
      
      if (!hasDataToday) {
        return "You haven't logged any health data today. Tap a quick action below to start!";
      }
      
      return "All health metrics are looking stable today! Great job.";
    }
    
    // Sort by priority (urgent -> low)
    activeDailies.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    final topRec = activeDailies.first;
    
    return "${topRec.title}: ${topRec.description}";
  });
});
