import 'package:florence/features/patient/core/repositories/monitor_data_repository.dart';

/// Lightweight health snapshot sent to the insight generation endpoint.
/// Much smaller than HealthSummary — only the signals needed for one insight.
class InsightSnapshot {
  final double? averageGlucose7d;   // mmol/L average over last 7 days
  final double? latestGlucose;      // most recent reading value
  final int hyperEvents7d;          // readings > 180 mg/dL (10 mmol/L)
  final int hypoEvents7d;           // readings < 70 mg/dL (3.9 mmol/L)
  final double timeInRange7d;       // fraction 0.0–1.0 (70–180 mg/dL)
  final int activityMinutesToday;   // logged activity minutes for today
  final int mealsToday;             // number of meals logged today
  final double medicationAdherence7d; // fraction 0.0–1.0
  final double? latestBmi;
  final List<String> activeDiseases;

  const InsightSnapshot({
    this.averageGlucose7d,
    this.latestGlucose,
    this.hyperEvents7d = 0,
    this.hypoEvents7d = 0,
    this.timeInRange7d = 0.0,
    this.activityMinutesToday = 0,
    this.mealsToday = 0,
    this.medicationAdherence7d = 0.0,
    this.latestBmi,
    this.activeDiseases = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      if (averageGlucose7d != null) 'average_glucose_7d': averageGlucose7d,
      if (latestGlucose != null) 'latest_glucose': latestGlucose,
      'hyper_events_7d': hyperEvents7d,
      'hypo_events_7d': hypoEvents7d,
      'time_in_range_7d': timeInRange7d,
      'activity_minutes_today': activityMinutesToday,
      'meals_today': mealsToday,
      'medication_adherence_7d': medicationAdherence7d,
      if (latestBmi != null) 'latest_bmi': latestBmi,
      if (activeDiseases.isNotEmpty) 'active_diseases': activeDiseases,
    };
  }

  /// Builds an InsightSnapshot from already-loaded health data.
  /// Call this after [HealthDataState] is available in the dashboard.
  factory InsightSnapshot.fromHealthData(HealthDataState data) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final todayStart = DateTime(now.year, now.month, now.day);

    // ── Glucose metrics (last 7 days) ──────────────────────────────
    final recentReadings = data.glucoseReadings
        .where((r) => r.timestamp.isAfter(sevenDaysAgo))
        .toList();

    double? avgGlucose;
    double? latestGlucose;
    int hyperEvents = 0;
    int hypoEvents = 0;
    double timeInRange = 0.0;

    if (recentReadings.isNotEmpty) {
      final values = recentReadings.map((r) => r.value).toList();
      avgGlucose = values.reduce((a, b) => a + b) / values.length;
      latestGlucose = recentReadings
          .reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b)
          .value;
      // Infer unit to pass correct bounds
      final bool isMmol = avgGlucose! < 40.0;
      final double highBound = isMmol ? 10.0 : 180.0;
      final double lowBound = isMmol ? 3.9 : 70.0;

      hyperEvents = values.where((v) => v > highBound).length;
      hypoEvents = values.where((v) => v < lowBound).length;
      final inRange = values.where((v) => v >= lowBound && v <= highBound).length;
      timeInRange = inRange / values.length;
    }

    // ── Activity today ─────────────────────────────────────────────
    final activityToday = data.activities
        .where((a) => a.startTime.isAfter(todayStart))
        .fold<int>(0, (sum, a) => sum + a.activeDurationMinutes);

    // ── Meals today ────────────────────────────────────────────────
    final mealsToday = data.meals
        .where((m) => m.timestamp.isAfter(todayStart))
        .length;

    // ── Latest BMI ─────────────────────────────────────────────────
    double? latestBmi;
    if (data.bmiResults.isNotEmpty) {
      latestBmi = data.bmiResults
          .reduce((a, b) => a.testDate.isAfter(b.testDate) ? a : b)
          .value;
    }

    // ── Active disease names ───────────────────────────────────────
    final activeDiseases = data.diseaseLogs
        .where((d) => d.status.toLowerCase() == 'active')
        .map((d) => d.conditionName)
        .toList();

    return InsightSnapshot(
      averageGlucose7d: avgGlucose,
      latestGlucose: latestGlucose,
      hyperEvents7d: hyperEvents,
      hypoEvents7d: hypoEvents,
      timeInRange7d: timeInRange,
      activityMinutesToday: activityToday,
      mealsToday: mealsToday,
      medicationAdherence7d: data.medicationAdherence,
      latestBmi: latestBmi,
      activeDiseases: activeDiseases,
    );
  }
}
