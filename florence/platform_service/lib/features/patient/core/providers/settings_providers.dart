import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';
import 'threshold_providers.dart';

class PatientSettings {
  final String glucoseUnit;
  final String cholesterolUnit;
  final bool showQuickActions;

  PatientSettings({
    this.glucoseUnit = 'mmol/L',
    this.cholesterolUnit = 'mmol/L',
    this.showQuickActions = false,
  });

  PatientSettings copyWith({String? glucoseUnit, String? cholesterolUnit, bool? showQuickActions}) {
    return PatientSettings(
      glucoseUnit: glucoseUnit ?? this.glucoseUnit,
      cholesterolUnit: cholesterolUnit ?? this.cholesterolUnit,
      showQuickActions: showQuickActions ?? this.showQuickActions,
    );
  }
}

class PatientSettingsNotifier extends Notifier<PatientSettings> {
  @override
  PatientSettings build() {
    _fetchInitialSettings();
    return PatientSettings();
  }

  Future<void> _fetchInitialSettings() async {
    try {
      final fetchedSettings = await ref.read(settingsRepositoryProvider).getSettings();
      state = fetchedSettings;
    } catch (e) {
      debugPrint('Failed to load initial user settings: $e');
    }
  }

  Future<void> updateGlucoseUnit(String unit) async {
    final previousState = state;
    state = state.copyWith(glucoseUnit: unit);

    try {
      await ref.read(settingsRepositoryProvider).updateSettings(glucoseUnit: unit);
      ref.invalidate(patientThresholdsProvider);
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
      ref.invalidate(patientThresholdsProvider);
    } catch (e) {
      state = previousState;
      debugPrint('Failed to update cholesterol unit: $e');
    }
  }

  Future<void> toggleQuickActions(bool value) async {
    final previousState = state;
    state = state.copyWith(showQuickActions: value);

    try {
      await ref.read(settingsRepositoryProvider).updateSettings(showQuickActions: value);
    } catch (e) {
      state = previousState;
      debugPrint('Failed to update quick actions setting: $e');
    }
  }
}

final patientSettingsProvider = NotifierProvider<PatientSettingsNotifier, PatientSettings>(() {
  return PatientSettingsNotifier();
});
