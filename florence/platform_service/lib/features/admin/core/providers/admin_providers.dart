import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';

/// Fetches the live list of patients from FastAPI `/admin/patients`
final adminPatientsProvider = FutureProvider.autoDispose<List<AdminPatient>>((ref) async {
  final apiService = ApiService();
  try {
    final response = await apiService.get('/admin/patients');
    if (response is List) {
      return response.map((json) => AdminPatient.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (e) {
    throw Exception('Failed to load patients: $e');
  }
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
      activeClinicians: 12, 
      connectedDevices: 89,
    );
  });
});