import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/patient/core/repositories/medication_repository.dart';
import 'package:florence/core/models/medication_models.dart';

/// Provider for the list of all medications assigned to the patient.
/// Removed .autoDispose to ensure state preservation across tab switches.
final patientMedicationsProvider = FutureProvider<List<PatientMedication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getPatientMedications();
});
