import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';

/// Repository for Admin Data
/// Handles direct communication with the FastAPI backend
class AdminRepository {
  final ApiService _apiService;

  AdminRepository(this._apiService);

  /// Fetch all patients
  Future<List<AdminPatient>> fetchPatients() async {
    try {
      final response = await _apiService.get('/admin/patients');
      if (response is List) {
        return response
            .map((json) => AdminPatient.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print("AdminRepository Error fetching patients: $e");
      throw Exception('Failed to load patients: $e');
    }
  }

  /// Register a new patient
  Future<void> registerNewPatient(Map<String, dynamic> patientData) async {
    try {
      // Force the role to PATIENT as expected by the backend
      patientData['role'] = 'PATIENT';
      
      // If the admin didn't specify a password, provide a secure temporary one
      if (patientData['password'] == null || patientData['password'].isEmpty) {
        patientData['password'] = 'FlorenceTemp123!';
      }

      await _apiService.post('/auth/register', patientData);
    } catch (e) {
      print("AdminRepository Error registering patient: $e");
      throw Exception('Registration failed: $e');
    }
  }

  /// Update Patient Risk Level
  Future<void> updatePatientRiskLevel(int patientId, String riskLevel) async {
    try {
      await _apiService.put('/admin/patients/$patientId', {
        'risk_level': riskLevel.toUpperCase(),
      });
    } catch (e) {
      print("AdminRepository Error updating risk: $e");
      throw Exception('Failed to update risk level: $e');
    }
  }

  /// Assign Clinician to Patient
  Future<void> assignClinicianToPatient(int patientId, int? clinicianId) async {
    try {
      await _apiService.put('/admin/patients/$patientId/assign-clinician', {
        'clinician_id': clinicianId,
      });
    } catch (e) {
      print("AdminRepository Error assigning clinician: $e");
      throw Exception('Failed to assign clinician: $e');
    }
  }

  // Fetch recent admin activity logs (for the dashboard)
  Future<List<AdminActivity>> fetchRecentActivity() async {
    try {
      final response = await _apiService.get('/admin/recent-activity');
      if (response is List) {
        return response.map((json) => AdminActivity.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print("AdminRepository Error fetching activity: $e");
      throw Exception('Failed to load activity: $e');
    }
  }
}

// ==========================================
// PROVIDERS
// ==========================================

/// Provides the AdminRepository instance
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ApiService());
});

/// Fetches the live list of patients from FastAPI `/admin/patients`
final adminPatientsProvider = FutureProvider.autoDispose<List<AdminPatient>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.fetchPatients();
});

/// Automatically derives dashboard metrics from the patient list
final adminMetricsProvider = Provider.autoDispose<AsyncValue<AdminMetrics>>((ref) {
  final patientsAsync = ref.watch(adminPatientsProvider);
  
  return patientsAsync.whenData((patients) {
    final highRiskCount = patients.where((p) => p.isHighRisk).length;
    
    // activeClinicians and connectedDevices are mocked for the prototype, 
    // but the patient counts are real-time.
    return AdminMetrics(
      totalPatients: patients.length,
      highRiskPatients: highRiskCount,
      hypoPatients: patients.where((p) => p.isHypo).length,
      hyperPatients: patients.where((p) => p.isHyper).length,
    );
  });
});

/// Fetches the recent system activity feed
final adminActivityProvider = FutureProvider.autoDispose<List<AdminActivity>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.fetchRecentActivity();
});