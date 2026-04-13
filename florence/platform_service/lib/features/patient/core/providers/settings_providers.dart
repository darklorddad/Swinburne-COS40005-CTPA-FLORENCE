import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/patient/core/repositories/settings_repository.dart';
import 'package:florence/features/patient/core/providers/threshold_providers.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';

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
    _backgroundSync(glucoseUnit: unit, previousState: previousState);
  }

  Future<void> updateCholesterolUnit(String unit) async {
    final previousState = state;
    state = state.copyWith(cholesterolUnit: unit);
    _backgroundSync(cholesterolUnit: unit, previousState: previousState);
  }

  Future<void> _backgroundSync({
    String? glucoseUnit,
    String? cholesterolUnit,
    required PatientSettings previousState,
  }) async {
    try {
      await ref.read(settingsRepositoryProvider).updateSettings(
            glucoseUnit: glucoseUnit ?? state.glucoseUnit,
            cholesterolUnit: cholesterolUnit ?? state.cholesterolUnit,
          );
      ref.invalidate(patientThresholdsProvider);
      ref.invalidate(monitorDataProvider);
    } catch (e) {
      state = previousState;
      debugPrint('Failed to sync unit: $e');
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
