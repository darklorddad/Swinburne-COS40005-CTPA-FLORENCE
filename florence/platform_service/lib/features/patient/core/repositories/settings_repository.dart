import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:florence/core/services/api_service.dart';

class SettingsRepository {
  final ApiService _apiService;

  SettingsRepository(this._apiService);

  Future<PatientSettings> getSettings() async {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.appMetadata['role']?.toString().toUpperCase() ?? 'PATIENT';
    
    final endpoint = (role == 'CLINICIAN') 
        ? '/clinicians/me/settings' 
        : '/patients/me/settings';

    final response = await _apiService.get(endpoint);
    
    return PatientSettings(
      glucoseUnit: response['glucose_unit'] ?? 'mmol/L',
      cholesterolUnit: response['cholesterol_unit'] ?? 'mmol/L',
      showQuickActions: response['show_quick_actions'] ?? false,
    );
  }

  Future<void> updateSettings({String? glucoseUnit, String? cholesterolUnit, bool? showQuickActions}) async {
    final Map<String, dynamic> payload = {};
    if (glucoseUnit != null) payload['glucose_unit'] = glucoseUnit;
    if (cholesterolUnit != null) payload['cholesterol_unit'] = cholesterolUnit;
    if (showQuickActions != null) payload['show_quick_actions'] = showQuickActions;

    if (payload.isNotEmpty) {
      final user = Supabase.instance.client.auth.currentUser;
      final role = user?.appMetadata['role']?.toString().toUpperCase() ?? 'PATIENT';
      
      if (role == 'CLINICIAN') {
        await _apiService.put('/clinicians/me/settings', payload);
      } else {
        await _apiService.patch('/patients/me/settings', payload);
      }
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ApiService());
});
