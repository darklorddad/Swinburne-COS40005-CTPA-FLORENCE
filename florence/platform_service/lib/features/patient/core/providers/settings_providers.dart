import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';

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
    // TODO: In a future PR, fetch initial settings from userProfileProvider
    return PatientSettings();
  }

  Future<void> updateGlucoseUnit(String unit) async {
    final previousState = state;
    state = state.copyWith(glucoseUnit: unit);

    try {
      await ref.read(settingsRepositoryProvider).updateSettings(glucoseUnit: unit);
    } catch (e) {
      state = previousState;
      debugPrint('Failed to update glucose unit: $e');
    }
  }

  Future<void> updateCholesterolUnit(String unit) async {
    final previousState = state;
    state = state.copyWith(cholesterolUnit: unit);

    try {
      await ref.read(settingsRepositoryProvider).updateSettings(cholesterolUnit: unit);
    } catch (e) {
      state = previousState;
      debugPrint('Failed to update cholesterol unit: $e');
    }
  }
}

final patientSettingsProvider = NotifierProvider<PatientSettingsNotifier, PatientSettings>(() {
  return PatientSettingsNotifier();
});
