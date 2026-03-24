import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/medication_models.dart';

/// Repository for managing medication data and intake logs.
class MedicationRepository {
  final ApiService _apiService;

  MedicationRepository(this._apiService);

  /// Fetches the compiled daily/weekly schedule with log counts.
  Future<List<dynamic>> getMedicationSchedule() async {
    try {
      final response = await _apiService.get('/patients/me/medication-schedule');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print("Error fetching schedule: $e");
      return [];
    }
  }

  /// Records a medication intake event.
  Future<void> logMedicationIntake(int patientMedicationId, String status, {DateTime? takenAt}) async {
    final Map<String, dynamic> payload = {
      'patient_medication_id': patientMedicationId,
      'status': status,
    };
    
    if (takenAt != null) {
      payload['taken_at'] = takenAt.toUtc().toIso8601String();
    }
    
    await _apiService.post('/patients/me/medication-intake', payload);
  }

  /// Deletes the most recent intake log for today for a specific medication.
  Future<void> unlogMedicationIntake(int patientMedicationId) async {
    await _apiService.delete('/patients/me/medication-intake/$patientMedicationId');
  }

  /// Fetches all medications for the current patient.
  Future<List<PatientMedication>> getPatientMedications() async {
    final response = await _apiService.get('/patients/me/medications');
    if (response is List) {
      return response.map((json) => PatientMedication.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Adds a new medication for the current patient.
  Future<void> addPatientMedication(Map<String, dynamic> data) async {
    await _apiService.post('/patients/me/medications', data);
  }

  /// Updates an existing medication.
  Future<void> updatePatientMedication(int id, Map<String, dynamic> data) async {
    await _apiService.patch('/patients/me/medications/$id', data);
  }

  /// Updates the status of a medication (e.g., to 'PAST').
  Future<void> updateMedicationStatus(int id, String status) async {
    await _apiService.patch('/patients/me/medications/$id', {'status': status});
  }

  /// Fetches the global medication dictionary for search/autocomplete.
  Future<List<dynamic>> getMedicationDictionary() async {
    try {
      final response = await _apiService.get('/patients/medications/dictionary');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print("Error fetching medication dictionary: $e");
      return [];
    }
  }

  /// Fetches the available dosage frequencies.
  Future<List<dynamic>> getDosageFrequencies() async {
    try {
      final response = await _apiService.get('/patients/medications/frequencies');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print("Error fetching dosage frequencies: $e");
      return [];
    }
  }
}

/// Provider for the MedicationRepository.
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(ApiService());
});
