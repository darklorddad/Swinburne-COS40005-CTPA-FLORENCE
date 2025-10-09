import 'dart:math';
import '../models/health_data.dart';

class AnomalyDetector {
  static const Map<String, double> _thresholds = {
    'glucose_spike': 180.0,
    'glucose_low': 70.0,
    'glucose_critical_low': 50.0,
    'glucose_critical_high': 300.0,
    'hba1c_high': 7.0,
    'activity_low': 2000.0,
    'sleep_low': 4.0,
    'sleep_high': 12.0,
    'heart_rate_high': 120.0,
    'heart_rate_low': 50.0,
  };

  /// Detect anomalies in health data
  static List<Anomaly> detectAnomalies({
    required String patientId,
    required List<HealthData> recentData,
    required PatientProfile patientProfile,
  }) {
    final anomalies = <Anomaly>[];

    // Detect glucose anomalies
    anomalies.addAll(_detectGlucoseAnomalies(patientId, recentData, patientProfile));

    // Detect activity anomalies
    anomalies.addAll(_detectActivityAnomalies(patientId, recentData, patientProfile));

    // Detect sleep anomalies
    anomalies.addAll(_detectSleepAnomalies(patientId, recentData, patientProfile));

    // Detect medication adherence anomalies
    anomalies.addAll(_detectMedicationAnomalies(patientId, recentData, patientProfile));

    // Detect heart rate anomalies
    anomalies.addAll(_detectHeartRateAnomalies(patientId, recentData, patientProfile));

    // Detect HbA1c anomalies
    anomalies.addAll(_detectHba1cAnomalies(patientId, recentData, patientProfile));

    return anomalies;
  }

  /// Detect glucose-related anomalies
  static List<Anomaly> _detectGlucoseAnomalies(
    String patientId,
    List<HealthData> data,
    PatientProfile profile,
  ) {
    final anomalies = <Anomaly>[];
    final glucoseReadings = data.where((d) => d.glucoseLevel != null).toList();

    for (final reading in glucoseReadings) {
      final glucose = reading.glucoseLevel!;
      final timestamp = reading.timestamp;

      // Critical high glucose
      if (glucose >= _thresholds['glucose_critical_high']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: timestamp,
          anomalyType: 'glucose_critical_high',
          severity: 'critical',
          description: 'Critical high glucose level detected: ${glucose.toStringAsFixed(1)} mg/dL',
          context: {
            'glucoseLevel': glucose,
            'timestamp': timestamp.toIso8601String(),
            'mealType': reading.mealType,
            'medicationTaken': reading.medicationTaken,
          },
        ));
      }
      // High glucose spike
      else if (glucose >= _thresholds['glucose_spike']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: timestamp,
          anomalyType: 'glucose_spike',
          severity: 'high',
          description: 'High glucose spike detected: ${glucose.toStringAsFixed(1)} mg/dL',
          context: {
            'glucoseLevel': glucose,
            'timestamp': timestamp.toIso8601String(),
            'mealType': reading.mealType,
            'medicationTaken': reading.medicationTaken,
          },
        ));
      }
      // Critical low glucose
      else if (glucose <= _thresholds['glucose_critical_low']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: timestamp,
          anomalyType: 'glucose_critical_low',
          severity: 'critical',
          description: 'Critical low glucose level detected: ${glucose.toStringAsFixed(1)} mg/dL',
          context: {
            'glucoseLevel': glucose,
            'timestamp': timestamp.toIso8601String(),
            'mealType': reading.mealType,
            'medicationTaken': reading.medicationTaken,
          },
        ));
      }
      // Low glucose
      else if (glucose <= _thresholds['glucose_low']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: timestamp,
          anomalyType: 'glucose_low',
          severity: 'moderate',
          description: 'Low glucose level detected: ${glucose.toStringAsFixed(1)} mg/dL',
          context: {
            'glucoseLevel': glucose,
            'timestamp': timestamp.toIso8601String(),
            'mealType': reading.mealType,
            'medicationTaken': reading.medicationTaken,
          },
        ));
      }
    }

    return anomalies;
  }

  /// Detect activity-related anomalies
  static List<Anomaly> _detectActivityAnomalies(
    String patientId,
    List<HealthData> data,
    PatientProfile profile,
  ) {
    final anomalies = <Anomaly>[];
    final activityData = data.where((d) => d.steps != null).toList();

    // Check for consecutive low activity days
    int consecutiveLowDays = 0;
    for (final reading in activityData) {
      if (reading.steps! < _thresholds['activity_low']!) {
        consecutiveLowDays++;
      } else {
        consecutiveLowDays = 0;
      }

      if (consecutiveLowDays >= 3) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: reading.timestamp,
          anomalyType: 'inactivity_pattern',
          severity: 'moderate',
          description: 'Consecutive low activity days detected: ${consecutiveLowDays} days',
          context: {
            'consecutiveDays': consecutiveLowDays,
            'avgSteps': activityData.map((d) => d.steps!).reduce((a, b) => a + b) / activityData.length,
            'timestamp': reading.timestamp.toIso8601String(),
          },
        ));
        break;
      }
    }

    return anomalies;
  }

  /// Detect sleep-related anomalies
  static List<Anomaly> _detectSleepAnomalies(
    String patientId,
    List<HealthData> data,
    PatientProfile profile,
  ) {
    final anomalies = <Anomaly>[];
    final sleepData = data.where((d) => d.sleepHours != null).toList();

    for (final reading in sleepData) {
      final sleepHours = reading.sleepHours!;

      if (sleepHours < _thresholds['sleep_low']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: reading.timestamp,
          anomalyType: 'insufficient_sleep',
          severity: 'moderate',
          description: 'Insufficient sleep detected: ${sleepHours.toStringAsFixed(1)} hours',
          context: {
            'sleepHours': sleepHours,
            'timestamp': reading.timestamp.toIso8601String(),
            'stressLevel': reading.stressLevel,
          },
        ));
      } else if (sleepHours > _thresholds['sleep_high']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: reading.timestamp,
          anomalyType: 'excessive_sleep',
          severity: 'low',
          description: 'Excessive sleep detected: ${sleepHours.toStringAsFixed(1)} hours',
          context: {
            'sleepHours': sleepHours,
            'timestamp': reading.timestamp.toIso8601String(),
            'stressLevel': reading.stressLevel,
          },
        ));
      }
    }

    return anomalies;
  }

  /// Detect medication adherence anomalies
  static List<Anomaly> _detectMedicationAnomalies(
    String patientId,
    List<HealthData> data,
    PatientProfile profile,
  ) {
    final anomalies = <Anomaly>[];
    final medicationData = data.where((d) => d.medicationTaken != null).toList();

    if (medicationData.isNotEmpty) {
      final missedCount = medicationData.where((d) => d.medicationTaken == 'no' || d.medicationTaken == 'missed').length;
      final adherenceRate = ((medicationData.length - missedCount) / medicationData.length) * 100;

      if (adherenceRate < 70) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: DateTime.now(),
          anomalyType: 'medication_non_adherence',
          severity: 'high',
          description: 'Low medication adherence detected: ${adherenceRate.toStringAsFixed(1)}%',
          context: {
            'adherenceRate': adherenceRate,
            'missedCount': missedCount,
            'totalCount': medicationData.length,
            'medications': profile.medications,
          },
        ));
      }
    }

    return anomalies;
  }

  /// Detect heart rate anomalies
  static List<Anomaly> _detectHeartRateAnomalies(
    String patientId,
    List<HealthData> data,
    PatientProfile profile,
  ) {
    final anomalies = <Anomaly>[];
    final heartRateData = data.where((d) => d.heartRate != null).toList();

    for (final reading in heartRateData) {
      final heartRate = reading.heartRate!;

      if (heartRate > _thresholds['heart_rate_high']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: reading.timestamp,
          anomalyType: 'high_heart_rate',
          severity: 'moderate',
          description: 'High heart rate detected: ${heartRate.toStringAsFixed(0)} bpm',
          context: {
            'heartRate': heartRate,
            'timestamp': reading.timestamp.toIso8601String(),
            'activity': reading.steps,
            'stressLevel': reading.stressLevel,
          },
        ));
      } else if (heartRate < _thresholds['heart_rate_low']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: reading.timestamp,
          anomalyType: 'low_heart_rate',
          severity: 'moderate',
          description: 'Low heart rate detected: ${heartRate.toStringAsFixed(0)} bpm',
          context: {
            'heartRate': heartRate,
            'timestamp': reading.timestamp.toIso8601String(),
            'activity': reading.steps,
            'stressLevel': reading.stressLevel,
          },
        ));
      }
    }

    return anomalies;
  }

  /// Detect HbA1c anomalies
  static List<Anomaly> _detectHba1cAnomalies(
    String patientId,
    List<HealthData> data,
    PatientProfile profile,
  ) {
    final anomalies = <Anomaly>[];
    final hba1cData = data.where((d) => d.hba1cLevel != null).toList();

    for (final reading in hba1cData) {
      final hba1c = reading.hba1cLevel!;

      if (hba1c > _thresholds['hba1c_high']!) {
        anomalies.add(Anomaly(
          id: _generateId(),
          patientId: patientId,
          detectedAt: reading.timestamp,
          anomalyType: 'high_hba1c',
          severity: 'high',
          description: 'High HbA1c level detected: ${hba1c.toStringAsFixed(1)}%',
          context: {
            'hba1cLevel': hba1c,
            'timestamp': reading.timestamp.toIso8601String(),
            'diabetesType': profile.diabetesType,
          },
        ));
      }
    }

    return anomalies;
  }

  /// Calculate risk score based on anomalies
  static String calculateRiskLevel(List<Anomaly> anomalies) {
    int criticalCount = 0;
    int highCount = 0;
    int moderateCount = 0;

    for (final anomaly in anomalies) {
      switch (anomaly.severity) {
        case 'critical':
          criticalCount++;
          break;
        case 'high':
          highCount++;
          break;
        case 'moderate':
          moderateCount++;
          break;
      }
    }

    if (criticalCount > 0) return 'critical';
    if (highCount >= 2) return 'high';
    if (highCount >= 1 || moderateCount >= 3) return 'moderate';
    return 'low';
  }

  /// Generate unique ID
  static String _generateId() {
    return 'anomaly_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
