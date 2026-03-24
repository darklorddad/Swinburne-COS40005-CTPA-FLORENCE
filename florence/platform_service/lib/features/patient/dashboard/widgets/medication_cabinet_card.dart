import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/models/medication_models.dart';
import '../../core/providers/medication_providers.dart';
import '../../core/repositories/medication_repository.dart';
import 'medication_form_dialog.dart';

/// A card for the dashboard that displays the patient's medication cabinet.
/// Stripped of its own container styling to fit within MedicationSection.
class MedicationCabinetCard extends ConsumerWidget {
  const MedicationCabinetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(patientMedicationsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches button to full width
        children: [
          // Content
          Expanded(
            child: medsAsync.when(
              data: (meds) {
                // Filter out 'PAST' (stopped) medications so they don't show in the active cabinet
                final activeMeds = meds.where((m) => m.status != 'PAST').toList();
                
                if (activeMeds.isEmpty) {
                  return Center(
                    child: Text(
                      "No active medications",
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: activeMeds.length,
                  itemBuilder: (context, index) {
                    final med = activeMeds[index];
                    return _buildCabinetRow(context, ref, med);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  "Unable to load cabinet",
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Add Medication Button at the bottom
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Add New Medication"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              foregroundColor: AppTheme.primaryBlue,
              // FIX: Forcing all elevations to 0 prevents the layout from shifting on hover
              elevation: 0,
              hoverElevation: 0,
              focusElevation: 0,
              highlightElevation: 0,
              splashFactory: NoSplash.splashFactory, // Removes the ripple for a cleaner look
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _showMedicationFormModal(context, isEdit: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCabinetRow(
    BuildContext context,
    WidgetRef ref,
    PatientMedication med,
  ) {
    final String brandName = med.medicationDictionary['brand_name'] ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.03)
              : AppTheme.backgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brandName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${med.amount} • ${med.timingInstruction ?? 'Anytime'}",
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showMedicationFormModal(context, isEdit: true, med: med);
                } else if (value == 'stop') {
                  _confirmStopMedication(context, ref, med, brandName);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'stop',
                  child: Row(
                    children: [
                      Icon(Icons.stop_circle, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Stop',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicationFormModal(BuildContext context, {required bool isEdit, PatientMedication? med}) {
    showDialog(
      context: context,
      builder: (context) => MedicationFormDialog(isEdit: isEdit, medication: med),
    );
  }

  void _confirmStopMedication(BuildContext context, WidgetRef ref, PatientMedication med, String medName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Stop Medication"),
        content: Text("Are you sure you want to stop taking $medName? It will be moved to your past records."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Call repository to update status to 'PAST'
              // await ref.read(medicationRepositoryProvider).updateMedicationStatus(med.id, 'PAST');
              // ref.invalidate(patientMedicationsProvider);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text("Stop Medication"),
          ),
        ],
      ),
    );
  }
}
