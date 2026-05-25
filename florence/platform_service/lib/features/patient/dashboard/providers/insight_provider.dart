import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';

/// The Insight Provider is now a fast, synchronous observer.
/// It reads the active Daily Recommendations and displays the most urgent one.
/// If the LLM determined the patient is perfectly healthy and returned 0 daily
/// recommendations, it praises them!
final insightProvider = Provider.autoDispose<AsyncValue<String>>((ref) {
  final recsAsync = ref.watch(recommendationProvider);
  
  return recsAsync.whenData((recs) {
    // Find active daily recommendations
    final activeDailies = recs.where((r) => r.isActive && r.timeframe == 'daily').toList();
    
    // If the LLM returned 0 tasks for today, they are doing great!
    if (activeDailies.isEmpty) {
      return "All health metrics are looking stable today! Great job.";
    }
    
    // Sort by priority (urgent -> low)
    activeDailies.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    final topRec = activeDailies.first;
    
    return "${topRec.title}: ${topRec.description}";
  });
});
