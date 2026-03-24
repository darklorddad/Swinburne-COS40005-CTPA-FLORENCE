import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/models/medication_models.dart';
import '../providers/medication_providers.dart';

/// Screen displaying the patient's medicine cabinet with active and past medications.
class MedicationCabinetScreen extends ConsumerWidget {
  const MedicationCabinetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(patientMedicationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Cabinet'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: medicationsAsync.when(
          data: (meds) {
            // Filter medications into Active (CURRENT) and History (PAST)
            // Note: Logic assumes 'status' field exists on PatientMedication as per requirements.
            final activeMeds = meds.where((m) => m.status == 'CURRENT').toList();
            final historyMeds = meds.where((m) => m.status == 'PAST').toList();

            return TabBarView(
              children: [
                _MedicationList(
                  medications: activeMeds,
                  emptyMessage: 'No active medications found.',
                ),
                _MedicationList(
                  medications: historyMeds,
                  emptyMessage: 'No medication history found.',
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to load medications: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/add-medication'),
          tooltip: 'Add Medication',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _MedicationList extends StatelessWidget {
  final List<PatientMedication> medications;
  final String emptyMessage;

  const _MedicationList({
    required this.medications,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final med = medications[index];
        final dict = med.medicationDictionary;
        // Use generic_name if available, otherwise brand_name
        final name = dict['generic_name'] ?? dict['brand_name'] ?? 'Unknown Medication';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _MedicationDetailRow(label: 'Amount', value: med.amount),
                _MedicationDetailRow(label: 'Type', value: med.medicationType ?? 'N/A'),
                _MedicationDetailRow(label: 'Timing', value: med.timingInstruction ?? 'Anytime'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MedicationDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _MedicationDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
