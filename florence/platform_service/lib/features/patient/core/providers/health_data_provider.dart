/// Health Data Provider for FLORENCE Digital Health Platform
/// State management for patient health data using Provider

import 'package:flutter/foundation.dart';
import '../models/health_data_models.dart';
import '../services/data_ingestion_service.dart';
import '../../chat/services/chatbot_service.dart';

/// Provider for managing all health-related data
class HealthDataProvider with ChangeNotifier {
  final DataIngestionService _dataService = DataIngestionService();
  final ChatbotService _chatbotService = ChatbotService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== GLUCOSE DATA ====================

  List<GlucoseReading> get allGlucoseReadings =>
      _dataService.allGlucoseReadings;

  List<GlucoseReading> getGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataService.getGlucoseReadings(
      startDate: startDate,
      endDate: endDate,
    );
  }

  GlucoseReading? get latestGlucose =>
      allGlucoseReadings.isNotEmpty ? allGlucoseReadings.first : null;

  Future<void> addGlucoseReading(GlucoseReading reading) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.addGlucoseReading(reading);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGlucoseReading(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.deleteGlucoseReading(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGlucoseReading(GlucoseReading reading) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.updateGlucoseReading(reading);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== MEAL DATA ====================

  List<MealLog> get allMeals => _dataService.allMeals;

  List<MealLog> getMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataService.getMeals(
      startDate: startDate,
      endDate: endDate,
    );
  }

  MealLog? get latestMeal => allMeals.isNotEmpty ? allMeals.first : null;

  Future<void> addMeal(MealLog meal) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.addMeal(meal);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMeal(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.deleteMeal(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMeal(MealLog meal) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.updateMeal(meal);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== ACTIVITY DATA ====================

  List<ActivityLog> get allActivities => _dataService.allActivities;

  List<ActivityLog> getActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataService.getActivities(
      startDate: startDate,
      endDate: endDate,
    );
  }

  ActivityLog? get latestActivity =>
      allActivities.isNotEmpty ? allActivities.first : null;

  Future<void> addActivity(ActivityLog activity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.addActivity(activity);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.deleteActivity(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateActivity(ActivityLog activity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.updateActivity(activity);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== MEDICATION DATA ====================

  List<MedicationLog> get allMedications => _dataService.allMedications;

  Future<void> addMedication(MedicationLog medication) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.addMedication(medication);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.deleteMedication(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMedication(MedicationLog medication) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.updateMedication(medication);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markDoseTaken(String medicationId, String doseId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.markDoseTaken(medicationId, doseId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== HbA1c DATA ====================

  List<HbA1cResult> get allHbA1cResults => _dataService.allHbA1cResults;

  HbA1cResult? get latestHbA1c => _dataService.latestHbA1c;

  Future<void> addHbA1cResult(HbA1cResult result) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.addHbA1cResult(result);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SLEEP DATA ====================

  List<SleepLog> get allSleepLogs => _dataService.allSleepLogs;

  List<SleepLog> getSleepLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataService.getSleepLogs(
      startDate: startDate,
      endDate: endDate,
    );
  }

  SleepLog? get latestSleep => allSleepLogs.isNotEmpty ? allSleepLogs.first : null;

  Future<void> addSleepLog(SleepLog log) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.addSleepLog(log);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== HEALTH SUMMARY ====================

  HealthSummary getHealthSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dataService.getHealthSummary(
      startDate: startDate,
      endDate: endDate,
    );
  }

  HealthSummary get last7DaysSummary {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    return getHealthSummary(startDate: startDate, endDate: endDate);
  }

  HealthSummary get last30DaysSummary {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    return getHealthSummary(startDate: startDate, endDate: endDate);
  }

  HealthSummary get last90DaysSummary {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 90));
    return getHealthSummary(startDate: startDate, endDate: endDate);
  }

  // ==================== STATISTICS ====================

  /// Average glucose for a time period
  double getAverageGlucose({DateTime? startDate, DateTime? endDate}) {
    final readings = getGlucoseReadings(startDate: startDate, endDate: endDate);
    if (readings.isEmpty) return 0;
    return readings.map((r) => r.value).reduce((a, b) => a + b) / readings.length;
  }

  /// Time in range percentage
  double getTimeInRange({DateTime? startDate, DateTime? endDate}) {
    final readings = getGlucoseReadings(startDate: startDate, endDate: endDate);
    if (readings.isEmpty) return 0;
    final inRange = readings.where((r) => r.isNormal).length;
    return (inRange / readings.length) * 100;
  }

  /// Total carbs consumed
  double getTotalCarbs({DateTime? startDate, DateTime? endDate}) {
    final meals = getMeals(startDate: startDate, endDate: endDate);
    if (meals.isEmpty) return 0;
    return meals.map((m) => m.carbs).reduce((a, b) => a + b);
  }

  /// Total activity minutes
  int getTotalActivityMinutes({DateTime? startDate, DateTime? endDate}) {
    final activities = getActivities(startDate: startDate, endDate: endDate);
    if (activities.isEmpty) return 0;
    return activities.map((a) => a.duration).reduce((a, b) => a + b);
  }

  /// Medication adherence rate
  double getMedicationAdherence() {
    if (allMedications.isEmpty) return 0;
    return allMedications.map((m) => m.adherenceRate).reduce((a, b) => a + b) / allMedications.length;
  }

  // ==================== UTILITY METHODS ====================

  /// Refresh all data from service
  Future<void> refreshData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _dataService.refreshMockData();

      // CRITICAL: Invalidate chatbot context so it fetches fresh data
      _chatbotService.invalidateContext();
      print('HealthDataProvider: Data refreshed, chatbot context invalidated');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clearAllData() {
    _dataService.clearAllData();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
