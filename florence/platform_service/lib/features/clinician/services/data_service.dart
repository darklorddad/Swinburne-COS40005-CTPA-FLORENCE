import 'package:clinician_dashboard/models/patient.dart';
import 'package:clinician_dashboard/models/alert.dart';
import 'package:clinician_dashboard/models/health_data.dart';
import 'package:clinician_dashboard/models/clinician_note.dart';

/// Abstract data service interface for fetching patient and health data
/// Implement this class with your API service (e.g., ApiDataService)
abstract class DataService {
  /// Get list of patients assigned to the current clinician
  Future<List<Patient>> getPatients();
  
  /// Get priority alerts for the current clinician
  Future<List<Alert>> getAlerts();
  
  /// Get health data for a specific patient
  Future<PatientHealthData> getPatientHealthData(String patientId);
  
  /// Get clinician notes for a specific patient
  Future<List<ClinicianNote>> getClinicianNotes(String patientId);
  
  /// Add a new patient
  Future<Patient> addPatient(Patient patient);
  
  /// Update patient information
  Future<void> updatePatient(Patient patient);
  
  /// Delete a patient
  Future<void> deletePatient(String patientId);
}

