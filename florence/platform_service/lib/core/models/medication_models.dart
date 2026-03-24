import 'package:flutter/foundation.dart';

/// Model representing a medication in the global dictionary.
@immutable
class MedicationDictionaryEntry {
  final int id;
  final String brandName;
  final String genericName;
  final String? category;

  const MedicationDictionaryEntry({
    required this.id,
    required this.brandName,
    required this.genericName,
    this.category,
  });

  factory MedicationDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return MedicationDictionaryEntry(
      id: json['id'] as int,
      brandName: json['brand_name'] as String,
      genericName: json['generic_name'] as String,
      category: json['category'] as String?,
    );
  }
}

/// Model representing a medication assigned to a specific patient.
@immutable
class PatientMedication {
  final int id;
  final int patientId;
  final int? medicationId;
  final String? customMedicationName;
  final int frequencyId;
  final String amount;
  final String? medicationType;
  final String? timingInstruction;
  final String status;
  final Map<String, dynamic> medicationDictionary;

  const PatientMedication({
    required this.id,
    required this.patientId,
    this.medicationId,
    this.customMedicationName,
    required this.frequencyId,
    required this.amount,
    this.medicationType,
    this.timingInstruction,
    required this.status,
    required this.medicationDictionary,
  });

  factory PatientMedication.fromJson(Map<String, dynamic> json) {
    return PatientMedication(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      medicationId: json['medication_id'] as int?,
      customMedicationName: json['custom_medication_name'] as String?,
      frequencyId: json['frequency_id'] as int,
      amount: json['amount'] as String,
      medicationType: json['medication_type'] as String?,
      timingInstruction: json['timing_instruction'] as String?,
      status: json['status'] as String,
      // SAFE CHECK: Handle null dictionary for custom medications by providing a fallback map
      medicationDictionary: json['medication_dictionary'] != null 
          ? json['medication_dictionary'] as Map<String, dynamic>
          : {
              'brand_name': json['custom_medication_name'] ?? 'Unknown',
              'generic_name': '',
              'dosage_frequencies': {'patient_text': 'Once a day'},
            },
    );
  }
}

/// Model representing a log of a patient taking their medication.
@immutable
class MedicationIntakeLog {
  final int id;
  final int patientId;
  final int patientMedicationId;
  final String status;
  final DateTime takenAt;
  final String? notes;

  const MedicationIntakeLog({
    required this.id,
    required this.patientId,
    required this.patientMedicationId,
    required this.status,
    required this.takenAt,
    this.notes,
  });

  factory MedicationIntakeLog.fromJson(Map<String, dynamic> json) {
    return MedicationIntakeLog(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      patientMedicationId: json['patient_medication_id'] as int,
      status: json['status'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String),
      notes: json['notes'] as String?,
    );
  }
}

/// Response model for the medication schedule endpoint.
class MedicationScheduleResponse {
  final List<PatientMedication> medications;
  final List<MedicationIntakeLog> todaysLogs;

  MedicationScheduleResponse({
    required this.medications,
    required this.todaysLogs,
  });

  factory MedicationScheduleResponse.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleResponse(
      medications: (json['medications'] as List)
          .map((m) => PatientMedication.fromJson(m as Map<String, dynamic>))
          .toList(),
      todaysLogs: (json['todays_logs'] as List)
          .map((l) => MedicationIntakeLog.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}
