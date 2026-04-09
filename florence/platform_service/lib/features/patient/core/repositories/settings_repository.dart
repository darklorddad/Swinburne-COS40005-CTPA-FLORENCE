import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';

class SettingsRepository {
  final ApiService _apiService;

  SettingsRepository(this._apiService);

  Future<void> updateSettings({String? glucoseUnit, String? cholesterolUnit}) async {
    final Map<String, dynamic> payload = {};
    if (glucoseUnit != null) payload['glucose_unit'] = glucoseUnit;
    if (cholesterolUnit != null) payload['cholesterol_unit'] = cholesterolUnit;

    // Assuming backend endpoint exists: PUT /patients/me
    // We use the existing patient profile update endpoint as it usually contains these preferences
    await _apiService.put('/patients/me', payload);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ApiService());
});
