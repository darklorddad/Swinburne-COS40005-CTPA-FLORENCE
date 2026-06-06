import 'dart:convert';
import 'dart:math';

import 'package:florence/core/config/environment.dart';
import 'package:florence/core/models/medication_models.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/disease_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Payload class for all health data
class HealthDataState {
  final List<GlucoseReading> glucoseReadings;
  final List<MealLog> meals;
  final List<ActivityLog> activities;
  final List<PatientMedication> patientMedications; // real model from patient_medications table
  final double medicationAdherence;                 // today's adherence from schedule API
  final List<DiseaseLog> diseaseLogs;               // from disease_logs table
  final List<HbA1cResult> hba1cResults;
  final List<BloodPressureReading> bloodPressureReadings;
  final List<CholesterolResult> cholesterolResults;
  final List<MonitorData> hdlResults;         // CHOLESTEROL_HDL rows
  final List<MonitorData> ldlResults;         // CHOLESTEROL_LDL rows
  final List<MonitorData> triglycerideResults; // CHOLESTEROL_TRIGLYCERIDES rows
  final List<BmiResult> bmiResults;
  final List<HealthThreshold> healthThresholds;
  final List<MonitorData> allMonitorData;

  const HealthDataState({
    this.glucoseReadings = const [],
    this.meals = const [],
    this.activities = const [],
    this.patientMedications = const [],
    this.medicationAdherence = 0.0,
    this.diseaseLogs = const [],
    this.hba1cResults = const [],
    this.bloodPressureReadings = const [],
    this.cholesterolResults = const [],
    this.hdlResults = const [],
    this.ldlResults = const [],
    this.triglycerideResults = const [],
    this.bmiResults = const [],
    this.healthThresholds = const [],
    this.allMonitorData = const [],
  });

  HealthDataState copyWith({
    List<GlucoseReading>? glucoseReadings,
    List<MealLog>? meals,
    List<ActivityLog>? activities,
    List<PatientMedication>? patientMedications,
    double? medicationAdherence,
    List<DiseaseLog>? diseaseLogs,
    List<HbA1cResult>? hba1cResults,
    List<BloodPressureReading>? bloodPressureReadings,
    List<CholesterolResult>? cholesterolResults,
    List<MonitorData>? hdlResults,
    List<MonitorData>? ldlResults,
    List<MonitorData>? triglycerideResults,
    List<BmiResult>? bmiResults,
    List<HealthThreshold>? healthThresholds,
    List<MonitorData>? allMonitorData,
  }) {
    return HealthDataState(
      glucoseReadings: glucoseReadings ?? this.glucoseReadings,
      meals: meals ?? this.meals,
      activities: activities ?? this.activities,
      patientMedications: patientMedications ?? this.patientMedications,
      medicationAdherence: medicationAdherence ?? this.medicationAdherence,
      diseaseLogs: diseaseLogs ?? this.diseaseLogs,
      hba1cResults: hba1cResults ?? this.hba1cResults,
      bloodPressureReadings: bloodPressureReadings ?? this.bloodPressureReadings,
      cholesterolResults: cholesterolResults ?? this.cholesterolResults,
      hdlResults: hdlResults ?? this.hdlResults,
      ldlResults: ldlResults ?? this.ldlResults,
      triglycerideResults: triglycerideResults ?? this.triglycerideResults,
      bmiResults: bmiResults ?? this.bmiResults,
      healthThresholds: healthThresholds ?? this.healthThresholds,
      allMonitorData: allMonitorData ?? this.allMonitorData,
    );
  }

  HealthSummary getHealthSummary({required DateTime startDate, required DateTime endDate}) {
    // 1. Get direct readings
    final directReadings = glucoseReadings
        .where((r) => r.timestamp.isAfter(startDate) && r.timestamp.isBefore(endDate))
        .map((r) => r.value);

    // 2. Extract readings from meals in this period
    final mealReadings = meals
        .where((m) => m.timestamp.isAfter(startDate) && m.timestamp.isBefore(endDate))
        .expand((m) => [
              if (m.glucoseBefore != null) m.glucoseBefore!,
              if (m.glucoseAfter != null) m.glucoseAfter!
            ]);

    // 3. Combine them
    final allGlucoseValues = [...directReadings, ...mealReadings].toList();

    // 4. Calculate Average using the combined list
    final avgGlucose = allGlucoseValues.isNotEmpty
        ? allGlucoseValues.reduce((a, b) => a + b) / allGlucoseValues.length
        : 0.0;

    // Detect unit securely (mmol/L is rarely above 40.0; mg/dL is rarely below 40.0)
    final bool isMmol = allGlucoseValues.isNotEmpty && avgGlucose < 40.0;
    final double highBound = isMmol ? 10.0 : 180.0;
    final double lowBound = isMmol ? 3.9 : 70.0;

    // 5. Calculate Time In Range using the combined list
    final inRangeCount = allGlucoseValues.where((v) => v >= lowBound && v <= highBound).length;
    final timeInRange = allGlucoseValues.isNotEmpty
        ? (inRangeCount / allGlucoseValues.length) * 100
        : 0.0;

    final activityInPeriod = activities
        .where((a) => a.startTime.isAfter(startDate) && a.startTime.isBefore(endDate))
        .toList();
    final totalMinutes = activityInPeriod.fold(0, (sum, a) => sum + a.activeDurationMinutes);

    final mealsInPeriod = meals
        .where((m) => m.timestamp.isAfter(startDate) && m.timestamp.isBefore(endDate))
        .toList();

    // Average calories per meal (calories IS stored in daily_patient_logs; carbs is NOT)
    final avgCalories = mealsInPeriod.isNotEmpty
        ? mealsInPeriod.map((m) => m.calories.toDouble()).reduce((a, b) => a + b) /
            mealsInPeriod.length
        : 0.0;

    // Calculate Standard Deviation
    double stdDev = 0.0;
    if (allGlucoseValues.isNotEmpty) {
      final sumSquaredDiff = allGlucoseValues.fold(0.0, (sum, v) {
        final diff = v - avgGlucose;
        return sum + (diff * diff);
      });
      stdDev = sqrt(sumSquaredDiff / allGlucoseValues.length);
    }

    final hyperEvents = allGlucoseValues.where((v) => v > highBound).length;
    final hypoEvents = allGlucoseValues.where((v) => v < lowBound).length;

    // Calculate Estimated A1c: Formula strictly requires mg/dL
    final double avgMgDl = isMmol ? (avgGlucose * 18.0) : avgGlucose;
    final estimatedA1c = avgMgDl > 0 ? (avgMgDl + 46.7) / 28.7 : 0.0;

    // Latest single-value vitals
    final sortedBmi = [...bmiResults]..sort((a, b) => b.testDate.compareTo(a.testDate));
    final latestBmi = sortedBmi.isNotEmpty ? sortedBmi.first.value : null;

    final sortedBp = [...bloodPressureReadings]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latestSystolic = sortedBp.isNotEmpty ? sortedBp.first.systolic : null;
    final latestDiastolic = sortedBp.isNotEmpty ? sortedBp.first.diastolic : null;

    final sortedChol = [...cholesterolResults]..sort((a, b) => b.testDate.compareTo(a.testDate));
    final latestCholesterol = sortedChol.isNotEmpty ? sortedChol.first.value : null;

    final sortedHba1c = [...hba1cResults]..sort((a, b) => b.testDate.compareTo(a.testDate));
    final latestHba1c = sortedHba1c.isNotEmpty ? sortedHba1c.first.value : null;

    // HDL, LDL, Triglycerides — now extracted separately from monitor data
    final sortedHdl = [...hdlResults]..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final latestHdl = sortedHdl.isNotEmpty ? sortedHdl.first.value : null;

    final sortedLdl = [...ldlResults]..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final latestLdl = sortedLdl.isNotEmpty ? sortedLdl.first.value : null;

    final sortedTrig = [...triglycerideResults]
        ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final latestTriglycerides = sortedTrig.isNotEmpty ? sortedTrig.first.value : null;

    // Active disease names (status == 'active' only)
    final activeDiseaseNames = diseaseLogs
        .where((d) => d.status == 'active')
        .map((d) => d.conditionName)
        .toList();

    // Current medications (status == 'CURRENT' only — excludes discontinued/past)
    final currentMedications = patientMedications
        .where((m) => m.status == 'CURRENT')
        .map((m) => {
              'name': m.medicationDictionary['brand_name'] ??
                  m.customMedicationName ??
                  'Unknown',
              'amount': m.amount,
              'timing': m.timingInstructions.join(', '),
              'type': m.medicationType ?? 'medication',
            })
        .toList();

    // Recent individual readings (newest first)
    final recentGlucose = ([...glucoseReadings]
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
        .take(10)
        .map((r) => {
              'value': r.value,
              'timestamp': r.timestamp.toIso8601String(),
            })
        .toList();

    final recentMealsList = ([...meals]
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
        .take(5)
        .map((m) => {
              'type': m.type,
              'description': m.description,
              'calories': m.calories,
              'glucose_before': m.glucoseBefore,
              'glucose_after': m.glucoseAfter,
              'timestamp': m.timestamp.toIso8601String(),
            })
        .toList();

    final recentActivitiesList = ([...activities]
          ..sort((a, b) => b.startTime.compareTo(a.startTime)))
        .take(5)
        .map((a) => {
              'type': a.type,
              'duration_minutes': a.activeDurationMinutes,
              'calories_burned': a.caloriesBurned,
              'timestamp': a.startTime.toIso8601String(),
            })
        .toList();

    return HealthSummary(
      startDate: startDate,
      endDate: endDate,
      averageGlucose: avgGlucose,
      glucoseStdDev: stdDev,
      estimatedA1c: estimatedA1c,
      timeInRange: timeInRange,
      totalReadings: allGlucoseValues.length,
      hyperEvents: hyperEvents,
      hypoEvents: hypoEvents,
      totalActivityMinutes: totalMinutes,
      totalMeals: mealsInPeriod.length,
      averageCalories: avgCalories,
      medicationAdherence: medicationAdherence,
      latestBmi: latestBmi,
      latestSystolic: latestSystolic,
      latestDiastolic: latestDiastolic,
      latestCholesterol: latestCholesterol,
      latestHdl: latestHdl,
      latestLdl: latestLdl,
      latestTriglycerides: latestTriglycerides,
      latestHba1c: latestHba1c,
      activeDiseaseNames: activeDiseaseNames,
      currentMedications: currentMedications,
      recentGlucoseReadings: recentGlucose,
      recentMeals: recentMealsList,
      recentActivities: recentActivitiesList,
    );
  }
}

class MonitorDataRepository {
  final ApiService _apiService;

  MonitorDataRepository(this._apiService);

  Future<List<MonitorData>> fetchMonitorDataPage({int limit = 20, int offset = 0}) async {
    final response = await _apiService.get('/patients/me/monitor-data?limit=$limit&offset=$offset&order=measured_at.desc');
    if (response is List) {
      return response.map((e) => MonitorData.fromJson(e)).toList();
    }
    return [];
  }

  Future<HealthDataState> fetchAllData({int limit = 20, int offset = 0}) async {
    // EXECUTE ALL REQUESTS IN PARALLEL FOR EFFICIENCY
    // This minimizes the initial load time to the slowest individual request
    final results = await Future.wait([
      _fetchThresholds(),                                              // Index 0
      _apiService.get('/patients/me/monitor-data?limit=$limit&offset=$offset&order=measured_at.desc'), // Index 1
      _fetchActivities(),                                              // Index 2
      _fetchMeals(),                                                   // Index 3
      _fetchPatientMedications(),                                      // Index 4
      _fetchDiseaseLogs(),                                             // Index 5
      _fetchMedicationAdherence(),                                     // Index 6
    ]);

    // Extract results
    final thresholds = results[0] as List<HealthThreshold>;
    final monitorDataJson = results[1] as List;
    final activities = results[2] as List<ActivityLog>;
    final meals = results[3] as List<MealLog>;
    final patientMedications = results[4] as List<PatientMedication>;
    final diseaseLogs = results[5] as List<DiseaseLog>;
    final medicationAdherence = results[6] as double;

    // Process Monitor Data
    final allMonitorData = monitorDataJson.map((e) => MonitorData.fromJson(e)).toList();

    final glucoseReadings = <GlucoseReading>[];
    final hba1cResults = <HbA1cResult>[];
    final cholesterolResults = <CholesterolResult>[];
    final hdlResults = <MonitorData>[];
    final ldlResults = <MonitorData>[];
    final triglycerideResults = <MonitorData>[];
    final bmiResults = <BmiResult>[];
    final systolicReadings = <String, dynamic>{};
    final diastolicReadings = <String, dynamic>{};
    final bloodPressureReadings = <BloodPressureReading>[];

    for (var item in monitorDataJson) {
      final dataType = item['data_type'];
      final timestamp = DateTime.parse(item['measured_at']);
      final id = item['id'].toString();
      final value = (item['value'] as num).toDouble();
      final patientId = item['patient_id'] as int? ?? 0;

      switch (dataType) {
        case 'GLUCOSE':
          glucoseReadings.add(GlucoseReading(
            id: id,
            timestamp: timestamp,
            value: value,
            // Convert to local to ensure '8 AM' is treated as morning, not UTC night
            context: _getGlucoseContext(timestamp.toLocal().hour),
            isFlagged: value > 180 || value < 70,
          ));
          break;
        case 'HBA1C':
          hba1cResults.add(HbA1cResult(
            id: id,
            testDate: timestamp,
            value: value,
          ));
          break;
        case 'BLOOD_PRESSURE_SYSTOLIC':
          systolicReadings[timestamp.toIso8601String()] = {'id': id, 'value': value};
          break;
        case 'BLOOD_PRESSURE_DIASTOLIC':
          diastolicReadings[timestamp.toIso8601String()] = {'id': id, 'value': value};
          break;
        case 'CHOLESTEROL':
        case 'CHOLESTEROL_TOTAL':
          cholesterolResults.add(CholesterolResult(
            id: id,
            testDate: timestamp,
            value: value,
          ));
          break;
        case 'CHOLESTEROL_HDL':
          hdlResults.add(MonitorData(
            id: int.tryParse(id) ?? 0,
            patientId: patientId,
            dataType: MonitorDataType.CHOLESTEROL_HDL,
            value: value,
            measuredAt: timestamp,
          ));
          break;
        case 'CHOLESTEROL_LDL':
          ldlResults.add(MonitorData(
            id: int.tryParse(id) ?? 0,
            patientId: patientId,
            dataType: MonitorDataType.CHOLESTEROL_LDL,
            value: value,
            measuredAt: timestamp,
          ));
          break;
        case 'CHOLESTEROL_TRIGLYCERIDES':
          triglycerideResults.add(MonitorData(
            id: int.tryParse(id) ?? 0,
            patientId: patientId,
            dataType: MonitorDataType.CHOLESTEROL_TRIGLYCERIDES,
            value: value,
            measuredAt: timestamp,
          ));
          break;
        case 'BMI':
          bmiResults.add(BmiResult(
            id: id,
            testDate: timestamp,
            value: value,
          ));
          break;
      }
    }

    // Pair BP readings
    systolicReadings.forEach((timestampStr, systolicData) {
      if (diastolicReadings.containsKey(timestampStr)) {
        final diastolicData = diastolicReadings[timestampStr];
        bloodPressureReadings.add(BloodPressureReading(
          id: systolicData['id'],
          timestamp: DateTime.parse(timestampStr),
          systolic: systolicData['value'],
          diastolic: diastolicData['value'],
        ));
      }
    });

    // 5. Integrate Meal Glucose into Monitor Data
    final mealMonitorData = <MonitorData>[];
    for (var m in meals) {
      final mealId = int.tryParse(m.id) ?? 0;
      
      // Glucose Before Meal
      if (m.glucoseBefore != null && m.glucoseBeforeTime != null) {
        mealMonitorData.add(MonitorData(
          id: -(mealId * 2), // Negative ID to avoid collision with main table
          patientId: 0, 
          dataType: MonitorDataType.GLUCOSE,
          value: m.glucoseBefore!,
          measuredAt: m.glucoseBeforeTime!,
        ));
      }
      
      // Glucose After Meal
      if (m.glucoseAfter != null && m.glucoseAfterTime != null) {
        mealMonitorData.add(MonitorData(
          id: -(mealId * 2) - 1,
          patientId: 0,
          dataType: MonitorDataType.GLUCOSE,
          value: m.glucoseAfter!,
          measuredAt: m.glucoseAfterTime!,
        ));
      }
    }

    // Combine and Sort
    final combinedMonitorData = [...allMonitorData, ...mealMonitorData];
    combinedMonitorData.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

    // Sort
    glucoseReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    hba1cResults.sort((a, b) => b.testDate.compareTo(a.testDate));
    bloodPressureReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    cholesterolResults.sort((a, b) => b.testDate.compareTo(a.testDate));
    hdlResults.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    ldlResults.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    triglycerideResults.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    bmiResults.sort((a, b) => b.testDate.compareTo(a.testDate));
    activities.sort((a, b) => b.startTime.compareTo(a.startTime));
    meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return HealthDataState(
      glucoseReadings: glucoseReadings,
      meals: meals,
      activities: activities,
      patientMedications: patientMedications,
      medicationAdherence: medicationAdherence,
      diseaseLogs: diseaseLogs,
      hba1cResults: hba1cResults,
      bloodPressureReadings: bloodPressureReadings,
      cholesterolResults: cholesterolResults,
      hdlResults: hdlResults,
      ldlResults: ldlResults,
      triglycerideResults: triglycerideResults,
      bmiResults: bmiResults,
      healthThresholds: thresholds,
      allMonitorData: combinedMonitorData,
    );
  }

  // ==================== WRITE OPERATIONS ====================

  Future<void> addGlucoseReading(GlucoseReading reading) async {
    await _apiService.post('/patients/me/monitor-data', {
      'data_type': 'GLUCOSE',
      'value': reading.value,
      'measured_at': reading.timestamp.toIso8601String(),
    });
    _triggerRiskAssessment();
  }

  Future<void> addMonitorData(String type, double value, DateTime timestamp, {int? documentId}) async {
    await _apiService.post('/patients/me/monitor-data', {
      'data_type': type,
      'value': value,
      'measured_at': timestamp.toIso8601String(),
      if (documentId != null) 'document_id': documentId,
    });
    _triggerRiskAssessment();
  }

  Future<int> createClinicalDocument({
    required int patientId,
    required String documentPath,
    required String documentType,
  }) async {
    final response = await _apiService.post('/patients/me/clinical-documents', {
      'patient_id': patientId,
      'document_path': documentPath,
      'document_type': documentType,
    });
    return response['id'] as int;
  }

  Future<void> addBloodPressure(DateTime timestamp, double systolic, double diastolic) async {
    await Future.wait([
      addMonitorData('BLOOD_PRESSURE_SYSTOLIC', systolic, timestamp),
      addMonitorData('BLOOD_PRESSURE_DIASTOLIC', diastolic, timestamp),
    ]);
  }

  Future<void> addMeal(
    String mealTime,
    DateTime logDate,
    String? mealDesc,
    // Add these optional parameters
    double? glucoseBefore,
    DateTime? timeBefore,
    double? glucoseAfter,
    DateTime? timeAfter, [
    int? calories,
    String? photoUrl,
  ]) async {
    // FIX: Convert back to Local before extracting the YYYY-MM-DD string.
    // This ensures that 7AM Monday (which is 11PM Sunday UTC) is logged as Monday.
    final Map<String, dynamic> payload = {
      'log_date': logDate.toLocal().toIso8601String().split('T')[0],
      'meal_time': mealTime,
    };

    // Only add meal_desc if it has a value to prevent overwriting existing data with null
    if (mealDesc != null && mealDesc.isNotEmpty) {
      payload['meal_desc'] = mealDesc;
    }

    if (calories != null) payload['calories'] = calories;
    if (photoUrl != null) payload['photo_url'] = photoUrl;

    // Add glucose data to payload if present
    if (glucoseBefore != null) {
      payload['glucose_before_meal'] = glucoseBefore;
      payload['glucose_before_meal_time'] = timeBefore?.toIso8601String();
    }

    if (glucoseAfter != null) {
      payload['glucose_after_meal'] = glucoseAfter;
      payload['glucose_after_meal_time'] = timeAfter?.toIso8601String();
    }

    await _apiService.post('/patients/me/daily-logs', payload);
    _triggerRiskAssessment();
  }

  Future<void> addActivity(ActivityLog log) async {
    await _apiService.post('/patients/me/activity-logs', {
      'activity_description': log.type,
      'active_duration_minutes': log.activeDurationMinutes,
      'start_time': log.startTime.toIso8601String(),
      'end_time': log.endTime.toIso8601String(),
      'calories_burned': log.caloriesBurned,
    });
    _triggerRiskAssessment();
  }

  Future<int> estimateActivityCalories({
    required int durationMinutes,
    required String description,
    double? weightKg,
    double? heightCm,
    int? age,
    String? gender,
  }) async {
    try {
      final llmUrl = '${Environment.llmEngineServiceUrl}/activity/estimate-calories';
      final session = Supabase.instance.client.auth.currentSession;
      
      final response = await http.post(
        Uri.parse(llmUrl),
        headers: {
          'Content-Type': 'application/json',
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'active_duration_minutes': durationMinutes,
          'activity_description': description,
          if (weightKg != null) 'weight_kg': weightKg,
          if (heightCm != null) 'height_cm': heightCm,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['estimated_calories'] as int;
      }
    } catch (e) {
      print("Error estimating calories: $e");
    }
    return durationMinutes * 5; // Fallback
  }

  Future<void> addMedication(String name, String type, String dosage, String timing, DateTime timestamp, String? notes) async {
    await _apiService.post('/patients/me/medications', {
      'name': name,
      'type': type,
      'dosage': dosage,
      'timing': timing,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    });
    _triggerRiskAssessment();
  }

  // ==================== FETCH HELPERS ====================

  Future<List<PatientMedication>> _fetchPatientMedications() async {
    try {
      final response = await _apiService.get('/patients/me/medications');
      if (response is List) {
        return response
            .map((j) => PatientMedication.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print("Error fetching medications: $e");
    }
    return [];
  }

  Future<List<DiseaseLog>> _fetchDiseaseLogs() async {
    try {
      final response = await _apiService.get('/patients/me/disease-logs');
      if (response is List) {
        return response
            .map((j) => DiseaseLog.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print("Error fetching disease logs: $e");
    }
    return [];
  }

  /// Computes today's medication adherence from the live schedule API.
  /// Formula: sum(times_logged) / sum(expected_doses_today) across all active meds.
  /// Returns 0.0 if the patient has no medications or the call fails.
  Future<double> _fetchMedicationAdherence() async {
    try {
      final schedule = await _apiService.get('/patients/me/medication-schedule');
      if (schedule is! List || schedule.isEmpty) return 1.0;
      int totalExpected = 0, totalLogged = 0;
      for (var item in schedule) {
        final med = PatientMedication.fromJson(item['medication'] as Map<String, dynamic>);
        final int timesLogged = item['times_logged'] ?? 0;
        final bool isWeekly = item['is_weekly'] ?? false;
        final int dosesExpected = isWeekly
            ? 1
            : (med.timingInstructions.isNotEmpty ? med.timingInstructions.length : 1);
        totalExpected += dosesExpected;
        totalLogged += timesLogged.clamp(0, dosesExpected);
      }
      return totalExpected > 0 ? totalLogged / totalExpected : 0.0;
    } catch (e) {
      print("Error computing medication adherence: $e");
      return 0.0;
    }
  }

  Future<List<HealthThreshold>> _fetchThresholds() async {
    try {
      final response = await _apiService.get('/patients/me/thresholds');
      if (response != null && response is List) {
        return response.map((item) => HealthThreshold.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching thresholds: $e");
    }
    return [];
  }

  Future<List<ActivityLog>> _fetchActivities() async {
    try {
      final activityData = await _apiService.get('/patients/me/activity-logs?order=start_time.desc');
      final activities = <ActivityLog>[];
      if (activityData is List) {
        for (var item in activityData) {
          activities.add(ActivityLog(
            id: item['id'].toString(),
            startTime: item['start_time'] != null 
                ? DateTime.parse(item['start_time']) 
                : DateTime.parse(item['created_at']),
            endTime: item['end_time'] != null 
                ? DateTime.parse(item['end_time']) 
                : DateTime.parse(item['created_at']).add(Duration(minutes: item['active_duration_minutes'] ?? 0)),
            type: item['activity_description'] ?? 'Activity',
            activeDurationMinutes: item['active_duration_minutes'] ?? 0,
            intensity: 'Moderate',
            caloriesBurned: item['calories_burned'],
          ));
        }
      }
      return activities;
    } catch (e) {
      print("Error fetching activities: $e");
      return [];
    }
  }

  Future<List<MealLog>> _fetchMeals() async {
    try {
      final mealData = await _apiService.get('/patients/me/daily-logs?order=log_date.desc');
      final meals = <MealLog>[];
      if (mealData is List) {
        for (var item in mealData) {
          meals.add(MealLog(
            id: item['id'].toString(),
            timestamp: DateTime.parse(item['log_date']),
            type: item['meal_time']?.toString().split('.').last ?? 'Snack',
            description: item['meal_desc'] ?? 'Logged Meal',
            carbs: 0, 
            calories: item['calories'] as int? ?? 0,
            photoUrl: item['photo_url'] as String?,
            glucoseBefore: item['glucose_before_meal'] != null ? (item['glucose_before_meal'] as num).toDouble() : null,
            glucoseAfter: item['glucose_after_meal'] != null ? (item['glucose_after_meal'] as num).toDouble() : null,
            glucoseBeforeTime: item['glucose_before_meal_time'] != null ? DateTime.parse(item['glucose_before_meal_time']) : null,
            glucoseAfterTime: item['glucose_after_meal_time'] != null ? DateTime.parse(item['glucose_after_meal_time']) : null,
          ));
        }
      }
      return meals;
    } catch (e) {
      print("Error fetching meals: $e");
      return [];
    }
  }

  // ==================== UTILS & MOCKS ====================

  String _getGlucoseContext(int hour) {
    if (hour >= 5 && hour < 9) return 'Before breakfast';
    if (hour >= 9 && hour < 11) return 'After breakfast';
    if (hour >= 11 && hour < 13) return 'Before lunch';
    if (hour >= 13 && hour < 17) return 'After lunch';
    if (hour >= 17 && hour < 19) return 'Before dinner';
    if (hour >= 19 && hour < 22) return 'After dinner';
    return 'Bedtime';
  }

  /// Silently triggers the LLM Engine to re-evaluate clinical risk.
  /// Fire-and-forget: does not block the UI or throw errors to the caller.
  void _triggerRiskAssessment() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      
      final url = Uri.parse('${Environment.llmEngineServiceUrl}/risk/assess');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      };
      
      // Fire and forget
      http.post(url, headers: headers).catchError((e) {
        print('[RiskEngine] Background trigger failed: $e');
      });
    } catch (e) {
      print('[RiskEngine] Error initiating trigger: $e');
    }
  }

}

/// Provider for the repository
final monitorDataRepositoryProvider = Provider<MonitorDataRepository>((ref) {
  // Create ApiService directly or use a provider if ApiService was converted to Riverpod
  // Assuming ApiService is still a factory/singleton
  return MonitorDataRepository(ApiService());
});
