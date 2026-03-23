import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/patient/core/repositories/medication_repository.dart';
import '../../../../core/models/medication_models.dart';

/// Provider for fetching the list of all medications for the current patient.
final patientMedicationsProvider = FutureProvider<List<PatientMedication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getPatientMedications();
});
