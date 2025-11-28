import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/models/alert.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/clinician_note.dart';
import 'package:florence/features/clinician/models/clinician.dart';
import 'package:florence/features/clinician/services/data_service.dart';
import 'package:florence/features/clinician/services/api_service.dart';
import 'package:flutter/foundation.dart';

class ApiDataService implements DataService {
  final ApiService _api = ApiService();

  @override
  Future<Clinician> getClinicianProfile() async {
    final data = await _api.get('/clinicians/me');
    if (data == null) throw Exception('Profile not found');
    return Clinician.fromJson(data);
  }

  @override
  Future<void> updateClinicianProfile(Clinician clinician) async {
    await _api.put('/clinicians/me', clinician.toJson());
  }

  @override
  Future<List<Patient>> getPatients() async {
    try {
      final data = await _api.get('/clinicians/me/patients');
      if (data == null) return [];
      
      // Assuming data is a list of patient objects
      return (data as List).map((json) => Patient(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? 'Unknown',
        age: json['age'] ?? 0,
        gender: json['gender'] ?? 'Unknown',
        condition: _parseCondition(json['condition']),
        riskLevel: _parseRiskLevel(json['risk_level']),
        lastSync: json['last_sync'] != null ? DateTime.parse(json['last_sync']) : DateTime.now(),
        contactInfo: json['contact_info'] ?? '',
      )).toList();
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      return [];
    }
  }

  @override
  Future<List<Patient>> getAvailablePatients() async {
    try {
      final data = await _api.get('/clinicians/available-patients');
      if (data == null) return [];
      
      return (data as List).map((json) => Patient(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? 'Unknown',
        age: json['age'] ?? 0,
        gender: json['gender'] ?? 'Unknown',
        condition: _parseCondition(json['condition']),
        riskLevel: _parseRiskLevel(json['risk_level']),
        lastSync: json['last_sync'] != null ? DateTime.parse(json['last_sync']) : DateTime.now(),
        contactInfo: json['contact_info'] ?? '',
      )).toList();
    } catch (e) {
      debugPrint('Error fetching available patients: $e');
      return [];
    }
  }

  @override
  Future<void> assignPatient(String patientId) async {
    await _api.post('/clinicians/patients/$patientId/assign', {});
  }

  @override
  Future<PatientHealthData> getPatientHealthData(String patientId) async {
    try {
      // Endpoint: GET /clinicians/me/patients/{id}
      // Includes logs, notes, thresholds. 
      // We need to map this to PatientHealthData.
      final data = await _api.get('/clinicians/me/patients/$patientId');
      if (data == null) throw Exception('Patient data not found');

      // Mapping logic (placeholder based on expected structure)
      // We might need to adapt this based on actual API response structure
      return PatientHealthData(
        patientId: patientId,
        weight: (data['weight'] ?? 0.0).toDouble(),
        height: (data['height'] ?? 0.0).toDouble(),
        glucoseReadings: _parseGlucoseReadings(data['glucose_logs']),
        hbA1cReadings: _parseHbA1cReadings(data['hba1c_logs']),
        bloodPressureReadings: _parseBPReadings(data['bp_logs']),
        cholesterolReadings: _parseCholesterolReadings(data['cholesterol_logs']),
        activityData: _parseActivityData(data['activity_logs']),
        mealEntries: [], // Map if available
        automatedActions: [], // Map if available
        medications: [], // Map if available
        aiGeneratedSummary: data['ai_summary'] ?? '',
        detectedPatterns: [], // Map if available
        recommendations: [], // Map if available
      );
    } catch (e) {
      debugPrint('Error fetching patient health data: $e');
      // Return empty data or rethrow
      return PatientHealthData(
        patientId: patientId,
        weight: 0,
        height: 0,
        glucoseReadings: [],
        hbA1cReadings: [],
        bloodPressureReadings: [],
        cholesterolReadings: [],
        activityData: [],
        mealEntries: [],
        automatedActions: [],
        medications: [],
        aiGeneratedSummary: 'Error fetching data',
        detectedPatterns: [],
        recommendations: [],
      );
    }
  }

  @override
  Future<List<Alert>> getAlerts() async {
    // Not explicitly mentioned in prompt endpoints, returning empty for now
    return [];
  }

  @override
  Future<List<ClinicianNote>> getClinicianNotes(String patientId) async {
    return [];
  }

  @override
  Future<Patient> addPatient(Patient patient) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePatient(String patientId) async {
    throw UnimplementedError();
  }

  // Parsing helpers
  ChronicCondition _parseCondition(String? condition) {
    // Map string to enum
    return ChronicCondition.type2Diabetes; // Default/Placeholder
  }

  RiskLevel _parseRiskLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'high': return RiskLevel.high;
      case 'medium': return RiskLevel.medium;
      case 'low': return RiskLevel.low;
      default: return RiskLevel.low;
    }
  }

  List<GlucoseReading> _parseGlucoseReadings(List? logs) {
    if (logs == null) return [];
    return logs.map((log) => GlucoseReading(
      timestamp: DateTime.parse(log['timestamp']),
      value: (log['value'] ?? 0).toDouble(),
      context: log['context'] ?? '',
    )).toList();
  }

  List<HbA1cReading> _parseHbA1cReadings(List? logs) {
    if (logs == null) return [];
    return logs.map((log) => HbA1cReading(
      timestamp: DateTime.parse(log['timestamp']),
      value: (log['value'] ?? 0).toDouble(),
    )).toList();
  }

  List<BloodPressureReading> _parseBPReadings(List? logs) {
    if (logs == null) return [];
    return logs.map((log) => BloodPressureReading(
      timestamp: DateTime.parse(log['timestamp']),
      systolic: (log['systolic'] ?? 0).toDouble(),
      diastolic: (log['diastolic'] ?? 0).toDouble(),
    )).toList();
  }

  List<CholesterolReading> _parseCholesterolReadings(List? logs) {
    if (logs == null) return [];
    return logs.map((log) => CholesterolReading(
      timestamp: DateTime.parse(log['timestamp']),
      total: (log['total'] ?? 0).toDouble(),
      ldl: (log['ldl'] ?? 0).toDouble(),
      hdl: (log['hdl'] ?? 0).toDouble(),
      triglycerides: (log['triglycerides'] ?? 0).toDouble(),
    )).toList();
  }

  List<ActivityData> _parseActivityData(List? logs) {
    if (logs == null) return [];
    return logs.map((log) => ActivityData(
      date: DateTime.parse(log['date']),
      steps: log['steps'] ?? 0,
      activeMinutes: log['active_minutes'] ?? 0,
      caloriesBurned: log['calories'] ?? 0,
    )).toList();
  }
}

