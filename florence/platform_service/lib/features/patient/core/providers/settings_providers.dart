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
  @override
  PatientSettings build() {
    return PatientSettings();
  }

  void updateGlucoseUnit(String unit) {
    state = state.copyWith(glucoseUnit: unit);
  }

  void updateCholesterolUnit(String unit) {
    state = state.copyWith(cholesterolUnit: unit);
  }
}

final patientSettingsProvider = NotifierProvider<PatientSettingsNotifier, PatientSettings>(() {
  return PatientSettingsNotifier();
});
