/// Supabase Health Service for FLORENCE Digital Health Platform
/// This service is prepared but NOT YET CONNECTED
///
/// To enable: Set ENABLE_SUPABASE = true in environment.dart
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/patient/core/models/health_data_models.dart';
import 'schema_definitions.dart';

/// Service for Supabase database operations
/// Currently NOT CONNECTED - uses mock data instead
class SupabaseHealthService {
  // Singleton pattern
  static final SupabaseHealthService _instance = SupabaseHealthService._internal();
  factory SupabaseHealthService() => _instance;
  SupabaseHealthService._internal();

  /// Check if Supabase is configured
  bool get isConfigured {
    // TODO: Check environment config when ready to connect
    return false; // Currently disabled
  }

  SupabaseClient get _client {
    // TODO: Return actual Supabase client when ready to connect
    // return Supabase.instance.client;
    throw UnimplementedError('Supabase not yet connected. Using in-memory data instead.');
  }

  String? get _currentUserId {
    // TODO: Get current user ID from Supabase Auth
    // return _client.auth.currentUser?.id;
    return null;
  }

  // ==================== GLUCOSE READINGS ====================

  Future<List<GlucoseReading>> fetchGlucoseReadings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      var query = _client
          .from(SupabaseTables.glucoseReadings)
          .select()
          .order(SupabaseColumns.timestamp, ascending: false);

      if (startDate != null) {
        query = query.gte(SupabaseColumns.timestamp, startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte(SupabaseColumns.timestamp, endDate.toIso8601String());
      }

      final data = await query;
      return (data as List).map((json) => GlucoseReading.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch glucose readings: $e');
    }
  }

  Future<GlucoseReading> insertGlucoseReading(GlucoseReading reading) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final data = await _client
          .from(SupabaseTables.glucoseReadings)
          .insert(reading.toJson())
          .select()
          .single();

      return GlucoseReading.fromJson(data);
    } catch (e) {
      throw Exception('Failed to insert glucose reading: $e');
    }
  }

  Future<void> deleteGlucoseReading(String id) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      await _client
          .from(SupabaseTables.glucoseReadings)
          .delete()
          .eq(SupabaseColumns.id, id);
    } catch (e) {
      throw Exception('Failed to delete glucose reading: $e');
    }
  }

  Future<GlucoseReading> updateGlucoseReading(GlucoseReading reading) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final data = await _client
          .from(SupabaseTables.glucoseReadings)
          .update(reading.toJson())
          .eq(SupabaseColumns.id, reading.id)
          .select()
          .single();

      return GlucoseReading.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update glucose reading: $e');
    }
  }

  // ==================== MEALS ====================

  Future<List<MealLog>> fetchMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      var query = _client
          .from(SupabaseTables.meals)
          .select()
          .order(SupabaseColumns.timestamp, ascending: false);

      if (startDate != null) {
        query = query.gte(SupabaseColumns.timestamp, startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte(SupabaseColumns.timestamp, endDate.toIso8601String());
      }

      final data = await query;
      return (data as List).map((json) => MealLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch meals: $e');
    }
  }

  Future<MealLog> insertMeal(MealLog meal) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final data = await _client
          .from(SupabaseTables.meals)
          .insert(meal.toJson())
          .select()
          .single();

      return MealLog.fromJson(data);
    } catch (e) {
      throw Exception('Failed to insert meal: $e');
    }
  }

  Future<void> deleteMeal(String id) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      await _client
          .from(SupabaseTables.meals)
          .delete()
          .eq(SupabaseColumns.id, id);
    } catch (e) {
      throw Exception('Failed to delete meal: $e');
    }
  }

  // ==================== ACTIVITIES ====================

  Future<List<ActivityLog>> fetchActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      var query = _client
          .from(SupabaseTables.activities)
          .select()
          .order(SupabaseColumns.timestamp, ascending: false);

      if (startDate != null) {
        query = query.gte(SupabaseColumns.timestamp, startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte(SupabaseColumns.timestamp, endDate.toIso8601String());
      }

      final data = await query;
      return (data as List).map((json) => ActivityLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch activities: $e');
    }
  }

  Future<ActivityLog> insertActivity(ActivityLog activity) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final data = await _client
          .from(SupabaseTables.activities)
          .insert(activity.toJson())
          .select()
          .single();

      return ActivityLog.fromJson(data);
    } catch (e) {
      throw Exception('Failed to insert activity: $e');
    }
  }

  // ==================== MEDICATIONS ====================

  Future<List<MedicationLog>> fetchMedications() async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final medsData = await _client
          .from(SupabaseTables.medications)
          .select('*, ${SupabaseTables.medicationDoses}(*)');

      return (medsData as List).map((json) => MedicationLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch medications: $e');
    }
  }

  Future<MedicationLog> insertMedication(MedicationLog medication) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      // Insert medication
      final medData = await _client
          .from(SupabaseTables.medications)
          .insert({
            'medication_name': medication.medicationName,
            'dosage': medication.dosage,
            'frequency': medication.frequency,
            'prescribed_date': medication.prescribedDate.toIso8601String(),
            'notes': medication.notes,
          })
          .select()
          .single();

      // Insert doses
      final medicationId = medData['id'];
      if (medication.doses.isNotEmpty) {
        await _client.from(SupabaseTables.medicationDoses).insert(
              medication.doses.map((dose) {
                final doseJson = dose.toJson();
                doseJson['medication_id'] = medicationId;
                return doseJson;
              }).toList(),
            );
      }

      return await fetchMedicationById(medicationId);
    } catch (e) {
      throw Exception('Failed to insert medication: $e');
    }
  }

  Future<MedicationLog> fetchMedicationById(String id) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final data = await _client
          .from(SupabaseTables.medications)
          .select('*, ${SupabaseTables.medicationDoses}(*)')
          .eq(SupabaseColumns.id, id)
          .single();

      return MedicationLog.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch medication: $e');
    }
  }

  Future<void> markDoseTaken(String medicationId, String doseId) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      await _client
          .from(SupabaseTables.medicationDoses)
          .update({
            'taken': true,
            'taken_time': DateTime.now().toIso8601String(),
          })
          .eq(SupabaseColumns.id, doseId);
    } catch (e) {
      throw Exception('Failed to mark dose as taken: $e');
    }
  }

  // ==================== HbA1c RESULTS ====================

  Future<List<HbA1cResult>> fetchHbA1cResults() async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final data = await _client
          .from(SupabaseTables.hba1cResults)
          .select()
          .order('test_date', ascending: false);

      return (data as List).map((json) => HbA1cResult.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch HbA1c results: $e');
    }
  }

  Future<HbA1cResult> insertHbA1cResult(HbA1cResult result) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final data = await _client
          .from(SupabaseTables.hba1cResults)
          .insert(result.toJson())
          .select()
          .single();

      return HbA1cResult.fromJson(data);
    } catch (e) {
      throw Exception('Failed to insert HbA1c result: $e');
    }
  }

  // ==================== SLEEP LOGS ====================

  Future<List<SleepLog>> fetchSleepLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      var query = _client
          .from(SupabaseTables.sleepLogs)
          .select()
          .order('bed_time', ascending: false);

      if (startDate != null) {
        query = query.gte('bed_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('bed_time', endDate.toIso8601String());
      }

      final data = await query;
      return (data as List).map((json) => SleepLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch sleep logs: $e');
    }
  }

  Future<SleepLog> insertSleepLog(SleepLog log) async {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    try {
      final data = await _client
          .from(SupabaseTables.sleepLogs)
          .insert(log.toJson())
          .select()
          .single();

      return SleepLog.fromJson(data);
    } catch (e) {
      throw Exception('Failed to insert sleep log: $e');
    }
  }

  // ==================== REAL-TIME SUBSCRIPTIONS ====================

  /// Subscribe to glucose reading changes (for real-time updates)
  RealtimeChannel subscribeToGlucoseReadings(
    void Function(List<GlucoseReading>) onData,
  ) {
    if (!isConfigured) throw UnimplementedError('Supabase not connected');

    return _client
        .channel('glucose_readings_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseTables.glucoseReadings,
          callback: (payload) {
            // Fetch updated data
            fetchGlucoseReadings().then(onData);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}

/// Example usage:
/// ```dart
/// final service = SupabaseHealthService();
///
/// // Fetch glucose readings
/// final readings = await service.fetchGlucoseReadings(
///   startDate: DateTime.now().subtract(Duration(days: 7)),
/// );
///
/// // Subscribe to real-time updates
/// final channel = service.subscribeToGlucoseReadings((readings) {
///   print('Updated readings: ${readings.length}');
/// });
///
/// // Unsubscribe when done
/// await service.unsubscribe(channel);
/// ```
