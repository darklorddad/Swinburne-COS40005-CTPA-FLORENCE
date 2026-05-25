import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/patient/dashboard/models/insight_snapshot.dart';
import 'package:florence/features/patient/dashboard/services/insight_service.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';

// Temporary dummy text — remove once backend /insights/generate is live
const String _kDummyInsight =
    'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!';

/// Manages the AI insight shown on the dashboard card.
///
/// - Does NOT auto-fetch on init (triggered explicitly by the dashboard
///   after health data is available, same pattern as chat history).
/// - Caches the last result for 1 hour to avoid hammering the API.
/// - Fallback chain: AI insight → first active recommendation → dummy text.
final insightProvider =
    AsyncNotifierProvider<InsightNotifier, String?>(InsightNotifier.new);

class InsightNotifier extends AsyncNotifier<String?> {
  final _service = InsightService();

  DateTime? _lastFetchedAt;
  bool _isFetching = false; // prevents concurrent duplicate calls

  @override
  Future<String?> build() async => null;

  /// Fetch a fresh insight from the backend.
  ///
  /// Skips the network call if a result was fetched within the last hour,
  /// or if a fetch is already in progress.
  /// Pass [force: true] to override the cache (e.g. on pull-to-refresh).
  Future<void> fetch(InsightSnapshot snapshot, {bool force = false}) async {
    // In-flight guard — prevents two simultaneous calls
    if (_isFetching) {
      debugPrint('[InsightProvider] Fetch already in progress, skipping duplicate call.');
      return;
    }

    // Cache guard — skip if fetched less than 1 hour ago
    if (!force && _lastFetchedAt != null) {
      final age = DateTime.now().difference(_lastFetchedAt!);
      if (age < const Duration(hours: 1)) {
        debugPrint('[InsightProvider] Cache hit (${age.inMinutes}m old), skipping fetch.');
        return;
      }
    }

    _isFetching = true;
    state = const AsyncLoading();

    try {
      final insight = await _service.generate(snapshot);
      _lastFetchedAt = DateTime.now();
      state = AsyncData(insight);
      debugPrint('[InsightProvider] Fetched insight successfully.');
    } catch (e) {
      debugPrint('[InsightProvider] Service failed: $e — applying fallback.');
      state = AsyncData(_fallback());
    } finally {
      _isFetching = false;
    }
  }

  /// Invalidates cache so the next [fetch] call hits the network.
  void invalidate() {
    _lastFetchedAt = null;
  }

  /// Fallback chain: first active recommendation → dummy text.
  String _fallback() {
    try {
      final recs = ref.read(recommendationProvider).value ?? [];
      final firstActive = recs.where((r) => r.isActive).firstOrNull;
      if (firstActive != null && firstActive.description.isNotEmpty) {
        return firstActive.description;
      }
    } catch (_) {}
    return _kDummyInsight;
  }
}
