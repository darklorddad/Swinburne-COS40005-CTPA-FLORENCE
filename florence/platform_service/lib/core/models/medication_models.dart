/// Medication-related data models for the FLORENCE platform.

class PatientMedication {
  final int id;
  final Map<String, dynamic> medicationDictionary;
  final String amount;
  final String? medicationType;
  final String? timingInstruction;
  final String status;

  PatientMedication({
    required this.id,
    required this.medicationDictionary,
    required this.amount,
    this.medicationType,
    this.timingInstruction,
    required this.status,
  });

  factory PatientMedication.fromJson(Map<String, dynamic> json) {
    return PatientMedication(
      id: json['id'] as int,
      medicationDictionary: json['medication_dictionary'] as Map<String, dynamic>,
      amount: json['amount'] as String,
      medicationType: json['medication_type'] as String?,
      timingInstruction: json['timing_instruction'] as String?,
      status: json['status'] as String,
    );
  }
}

class MedicationIntakeLog {
  final int id;
  final int patientMedicationId;
  final DateTime takenAt;
  final String status;

  MedicationIntakeLog({
    required this.id,
    required this.patientMedicationId,
    required this.takenAt,
    required this.status,
  });

  factory MedicationIntakeLog.fromJson(Map<String, dynamic> json) {
    return MedicationIntakeLog(
      id: json['id'] as int,
      patientMedicationId: json['patient_medication_id'] as int,
      takenAt: DateTime.parse(json['taken_at'] as String),
      status: json['status'] as String,
    );
  }
}

class MedicationScheduleResponse {
  final List<PatientMedication> medications;
  final List<MedicationIntakeLog> todaysLogs;

  MedicationScheduleResponse({
    required this.medications,
    required this.todaysLogs,
  });

  factory MedicationScheduleResponse.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleResponse(
      medications: (json['medications'] as List<dynamic>)
          .map((e) => PatientMedication.fromJson(e as Map<String, dynamic>))
          .toList(),
      todaysLogs: (json['todays_logs'] as List<dynamic>)
          .map((e) => MedicationIntakeLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
