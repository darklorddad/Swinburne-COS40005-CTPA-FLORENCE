import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/core/services/api_service.dart';

class PatientThreshold {
  final String dataType;
  final double minValue;
  final double maxValue;

  PatientThreshold({required this.dataType, required this.minValue, required this.maxValue});

  factory PatientThreshold.fromJson(Map<String, dynamic> json) {
    return PatientThreshold(
      dataType: json['data_type'],
      minValue: (json['min_value'] as num).toDouble(),
      maxValue: (json['max_value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'data_type': dataType,
        'min_value': minValue,
        'max_value': maxValue,
      };
}

class ThresholdNotifier extends AsyncNotifier<List<PatientThreshold>> {
  @override
  Future<List<PatientThreshold>> build() async {
    return _fetchThresholds();
  }

  Future<List<PatientThreshold>> _fetchThresholds() async {
    final api = ApiService();
    final response = await api.get('/patients/me/thresholds');
    return (response as List).map((e) => PatientThreshold.fromJson(e)).toList();
  }

  Future<void> updateThresholds(List<PatientThreshold> updatedThresholds) async {
    final api = ApiService();
    
    // Save the current healthy state before we try anything risky
    final previousState = state; 
    
    try {
      final payload = {
        "thresholds": updatedThresholds.map((t) => t.toJson()).toList()
      };
      await api.put('/patients/me/thresholds', payload);
      
      // If successful, fetch the newly updated data
      state = AsyncData(await _fetchThresholds()); 
    } catch (e) {
      // If it fails, instantly put the good data back so the UI doesn't break
      state = previousState; 
      
      // Toss the error up to the UI so it can show a SnackBar
      rethrow; 
    }
  }
}

final patientThresholdsProvider = AsyncNotifierProvider<ThresholdNotifier, List<PatientThreshold>>(() {
  return ThresholdNotifier();
});
