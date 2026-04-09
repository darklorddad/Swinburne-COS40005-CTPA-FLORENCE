import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientSettings {
  final String glucoseUnit;
  final String cholesterolUnit;

  PatientSettings({
    this.glucoseUnit = 'mmol/L',
    this.cholesterolUnit = 'mmol/L',
  });

  PatientSettings copyWith({String? glucoseUnit, String? cholesterolUnit}) {
    return PatientSettings(
      glucoseUnit: glucoseUnit ?? this.glucoseUnit,
      cholesterolUnit: cholesterolUnit ?? this.cholesterolUnit,
    );
  }
}

class PatientSettingsNotifier extends Notifier<PatientSettings> {
  PatientSettingsNotifier() : super(PatientSettings());

  void updateGlucoseUnit(String unit) {
    state = state.copyWith(glucoseUnit: unit);
  }

  void updateCholesterolUnit(String unit) {
    state = state.copyWith(cholesterolUnit: unit);
  }
}

final patientSettingsProvider = StateNotifierProvider<PatientSettingsNotifier, PatientSettings>((ref) {
  return PatientSettingsNotifier();
});
