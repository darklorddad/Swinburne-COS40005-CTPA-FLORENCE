import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';

class DiseaseLog {
  final int? id;
  final String conditionName;
  final String status;
  final DateTime? diagnosedDate;
  final DateTime? resolvedDate;
  final String? notes;

  DiseaseLog({
    this.id,
    required this.conditionName,
    required this.status,
    this.diagnosedDate,
    this.resolvedDate,
    this.notes,
  });

  factory DiseaseLog.fromJson(Map<String, dynamic> json) {
    return DiseaseLog(
      id: json['id'],
      conditionName: json['condition_name'],
      status: json['status'],
      diagnosedDate: json['diagnosed_date'] != null ? DateTime.parse(json['diagnosed_date']) : null,
      resolvedDate: json['resolved_date'] != null ? DateTime.parse(json['resolved_date']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'condition_name': conditionName,
        'status': status,
        'diagnosed_date': diagnosedDate?.toIso8601String().split('T')[0],
        'resolved_date': resolvedDate?.toIso8601String().split('T')[0],
        'notes': notes,
      };
}

class DiseaseLogNotifier extends AsyncNotifier<List<DiseaseLog>> {
  @override
  Future<List<DiseaseLog>> build() async {
    return _fetchLogsFromApi();
  }

  Future<List<DiseaseLog>> _fetchLogsFromApi() async {
    final api = ApiService();
    final response = await api.get('/patients/me/disease-logs');

    return (response as List)
        .map((json) => DiseaseLog.fromJson(json))
        .toList();
  }

  Future<void> addLog(DiseaseLog log) async {
    final api = ApiService();

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await api.post('/patients/me/disease-logs', log.toJson());
      return _fetchLogsFromApi();
    });
  }
}

final diseaseLogProvider =
    AsyncNotifierProvider<DiseaseLogNotifier, List<DiseaseLog>>(() {
  return DiseaseLogNotifier();
});
