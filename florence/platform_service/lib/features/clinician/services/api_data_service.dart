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
      return (data as List).map((json) {
        final diseaseLogs = json['disease_logs'] as List? ?? [];
        final monitorData = json['patient_monitor_data'] as List? ?? [];
        
        DateTime? latest;
        for (var log in monitorData) {
          final ts = log['measured_at'] != null ? DateTime.tryParse(log['measured_at']) : null;
          if (ts != null && (latest == null || ts.isAfter(latest))) latest = ts;
        }

        final activeDiseases = diseaseLogs
            .where((log) => log['status']?.toString().toLowerCase() == 'active')
            .map((log) => log['condition_name']?.toString() ?? 'Unknown')
            .toList();

        return Patient(
          id: json['id']?.toString() ?? '',
          name: json['name'] ?? 'Unknown',
          age: 0, // Age requires date_of_birth which is not in this endpoint
          gender: 'Unknown',
          activeDiseases: activeDiseases,
          riskLevel: _parseRiskLevel(json['risk_level']),
          lastUpdate: latest,
          contactInfo: json['phone_number'] ?? json['contact_info'] ?? '',
          emergencyContactName: json['emergency_contact_name'],
          emergencyContactRelationship: json['emergency_contact_relationship'],
          emergencyContactPhone: json['emergency_contact_phone'],
        );
      }).toList();
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
      
      return (data as List).map((json) {
        final diseaseLogs = json['disease_logs'] as List? ?? [];
        final monitorData = json['patient_monitor_data'] as List? ?? [];
        
        DateTime? latest;
        for (var log in monitorData) {
          final ts = log['measured_at'] != null ? DateTime.tryParse(log['measured_at']) : null;
          if (ts != null && (latest == null || ts.isAfter(latest))) latest = ts;
        }

        final activeDiseases = diseaseLogs
            .where((log) => log['status']?.toString().toLowerCase() == 'active')
            .map((log) => log['condition_name']?.toString() ?? 'Unknown')
            .toList();

        return Patient(
          id: json['id']?.toString() ?? '',
          name: json['name'] ?? 'Unknown',
          age: 0,
          gender: 'Unknown',
          activeDiseases: activeDiseases,
          riskLevel: _parseRiskLevel(json['risk_level']),
          lastUpdate: latest,
          contactInfo: json['phone_number'] ?? json['contact_info'] ?? '',
          emergencyContactName: json['emergency_contact_name'],
          emergencyContactRelationship: json['emergency_contact_relationship'],
          emergencyContactPhone: json['emergency_contact_phone'],
        );
      }).toList();
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
  Future<void> unassignPatient(String patientId) async {
    await _api.post('/clinicians/patients/$patientId/unassign', {});
  }

  @override
  Future<void> addPatientNote(String patientId, String noteContent) async {
    await _api.post('/clinicians/me/patients/$patientId/notes', {
      'note_content': noteContent,
    });
  }

  @override
  Future<void> updatePatientRiskLevel(String patientId, String riskLevel) async {
    await _api.put('/clinicians/me/patients/$patientId/assess-risk', {
      'risk_level': riskLevel.toUpperCase(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPatientThresholds(String patientId) async {
    final data = await _api.get('/clinicians/me/patients/$patientId/thresholds');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<void> setPatientThresholds(String patientId, List<Map<String, dynamic>> thresholds) async {
    await _api.put('/clinicians/me/patients/$patientId/thresholds', thresholds);
  }

  @override
  Future<Patient> getPatient(String patientId) async {
    try {
      final data = await _api.get('/clinicians/me/patients/$patientId');
      if (data == null) throw Exception('Patient data not found');

      final profile = data['profile'];
      if (profile == null) throw Exception('Patient profile not found');

      int calculatedAge = 0;
      if (profile['date_of_birth'] != null) {
        final dob = DateTime.parse(profile['date_of_birth']);
        final now = DateTime.now();
        calculatedAge = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          calculatedAge--;
        }
      }

      final diseaseLogs = data['disease_logs'] as List? ?? [];
      final activeDiseases = diseaseLogs
          .where((log) => log['status']?.toString().toLowerCase() == 'active')
          .map((log) => log['condition_name']?.toString() ?? 'Unknown')
          .toList();

      final monitorData = data['monitor_data'] as List? ?? [];
      DateTime? latest;
      for (var log in monitorData) {
        final ts = log['measured_at'] != null ? DateTime.tryParse(log['measured_at']) : null;
        if (ts != null && (latest == null || ts.isAfter(latest))) latest = ts;
      }

      return Patient(
        id: profile['id']?.toString() ?? '',
        name: profile['name'] ?? 'Unknown',
        age: calculatedAge,
        gender: profile['gender'] ?? 'Unknown',
        activeDiseases: activeDiseases,
        riskLevel: _parseRiskLevel(profile['risk_level']),
        lastUpdate: latest,
        contactInfo: profile['phone_number'] ?? profile['contact_info'] ?? '',
        emergencyContactName: profile['emergency_contact_name'],
        emergencyContactRelationship: profile['emergency_contact_relationship'],
        emergencyContactPhone: profile['emergency_contact_phone'],
      );
    } catch (e) {
      debugPrint('Error fetching patient: $e');
      rethrow;
    }
  }

  @override
  Future<PatientHealthData> getPatientHealthData(String patientId) async {
    try {
      // Endpoint: GET /clinicians/me/patients/{id}
      final data = await _api.get('/clinicians/me/patients/$patientId');
      if (data == null) throw Exception('Patient data not found');

      final monitorData = data['monitor_data'] as List? ?? [];
      final activityLogs = data['activity_logs'] as List? ?? [];
      
      // Parse monitor data into specific categories
      final glucose = <GlucoseReading>[];
      final hba1c = <HbA1cReading>[];
      
      // Grouping maps for multi-part data (BP, Cholesterol)
      final bpMap = <String, Map<String, dynamic>>{}; // timestamp -> {systolic, diastolic}
      final cholMap = <String, Map<String, dynamic>>{}; // timestamp -> {total, ldl, hdl, trig}

      for (var record in monitorData) {
        final type = record['data_type'];
        final value = (record['value'] as num).toDouble();
        final timestamp = DateTime.parse(record['measured_at']);
        final timeKey = timestamp.toString(); // Simple grouping key

        if (type == 'GLUCOSE') {
          glucose.add(GlucoseReading(
            timestamp: timestamp,
            value: value,
            context: 'Measured',
          ));
        } else if (type == 'HBA1C') {
          hba1c.add(HbA1cReading(
            timestamp: timestamp,
            value: value,
          ));
        } else if (type == 'BLOOD_PRESSURE_SYSTOLIC') {
          bpMap.putIfAbsent(timeKey, () => {'ts': timestamp});
          bpMap[timeKey]!['sys'] = value;
        } else if (type == 'BLOOD_PRESSURE_DIASTOLIC') {
          bpMap.putIfAbsent(timeKey, () => {'ts': timestamp});
          bpMap[timeKey]!['dia'] = value;
        } else if (type.startsWith('CHOLESTEROL')) {
          cholMap.putIfAbsent(timeKey, () => {'ts': timestamp});
          if (type == 'CHOLESTEROL_TOTAL') cholMap[timeKey]!['total'] = value;
          if (type == 'CHOLESTEROL_LDL') cholMap[timeKey]!['ldl'] = value;
          if (type == 'CHOLESTEROL_HDL') cholMap[timeKey]!['hdl'] = value;
          if (type == 'CHOLESTEROL_TRIGLYCERIDES') cholMap[timeKey]!['trig'] = value;
        }
      }

      // Convert maps to lists
      final bpReadings = bpMap.values
          .where((e) => e.containsKey('sys') && e.containsKey('dia'))
          .map((e) => BloodPressureReading(
                timestamp: e['ts'],
                systolic: e['sys'],
                diastolic: e['dia'],
              ))
          .toList();

      final cholReadings = cholMap.values
          .where((e) => e.containsKey('total'))
          .map((e) => CholesterolReading(
                timestamp: e['ts'],
                total: e['total'] ?? 0,
                ldl: e['ldl'] ?? 0,
                hdl: e['hdl'] ?? 0,
                triglycerides: e['trig'] ?? 0,
              ))
          .toList();

      // Parse daily_logs to mealEntries
      final dailyLogs = data['daily_logs'] as List? ?? [];
      final mealEntries = <MealEntry>[];

      for (var log in dailyLogs) {
        if (log['meal_desc'] != null || log['calories'] != null || log['photo_url'] != null) {
          mealEntries.add(MealEntry(
            timestamp: log['log_date'] != null ? DateTime.parse('${log['log_date']}T12:00:00Z') : DateTime.now(),
            mealType: log['meal_time'] ?? 'Meal',
            foodItems: log['meal_desc'] != null 
                ? [FoodItem(name: log['meal_desc'], quantity: 1, unit: 'serving', nutrition: {'calories': (log['calories'] as num?)?.toDouble() ?? 0})] 
                : [],
            nutritionSummary: {
              if (log['calories'] != null) 'calories': (log['calories'] as num).toDouble(),
            },
          ));
        }
      }
      
      mealEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Parse BMI from monitor data
      double weight = 70.0; // Default
      double height = 170.0; // Default
      final bmiRecords = monitorData.where((r) => r['data_type'] == 'BMI').toList();
      
      final bmiReadings = bmiRecords.map((r) {
        final val = (r['value'] as num).toDouble();
        final w = val * (1.7 * 1.7);
        return BmiReading(
          timestamp: DateTime.parse(r['measured_at']),
          value: val,
          weight: w,
          height: 170.0,
        );
      }).toList();
      bmiReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (bmiRecords.isNotEmpty) {
        // Reverse calculate weight if we assume height (or fetch height from profile if available)
        // For now, we'll just use the BMI value to display, but the model asks for weight/height.
        // We'll mock weight/height to match the BMI for the gauge.
        final latestBmi = (bmiRecords.last['value'] as num).toDouble();
        weight = latestBmi * (1.7 * 1.7);
      }

      // Parse medications
      final medsData = data['medications'] as List? ?? [];
      final medications = medsData.map((m) {
        final dict = m['medication_dictionary'] as Map<String, dynamic>?;
        final freq = m['dosage_frequencies'] as Map<String, dynamic>?;
        
        return Medication(
          name: dict?['brand_name'] ?? m['custom_medication_name'] ?? 'Unknown',
          dosage: m['amount'] ?? '',
          frequency: freq?['patient_text'] ?? 'Not specified',
          route: m['medication_type'] ?? 'Oral',
          startDate: m['created_at'] != null ? DateTime.parse(m['created_at']) : null,
          notes: m['notes'],
        );
      }).toList();

      return PatientHealthData(
        patientId: patientId,
        weight: weight,
        height: height,
        glucoseReadings: glucose,
        hbA1cReadings: hba1c,
        bloodPressureReadings: bpReadings,
        cholesterolReadings: cholReadings,
        bmiReadings: bmiReadings,
        activityData: _parseActivityData(activityLogs),
        mealEntries: mealEntries, 
        automatedActions: [], 
        medications: medications, 
        aiGeneratedSummary: 'Patient data loaded successfully.',
        detectedPatterns: [], 
        recommendations: [], 
      );
    } catch (e) {
      debugPrint('Error fetching patient health data: $e');
      rethrow;
    }
  }

  @override
  Future<List<Alert>> getAlerts() async {
    try {
      final data = await _api.get('/clinicians/me/alerts');
      if (data == null) return [];
      
      return (data as List).map((json) => Alert(
        id: json['id']?.toString() ?? '',
        patientId: json['patientId']?.toString() ?? '',
        patientName: json['patientName'] ?? 'Unknown',
        type: _parseAlertType(json['type']),
        timestamp: DateTime.parse(json['timestamp']),
        description: json['description'] ?? '',
        dataPointRef: json['dataPointRef']?.toString() ?? '',
      )).toList();
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      return [];
    }
  }

  @override
  Future<List<ClinicianNote>> getClinicianNotes(String patientId) async {
    try {
      // We fetch the full patient details which includes notes
      final data = await _api.get('/clinicians/me/patients/$patientId');
      if (data == null || data['notes'] == null) return [];
      
      return (data['notes'] as List).map((json) => ClinicianNote(
        id: json['id'].toString(),
        patientId: json['patient_id'].toString(),
        timestamp: DateTime.parse(json['created_at']),
        content: json['note_content'] ?? '',
        isPrivate: true,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      return [];
    }
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
  RiskLevel _parseRiskLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'high': return RiskLevel.high;
      case 'medium': return RiskLevel.medium;
      case 'low': return RiskLevel.low;
      default: return RiskLevel.low;
    }
  }

  AlertType _parseAlertType(String? type) {
    switch (type) {
      case 'highGlucose': return AlertType.highGlucose;
      case 'lowGlucose': return AlertType.lowGlucose;
      case 'highHbA1c': return AlertType.highHbA1c;
      case 'highBloodPressure': return AlertType.highBloodPressure;
      default: return AlertType.missedMedication; // Fallback
    }
  }

  List<ActivityData> _parseActivityData(List? logs) {
    if (logs == null) return [];
    return logs.map((log) => ActivityData(
      date: log['start_time'] != null 
          ? DateTime.parse(log['start_time']) 
          : DateTime.parse(log['created_at']),
      steps: 0, // Not in DB yet
      activeMinutes: log['active_duration_minutes'] ?? 0,
      caloriesBurned: log['calories_burned'] ?? 0,
    )).toList();
  }
}

