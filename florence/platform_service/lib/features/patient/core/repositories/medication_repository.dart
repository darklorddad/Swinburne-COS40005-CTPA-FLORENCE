import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/medication_models.dart';

/// Repository for managing medication data and intake logs.
class MedicationRepository {
  final ApiService _apiService;

  MedicationRepository(this._apiService);

  /// Fetches the medication schedule and intake logs for a specific date.
  Future<MedicationScheduleResponse> getMedicationSchedule(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _apiService.get('/patients/me/medication-schedule?target_date=$dateStr');
    return MedicationScheduleResponse.fromJson(response as Map<String, dynamic>);
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
}

/// Provider for the MedicationRepository.
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(ApiService());
});
