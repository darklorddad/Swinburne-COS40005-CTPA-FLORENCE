import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';

class SettingsRepository {
  final ApiService _apiService;

  SettingsRepository(this._apiService);

  Future<PatientSettings> getSettings() async {
    final response = await _apiService.get('/patients/me/settings');
    
    return PatientSettings(
      glucoseUnit: response['glucose_unit'] ?? 'mmol/L',
      cholesterolUnit: response['cholesterol_unit'] ?? 'mmol/L',
    );
  }

  Future<void> updateSettings({String? glucoseUnit, String? cholesterolUnit}) async {
    final Map<String, dynamic> payload = {};
    if (glucoseUnit != null) payload['glucose_unit'] = glucoseUnit;
    if (cholesterolUnit != null) payload['cholesterol_unit'] = cholesterolUnit;

    if (payload.isNotEmpty) {
      await _apiService.patch('/patients/me/settings', payload);
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ApiService());
});
