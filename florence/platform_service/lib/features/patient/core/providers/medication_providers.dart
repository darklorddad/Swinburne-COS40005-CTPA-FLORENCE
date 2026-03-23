import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/medication_repository.dart';
import '../../../../core/models/medication_models.dart';

/// Provider for the list of all medications assigned to the patient.
final patientMedicationsProvider = FutureProvider<List<PatientMedication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getPatientMedications();
});
