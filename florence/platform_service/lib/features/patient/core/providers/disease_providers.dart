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

class DiseaseLogNotifier extends StateNotifier<AsyncValue<List<DiseaseLog>>> {
  final ApiService _api = ApiService();
  DiseaseLogNotifier() : super(const AsyncValue.loading()) {
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get('/patients/me/disease-logs');
      final List<DiseaseLog> logs = (response as List)
          .map((json) => DiseaseLog.fromJson(json))
          .toList();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLog(DiseaseLog log) async {
    try {
      await _api.post('/patients/me/disease-logs', log.toJson());
      await fetchLogs();
    } catch (e) {
      rethrow;
    }
  }
}

final diseaseLogProvider =
    StateNotifierProvider<DiseaseLogNotifier, AsyncValue<List<DiseaseLog>>>((ref) {
  return DiseaseLogNotifier();
});
