enum AlertType {
  highGlucose,
  lowGlucose,
  highHbA1c,
  lowPhysicalActivity,
  missedMedication,
  irregularSleepPattern,
  highBloodPressure,
}

class Alert {
  final String id;
  final String patientId;
  final String patientName;
  final AlertType type;
  final DateTime timestamp;
  final String description;
  final String dataPointRef; // Reference to specific data that triggered the alert
  
  Alert({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.type,
    required this.timestamp,
    required this.description,
    required this.dataPointRef,
  });
  
  String get typeDisplay {
    switch (type) {
      case AlertType.highGlucose:
        return 'High Glucose Reading';
      case AlertType.lowGlucose:
        return 'Low Glucose Reading';
      case AlertType.highHbA1c:
        return 'High HbA1c Reading';
      case AlertType.lowPhysicalActivity:
        return 'Low Physical Activity';
      case AlertType.missedMedication:
        return 'Missed Medication';
      case AlertType.irregularSleepPattern:
        return 'Irregular Sleep Pattern';
      case AlertType.highBloodPressure:
        return 'High Blood Pressure';
    }
  }
}
