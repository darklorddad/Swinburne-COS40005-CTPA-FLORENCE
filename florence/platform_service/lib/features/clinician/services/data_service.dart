import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/models/alert.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/clinician_note.dart';
import 'package:florence/features/clinician/models/clinician.dart';

/// Abstract data service interface for fetching patient and health data
/// Implement this class with your API service (e.g., ApiDataService)
abstract class DataService {
  /// Get current clinician profile
  Future<Clinician> getClinicianProfile();

  /// Update clinician profile
  Future<void> updateClinicianProfile(Clinician clinician);

  /// Get list of patients assigned to the current clinician
  Future<List<Patient>> getPatients();
  
  /// Get priority alerts for the current clinician
  Future<List<Alert>> getAlerts();
  
  /// Get health data for a specific patient
  Future<PatientHealthData> getPatientHealthData(String patientId);
  
  /// Get clinician notes for a specific patient
  Future<List<ClinicianNote>> getClinicianNotes(String patientId);

  /// Get list of unassigned patients
  Future<List<Patient>> getAvailablePatients();

  /// Assign a patient to the current clinician
  Future<void> assignPatient(String patientId);

  /// Assign a patient to the current clinician
  Future<void> unassignPatient(String patientId);
  
  /// Add a new patient
  Future<Patient> addPatient(Patient patient);
  
  /// Update patient information
  Future<void> updatePatient(Patient patient);
  
  /// Delete a patient
  Future<void> deletePatient(String patientId);
}

